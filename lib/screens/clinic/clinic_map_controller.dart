import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/api/core_apis.dart';
import 'package:flutter/material.dart';
import 'package:kivicare_patient/network/location_service.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'model/clinics_res_model.dart';

class ClinicMapController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<Clinic> clinics = RxList();
  Rx<Position?> currentPosition = Rx<Position?>(null);
  RxSet<Marker> markers = RxSet<Marker>();
  Rxn<Clinic> selectedClinic = Rxn<Clinic>();
  RxString searchQuery = ''.obs;
  final TextEditingController searchTextController = TextEditingController();

  RxList<dynamic> placePredictions = <dynamic>[].obs;
  Timer? _debounce;
  final String _placesApiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ??
      const String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  GoogleMapController? mapController;

  // Default position (Kuwait)
  final CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(29.3759, 47.9774),
    zoom: 10,
  );

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    await getCurrentLocation();
    await getAllClinics();
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await getUserLocationPosition();
      currentPosition.value = position;

      // Move camera to current location
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 12,
            ),
          ),
        );
      }
    } catch (e) {
      log("Error getting current location: $e");
    }
  }

  Future<void> getAllClinics() async {
    isLoading(true);
    try {
      await CoreServiceApis.getClinics(
        page: 1,
        perPage: 100, // Get all clinics for the map
        clinics: clinics,
        lastPageCallBack: (p0) {},
      );

      _createMarkers();
    } catch (e) {
      log("Error getting clinics: $e");
    } finally {
      isLoading(false);
    }
  }

  void _createMarkers() {
    markers.clear();

    // Add current location marker
    if (currentPosition.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            currentPosition.value!.latitude,
            currentPosition.value!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow:
              const InfoWindow(title: 'موقعك الحالي', snippet: 'You are here'),
        ),
      );
    }

    // Add clinic markers
    final clinicsToShow = filteredClinics;
    for (var clinic in clinicsToShow) {
      if (clinic.latitude.isNotEmpty && clinic.longitude.isNotEmpty) {
        try {
          final lat = double.tryParse(clinic.latitude);
          final lng = double.tryParse(clinic.longitude);

          if (lat != null && lng != null) {
            markers.add(
              Marker(
                markerId: MarkerId('clinic_${clinic.id}'),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(
                  title: clinic.name,
                  snippet: clinic.address.isNotEmpty
                      ? clinic.address
                      : clinic.cityName,
                ),
                onTap: () {
                  _onClinicMarkerTap(clinic);
                },
              ),
            );
          }
        } catch (e) {
          log("Error parsing clinic coordinates: $e");
        }
      }
    }

    markers.refresh();
  }

  void _onClinicMarkerTap(Clinic clinic) {
    selectedClinic.value = clinic;
    // Center camera on selected clinic
    goToClinic(clinic);
  }

  void onMapTap(LatLng position) {
    selectedClinic.value = null;
  }

  List<Clinic> get filteredClinics {
    if (searchQuery.value.isEmpty) return clinics;
    final q = searchQuery.value.toLowerCase();
    return clinics
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.address.toLowerCase().contains(q) ||
            c.cityName.toLowerCase().contains(q))
        .toList();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    selectedClinic.value = null;
    _createMarkers();

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getPlacePredictions(query);
    });
  }

  Future<void> _getPlacePredictions(String query) async {
    if (query.isEmpty) {
      placePredictions.clear();
      return;
    }

    if (_placesApiKey.trim().isEmpty) {
      placePredictions.clear();
      if (kDebugMode) {
        log('Google Places API key is not configured');
      }
      return;
    }

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_placesApiKey&language=${selectedLanguageCode.value}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          placePredictions.value = data['predictions'];
        } else {
          placePredictions.clear();
        }
      }
    } catch (e) {
      log('Error getting predictions: $e');
    }
  }

  Future<void> onPlaceSelected(String placeId, String description) async {
    searchTextController.text = description;
    searchQuery.value = description;
    placePredictions.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      if (mapController == null) return;

      if (_placesApiKey.trim().isEmpty) {
        if (kDebugMode) {
          log('Google Places API key is not configured');
        }
        return;
      }

      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_placesApiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(loc['lat'], loc['lng']),
              12,
            ),
          );
        }
      }
    } catch (e) {
      log('Error getting place details: $e');
    }
  }

  void onSearchSubmitted(String query) {
    if (mapController == null) return;

    final searchClinics = filteredClinics;
    if (searchClinics.isEmpty) return;

    if (searchClinics.length == 1) {
      goToClinic(searchClinics.first);
      selectedClinic.value = searchClinics.first;
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var clinic in searchClinics) {
      if (clinic.latitude.isNotEmpty && clinic.longitude.isNotEmpty) {
        final lat = double.tryParse(clinic.latitude);
        final lng = double.tryParse(clinic.longitude);
        if (lat != null && lng != null) {
          if (lat < minLat) minLat = lat;
          if (lat > maxLat) maxLat = lat;
          if (lng < minLng) minLng = lng;
          if (lng > maxLng) maxLng = lng;
        }
      }
    }

    if (minLat != double.infinity) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    // Move to current location if available
    if (currentPosition.value != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentPosition.value!.latitude,
              currentPosition.value!.longitude,
            ),
            zoom: 12,
          ),
        ),
      );
    }
  }

  void goToCurrentLocation() {
    if (currentPosition.value != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentPosition.value!.latitude,
              currentPosition.value!.longitude,
            ),
            zoom: 14,
          ),
        ),
      );
    }
  }

  void goToClinic(Clinic clinic) {
    if (clinic.latitude.isNotEmpty &&
        clinic.longitude.isNotEmpty &&
        mapController != null) {
      final lat = double.tryParse(clinic.latitude);
      final lng = double.tryParse(clinic.longitude);

      if (lat != null && lng != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat, lng),
              zoom: 16,
            ),
          ),
        );
      }
    }
  }

  // Calculate distance between current location and clinic
  String getDistanceToClinic(Clinic clinic) {
    if (currentPosition.value == null ||
        clinic.latitude.isEmpty ||
        clinic.longitude.isEmpty) {
      return '';
    }

    try {
      final lat = double.tryParse(clinic.latitude);
      final lng = double.tryParse(clinic.longitude);

      if (lat != null && lng != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
          lat,
          lng,
        );

        if (distanceInMeters < 1000) {
          return '${distanceInMeters.toStringAsFixed(0)} م';
        } else {
          return '${(distanceInMeters / 1000).toStringAsFixed(1)} كم';
        }
      }
    } catch (e) {
      log("Error calculating distance: $e");
    }

    return '';
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }
}

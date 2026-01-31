import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/api/core_apis.dart';
import 'package:kivicare_patient/network/location_service.dart';
import 'model/clinics_res_model.dart';

class ClinicMapController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<Clinic> clinics = RxList();
  Rx<Position?> currentPosition = Rx<Position?>(null);
  RxSet<Marker> markers = RxSet<Marker>();

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
    for (var clinic in clinics) {
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
                    BitmapDescriptor.hueRed),
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
    // This is called when marker info window is tapped
    log("Clinic tapped: ${clinic.name}");
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

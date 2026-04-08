// ignore_for_file: body_might_complete_normally_catch_error

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/constants.dart';
import '../main.dart';
import '../utils/local_storage.dart';

Future<Position> getUserLocationPosition() async {
  final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  LocationPermission permission = await Geolocator.checkPermission();
  if (!serviceEnabled) {
    //
  }

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.openAppSettings();
      throw locale.value.locationPermissionDenied;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw '${locale.value.selectBranch} ${locale.value.permissionDeniedPermanently}';
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  ).catchError((_) async {
    final Position? value = await Geolocator.getLastKnownPosition();
    if (value != null) {
      return value;
    }
    throw locale.value.enableLocation;
  });
}

Future<String> getUserLocation() async {
  final Position position = await getUserLocationPosition().catchError((e) {
    throw e.toString();
  });

  return buildFullAddressFromLatLong(position.latitude, position.longitude);
}

Future<String> buildFullAddressFromLatLong(
    double latitude, double longitude) async {
  final List<Placemark> placeMark = await placemarkFromCoordinates(
    latitude,
    longitude,
  ).catchError((e) async {
    log(e);
    throw errorSomethingWentWrong;
  });

  if (placeMark.isEmpty) {
    throw errorSomethingWentWrong;
  }

  setValueToLocal(LocatinKeys.LATITUDE, latitude);
  setValueToLocal(LocatinKeys.LONGITUDE, longitude);

  final Placemark place = placeMark[0];

  String address = '';

  if (!place.name.isEmptyOrNull &&
      !place.street.isEmptyOrNull &&
      place.name != place.street) {
    address = '${place.name.validate()}, ';
  }
  if (!place.street.isEmptyOrNull) {
    address = '$address${place.street.validate()}';
  }
  if (!place.locality.isEmptyOrNull) {
    address = '$address, ${place.locality.validate()}';
  }
  if (!place.administrativeArea.isEmptyOrNull) {
    address = '$address, ${place.administrativeArea.validate()}';
  }
  if (!place.postalCode.isEmptyOrNull) {
    address = '$address, ${place.postalCode.validate()}';
  }
  if (!place.country.isEmptyOrNull) {
    address = '$address, ${place.country.validate()}';
  }

  setValueToLocal(LocatinKeys.CURRENT_ADDRESS, address);
  setValueToLocal(LocatinKeys.ZIP_CODE, place.postalCode.validate());

  return address;
}

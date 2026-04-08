import 'clinic_detail_model.dart';

import '../../../utils/app_common.dart';

class ClinicsRes {
  bool status;
  List<Clinic> data;
  String message;

  ClinicsRes({
    this.status = false,
    this.data = const <Clinic>[],
    this.message = "",
  });

  factory ClinicsRes.fromJson(Map<String, dynamic> json) {
    return ClinicsRes(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] is List
          ? List<Clinic>.from(json['data'].map((x) => Clinic.fromJson(x)))
          : [],
      message: json['message'] is String ? json['message'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}

class PopularClinicListRes {
  bool status;
  PopularClinicData? data;
  String message;

  PopularClinicListRes({
    this.status = false,
    this.data,
    this.message = "",
  });

  factory PopularClinicListRes.fromJson(Map<String, dynamic> json) {
    return PopularClinicListRes(
      status: json['status'] is bool ? json['status'] : false,
      data: json['data'] != null
          ? PopularClinicData.fromJson(json['data']['perfect_clinics'] ?? {})
          : null,
      message: json['message'] is String ? json['message'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': {
        'perfect_clinics': data?.toJson(),
      },
      'message': message,
    };
  }
}

class PopularClinicData {
  String title;
  String subTitle;
  List<Clinic> selectedClinic;

  PopularClinicData({
    this.title = "",
    this.subTitle = "",
    this.selectedClinic = const [],
  });

  factory PopularClinicData.fromJson(Map<String, dynamic> json) {
    return PopularClinicData(
      title: json['title'] is String ? json['title'] : "",
      subTitle: json['sub_title'] is String ? json['sub_title'] : "",
      selectedClinic: json['selected_clinic'] is List
          ? List<Clinic>.from(
              json['selected_clinic'].map((x) => Clinic.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'sub_title': subTitle,
      'selected_clinic': selectedClinic.map((e) => e.toJson()).toList(),
    };
  }
}

class Clinic {
  int id;
  String slug;
  String name;
  String email;
  String description;
  String systemServiceCategory;
  String specialty;
  String specialtyAr;
  String contactNumber;
  int countryId;
  int stateId;
  int cityId;
  String countryName;
  String stateName;
  String cityName;
  String address;
  String pincode;
  String latitude;
  String longitude;
  String googleMapLink;
  List<AdditionalAddress> additionalAddresses;
  dynamic distance;
  dynamic distanceFormate;
  int status;
  int isPending;
  String logo;
  String clinicImage;
  int createdBy;
  int updatedBy;
  int deletedBy;
  String createdAt;
  String updatedAt;
  String deletedAt;

  ///Clinic Detail
  dynamic timeSlot;
  int vendorId;
  ClinicSession clinicSession;
  List<AllClinicSession> allClinicSession;
  String clinicStatus;
  int totalServices;
  int totalDoctors;
  int totalGalleryImages;

  ///Doctor Detail
  int clinicId;
  int doctorId;

  int totalAppointment;
  int satisfactionPercentage;
  int totalVerifiedDoctor;

  bool get isPinned => isPending == 1;

  String get localizedSpecialty =>
      selectedLanguageCode.value == 'ar' && specialtyAr.isNotEmpty
          ? specialtyAr
          : specialty;

  Clinic({
    this.id = -1,
    this.slug = "",
    this.name = "",
    this.email = "",
    this.description = "",
    this.systemServiceCategory = "",
    this.specialty = "",
    this.specialtyAr = "",
    this.contactNumber = "",
    this.countryId = -1,
    this.stateId = -1,
    this.cityId = -1,
    this.countryName = "",
    this.stateName = "",
    this.cityName = "",
    this.address = "",
    this.pincode = "",
    this.latitude = "",
    this.longitude = "",
    this.googleMapLink = "",
    this.additionalAddresses = const <AdditionalAddress>[],
    this.distance,
    this.distanceFormate,
    this.status = -1,
    this.isPending = 0,
    this.logo = "",
    this.clinicImage = "",
    this.createdBy = -1,
    this.updatedBy = -1,
    this.deletedBy = -1,
    this.createdAt = "",
    this.updatedAt = "",
    this.deletedAt = "",
    this.timeSlot,
    this.vendorId = -1,
    required this.clinicSession,
    this.allClinicSession = const <AllClinicSession>[],
    this.clinicStatus = "",
    this.totalServices = 0,
    this.totalDoctors = 0,
    this.totalGalleryImages = 0,
    this.clinicId = -1,
    this.doctorId = -1,
    this.totalAppointment = 0,
    this.satisfactionPercentage = 0,
    this.totalVerifiedDoctor = 0,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] is int ? json['id'] : -1,
      slug: json['slug'] is String ? json['slug'] : "",
      name: json['name'] is String ? json['name'] : "",
      email: json['email'] is String ? json['email'] : "",
      description: json['description'] is String ? json['description'] : "",
      systemServiceCategory: json['system_service_category'] is String
          ? json['system_service_category']
          : "",
      specialty: json['specialty'] is String ? json['specialty'] : "",
      specialtyAr: json['specialty_ar'] is String ? json['specialty_ar'] : "",
      contactNumber:
          json['contact_number'] is String ? json['contact_number'] : "",
      countryId: json['country_id'] is int ? json['country_id'] : -1,
      stateId: json['state_id'] is int ? json['state_id'] : -1,
      cityId: json['city_id'] is int ? json['city_id'] : -1,
      countryName: json['country_name'] is String ? json['country_name'] : "",
      stateName: json['state_name'] is String ? json['state_name'] : "",
      cityName: json['city_name'] is String ? json['city_name'] : "",
      address: json['address'] is String ? json['address'] : "",
      pincode: json['pincode'] is String ? json['pincode'] : "",
      latitude: json['latitude'] is String ? json['latitude'] : "",
      longitude: json['longitude'] is String ? json['longitude'] : "",
      googleMapLink:
          json['google_map_link'] is String ? json['google_map_link'] : "",
      additionalAddresses: json['additional_addresses'] is List
          ? List<AdditionalAddress>.from(json['additional_addresses']
              .map((x) => AdditionalAddress.fromJson(x)))
          : [],
      distance: json['distance'],
      distanceFormate: json['distance_formate'],
      status: json['status'] is int ? json['status'] : -1,
      isPending: json['is_pending'] is int
          ? json['is_pending']
          : json['is_pending'] is bool
              ? (json['is_pending'] ? 1 : 0)
              : int.tryParse('${json['is_pending'] ?? 0}') ?? 0,
      logo: json['logo'] is String ? json['logo'] : "",
      clinicImage: json['clinic_image'] is String ? json['clinic_image'] : "",
      createdBy: json['created_by'] is int ? json['created_by'] : -1,
      updatedBy: json['updated_by'] is int ? json['updated_by'] : -1,
      deletedBy: json['deleted_by'] is int ? json['deleted_by'] : -1,
      createdAt: json['created_at'] is String ? json['created_at'] : "",
      updatedAt: json['updated_at'] is String ? json['updated_at'] : "",
      deletedAt: json['deleted_at'] is String ? json['deleted_at'] : "",
      timeSlot: json['time_slot'],
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : -1,
      clinicSession: json['clinic_session'] is Map
          ? ClinicSession.fromJson(json['clinic_session'])
          : ClinicSession(),
      allClinicSession: json['all_clinic_session'] is List
          ? List<AllClinicSession>.from(json['all_clinic_session']
              .map((x) => AllClinicSession.fromJson(x)))
          : [],
      clinicStatus:
          json['clinic_status'] is String ? json['clinic_status'] : "",
      totalServices: json['total_services'] is int ? json['total_services'] : 0,
      totalDoctors: json['total_doctors'] is int ? json['total_doctors'] : 0,
      totalAppointment:
          json['total_appointments'] is int ? json['total_appointments'] : 0,
      satisfactionPercentage: json['satisfaction_percentage'] is int
          ? json['satisfaction_percentage']
          : 0,
      totalVerifiedDoctor:
          json['total_doctors'] is int ? json['total_doctors'] : 0,
      totalGalleryImages: json['total_gallery_images'] is int
          ? json['total_gallery_images']
          : 0,
      clinicId: json['clinic_id'] is int ? json['clinic_id'] : -1,
      doctorId: json['doctor_id'] is int ? json['doctor_id'] : -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'email': email,
      'description': description,
      'system_service_category': systemServiceCategory,
      'specialty': specialty,
      'specialty_ar': specialtyAr,
      'contact_number': contactNumber,
      'country_id': countryId,
      'state_id': stateId,
      'city_id': cityId,
      'country_name': countryName,
      'state_name': stateName,
      'city_name': cityName,
      'address': address,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'google_map_link': googleMapLink,
      'additional_addresses':
          additionalAddresses.map((e) => e.toJson()).toList(),
      'distance': distance,
      'distance_formate': distanceFormate,
      'status': status,
      'is_pending': isPending,
      'logo': logo,
      'clinic_image': clinicImage,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'time_slot': timeSlot,
      'vendor_id': vendorId,
      'clinic_session': clinicSession.toJson(),
      'all_clinic_session': allClinicSession.map((e) => e.toJson()).toList(),
      'clinic_status': clinicStatus,
      'total_services': totalServices,
      'total_doctors': totalDoctors,
      'total_gallery_images': totalGalleryImages,
      'clinic_id': clinicId,
      'doctor_id': doctorId,
    };
  }
}

class AdditionalAddress {
  int id;
  String address;
  int countryId;
  int stateId;
  int cityId;
  String countryName;
  String stateName;
  String cityName;
  String pincode;
  String latitude;
  String longitude;
  String googleMapLink;

  AdditionalAddress({
    this.id = -1,
    this.address = "",
    this.countryId = -1,
    this.stateId = -1,
    this.cityId = -1,
    this.countryName = "",
    this.stateName = "",
    this.cityName = "",
    this.pincode = "",
    this.latitude = "",
    this.longitude = "",
    this.googleMapLink = "",
  });

  factory AdditionalAddress.fromJson(Map<String, dynamic> json) {
    return AdditionalAddress(
      id: json['id'] is int ? json['id'] : -1,
      address: json['address'] is String ? json['address'] : "",
      countryId: json['country_id'] is int ? json['country_id'] : -1,
      stateId: json['state_id'] is int ? json['state_id'] : -1,
      cityId: json['city_id'] is int ? json['city_id'] : -1,
      countryName: json['country_name'] is String ? json['country_name'] : "",
      stateName: json['state_name'] is String ? json['state_name'] : "",
      cityName: json['city_name'] is String ? json['city_name'] : "",
      pincode: json['pincode'] is String ? json['pincode'] : "",
      latitude: json['latitude'] is String ? json['latitude'] : "",
      longitude: json['longitude'] is String ? json['longitude'] : "",
      googleMapLink:
          json['google_map_link'] is String ? json['google_map_link'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'country_id': countryId,
      'state_id': stateId,
      'city_id': cityId,
      'country_name': countryName,
      'state_name': stateName,
      'city_name': cityName,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'google_map_link': googleMapLink,
    };
  }

  String get fullLocation {
    List<String> parts = [];
    if (cityName.isNotEmpty) parts.add(cityName);
    if (stateName.isNotEmpty) parts.add(stateName);
    if (countryName.isNotEmpty) parts.add(countryName);
    return parts.join(', ');
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/screens/clinic/clinic_detail_screen.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../../../network/location_service.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../../clinic/model/clinics_res_model.dart';
import '../home_controller.dart';

enum ClinicSortOption { none, nameAZ, nameZA, ratingHigh, ratingLow, nearest }

/// Browse Clinics Component for home screen
/// Shows all clinics in a vertical list with sort dropdown
class SortByComponent extends StatefulWidget {
  const SortByComponent({super.key});

  @override
  State<SortByComponent> createState() => _SortByComponentState();
}

class _SortByComponentState extends State<SortByComponent> {
  final HomeController homeController = Get.find();
  ClinicSortOption _currentSort = ClinicSortOption.none;
  Position? _userPosition;
  bool _loadingLocation = false;

  String _getSortLabel(ClinicSortOption option) {
    switch (option) {
      case ClinicSortOption.none:
        return locale.value.sortBy;
      case ClinicSortOption.nameAZ:
        return locale.value.nameAZ;
      case ClinicSortOption.nameZA:
        return locale.value.nameZA;
      case ClinicSortOption.ratingHigh:
        return locale.value.ratingHighToLow;
      case ClinicSortOption.ratingLow:
        return locale.value.ratingLowToHigh;
      case ClinicSortOption.nearest:
        return locale.value.nearestClinics;
    }
  }

  IconData _getSortIcon(ClinicSortOption option) {
    switch (option) {
      case ClinicSortOption.none:
        return Icons.sort_rounded;
      case ClinicSortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
      case ClinicSortOption.nameZA:
        return Icons.sort_by_alpha_rounded;
      case ClinicSortOption.ratingHigh:
        return Icons.star_rounded;
      case ClinicSortOption.ratingLow:
        return Icons.star_outline_rounded;
      case ClinicSortOption.nearest:
        return Icons.near_me_rounded;
    }
  }

  Future<void> _onSortChanged(ClinicSortOption option) async {
    if (option == ClinicSortOption.nearest && _userPosition == null) {
      setState(() => _loadingLocation = true);
      try {
        _userPosition = await getUserLocationPosition();
      } catch (e) {
        toast(e.toString());
        setState(() => _loadingLocation = false);
        return;
      }
      setState(() => _loadingLocation = false);
    }
    setState(() => _currentSort = option);
  }

  List<Clinic> _sortClinics(List<Clinic> clinics) {
    final sorted = List<Clinic>.from(clinics);
    switch (_currentSort) {
      case ClinicSortOption.none:
        break;
      case ClinicSortOption.nameAZ:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ClinicSortOption.nameZA:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ClinicSortOption.ratingHigh:
        sorted.sort((a, b) => b.satisfactionPercentage.compareTo(a.satisfactionPercentage));
        break;
      case ClinicSortOption.ratingLow:
        sorted.sort((a, b) => a.satisfactionPercentage.compareTo(b.satisfactionPercentage));
        break;
      case ClinicSortOption.nearest:
        if (_userPosition != null) {
          sorted.sort((a, b) {
            final distA = _distanceTo(a);
            final distB = _distanceTo(b);
            return distA.compareTo(distB);
          });
        }
        break;
    }
    return sorted;
  }

  double _distanceTo(Clinic clinic) {
    if (_userPosition == null) return double.infinity;
    final lat = double.tryParse(clinic.latitude) ?? 0;
    final lng = double.tryParse(clinic.longitude) ?? 0;
    if (lat == 0 && lng == 0) return double.infinity;
    return _haversineDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    );
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with Sort By dropdown
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Row(
            children: [
              Text(
                locale.value.clinics,
                style: boldTextStyle(size: 18),
              ).expand(),
              // Sort By dropdown
              GestureDetector(
                onTap: () => _showSortBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: boxDecorationDefault(
                    color: _currentSort != ClinicSortOption.none
                        ? appColorPrimary.withValues(alpha: 0.1)
                        : context.cardColor,
                    borderRadius: radius(20),
                    border: Border.all(
                      color: _currentSort != ClinicSortOption.none
                          ? appColorPrimary
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSortIcon(_currentSort),
                        size: 16,
                        color: _currentSort != ClinicSortOption.none
                            ? appColorPrimary
                            : iconColor,
                      ),
                      6.width,
                      Text(
                        _currentSort == ClinicSortOption.none
                            ? locale.value.sortBy
                            : _getSortLabel(_currentSort),
                        style: boldTextStyle(
                          size: 12,
                          color: _currentSort != ClinicSortOption.none
                              ? appColorPrimary
                              : null,
                        ),
                      ),
                      4.width,
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: _currentSort != ClinicSortOption.none
                            ? appColorPrimary
                            : iconColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        12.height,

        // Loading indicator for location
        if (_loadingLocation)
          const Center(child: CircularProgressIndicator()).paddingSymmetric(vertical: 20),

        // Clinics List
        Obx(() {
          final popularClinics = List<Clinic>.from(
            homeController.dashboardData.value.popularClinic.selectedClinic,
          );
          final nearByClinics = List<Clinic>.from(
            homeController.dashboardData.value.nearByClinic,
          );

          final List<Clinic> clinics = <Clinic>[];
          final Set<int> addedClinicIds = <int>{};

          for (final clinic in [...popularClinics, ...nearByClinics]) {
            if (addedClinicIds.add(clinic.id)) {
              clinics.add(clinic);
            }
          }

          if (clinics.isEmpty) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital_outlined,
                      size: 48, color: Colors.grey.shade300),
                  12.height,
                  Text(locale.value.noDataFound, style: secondaryTextStyle()),
                ],
              ),
            );
          }

          final sortedClinics = _sortClinics(clinics);

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedClinics.length,
            separatorBuilder: (_, __) => 12.height,
            itemBuilder: (context, index) {
              final clinic = sortedClinics[index];
              return _ClinicListCard(
                clinic: clinic,
                distance: _currentSort == ClinicSortOption.nearest && _userPosition != null
                    ? _distanceTo(clinic)
                    : null,
              );
            },
          );
        }),
      ],
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: radius(2),
                ),
              ),
              16.height,
              Text(locale.value.sortBy, style: boldTextStyle(size: 18)),
              16.height,
              ...ClinicSortOption.values.where((o) => o != ClinicSortOption.none).map(
                (option) => ListTile(
                  leading: Icon(
                    _getSortIcon(option),
                    color: _currentSort == option ? appColorPrimary : iconColor,
                  ),
                  title: Text(
                    _getSortLabel(option),
                    style: _currentSort == option
                        ? boldTextStyle(color: appColorPrimary)
                        : primaryTextStyle(),
                  ),
                  trailing: _currentSort == option
                      ? const Icon(Icons.check_circle, color: appColorPrimary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _onSortChanged(option);
                  },
                ),
              ),
              // Clear sort option
              if (_currentSort != ClinicSortOption.none)
                ListTile(
                  leading: const Icon(Icons.clear_rounded, color: cancelStatusColor),
                  title: Text(
                    locale.value.clearAll,
                    style: primaryTextStyle(color: cancelStatusColor),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _currentSort = ClinicSortOption.none);
                  },
                ),
              16.height,
            ],
          ),
        );
      },
    );
  }
}

/// A clinic card matching the delivery-app reference design:
/// Cover image on the left with rounded corners,
/// logo overlapping the cover (top-left, rectangular),
/// clinic name + details on the right.
class _ClinicListCard extends StatelessWidget {
  final Clinic clinic;
  final double? distance;

  const _ClinicListCard({required this.clinic, this.distance});

  @override
  Widget build(BuildContext context) {
    const double imageSize = 120.0;
    const double logoSize = 42.0;

    return GestureDetector(
      onTap: () => Get.to(() => ClinicDetailScreen(), arguments: clinic),
      child: Container(
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side: Cover image + overlapping logo
            SizedBox(
              width: imageSize,
              height: imageSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: CachedImageWidget(
                      url: clinic.clinicImage,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Logo overlapping top-left of cover (rectangular with margin)
                  if (clinic.logo.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: context.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedImageWidget(
                            url: clinic.logo,
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Right side: Clinic info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Clinic Name
                    Text(
                      clinic.name,
                      style: boldTextStyle(size: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    6.height,

                    // Specialty
                    if (clinic.localizedSpecialty.isNotEmpty)
                      Text(
                        clinic.localizedSpecialty,
                        style: secondaryTextStyle(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    8.height,

                    // Address
                    if (clinic.address.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: iconColor),
                          4.width,
                          Expanded(
                            child: Text(
                              clinic.address,
                              style: secondaryTextStyle(size: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    6.height,

                    // Bottom row: Rating + Status + Distance
                    Row(
                      children: [
                        // Rating
                        if (clinic.satisfactionPercentage > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          2.width,
                          Text(
                            '${clinic.satisfactionPercentage}%',
                            style: secondaryTextStyle(size: 11),
                          ),
                          8.width,
                        ],
                        // Distance
                        if (distance != null && distance != double.infinity) ...[
                          const Icon(Icons.near_me_rounded,
                              size: 12, color: appColorSecondary),
                          2.width,
                          Text(
                            distance! < 1
                                ? '${(distance! * 1000).toStringAsFixed(0)} m'
                                : '${distance!.toStringAsFixed(1)} km',
                            style: boldTextStyle(
                                size: 11, color: appColorSecondary),
                          ),
                          8.width,
                        ],
                        const Spacer(),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: boxDecorationDefault(
                            color: getClinicStatusLightColor(
                              clinicStatus:
                                  clinic.clinicStatus.toLowerCase(),
                            ),
                            borderRadius: radius(12),
                          ),
                          child: Text(
                            getClinicStatus(
                                status: clinic.clinicStatus.toLowerCase()),
                            style: boldTextStyle(
                              size: 10,
                              color: getClinicStatusColor(
                                clinicStatus:
                                    clinic.clinicStatus.toLowerCase(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

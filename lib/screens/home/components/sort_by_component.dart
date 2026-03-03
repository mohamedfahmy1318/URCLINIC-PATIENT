import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/screens/clinic/clinic_detail_screen.dart';
import 'package:kivicare_patient/screens/clinic/clinic_map_screen.dart';
import 'package:kivicare_patient/screens/clinic/clinics_list_screen.dart';
import 'package:kivicare_patient/utils/colors.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../generated/assets.dart';
import '../../../main.dart';
import '../../../utils/view_all_label_component.dart';
import '../../clinic/model/clinics_res_model.dart';
import '../home_controller.dart';

/// Browse Clinics Component for home screen
/// Shows clinics with filter options: All, Top Rated, Nearest
/// Sort By: Name, Rating
class SortByComponent extends StatefulWidget {
  const SortByComponent({super.key});

  @override
  State<SortByComponent> createState() => _SortByComponentState();
}

class _SortByComponentState extends State<SortByComponent> {
  final HomeController homeController = Get.find();

  // Filter: 0: Sort By (All Clinics), 1: Top Rated, 2: Nearest (Map)
  int selectedFilter = 0;

  // Sort: 0: Default, 1: Name A-Z, 2: Name Z-A, 3: Rating High-Low, 4: Rating Low-High
  int selectedSort = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with View All
        ViewAllLabel(
          label: locale.value.clinics,
          isShowAll: true,
          onTap: () => Get.to(() => ClinicListScreen()),
        ).paddingOnly(left: 16, right: 16, top: 16),
        12.height,

        // Filter Chips (Clinics only)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Sort By Chip - opens bottom sheet with sorting options
              _buildSortByChip(),
              10.width,
              _buildFilterChip(
                index: 1,
                icon: Icons.star_rounded,
                label: locale.value.topRated,
                color: const Color(0xFFFFB300),
                isIconData: true,
              ),
              10.width,
              _buildFilterChip(
                index: 2,
                icon: Assets.iconsIcLocation,
                label: locale.value.nearestClinics,
                color: const Color(0xFFFF7043),
                showMapIcon: true,
              ),
            ],
          ),
        ),
        16.height,

        // Clinics List
        _buildClinicsVerticalList(),
      ],
    );
  }

  // Sort By chip with dropdown indicator
  Widget _buildSortByChip() {
    final isSelected = selectedFilter == 0;
    final color = const Color(0xFF00BFA5);
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = 0;
        });
        _showSortBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: boxDecorationDefault(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            8.width,
            Text(
              locale.value.sortBy,
              style: boldTextStyle(
                size: 12,
                color: isSelected ? Colors.white : color,
              ),
            ),
            4.width,
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            if (selectedSort != 0) ...[
              4.width,
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required int index,
    required dynamic icon,
    required String label,
    required Color color,
    bool showMapIcon = false,
    bool isIconData = false,
  }) {
    final isSelected = selectedFilter == index;
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          // Nearest Clinics - Go to Map
          Get.to(() => ClinicMapScreen());
        } else {
          setState(() {
            selectedFilter = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: boxDecorationDefault(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isIconData)
              Icon(
                icon as IconData,
                size: 18,
                color: isSelected ? Colors.white : color,
              )
            else
              CachedImageWidget(
                url: icon as String,
                height: 18,
                width: 18,
                color: isSelected ? Colors.white : color,
              ),
            8.width,
            Text(
              label,
              style: boldTextStyle(
                size: 12,
                color: isSelected ? Colors.white : color,
              ),
            ),
            if (showMapIcon) ...[
              6.width,
              Icon(
                Icons.map_outlined,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: boxDecorationDefault(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: boxDecorationDefault(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            16.height,
            Text(locale.value.sortBy, style: boldTextStyle(size: 18)),
            8.height,
            Text(
              locale.value.clinics,
              style: secondaryTextStyle(size: 14),
            ),
            16.height,

            // Sort Options for Clinics - Scrollable
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSortOption(
                        0, locale.value.defaultSort, Icons.restore),
                    _buildSortOption(
                        1, locale.value.nameAZ, Icons.sort_by_alpha),
                    _buildSortOption(
                        2, locale.value.nameZA, Icons.sort_by_alpha),
                    _buildSortOption(
                        3, locale.value.ratingHighToLow, Icons.star),
                    _buildSortOption(
                        4, locale.value.ratingLowToHigh, Icons.star_border),
                  ],
                ),
              ),
            ),

            24.height,
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(int index, String label, IconData icon) {
    final isSelected = selectedSort == index;
    return ListTile(
      onTap: () {
        setState(() => selectedSort = index);
        Get.back();
      },
      leading: Icon(
        icon,
        color: isSelected ? appColorPrimary : Colors.grey,
      ),
      title: Text(
        label,
        style: isSelected
            ? boldTextStyle(color: appColorPrimary)
            : primaryTextStyle(),
      ),
      trailing:
          isSelected ? Icon(Icons.check_circle, color: appColorPrimary) : null,
    );
  }

  // Get filtered and sorted clinics
  List<Clinic> _getFilteredClinics() {
    List<Clinic> clinics = List<Clinic>.from(
      homeController.dashboardData.value.popularClinic.selectedClinic,
    );

    // Apply filter first
    switch (selectedFilter) {
      case 0: // Sort By (All Clinics) - apply selected sort
        break;
      case 1: // Top Rated - sort by satisfaction percentage descending
        clinics.sort((a, b) =>
            b.satisfactionPercentage.compareTo(a.satisfactionPercentage));
        return clinics; // Return early, no additional sort needed
    }

    // Apply sort (only for filter 0 - Sort By)
    switch (selectedSort) {
      case 1: // Name A-Z
        clinics.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 2: // Name Z-A
        clinics.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 3: // Rating High-Low
        clinics.sort((a, b) =>
            b.satisfactionPercentage.compareTo(a.satisfactionPercentage));
        break;
      case 4: // Rating Low-High
        clinics.sort((a, b) =>
            a.satisfactionPercentage.compareTo(b.satisfactionPercentage));
        break;
    }

    return clinics;
  }

  Widget _buildClinicsVerticalList() {
    return Obx(() {
      final clinics = _getFilteredClinics();

      if (clinics.isEmpty) {
        return _buildEmptyState(locale.value.noDataFound);
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: clinics.length > 6 ? 6 : clinics.length,
        itemBuilder: (context, index) {
          final clinic = clinics[index];
          return _buildClinicGridCard(clinic);
        },
      );
    });
  }

  Widget _buildClinicGridCard(Clinic clinic) {
    return GestureDetector(
      onTap: () => Get.to(() => ClinicDetailScreen(), arguments: clinic),
      child: Container(
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clinic Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedImageWidget(
                  url: clinic.clinicImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            // Clinic Name
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      clinic.name,
                      style: boldTextStyle(size: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.height,
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 14),
                        4.width,
                        Text(
                          '${clinic.satisfactionPercentage}%',
                          style: secondaryTextStyle(size: 11),
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

  Widget _buildEmptyState(String message) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_hospital_outlined,
              size: 48, color: Colors.grey.shade300),
          12.height,
          Text(message, style: secondaryTextStyle()),
        ],
      ),
    );
  }
}

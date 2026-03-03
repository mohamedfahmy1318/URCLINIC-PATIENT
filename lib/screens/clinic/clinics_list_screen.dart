import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/screens/clinic/search_clinic_widget.dart';
import 'package:kivicare_patient/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../main.dart';
import '../../utils/empty_error_state_widget.dart';
import '../doctor/doctor_list_screen.dart';
import 'clinic_detail_screen.dart';
import 'clinic_list_controller.dart';
import 'clinic_map_screen.dart';
import 'model/clinics_res_model.dart';

class ClinicListScreen extends StatefulWidget {
  ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final ClinicListController clinicListCont = Get.put(ClinicListController());

  // Sort: 0: Default, 1: Name A-Z, 2: Name Z-A, 3: Rating High-Low, 4: Rating Low-High
  int selectedSort = 0;
  // Filter: 0: All, 1: Top Rated
  int selectedFilter = 0;

  List<Clinic> _getFilteredClinics() {
    List<Clinic> clinics = List<Clinic>.from(clinicListCont.clinics);

    // Apply filter
    if (selectedFilter == 1) {
      clinics.sort((a, b) =>
          b.satisfactionPercentage.compareTo(a.satisfactionPercentage));
      return clinics;
    }

    // Apply sort (only for filter 0)
    switch (selectedSort) {
      case 1:
        clinics.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 2:
        clinics.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 3:
        clinics.sort((a, b) =>
            b.satisfactionPercentage.compareTo(a.satisfactionPercentage));
        break;
      case 4:
        clinics.sort((a, b) =>
            a.satisfactionPercentage.compareTo(b.satisfactionPercentage));
        break;
    }

    return clinics;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: boxDecorationDefault(
          color: context.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: boxDecorationDefault(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            16.height,
            Text(locale.value.sortBy, style: boldTextStyle(size: 18)),
            8.height,
            Text(locale.value.clinics, style: secondaryTextStyle(size: 14)),
            16.height,
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
      leading: Icon(icon, color: isSelected ? appColorPrimary : Colors.grey),
      title: Text(label,
          style: isSelected
              ? boldTextStyle(color: appColorPrimary)
              : primaryTextStyle()),
      trailing:
          isSelected ? Icon(Icons.check_circle, color: appColorPrimary) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.searchHere,
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: clinicListCont.isLoading,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          SearchClinicWidget(
            clinicListController: clinicListCont,
            onFieldSubmitted: (p0) {
              hideKeyboard(context);
            },
          ).paddingAll(16),

          // Sort & Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSortByChip(),
                12.width,
                _buildFilterChip(
                  index: 1,
                  icon: Icons.star,
                  label: locale.value.ratingHighToLow,
                  color: const Color(0xFFFF9800),
                  isIconData: true,
                ),
                12.width,
                _buildFilterChip(
                  index: 2,
                  icon: Icons.location_on,
                  label: locale.value.nearestClinics,
                  color: const Color(0xFF2196F3),
                  showMapIcon: true,
                  isIconData: true,
                ),
              ],
            ),
          ),
          12.height,

          // Clinics Grid
          Obx(() {
            // Show empty search state when coming from search and no search performed yet
            if (clinicListCont.isFromSearch.value &&
                clinicListCont.clinics.isEmpty &&
                !clinicListCont.isLoading.value &&
                clinicListCont.searchClinicCont.text.trim().isEmpty) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      16.height,
                      Text(
                        locale.value.searchDoctorClinicService,
                        style: secondaryTextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SnapHelperWidget(
              future: clinicListCont.clinicsFuture.value,
              errorBuilder: (error) {
                return NoDataWidget(
                  title: error,
                  retryText: locale.value.reload,
                  imageWidget: const ErrorStateWidget(),
                  onRetry: () {
                    clinicListCont.page(1);
                    clinicListCont.getClinicList();
                  },
                ).paddingSymmetric(horizontal: 32);
              },
              loadingWidget: clinicListCont.isLoading.value
                  ? const Offstage()
                  : const LoaderWidget(),
              onSuccess: (p0) {
                final clinics = _getFilteredClinics();

                if (clinics.isEmpty && !clinicListCont.isLoading.value) {
                  return SingleChildScrollView(
                    child: NoDataWidget(
                      title: locale.value.noClinicsFoundAtAMoment,
                      subTitle: locale
                          .value.looksLikeThereIsNoClinicForThisServiceWellKee,
                      titleTextStyle: primaryTextStyle(),
                      imageWidget: const EmptyStateWidget(),
                      retryText: locale.value.reload,
                      onRetry: () {
                        clinicListCont.page(1);
                        clinicListCont.getClinicList();
                      },
                    ).paddingSymmetric(horizontal: 25),
                  ).center();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    clinicListCont.page(1);
                    return clinicListCont.getClinicList(showLoader: false);
                  },
                  child: AnimatedListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    listAnimationType: ListAnimationType.FadeIn,
                    itemCount: clinics.length,
                    itemBuilder: (context, index) {
                      final clinic = clinics[index];
                      return _buildClinicListCard(clinic)
                          .paddingOnly(bottom: 12);
                    },
                  ),
                );
              },
            ).expand();
          }),
        ],
      ),
      fabWidget: Obx(
        () => FloatingActionButton(
          backgroundColor: appColorSecondary,
          onPressed: () {
            if (!clinicListCont.selectedClinic.value.id.isNegative) {
              Get.to(() => DoctorsListScreen(),
                  arguments: clinicListCont.selectedClinic.value.id);
            }
          },
          child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ).visible(clinicListCont.clinics.isNotEmpty &&
            (!clinicListCont.selectedClinic.value.id.isNegative)),
      ),
    );
  }

  // Sort By chip
  Widget _buildSortByChip() {
    final isSelected = selectedFilter == 0;
    const color = Color(0xFF00BFA5);
    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = 0);
        _showSortBottomSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: boxDecorationDefault(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort,
                size: 18, color: isSelected ? Colors.white : color),
            8.width,
            Text(locale.value.sortBy,
                style: boldTextStyle(
                    size: 12, color: isSelected ? Colors.white : color)),
            4.width,
            Icon(Icons.keyboard_arrow_down,
                size: 18, color: isSelected ? Colors.white : color),
            if (selectedSort != 0) ...[
              4.width,
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: isSelected ? Colors.white : color,
                    shape: BoxShape.circle),
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
          Get.to(() => ClinicMapScreen());
        } else {
          setState(() => selectedFilter = index);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: boxDecorationDefault(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isIconData)
              Icon(icon as IconData,
                  size: 18, color: isSelected ? Colors.white : color)
            else
              CachedImageWidget(
                  url: icon as String,
                  height: 18,
                  width: 18,
                  color: isSelected ? Colors.white : color),
            8.width,
            Text(label,
                style: boldTextStyle(
                    size: 12, color: isSelected ? Colors.white : color)),
            if (showMapIcon) ...[
              6.width,
              Icon(Icons.map_outlined,
                  size: 16, color: isSelected ? Colors.white : color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicListCard(Clinic clinic) {
    return GestureDetector(
      onTap: () => Get.to(() => ClinicDetailScreen(), arguments: clinic),
      child: Container(
        height: 100,
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Clinic Image - wider and takes good space
            CachedImageWidget(
              url: clinic.clinicImage,
              fit: BoxFit.cover,
              width: 120,
              height: 100,
            ),
            // Clinic Name centered
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  clinic.name,
                  style: boldTextStyle(size: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Arrow indicator
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

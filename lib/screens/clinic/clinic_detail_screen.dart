import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/utils/common_base.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../components/loader_widget.dart';
import '../../generated/assets.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/empty_error_state_widget.dart';
import '../../utils/price_widget.dart';
import '../doctor/doctor_detail_screen.dart';
import '../doctor/doctor_list_screen.dart';
import '../doctor/model/doctor_list_res.dart';
import '../service/model/service_list_model.dart';
import '../service/service_detail_screen.dart';
import '../service/services_list_screen.dart';
import 'clinic_detail_controller.dart';
import 'clinic_gallery_list_screen.dart';
import 'components/clinic_session_component.dart';

class ClinicDetailScreen extends StatelessWidget {
  ClinicDetailScreen({super.key});

  final ClinicDetailController clinicDetailCont =
      Get.put(ClinicDetailController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      isLoading: clinicDetailCont.isLoading,
      appBartitleText: locale.value.clinicDetail,
      appBarVerticalSize: Get.height * 0.12,
      body: RefreshIndicator(
        onRefresh: () {
          return clinicDetailCont.init(showLoader: false);
        },
        child: Obx(
          () => SnapHelperWidget(
            future: clinicDetailCont.getClinicDetail.value,
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: () {
                  clinicDetailCont.init();
                },
              ).paddingSymmetric(horizontal: 16);
            },
            loadingWidget: const LoaderWidget(),
            onSuccess: (clinicDetailRes) {
              return Stack(
                children: [
                  AnimatedScrollView(
                    listAnimationType: ListAnimationType.FadeIn,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      // Clinic Header with Image
                      _buildClinicHeader(context),

                      // Quick Stats Section
                      _buildQuickStats(context),

                      // Description Section
                      _buildDescriptionSection(context),

                      // Our Doctors Section
                      _buildDoctorsSection(context),

                      // Our Services Section
                      _buildServicesSection(context),

                      // Sessions & Gallery Links
                      _buildSessionsAndGallery(context),

                      24.height,
                    ],
                  ),

                  // Floating Book Now Button
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildBookNowButton(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Clinic Header with Image, Name, and Contact Info
  Widget _buildClinicHeader(BuildContext context) {
    return Container(
      color: context.cardColor,
      child: Column(
        children: [
          // Clinic Image with Status Badge
          Stack(
            children: [
              CachedImageWidget(
                url: clinicDetailCont.clinicData.value.clinicImage,
                fit: BoxFit.cover,
                width: Get.width,
                height: Get.height * 0.28,
                topLeftRadius: (defaultRadius * 2).toInt(),
                topRightRadius: (defaultRadius * 2).toInt(),
              ),
              // Status Badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: boxDecorationDefault(
                    color: getClinicStatusLightColor(
                      clinicStatus: clinicDetailCont
                          .clinicData.value.clinicStatus
                          .toLowerCase(),
                    ),
                    borderRadius: radius(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                      8.width,
                      Text(
                        getClinicStatus(
                            status: clinicDetailCont
                                .clinicData.value.clinicStatus
                                .toLowerCase()),
                        style: boldTextStyle(
                            size: 12, color: Colors.green.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Clinic Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clinic Name
                Text(
                  clinicDetailCont.clinicData.value.name,
                  style: boldTextStyle(size: 20),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).visible(clinicDetailCont.clinicData.value.name.isNotEmpty),

                8.height,

                // Specialty
                Row(
                  children: [
                    const CachedImageWidget(
                      url: Assets.iconsIcSpecialization,
                      color: appColorPrimary,
                      height: 16,
                      width: 16,
                    ),
                    8.width,
                    Text(
                      clinicDetailCont.clinicData.value.specialty,
                      style: primaryTextStyle(color: appColorPrimary, size: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).flexible(),
                  ],
                ).visible(
                    clinicDetailCont.clinicData.value.specialty.isNotEmpty),

                12.height,

                // Location
                GestureDetector(
                  onTap: () =>
                      launchMap(clinicDetailCont.clinicData.value.address),
                  child: Row(
                    children: [
                      const CachedImageWidget(
                        url: Assets.iconsIcLocation,
                        color: iconColor,
                        height: 16,
                        width: 16,
                      ),
                      8.width,
                      Text(
                        "${clinicDetailCont.clinicData.value.cityName}, ${clinicDetailCont.clinicData.value.stateName}",
                        style: secondaryTextStyle(size: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).flexible(),
                      4.width,
                      Icon(Icons.open_in_new, size: 14, color: appColorPrimary),
                    ],
                  ),
                ).visible(clinicDetailCont.clinicData.value.address.isNotEmpty),

                16.height,

                // Contact Row
                Row(
                  children: [
                    // Phone
                    Expanded(
                      child: GestureDetector(
                        onTap: () => launchCall(
                            clinicDetailCont.clinicData.value.contactNumber),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: boxDecorationDefault(
                            color: appColorPrimary.withOpacity(0.1),
                            borderRadius: radius(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CachedImageWidget(
                                url: Assets.iconsIcCall,
                                color: appColorPrimary,
                                height: 18,
                                width: 18,
                              ),
                              8.width,
                              Text(
                                locale.value.contactNumber,
                                style: boldTextStyle(
                                    size: 13, color: appColorPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).visible(clinicDetailCont.clinicData.value.contactNumber
                        .trim()
                        .isNotEmpty),

                    12.width.visible(clinicDetailCont
                            .clinicData.value.contactNumber
                            .trim()
                            .isNotEmpty &&
                        clinicDetailCont.clinicData.value.email.isNotEmpty),

                    // Email
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            launchMail(clinicDetailCont.clinicData.value.email),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: boxDecorationDefault(
                            color: appColorSecondary.withOpacity(0.1),
                            borderRadius: radius(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CachedImageWidget(
                                url: Assets.iconsIcMail,
                                color: appColorSecondary,
                                height: 18,
                                width: 18,
                              ),
                              8.width,
                              Text(
                                locale.value.email,
                                style: boldTextStyle(
                                    size: 13, color: appColorSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).visible(
                        clinicDetailCont.clinicData.value.email.isNotEmpty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Stats Section - Doctors, Services, Satisfaction
  Widget _buildQuickStats(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Doctors Count
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        borderRadius: radius(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: CachedImageWidget(
              url: icon,
              height: 22,
              width: 22,
              color: color,
            ),
          ),
          10.height,
          Text(
            value,
            style: boldTextStyle(size: 18, color: color),
          ),
          4.height,
          Text(
            label,
            style: secondaryTextStyle(size: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Description Section
  Widget _buildDescriptionSection(BuildContext context) {
    if (clinicDetailCont.clinicData.value.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        borderRadius: radius(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.value.about,
            style: boldTextStyle(size: 16),
          ),
          12.height,
          ReadMoreText(
            parseHtmlString(
                "${clinicDetailCont.clinicData.value.description} "),
            trimLines: 3,
            style: secondaryTextStyle(size: 14, color: secondaryTextColor),
            colorClickableText: appColorPrimary,
            trimMode: TrimMode.Line,
            trimCollapsedText: " ...${locale.value.readMore}",
            trimExpandedText: locale.value.readLess,
            locale: Localizations.localeOf(context),
          ),
        ],
      ),
    );
  }

  /// Doctors Section with Horizontal List
  Widget _buildDoctorsSection(BuildContext context) {
    return Obx(
      () {
        if (clinicDetailCont.doctors.isEmpty &&
            !clinicDetailCont.isDoctorsLoading.value) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: appColorPrimary.withOpacity(0.1),
                          borderRadius: radius(8),
                        ),
                        child: const CachedImageWidget(
                          url: Assets.iconsIcDoctor,
                          height: 20,
                          width: 20,
                          color: appColorPrimary,
                        ),
                      ),
                      12.width,
                      Text(
                        locale.value.doctors,
                        style: boldTextStyle(size: 16),
                      ),
                    ],
                  ),
                  if (clinicDetailCont.activeDoctorsCount.value > 3)
                    GestureDetector(
                      onTap: () => Get.to(() => DoctorsListScreen(),
                          arguments: clinicDetailCont.clinicData.value.id),
                      child: Text(
                        locale.value.viewAll,
                        style:
                            primaryTextStyle(color: appColorPrimary, size: 13),
                      ),
                    ),
                ],
              ),
            ),
            16.height,
            if (clinicDetailCont.isDoctorsLoading.value)
              const Center(child: CircularProgressIndicator())
                  .paddingSymmetric(vertical: 20)
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clinicDetailCont.doctors.take(5).length,
                  separatorBuilder: (_, __) => 12.width,
                  itemBuilder: (context, index) {
                    final doctor = clinicDetailCont.doctors[index];
                    return _buildDoctorCard(context, doctor);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    return GestureDetector(
      onTap: () => Get.to(() => DoctorDetailScreen(), arguments: doctor),
      child: Container(
        width: 140,
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: radius(12),
        ),
        child: Column(
          children: [
            // Doctor Image
            Stack(
              children: [
                CachedImageWidget(
                  url: doctor.profileImage,
                  height: 100,
                  width: 140,
                  fit: BoxFit.cover,
                  topLeftRadius: 12,
                  topRightRadius: 12,
                ),
                // Online indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: boxDecorationDefault(
                      color: completedStatusColor,
                      borderRadius: radius(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        4.width,
                        Text(
                          locale.value.active,
                          style: boldTextStyle(size: 9, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ).visible(doctor.status == 1),
                // Rating badge
                if (doctor.averageRating > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: boxDecorationDefault(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: radius(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: ratingColor, size: 12),
                          4.width,
                          Text(
                            doctor.averageRating.toStringAsFixed(1),
                            style: boldTextStyle(size: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Doctor Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      doctor.fullName,
                      style: boldTextStyle(size: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    4.height,
                    Text(
                      doctor.expert,
                      style: secondaryTextStyle(size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ).visible(doctor.expert.isNotEmpty),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Services Section with Horizontal List
  Widget _buildServicesSection(BuildContext context) {
    return Obx(
      () {
        if (clinicDetailCont.serviceList.isEmpty &&
            !clinicDetailCont.isServicesLoading.value) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: appColorSecondary.withOpacity(0.1),
                          borderRadius: radius(8),
                        ),
                        child: const CachedImageWidget(
                          url: Assets.iconsIcServices,
                          height: 20,
                          width: 20,
                          color: appColorSecondary,
                        ),
                      ),
                      12.width,
                      Text(
                        locale.value.services,
                        style: boldTextStyle(size: 16),
                      ),
                    ],
                  ),
                  if (clinicDetailCont.activeServicesCount.value > 3)
                    GestureDetector(
                      onTap: () => Get.to(
                          () => ServiceListScreen(isFromClinicDetail: true),
                          arguments: clinicDetailCont.clinicData.value.id),
                      child: Text(
                        locale.value.viewAll,
                        style:
                            primaryTextStyle(color: appColorPrimary, size: 13),
                      ),
                    ),
                ],
              ),
            ),
            16.height,
            if (clinicDetailCont.isServicesLoading.value)
              const Center(child: CircularProgressIndicator())
                  .paddingSymmetric(vertical: 20)
            else
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clinicDetailCont.serviceList.take(5).length,
                  separatorBuilder: (_, __) => 12.width,
                  itemBuilder: (context, index) {
                    final service = clinicDetailCont.serviceList[index];
                    return _buildServiceCard(context, service);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceElement service) {
    return GestureDetector(
      onTap: () => Get.to(() => ServiceDetailScreen(isFromClinicDetail: true),
          arguments: service),
      child: Container(
        width: 160,
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: radius(12),
        ),
        child: Column(
          children: [
            // Service Image
            Stack(
              children: [
                CachedImageWidget(
                  url: service.serviceImage,
                  height: 85,
                  width: 160,
                  fit: BoxFit.cover,
                  topLeftRadius: 12,
                  topRightRadius: 12,
                ),
                // Video consultation badge
                if (service.isVideoConsultancy)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: boxDecorationDefault(
                        color: completedStatusColor,
                        borderRadius: radius(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam,
                              color: Colors.white, size: 12),
                          4.width,
                          Text(
                            locale.value.video,
                            style: boldTextStyle(size: 9, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Discount badge
                if (service.isDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: boxDecorationDefault(
                        color: Colors.red,
                        borderRadius: radius(10),
                      ),
                      child: Text(
                        '${service.discountValue.toInt()}% OFF',
                        style: boldTextStyle(size: 9, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            // Service Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      service.name,
                      style: boldTextStyle(size: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        PriceWidget(
                          price: service.isDiscount
                              ? service.payableAmount
                              : service.charges,
                          size: 14,
                        ),
                        6.width,
                        if (service.isDiscount)
                          PriceWidget(
                            price: service.charges,
                            isLineThroughEnabled: true,
                            size: 11,
                            color: textSecondaryColorGlobal,
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

  /// Sessions and Gallery Links
  Widget _buildSessionsAndGallery(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          16.height,
          // Sessions
          GestureDetector(
            onTap: () => Get.to(() =>
                ClinicSessionComponent(clinicDetailCont: clinicDetailCont)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: boxDecorationDefault(
                color: context.cardColor,
                borderRadius: radius(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: appColorSecondary.withOpacity(0.1),
                      borderRadius: radius(10),
                    ),
                    child: const CachedImageWidget(
                      url: Assets.iconsIcClock,
                      height: 24,
                      width: 24,
                      color: appColorSecondary,
                    ),
                  ),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.value.sessions,
                        style: boldTextStyle(size: 15),
                      ),
                      4.height,
                      Text(
                        locale.value.clinicSessionsInformation,
                        style: secondaryTextStyle(size: 12),
                      ),
                    ],
                  ).expand(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: darkGray),
                ],
              ),
            ),
          ),

          12.height,

          // Gallery
          Obx(
            () => GestureDetector(
              onTap: () => Get.to(() => ClinicGalleryListScreen(),
                  arguments: clinicDetailCont.clinicData.value.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: boxDecorationDefault(
                  color: context.cardColor,
                  borderRadius: radius(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ratingColor.withOpacity(0.1),
                        borderRadius: radius(10),
                      ),
                      child: CachedImageWidget(
                        url: Assets.iconsIcGallery,
                        height: 24,
                        width: 24,
                        color: ratingColor,
                      ),
                    ),
                    16.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.value.gallery,
                          style: boldTextStyle(size: 15),
                        ),
                        4.height,
                        Text(
                          clinicDetailCont
                                      .clinicData.value.totalGalleryImages !=
                                  0
                              ? "${locale.value.total} ${clinicDetailCont.clinicData.value.totalGalleryImages} ${locale.value.photosAvailable}"
                              : locale.value.noPhotosAvailable,
                          style: secondaryTextStyle(size: 12),
                        ),
                      ],
                    ).expand(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: darkGray),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating Book Now Button
  Widget _buildBookNowButton(BuildContext context) {
    return Container(
      decoration: boxDecorationDefault(
        borderRadius: radius(16),
        boxShadow: [
          BoxShadow(
            color: appColorPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppButton(
        width: Get.width,
        color: appColorPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shapeBorder: RoundedRectangleBorder(borderRadius: radius(16)),
        onTap: () {
          // Set the current clinic and navigate to booking
          currentSelectedClinic(clinicDetailCont.clinicData.value);
          Get.to(() => ServiceListScreen(isFromClinicDetail: true),
              arguments: clinicDetailCont.clinicData.value.id);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_outlined,
                color: Colors.white, size: 22),
            12.width,
            Text(
              locale.value.bookNow,
              style: boldTextStyle(size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

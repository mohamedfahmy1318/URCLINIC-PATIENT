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
import '../doctor/model/doctor_list_res.dart';
import '../doctor/doctor_detail_screen.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Image with Status Badge and Logo
          SizedBox(
            height: Get.height * 0.32,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CachedImageWidget(
                  url: clinicDetailCont.clinicData.value.clinicImage,
                  fit: BoxFit.cover,
                  width: Get.width,
                  height: Get.height * 0.28,
                  topLeftRadius: 0,
                  topRightRadius: 0,
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
                // Circular Logo Overlay
                Positioned(
                  bottom: 0,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: boxDecorationDefault(
                      shape: BoxShape.circle,
                      color: context.cardColor,
                      border: Border.all(color: context.cardColor, width: 2),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue, // Placeholder brand color
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        clinicDetailCont.clinicData.value.name.isNotEmpty
                            ? clinicDetailCont.clinicData.value.name[0]
                                .toUpperCase()
                            : "C",
                        style: boldTextStyle(size: 30, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Clinic Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clinic Name
                Text(
                  clinicDetailCont.clinicData.value.name,
                  style: boldTextStyle(size: 24),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).visible(clinicDetailCont.clinicData.value.name.isNotEmpty),

                16.height,

                // Select Branch Button
                AppButton(
                  width: Get.width,
                  color: transparentColor,
                  elevation: 0,
                  shapeBorder: RoundedRectangleBorder(
                      borderRadius: radius(8),
                      side: const BorderSide(color: appColorPrimary)),
                  onTap: () {
                    // TODO: Implement Branch Selection Logic
                    toast("Select Branch clicked");
                  },
                  child: Text("Select branch",
                      style: boldTextStyle(color: appColorPrimary)),
                ),

                16.height,

                // Clinic Number / Email (Semi-bold text)
                Row(
                  children: [
                    Text("Clinic number / email",
                        style: boldTextStyle(size: 16)),
                  ],
                ),
                12.height,

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
                              vertical: 12,
                              horizontal: 8), // Reduced horizontal padding
                          decoration: boxDecorationDefault(
                            color: Colors.grey.shade200,
                            borderRadius: radius(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CachedImageWidget(
                                url: Assets.iconsIcCall,
                                color: appColorPrimary,
                                height: 20,
                                width: 20,
                              ),
                              8.width,
                              Flexible(
                                // Used Flexible to prevent overflow
                                child: Text(
                                  locale.value.contactNumber,
                                  style: boldTextStyle(
                                      size: 13, // Reduced font size slightly
                                      color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
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
                              vertical: 12,
                              horizontal: 8), // Reduced horizontal padding
                          decoration: boxDecorationDefault(
                            color: Colors.grey.shade200,
                            borderRadius: radius(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CachedImageWidget(
                                url: Assets.iconsIcMail,
                                color: appColorPrimary,
                                height: 20,
                                width: 20,
                              ),
                              8.width,
                              Flexible(
                                // Used Flexible to prevent overflow
                                child: Text(
                                  locale.value.email,
                                  style: boldTextStyle(
                                      size: 13, // Reduced font size slightly
                                      color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
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

  /// Quick Stats Section - Removed as it was empty and causing GetX error
  Widget _buildQuickStats(BuildContext context) {
    return const SizedBox.shrink();
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

  /// Doctors Section with Grid List
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
            ),
            16.height,
            if (clinicDetailCont.isDoctorsLoading.value)
              const Center(child: CircularProgressIndicator())
                  .paddingSymmetric(vertical: 20)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(
                      clinicDetailCont.doctors.take(4).length, (index) {
                    final doctor = clinicDetailCont.doctors[index];
                    // Calculate width for 2 columns with spacing
                    final width = (Get.width - 48) / 2;
                    return _buildDoctorCard(context, doctor, width);
                  }),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor, double width) {
    return GestureDetector(
      onTap: () => Get.to(() => DoctorDetailScreen(), arguments: doctor),
      child: Container(
        width: width,
        decoration: boxDecorationDefault(
          color: context.cardColor,
          borderRadius: radius(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Image
            Stack(
              children: [
                CachedImageWidget(
                  url: doctor.profileImage,
                  height: width * 0.8,
                  width: width,
                  fit: BoxFit.cover,
                  topLeftRadius: 12,
                  topRightRadius: 12,
                ),
                // Status (Active/Inactive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: boxDecorationDefault(
                      color: doctor.status == 1 ? Colors.green : Colors.grey,
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
                          doctor.status == 1 ? locale.value.active : 'Inactive',
                          style: boldTextStyle(size: 9, color: Colors.white),
                        ),
                      ],
                    ),
                  ).visible(doctor.status == 1),
                ),
              ],
            ),
            // Doctor Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: boldTextStyle(size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.height,
                  Text(
                    doctor
                        .expert, // Using expert field as "Doctor CV" placeholder equivalent
                    style: secondaryTextStyle(size: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).visible(doctor.expert.isNotEmpty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Services Section with Vertical List
  Widget _buildServicesSection(BuildContext context) {
    return Obx(
      () {
        if (clinicDetailCont.serviceList.isEmpty &&
            !clinicDetailCont.isServicesLoading.value) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: boxDecorationDefault(
              color: context.cardColor,
              borderRadius: radius(12),
              border: Border.all(color: Colors.grey.shade300)),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (clinicDetailCont.isServicesLoading.value)
                const Center(child: CircularProgressIndicator())
                    .paddingSymmetric(vertical: 20)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: clinicDetailCont.serviceList.take(5).length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.grey)
                          .paddingSymmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final service = clinicDetailCont.serviceList[index];
                    return _buildServiceRow(context, service);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceRow(BuildContext context, ServiceElement service) {
    return GestureDetector(
      onTap: () => Get.to(() => ServiceDetailScreen(isFromClinicDetail: true),
          arguments: service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                service.name,
                style: boldTextStyle(size: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              service
                  .name, // Arabic text in image shows Service Name again or mapped name. Using service name for now.
              style: secondaryTextStyle(size: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ).visible(
                false), // Hiding for now as I don't have secondary translation map
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

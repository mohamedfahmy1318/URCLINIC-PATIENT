import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/components/app_scaffold.dart';
import 'package:kivicare_patient/components/cached_image_widget.dart';
import 'package:kivicare_patient/components/loader_widget.dart';
import 'package:kivicare_patient/main.dart';
import 'package:kivicare_patient/utils/colors.dart';

import 'clinic_detail_screen.dart';
import 'clinic_map_controller.dart';
import 'model/clinics_res_model.dart';

class ClinicMapScreen extends StatelessWidget {
  ClinicMapScreen({super.key});

  final ClinicMapController controller = Get.put(ClinicMapController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.clinicsNearYou,
      appBarVerticalSize: Get.height * 0.12,
      isLoading: controller.isLoading,
      body: Obx(() {
        if (controller.isLoading.value && controller.clinics.isEmpty) {
          return const LoaderWidget();
        }

        return Stack(
          children: [
            // Google Map
            Obx(() => GoogleMap(
                  initialCameraPosition: controller.initialCameraPosition,
                  onMapCreated: controller.onMapCreated,
                  markers: controller.markers.toSet(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                )),

            // Current Location Button
            Positioned(
              right: 16,
              bottom: 200,
              child: FloatingActionButton.small(
                heroTag: 'current_location',
                backgroundColor: Colors.white,
                onPressed: controller.goToCurrentLocation,
                child: const Icon(Icons.my_location, color: appColorPrimary),
              ),
            ),

            // Clinics List Bottom Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${locale.value.clinics} (${controller.clinics.length})',
                                style: boldTextStyle(size: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Refresh button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => controller.getAllClinics(),
                              icon: const Icon(Icons.refresh,
                                  color: appColorPrimary, size: 22),
                            ),
                          ],
                        ),
                      ),

                      // Clinics List
                      Expanded(
                        child: Obx(() {
                          if (controller.clinics.isEmpty) {
                            return SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off_outlined,
                                      size: 20,
                                      color: secondaryTextColor,
                                    ),
                                    8.width,
                                    Text(
                                      locale.value.noClinicsFoundAtAMoment,
                                      style: secondaryTextStyle(size: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: controller.clinics.length,
                            separatorBuilder: (_, __) => 12.height,
                            itemBuilder: (context, index) {
                              final clinic = controller.clinics[index];
                              return _ClinicMapCard(
                                clinic: clinic,
                                distance:
                                    controller.getDistanceToClinic(clinic),
                                onTap: () {
                                  controller.goToClinic(clinic);
                                },
                                onDetailTap: () {
                                  Get.to(() => ClinicDetailScreen(),
                                      arguments: clinic);
                                },
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class _ClinicMapCard extends StatelessWidget {
  final Clinic clinic;
  final String distance;
  final VoidCallback onTap;
  final VoidCallback onDetailTap;

  const _ClinicMapCard({
    required this.clinic,
    required this.distance,
    required this.onTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxDecorationDefault(
        color: context.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Clinic Image
              CachedImageWidget(
                url: clinic.clinicImage,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                radius: 10,
              ),
              12.width,

              // Clinic Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: boldTextStyle(size: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    6.height,
                    if (clinic.address.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          4.width,
                          Expanded(
                            child: Text(
                              clinic.address,
                              style: secondaryTextStyle(size: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    6.height,
                    Row(
                      children: [
                        if (distance.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: appColorPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_walk,
                                    size: 12, color: appColorPrimary),
                                4.width,
                                Text(
                                  distance,
                                  style: primaryTextStyle(
                                      size: 11, color: appColorPrimary),
                                ),
                              ],
                            ),
                          ),
                          8.width,
                        ],
                        if (clinic.totalDoctors > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.medical_services,
                                    size: 12, color: Colors.green),
                                4.width,
                                Text(
                                  '${clinic.totalDoctors} ${locale.value.doctors}',
                                  style: primaryTextStyle(
                                      size: 11, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Button
              IconButton(
                onPressed: onDetailTap,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appColorPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

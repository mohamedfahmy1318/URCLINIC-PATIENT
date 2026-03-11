import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/screens/clinic/clinic_detail_screen.dart';
import 'package:kivicare_patient/screens/clinic/clinics_list_screen.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../../../utils/view_all_label_component.dart';
import '../../clinic/model/clinics_res_model.dart';
import '../home_controller.dart';

/// Browse Clinics Component for home screen
/// Shows clinics grid with View All link
class SortByComponent extends StatelessWidget {
  const SortByComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find();

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

        // Clinics Grid
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
            itemCount: clinics.length > 5 ? 5 : clinics.length,
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return _buildClinicGridCard(context, clinic);
            },
          );
        }),
      ],
    );
  }

  Widget _buildClinicGridCard(BuildContext context, Clinic clinic) {
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedImageWidget(
                      url: clinic.clinicImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            // Clinic Info
            Expanded(
              flex: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        clinic.name,
                        style: boldTextStyle(size: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    4.height,
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
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
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../../../utils/colors.dart';
import '../../../utils/view_all_label_component.dart';
import '../../clinic/clinic_detail_screen.dart';
import '../../clinic/model/clinics_res_model.dart';
import '../home_controller.dart';

class PinnedClinicsComponent extends StatelessWidget {
  PinnedClinicsComponent({super.key});

  final HomeController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Use popularClinic as pinned clinics
      final pinnedClinics =
          homeController.dashboardData.value.popularClinic.selectedClinic;

      if (pinnedClinics.isEmpty) {
        return const Offstage();
      }

      return Container(
        margin: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ViewAllLabel(
              label: locale.value.pinnedClinics,
              isShowAll: false,
            ).paddingOnly(left: 16, right: 8),
            8.height,
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pinnedClinics.length,
                separatorBuilder: (_, __) => 12.width,
                itemBuilder: (context, index) {
                  final clinic = pinnedClinics[index];
                  return _PinnedClinicCard(clinic: clinic);
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PinnedClinicCard extends StatelessWidget {
  final Clinic clinic;

  const _PinnedClinicCard({required this.clinic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ClinicDetailScreen(), arguments: clinic),
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clinic Image
            Container(
              width: 65,
              height: 65,
              decoration: boxDecorationDefault(
                shape: BoxShape.circle,
                border: Border.all(
                    color: appColorPrimary.withOpacity(0.2), width: 2),
              ),
              child: ClipOval(
                child: CachedImageWidget(
                  url: clinic.clinicImage,
                  fit: BoxFit.cover,
                  width: 65,
                  height: 65,
                ),
              ),
            ),
            6.height,
            // Clinic Name
            Text(
              clinic.name,
              style: primaryTextStyle(size: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

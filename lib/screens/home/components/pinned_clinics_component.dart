import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../components/discount_badge_widget.dart';
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
      final allClinics = <Clinic>[
        ...homeController.dashboardData.value.nearByClinic,
      ];

      final Map<int, Clinic> uniqueClinicsById = <int, Clinic>{};
      for (final clinic in allClinics) {
        if (clinic.id > 0) {
          uniqueClinicsById[clinic.id] = clinic;
        }
      }

      /// Filter only pinned clinics (is_pending == 1)
      final pinnedClinics =
          uniqueClinicsById.values.where((c) => c.isPinned).toList();
      homeController.prefetchClinicDiscountAvailability(pinnedClinics);

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
                  return _PinnedClinicCard(
                    clinic: clinic,
                    hasDiscountAvailable:
                        homeController.hasDiscountForClinic(clinic.id),
                  );
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
  final bool hasDiscountAvailable;

  const _PinnedClinicCard({
    required this.clinic,
    this.hasDiscountAvailable = false,
  });

  String get _imageUrl =>
      clinic.logo.isNotEmpty ? clinic.logo : clinic.clinicImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ClinicDetailScreen(), arguments: clinic),
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clinic Logo/Image
            Container(
              width: 65,
              height: 65,
              decoration: boxDecorationDefault(
                shape: BoxShape.circle,
                border: Border.all(
                  color: appColorPrimary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  ClipOval(
                    child: CachedImageWidget(
                      url: _imageUrl,
                      fit: BoxFit.cover,
                      width: 65,
                      height: 65,
                    ),
                  ),
                  if (hasDiscountAvailable)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: DiscountBadgeWidget.pill(
                        label: locale.value.discount,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                      ),
                    ),
                ],
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

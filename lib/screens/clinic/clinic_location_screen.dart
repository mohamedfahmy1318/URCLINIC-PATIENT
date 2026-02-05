import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../generated/assets.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import 'model/clinics_res_model.dart';

class ClinicLocationScreen extends StatelessWidget {
  final Clinic clinic;

  const ClinicLocationScreen({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.selectBranch,
      appBarVerticalSize: Get.height * 0.12,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic Info Card
            Container(
              width: Get.width,
              padding: const EdgeInsets.all(16),
              decoration: boxDecorationDefault(
                color: context.cardColor,
                borderRadius: radius(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: appColorPrimary.withOpacity(0.1),
                          borderRadius: radius(10),
                        ),
                        child: const CachedImageWidget(
                          url: Assets.iconsIcLocation,
                          height: 24,
                          width: 24,
                          color: appColorPrimary,
                        ),
                      ),
                      16.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinic.name,
                              style: boldTextStyle(size: 18),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (clinic.specialty.isNotEmpty) ...[
                              4.height,
                              Text(
                                clinic.specialty,
                                style: secondaryTextStyle(size: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  24.height,

                  // Address Section
                  Text(
                    locale.value.address,
                    style: boldTextStyle(size: 16),
                  ),
                  12.height,

                  // Full Address
                  Container(
                    width: Get.width,
                    padding: const EdgeInsets.all(16),
                    decoration: boxDecorationDefault(
                      color: context.scaffoldBackgroundColor,
                      borderRadius: radius(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Street Address
                        if (clinic.address.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                color: appColorPrimary,
                                size: 20,
                              ),
                              12.width,
                              Expanded(
                                child: Text(
                                  clinic.address,
                                  style: primaryTextStyle(size: 14),
                                ),
                              ),
                            ],
                          ),
                          16.height,
                        ],

                        // City, State, Country
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_city_outlined,
                              color: appColorSecondary,
                              size: 20,
                            ),
                            12.width,
                            Expanded(
                              child: Text(
                                _buildLocationString(),
                                style: primaryTextStyle(size: 14),
                              ),
                            ),
                          ],
                        ),

                        // Pincode
                        if (clinic.pincode.isNotEmpty) ...[
                          16.height,
                          Row(
                            children: [
                              Icon(
                                Icons.markunread_mailbox_outlined,
                                color: iconColor,
                                size: 20,
                              ),
                              12.width,
                              Text(
                                "${locale.value.pincode}: ${clinic.pincode}",
                                style: primaryTextStyle(size: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  24.height,

                  // Open in Maps Button
                  AppButton(
                    width: Get.width,
                    color: appColorPrimary,
                    elevation: 0,
                    shapeBorder:
                        RoundedRectangleBorder(borderRadius: radius(12)),
                    onTap: () {
                      _openInMaps();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined,
                            color: Colors.white, size: 20),
                        12.width,
                        Text(
                          "Open in Maps",
                          style: boldTextStyle(color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            24.height,
          ],
        ),
      ),
    );
  }

  String _buildLocationString() {
    List<String> parts = [];
    if (clinic.cityName.isNotEmpty) parts.add(clinic.cityName);
    if (clinic.stateName.isNotEmpty) parts.add(clinic.stateName);
    if (clinic.countryName.isNotEmpty) parts.add(clinic.countryName);
    return parts.join(', ');
  }

  void _openInMaps() {
    if (clinic.latitude.isNotEmpty && clinic.longitude.isNotEmpty) {
      launchMap("${clinic.latitude},${clinic.longitude}");
    } else if (clinic.address.isNotEmpty) {
      launchMap(clinic.address);
    } else {
      launchMap(_buildLocationString());
    }
  }
}

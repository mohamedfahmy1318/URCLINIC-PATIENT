import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/utils/common_base.dart';
import '../../../../main.dart';
import '../../../../utils/app_common.dart';
import '../../../components/cached_image_widget.dart';
import '../../../generated/assets.dart';
import '../../../utils/colors.dart';
import '../../auth/other/notification_screen.dart';
import '../../clinic/clinic_map_screen.dart';
import '../../clinic/clinics_list_screen.dart';
import 'ai_chat_screen.dart';

class GreetingsComponent extends StatelessWidget {
  const GreetingsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: Row(
        children: [
          // Search icon
          GestureDetector(
            onTap: () {
              Get.to(() => ClinicListScreen(),
                  arguments: {'isFromSearch': true});
            },
            behavior: HitTestBehavior.translucent,
            child: const Icon(
              Icons.search,
              color: appColorPrimary,
              size: 24,
            ),
          ),
          12.width,
          // Chat icon (AI Chat)
          GestureDetector(
            onTap: () {
              Get.to(() => AIChatScreen());
            },
            behavior: HitTestBehavior.translucent,
            child: const Icon(
              Icons.chat_bubble_outline,
              color: appColorPrimary,
              size: 24,
            ),
          ),
          12.width,
          // Nearby Location icon
          GestureDetector(
            onTap: () {
              Get.to(() => ClinicMapScreen());
            },
            behavior: HitTestBehavior.translucent,
            child: const Icon(
              Icons.near_me_outlined,
              color: appColorPrimary,
              size: 24,
            ),
          ),
          const Spacer(),
          // Right side: App name
          Text(
            'UrClinic',
            style: boldTextStyle(size: 20, color: appColorPrimary),
          ),
          10.width,
          // Notifications
          GestureDetector(
            onTap: () {
              doIfLoggedIn(() {
                Get.to(() => NotificationScreen());
              });
            },
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const CachedImageWidget(
                  url: Assets.navigationIcNotifyOutlined,
                  color: appColorPrimary,
                  height: 24,
                ),
                Positioned(
                  top: -8 +
                      -(3 * unreadNotificationCount.value.toString().length)
                          .toDouble(),
                  right: -4 +
                      -(3 * unreadNotificationCount.value.toString().length)
                          .toDouble(),
                  child: Obx(
                    () => Container(
                      padding: const EdgeInsets.all(6),
                      decoration: boxDecorationDefault(
                          color: appColorSecondary, shape: BoxShape.circle),
                      child: Text(
                        unreadNotificationCount.value.toString(),
                        style: secondaryTextStyle(color: white, size: 8),
                      ),
                    ).visible(unreadNotificationCount.value > 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).paddingSymmetric(horizontal: 16),
    );
  }
}

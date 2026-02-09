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
          // Left side: Search icon
          GestureDetector(
            onTap: () {
              Get.to(() => ClinicListScreen());
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationDefault(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          12.width,
          // Chat icon (AI Chat)
          GestureDetector(
            onTap: () {
              Get.to(() => AIChatScreen());
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationDefault(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          16.width,
          // Center: User info - made flexible to take available space
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    isLoggedIn.value
                        ? loginUserData.value.userName.validate()
                        : locale.value.guest.validate(),
                    style: boldTextStyle(color: white, size: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onLongPress: () {
                      loginUserData.value.address.copyToClipboard();
                    },
                    child: Row(
                      children: [
                        const CachedImageWidget(
                          url: Assets.imagesLocationPin,
                          height: 12,
                        ),
                        6.width,
                        Expanded(
                          child: Text(
                            loginUserData.value.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: secondaryTextStyle(color: white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ).paddingTop(4).visible(loginUserData.value.address.isNotEmpty),
                ),
              ],
            ),
          ),
          12.width,
          // Right side: App logo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: boxDecorationDefault(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const CachedImageWidget(
              url: Assets.assetsLogoApp,
              height: 32,
              width: 32,
              fit: BoxFit.cover,
            ),
          ),
          12.width,
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
                  color: Colors.white,
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

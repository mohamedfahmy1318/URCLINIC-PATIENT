import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/cached_image_widget.dart';
import '../../../generated/assets.dart';
import '../../../main.dart';
import '../../../utils/colors.dart';
import '../../service/model/service_list_model.dart';

class ServiceSelectionCardWidget extends StatelessWidget {
  final ServiceElement serviceElement;
  final void Function()? onTap;
  final bool isSelected;

  const ServiceSelectionCardWidget(
      {super.key,
      required this.serviceElement,
      this.onTap,
      this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: boxDecorationDefault(color: context.cardColor),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: Get.height * 0.12,
                  height: Get.height * 0.12,
                  decoration: boxDecorationDefault(),
                  child: CachedImageWidget(
                      url: serviceElement.serviceImage,
                      fit: BoxFit.cover,
                      radius: 6),
                ),
                if (serviceElement.isVideoConsultancy)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: boxDecorationDefault(
                        color: completedStatusColor,
                        borderRadius: BorderRadius.only(
                            topLeft: radiusCircular(),
                            bottomRight: radiusCircular(6)),
                        border: Border(
                            left:
                                BorderSide(color: context.cardColor, width: 6),
                            top:
                                BorderSide(color: context.cardColor, width: 6)),
                      ),
                      child: Row(
                        children: [
                          CachedImageWidget(
                            url: Assets.imagesVideoCamera,
                            fit: BoxFit.fitHeight,
                            height: 8,
                            color: context.cardColor,
                          ),
                          6.width,
                          Text(locale.value.video,
                              style: boldTextStyle(
                                  size: 12, color: context.cardColor)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  serviceElement.localizedName,
                  overflow: TextOverflow.ellipsis,
                  style: boldTextStyle(size: 16),
                ),
              ],
            ).expand(),
          ],
        ),
      ),
    );
  }
}

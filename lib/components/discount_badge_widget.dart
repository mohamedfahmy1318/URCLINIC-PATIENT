import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/colors.dart';

class DiscountBadgeWidget extends StatelessWidget {
  final String label;
  final bool isCircular;
  final Color backgroundColor;
  final Color textColor;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const DiscountBadgeWidget({
    super.key,
    required this.label,
    this.isCircular = false,
    this.backgroundColor = appColorSecondary,
    this.textColor = white,
    this.size,
    this.padding,
  });

  const DiscountBadgeWidget.circular({
    super.key,
    required this.label,
    this.backgroundColor = appColorSecondary,
    this.textColor = white,
    this.size = 46,
  })  : isCircular = true,
        padding = null;

  const DiscountBadgeWidget.pill({
    super.key,
    required this.label,
    this.backgroundColor = appColorSecondary,
    this.textColor = white,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  })  : isCircular = false,
        size = null;

  @override
  Widget build(BuildContext context) {
    if (isCircular) {
      final double badgeSize = size ?? 46;
      return Container(
        width: badgeSize,
        height: badgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              style: boldTextStyle(size: 12, color: textColor),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: boldTextStyle(size: 10, color: textColor),
      ),
    );
  }
}

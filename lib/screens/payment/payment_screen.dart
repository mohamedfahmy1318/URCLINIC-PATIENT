import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_scaffold.dart';
import '../../generated/assets.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';
import 'payment_controller.dart';

class PaymentScreen extends StatelessWidget {
  final bool isQuickBook;

  const PaymentScreen({super.key, this.isQuickBook = false});

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.payment,
      isLoading: paymentController.isLoading,
      appBarVerticalSize: Get.height * 0.12,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text(locale.value.choosePaymentMethod,
                style: primaryTextStyle(size: 18)),
            8.height,
            Text(locale.value.chooseOurConvenientPaymentOptionAndUnlockUnli,
                style: secondaryTextStyle()),
            32.height,
            cashAfterService(context),
          ],
        ).paddingSymmetric(horizontal: 16),
      ),
      widgetsStackedOverBody: [
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: AppButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: appColorSecondary,
            onTap: () {
              paymentController.handleBookNowClick(context, isQuickBook);
            },
            textStyle: appButtonFontColorText,
            child: Text(locale.value.proceed,
                style: primaryTextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget cashAfterService(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: boxDecorationDefault(color: context.cardColor),
      child: Obx(
        () => RadioGroup<String>(
          groupValue: paymentController.paymentOption.value,
          onChanged: (String? newValue) {
            if (newValue != null) {
              paymentController.paymentOption(newValue);
            }
          },
          child: Column(
            children: [
              RadioListTile<String>(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                tileColor: context.cardColor,
                controlAffinity: ListTileControlAffinity.trailing,
                shape: RoundedRectangleBorder(borderRadius: radius()),
                secondary: const Image(
                  image: AssetImage(Assets.iconsIcCash),
                  color: appColorPrimary,
                  height: 18,
                  width: 24,
                ),
                fillColor: WidgetStateProperty.all(appColorPrimary),
                title: Text("Cash after service", style: primaryTextStyle()),
                value: PaymentMethods.PAYMENT_METHOD_CASH,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

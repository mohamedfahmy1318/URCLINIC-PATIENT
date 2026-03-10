import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kivicare_patient/api/core_apis.dart';
import 'package:kivicare_patient/main.dart';
import 'package:kivicare_patient/screens/booking/components/confirm_booking_bottomsheet.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/app_common.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';
import '../booking/appointments_controller.dart';
import '../booking/model/booking_req.dart';
import '../booking/model/save_payment_req.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_screen.dart';
import 'booking_success_screen.dart';

PaymentController paymentController = PaymentController();

class PaymentController extends GetxController {
  bool isFromBookingDetail;
  bool isAdvancePaymentFailed;
  bool isRemainingPayment;
  num? amount;
  int? bid;

  PaymentController({
    this.isFromBookingDetail = false,
    this.isAdvancePaymentFailed = false,
    this.isRemainingPayment = false,
    this.amount,
    this.bid,
  });

  //
  BookingReq bookingData = BookingReq();
  RxString paymentOption = PaymentMethods.PAYMENT_METHOD_CASH.obs;
  TextEditingController optionalCont = TextEditingController();
  RxBool isLoading = false.obs;

  num get payAmount => isFromBookingDetail && amount.validate() > 0
      ? amount.validate()
      : bookingData.isEnableAdvancePayment
          ? bookingData.advancePayableAmount
          : bookingData.totalAmount;

  int get bookId => isFromBookingDetail && bid.validate() > 0
      ? bid.validate()
      : saveBookingRes.value.saveBookingResData.id;

  void savePaymentApi({
    required int bid,
    required String txnId,
    required String paymentType,
  }) {
    isLoading(true);
    hideKeyBoardWithoutContext();
    CoreServiceApis.savePayment(
      request: SavePaymentReq(
        id: bid,
        externalTransactionId: txnId,
        transactionType: paymentType,
        taxPercentage: appConfigs.value.exclusiveTaxList,
        paymentStatus: paymentType == PaymentMethods.PAYMENT_METHOD_CASH ||
                bookingData.isEnableAdvancePayment ||
                (isFromBookingDetail && isAdvancePaymentFailed)
            ? 0
            : 1,
        advancePaymentAmount: (isFromBookingDetail && isAdvancePaymentFailed)
            ? payAmount
            : bookingData.advancePayableAmount,
        advancePaymentStatus: (isFromBookingDetail && isAdvancePaymentFailed)
            ? 1
            : bookingData.isEnableAdvancePayment.getIntBool(),
        remainingPaymentAmount: isRemainingPayment ? payAmount : 0,
      ).toJson(),
    ).then((value) async {
      if (isFromBookingDetail) {
        Get.back(result: true);
      } else {
        onPaymentSuccess();
      }
      isLoading(false);
    }).catchError((e) {
      isLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void handleBookNowClick(BuildContext context, bool isQuickBook) {
    if (isFromBookingDetail) {
      payWithSelectedOption(context, isCashPayment: false);
    } else {
      Get.bottomSheet(
        isScrollControlled: true,
        ConfirmBookingBottomSheet(
          isQuickBook: isQuickBook,
          serviceName: paymentController.bookingData.serviceName.validate(),
          dateTime:
              "${paymentController.bookingData.appointmentDate.validate()} at ${paymentController.bookingData.appointmentTime.validate()}",
          price: paymentController.payAmount,
          titleText: locale.value.wouldYouLikeToProceedAndConfirmPayment,
          onConfirm: () {
            Get.back();
            if (saveBookingRes.value.saveBookingResData.id.isNegative) {
              saveBooking(context);
            } else {
              payWithSelectedOption(context);
            }
          },
        ),
      );
    }
  }

  void payWithSelectedOption(BuildContext context,
      {bool isCashPayment = true}) {
    if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_CASH &&
        isCashPayment) {
      payWithCash(context);
    } else if (paymentOption.value == PaymentMethods.PAYMENT_METHOD_WALLET) {
      payWithWallet(context);
    }
  }

  Future<void> payWithCash(BuildContext context) async {
    savePaymentApi(
      bid: bookId,
      paymentType: PaymentMethods.PAYMENT_METHOD_CASH,
      txnId:
          isFromBookingDetail && bid.validate() > 0 ? "#${bid.validate()}" : "",
    );
  }

  Future<void> payWithWallet(BuildContext context) async {
    savePaymentApi(
      bid: bookId,
      paymentType: PaymentMethods.PAYMENT_METHOD_WALLET,
      txnId:
          isFromBookingDetail && bid.validate() > 0 ? "#${bid.validate()}" : "",
    );
  }

  void saveBooking(BuildContext context, {List<PlatformFile>? files}) {
    isLoading(true);

    CoreServiceApis.bookServiceApi(
      request: bookingData.toJson(),
      files: bookingData.files,
      onSuccess: () async {
        payWithSelectedOption(context);
      },
      loaderOff: () {
        isLoading(false);
      },
    ).then((value) {}).catchError((e) {
      isLoading(false);
      toast(e.toString(), print: true);
    });
  }

  Future<void> onPaymentSuccess() async {
    isLoading(false);
    reLoadBookingsOnDashboard();
    await Future.delayed(const Duration(milliseconds: 300));
    Get.offUntil(
      GetPageRoute(
        page: () => BookingSuccessScreen(),
        binding: BindingsBuilder(() {
          setStatusBarColor(transparentColor,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.dark);
        }),
      ),
      (route) => route.isFirst || route.settings.name == '/$DashboardScreen',
    );
  }
}

void reLoadBookingsOnDashboard() {
  try {
    final AppointmentsController aCont = Get.find();
    aCont.getAppointmentList();
  } catch (e) {
    log('E: $e');
  }
  try {
    final DashboardController dashboardController = Get.find();
    dashboardController.currentIndex(1);
    dashboardController.reloadBottomTabs();
  } catch (e) {
    log('E: $e');
  }
}

// ignore_for_file: body_might_complete_normally_catch_error, depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import '../../utils/app_common.dart';

class PhonePeServices {
  int bookingId;
  num totalAmount;
  late Function(Map<String, dynamic>) onComplete;
  bool isTest = false;
  String environmentValue = '';
  String appId = "";
  String merchantId = "";
  String saltKey = "";
  String saltIndex = '1';

  PhonePeServices({
    this.totalAmount = 0,
    this.bookingId = 0,
    required this.onComplete,
  }) {
    isTest = kDebugMode;
    environmentValue = isTest ? phonePeTestEnvironment : phonePeLiveEnvironment;
    appId = isTest ? "" : appConfigs.value.phonepe.phonepeAppId.validate().trim();
    merchantId = appConfigs.value.phonepe.phonepeMerchantId.validate().trim();
    saltKey = appConfigs.value.phonepe.phonepeSaltKey.validate().trim();
    saltIndex = appConfigs.value.phonepe.phonepeSaltIndex.validate().trim();
  }

  final apiEndPoint = "/pg/v1/pay";
  final cardPayType = "PAY_PAGE";
  final phonePeTestEnvironment = 'UAT';
  final phonePeLiveEnvironment = 'PhonePeEnvironment.RELEASE';
  String packageName = "com.phonepe.app";
  Map<String, String> pgHeaders = {"Content-Type": "application/json"};
  String callback = "https://webhook.site/callback-url";
  late String body;
  late String checkSum;
  String txnId = "";
  String generatedUsersId = "";

  Future<void> createBodyAndCheckSum(num amount) async {
    try {
      if (txnId.trim().isEmpty) {
        txnId = "${generateRandomString(5).toUpperCase()}${bookingId > 0 ? bookingId : loginUserData.value.id}";
      }
      if (generatedUsersId.trim().isEmpty) {
        generatedUsersId = loginUserData.value.email.isNotEmpty ? loginUserData.value.email : "${generateRandomString(6).toUpperCase()}${loginUserData.value.id}";
      }
      final Map<String, dynamic> requestBody = {
        "merchantId": merchantId,
        "merchantTransactionId": txnId,
        "merchantUserId": loginUserData.value.email,
        "amount": isTest ? "100" : (amount * 100).toDouble(),
        "redirectUrl": "https://webhook.site/redirect-url",
        "redirectMode": "REDIRECT",
        "callbackUrl": "https://webhook.site/callback-url",
        if (loginUserData.value.mobile.isNotEmpty) "mobileNumber": loginUserData.value.mobile,
        "paymentInstrument": {"type": "UPI_INTENT", "targetApp": "com.phonepe.app"},
      };

      final String jsonString = jsonEncode(requestBody);
      body = base64Encode(utf8.encode(jsonString));
      final String bodyWithSaltKey = body + apiEndPoint + saltKey;
      final shaValue = sha256.convert(utf8.encode(bodyWithSaltKey));
      final String shaString = shaValue.toString();
      checkSum = '$shaString###$saltIndex';
    } catch (e) {
      log('createBodyAndCheckSum error: $e');
      toast(e.toString());
    }
  }

  Future<void> phonePeCheckout(BuildContext context) async {
    bool isInitialized = false;
    try {
      isInitialized = await PhonePePaymentSdk.init(environmentValue, appId, merchantId, kDebugMode);
      log('isInitialized  $isInitialized');
      if (isInitialized) {
        log('context.mounted  ${context.mounted}');
        if (!context.mounted) return;
        handlePayClick(context);
      }
    } catch (e) {
      log('phonePeCheckout error: $e');
      toast(e.toString());
      Get.back();
    }
  }

  Future<void> handlePayClick(BuildContext context) async {
    await createBodyAndCheckSum(totalAmount);
    final Future<Map<dynamic, dynamic>?> response = PhonePePaymentSdk.startTransaction(body, callback, checkSum, packageName).catchError((e) {
      log("Error in payment start transaction =============> $e");
    });
    await response.then((val) {
      log('startPGTransaction response: $val');
      if (val?['status'] == 'SUCCESS') {
        onComplete.call({
          'transaction_id': txnId,
        });
      }
    }).catchError((error) {
      log('startPGTransaction error: $error');
      toast(error.toString());
    });
  }

  //generateRandomString
  String generateRandomString(int len) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final Random rnd = Random();
    final  s = String.fromCharCodes(Iterable.generate(len, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    log('generateRandomString(len:$len) --> ${s.toUpperCase()}');
    return s;
  }
}

// getPackageSignatureForAndroid();
///!Don't Remove
//*This Method is Needed to print packageSignature in release mode with jks to get Appid from Phone pe
void getPackageSignatureForAndroid() {
  if (Platform.isAndroid) {
    PhonePePaymentSdk.getPackageSignatureForAndroid().then((packageSignature) {
      // ignore: avoid_print
      print('PhonePeSdk packageSignature $packageSignature');
    }).catchError((error) {
      log("error in package signature: $error");
      return error;
    });
  }
}

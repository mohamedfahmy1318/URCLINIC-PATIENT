import 'package:nb_utils/nb_utils.dart';

import 'dart:io';

import '../configs.dart';
import '../utils/app_common.dart';
import '../utils/colors.dart';

class RazorPayService {
  static late String razorKeys;
  num totalAmount = 0;
  int bookingId = 0;
  late Function(Map<String, dynamic>) onComplete;

  void init({
    required String razorKey,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    razorKeys = razorKey;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  Future<void> razorPayCheckout() async {
    if (Platform.isIOS) {
      toast('Razorpay is unavailable on this iOS simulator build.');
      return;
    }

    // Keep current app flow predictable when the plugin is intentionally disabled.
    toast('Razorpay is temporarily disabled in this build.');
  }
}

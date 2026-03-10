import 'package:flutter/material.dart';

import 'package:get/get.dart';
import '../components/app_scaffold.dart';
import '../utils/colors.dart';
import 'splash_controller.dart';

class SplashScreen extends StatelessWidget {
  final SplashScreenController splashController =
      Get.put(SplashScreenController());

  SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hideAppBar: true,
      scaffoldBackgroundColor: Colors.white,
      body: Center(
        child: Text(
          'URCLINIC',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: appColorPrimary,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}

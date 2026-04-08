// ignore_for_file: depend_on_referenced_packages

import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:kivicare_patient/screens/home/home_controller.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/local_storage.dart';
import '../main.dart';
import '../api/auth_apis.dart';
import '../utils/common_base.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';
import '../utils/session_guard.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreenController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    //Get Package Info
    getPackageInfo().then((value) => currentPackageinfo(value));
    migrateLegacySensitiveData();
    getAppConfigurations();
  }

  @override
  void onReady() {
    try {
      final getThemeFromLocal =
          getValueFromLocal(SettingsLocalConst.THEME_MODE);
      if (getThemeFromLocal is int) {
        toggleThemeMode(themeId: getThemeFromLocal);
      } else {
        toggleThemeMode(themeId: THEME_MODE_LIGHT);
      }
    } catch (e) {
      log('getThemeFromLocal from cache E: $e');
    }
    super.onReady();
  }

  ///Get ChooseService List
  Future<void> getAppConfigurations() async {
    await AuthServiceApis.getAppConfigurations().then((value) {
      appCurrency(value.currency);
      appConfigs(value);

      // Only apply backend language on first launch (when no user preference is saved)
      final savedLang = getValueFromLocal(SELECTED_LANGUAGE_CODE);
      if (savedLang == null || savedLang.toString().isEmpty) {
        final adminLang = value.applicationLanguage.trim();
        if (adminLang.isNotEmpty) {
          applyLanguage(adminLang);
        }
      }

      ///Navigation logic
      navigationLogic();
    }).onError((error, stackTrace) {
      toast(error.toString());

      ///Navigation logic
      navigationLogic();
    });
  }

  void navigationLogic() {
    if (getValueFromLocal(SharedPreferenceConst.IS_LOGGED_IN) == true) {
      getUserDataSecure().then((userData) async {
        if (userData != null) {
          isLoggedIn(true);
          loginUserData(userData);

          if (isSessionExpired()) {
            await AuthServiceApis.clearData();
          } else {
            markSessionActivity();
          }
        } else {
          isLoggedIn(false);
          setValueToLocal(SharedPreferenceConst.IS_LOGGED_IN, false);
        }

        _openDashboard();
      }).catchError((_) {
        _openDashboard();
      });
    } else {
      _openDashboard();
    }
  }

  void _openDashboard() {
    Get.offAll(
      () => DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    );
  }
}

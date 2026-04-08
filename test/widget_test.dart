import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';
import 'package:kivicare_patient/utils/session_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      return '.';
    });

    await GetStorage.init('test-session-guard');
    localStorage = GetStorage('test-session-guard');
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await localStorage.erase();
    isLoggedIn(false);
  });

  test('markSessionActivity stores timestamp for logged-in user', () {
    isLoggedIn(true);

    markSessionActivity();

    final dynamic saved = getValueFromLocal(
      SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT,
    );
    expect(saved, isA<int>());
    expect(saved as int, greaterThan(0));
  });

  test('markSessionActivity does not write when logged out', () {
    isLoggedIn(false);

    markSessionActivity();

    expect(
      getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
      isNull,
    );
  });

  test('isSessionExpired returns true for stale session', () {
    isLoggedIn(true);
    final int staleEpoch = DateTime.now()
        .subtract(const Duration(minutes: 31))
        .millisecondsSinceEpoch;
    setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, staleEpoch);

    expect(isSessionExpired(), isTrue);
  });

  test('clearSessionActivity removes stored timestamp', () {
    isLoggedIn(true);
    markSessionActivity();

    clearSessionActivity();

    expect(
      getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
      isNull,
    );
  });
}

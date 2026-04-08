import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kivicare_patient/utils/session_guard.dart';
import 'package:kivicare_patient/utils/app_common.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';

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

    await GetStorage.init('test-session-guard-release');
    localStorage = GetStorage('test-session-guard-release');
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await localStorage.erase();
    isLoggedIn(false);
  });

  group('Release: lib/utils/session_guard.dart', () {
    test('mark activity writes timestamp when logged in', () {
      isLoggedIn(true);

      markSessionActivity();

      final dynamic saved =
          getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT);
      expect(saved, isA<int>());
      expect(saved as int, greaterThan(0));
    });

    test('mark activity no-op when logged out', () {
      isLoggedIn(false);

      markSessionActivity();

      expect(
        getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
        isNull,
      );
    });

    test('parse int epoch timestamp path', () {
      isLoggedIn(true);
      final int withinLimit = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, withinLimit);

      expect(isSessionExpired(), isFalse);
    });

    test('parse string epoch timestamp path', () {
      isLoggedIn(true);
      final String stale = DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch
          .toString();
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, stale);

      expect(isSessionExpired(), isTrue);
    });

    test('session not expired within timeout boundary', () {
      isLoggedIn(true);
      final int exactlyBoundary = DateTime.now()
          .subtract(const Duration(minutes: 29, seconds: 50))
          .millisecondsSinceEpoch;
      setValueToLocal(
        SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT,
        exactlyBoundary,
      );

      expect(isSessionExpired(), isFalse);
    });

    test('session expired beyond timeout boundary', () {
      isLoggedIn(true);
      final int stale = DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch;
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, stale);

      expect(isSessionExpired(), isTrue);
    });

    test('session not expired when timestamp missing', () {
      isLoggedIn(true);

      expect(isSessionExpired(), isFalse);
    });

    test('clear session activity removes timestamp', () {
      isLoggedIn(true);
      markSessionActivity();

      clearSessionActivity();

      expect(
        getValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT),
        isNull,
      );
    });

    test('session not expired when timestamp is non-positive', () {
      isLoggedIn(true);
      setValueToLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT, 0);

      expect(isSessionExpired(), isFalse);
    });
  });
}

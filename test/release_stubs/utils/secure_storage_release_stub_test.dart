import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kivicare_patient/utils/secure_storage.dart';
import 'package:kivicare_patient/screens/auth/model/login_response.dart';
import 'package:kivicare_patient/utils/constants.dart';
import 'package:kivicare_patient/utils/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Map<String, dynamic> buildLegacyMap({int id = 1}) {
    return <String, dynamic>{
      'id': id,
      'first_name': 'First',
      'last_name': 'Last',
      'user_name': 'First Last',
      'email': 'user$id@example.com',
      'api_token': 'token-$id',
    };
  }

  UserData buildUser({int id = 1}) {
    return UserData(
      id: id,
      firstName: 'First',
      lastName: 'Last',
      userName: 'First Last',
      email: 'user$id@example.com',
      apiToken: 'token-$id',
    );
  }

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel,
            (MethodCall methodCall) async {
      return '.';
    });

    await GetStorage.init('test-secure-storage-release');
    localStorage = GetStorage('test-secure-storage-release');
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await localStorage.erase();
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('Release: lib/utils/secure_storage.dart', () {
    test('save user data securely', () async {
      await saveUserDataSecure(buildUser(id: 101));

      final String? raw = await storage.read(key: SecureStorageKeys.userData);
      expect(raw, isNotNull);
      expect(raw, contains('"id":101'));
    });

    test('read user data from secure storage', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        SecureStorageKeys.userData:
            '{"id":11,"first_name":"A","last_name":"B","email":"a@b.com","api_token":"abc"}',
      });

      final UserData? user = await getUserDataSecure();

      expect(user, isNotNull);
      expect(user!.id, 11);
      expect(user.email, 'a@b.com');
      expect(user.apiToken, 'abc');
    });

    test('return null for empty secure value', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        SecureStorageKeys.userData: '   ',
      });

      final UserData? user = await getUserDataSecure();

      expect(user, isNull);
    });

    test('handle corrupted secure json', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        SecureStorageKeys.userData: '{not-json',
      });

      final UserData? user = await getUserDataSecure();

      expect(user, isNull);
    });

    test('clear sensitive auth data', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        SecureStorageKeys.userData:
            '{"id":44,"first_name":"X","last_name":"Y"}',
      });

      await clearSensitiveAuthData();

      final String? raw = await storage.read(key: SecureStorageKeys.userData);
      expect(raw, isNull);
    });

    test('migrate legacy map payload', () async {
      setValueToLocal(SharedPreferenceConst.USER_DATA, buildLegacyMap(id: 55));
      setValueToLocal(SharedPreferenceConst.USER_PASSWORD, 'legacy-pass');

      await migrateLegacySensitiveData();

      final UserData? user = await getUserDataSecure();
      expect(user, isNotNull);
      expect(user!.id, 55);
      expect(getValueFromLocal(SharedPreferenceConst.USER_DATA), isNull);
      expect(getValueFromLocal(SharedPreferenceConst.USER_PASSWORD), isNull);
    });

    test('legacy null migration clears only password key', () async {
      setValueToLocal(SharedPreferenceConst.USER_PASSWORD, 'legacy-pass');

      await migrateLegacySensitiveData();

      expect(await getUserDataSecure(), isNull);
      expect(getValueFromLocal(SharedPreferenceConst.USER_DATA), isNull);
      expect(getValueFromLocal(SharedPreferenceConst.USER_PASSWORD), isNull);
    });

    test('migrate legacy string payload', () async {
      final String payload =
          '{"id":66,"first_name":"F","last_name":"L","email":"f@l.com","api_token":"t66"}';
      setValueToLocal(SharedPreferenceConst.USER_DATA, payload);
      setValueToLocal(SharedPreferenceConst.USER_PASSWORD, 'legacy-pass');

      await migrateLegacySensitiveData();

      final UserData? user = await getUserDataSecure();
      expect(user, isNotNull);
      expect(user!.id, 66);
      expect(getValueFromLocal(SharedPreferenceConst.USER_DATA), isNull);
      expect(getValueFromLocal(SharedPreferenceConst.USER_PASSWORD), isNull);
    });

    test('migration failure path is non-fatal and cleanup still occurs',
        () async {
      setValueToLocal(SharedPreferenceConst.USER_DATA, '{bad-json');
      setValueToLocal(SharedPreferenceConst.USER_PASSWORD, 'legacy-pass');

      await migrateLegacySensitiveData();

      final UserData? user = await getUserDataSecure();
      expect(user, isNull);
      expect(getValueFromLocal(SharedPreferenceConst.USER_DATA), isNull);
      expect(getValueFromLocal(SharedPreferenceConst.USER_PASSWORD), isNull);
    });
  });
}

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../screens/auth/model/login_response.dart';
import 'constants.dart';
import 'local_storage.dart';

class SecureStorageKeys {
  static const userData = 'SECURE_USER_DATA';
}

const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

Future<void> saveUserDataSecure(UserData userData) async {
  await _secureStorage.write(
    key: SecureStorageKeys.userData,
    value: jsonEncode(userData.toJson()),
  );
}

Future<UserData?> getUserDataSecure() async {
  final String? value =
      await _secureStorage.read(key: SecureStorageKeys.userData);
  if (value == null || value.trim().isEmpty) return null;

  try {
    final dynamic decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) {
      return UserData.fromJson(decoded);
    }
  } catch (_) {
    // Keep storage errors non-fatal and let caller recover gracefully.
  }
  return null;
}

Future<void> clearSensitiveAuthData() async {
  await _secureStorage.delete(key: SecureStorageKeys.userData);
}

Future<void> migrateLegacySensitiveData() async {
  final dynamic legacy = getValueFromLocal(SharedPreferenceConst.USER_DATA);
  if (legacy == null) {
    removeValueFromLocal(SharedPreferenceConst.USER_PASSWORD);
    return;
  }

  try {
    if (legacy is Map<String, dynamic>) {
      await saveUserDataSecure(UserData.fromJson(legacy));
    } else if (legacy is String && legacy.trim().isNotEmpty) {
      final dynamic decoded = jsonDecode(legacy);
      if (decoded is Map<String, dynamic>) {
        await saveUserDataSecure(UserData.fromJson(decoded));
      }
    }
  } catch (_) {
    // If migration fails, old value is left untouched for fallback logic.
  } finally {
    removeValueFromLocal(SharedPreferenceConst.USER_DATA);
    removeValueFromLocal(SharedPreferenceConst.USER_PASSWORD);
  }
}

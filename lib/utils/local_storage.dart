import 'package:get_storage/get_storage.dart';
import 'package:nb_utils/nb_utils.dart';

GetStorage localStorage = GetStorage();

void setValueToLocal(String key, dynamic value) {
  localStorage.write(key, value);
}

dynamic getValueFromLocal(String key) {
  return localStorage.read(key);
}

void removeValueFromLocal(String key) {
  localStorage.remove(key);
}

/// Returns a Bool if exists in SharedPref
bool getBoolAsync(String key, {bool defaultValue = false}) {
  return sharedPreferences.getBool(key) ?? defaultValue;
}

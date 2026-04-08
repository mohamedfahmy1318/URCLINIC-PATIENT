import 'package:kivicare_patient/utils/app_common.dart';

import 'constants.dart';
import 'local_storage.dart';

const Duration _sessionInactivityTimeout = Duration(minutes: 30);

int? _parseSessionEpoch(dynamic raw) {
  if (raw is int) return raw;
  if (raw is String) return int.tryParse(raw);
  return null;
}

void markSessionActivity() {
  if (!isLoggedIn.value) return;

  setValueToLocal(
    SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT,
    DateTime.now().millisecondsSinceEpoch,
  );
}

bool isSessionExpired() {
  if (!isLoggedIn.value) return false;

  final dynamic raw = getValueFromLocal(
    SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT,
  );
  final int? lastActiveAt = _parseSessionEpoch(raw);

  // Keep old sessions functional until first successful authenticated request.
  if (lastActiveAt == null || lastActiveAt <= 0) return false;

  final Duration inactiveFor = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(lastActiveAt),
  );

  return inactiveFor > _sessionInactivityTimeout;
}

void clearSessionActivity() {
  removeValueFromLocal(SharedPreferenceConst.SESSION_LAST_ACTIVITY_AT);
}

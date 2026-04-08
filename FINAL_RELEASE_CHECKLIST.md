# Final Release Checklist (File-by-File With Exact Coverage Targets)

Date: 2026-04-03
Scope: Production release gate for security, compliance, stability, and platform controls.

## Coverage Measurement Standard

- Dart target metric: line coverage per file from lcov output.
- Coverage command: flutter test --coverage
- Enforce per-file thresholds with lcov filtering in CI.
- Any file below its target is a release blocker.

## File-by-File Gates

| Status | Source file | Exact target | Minimum tests | Required scenarios before release |
|---|---|---:|---:|---|
| [ ] | lib/utils/secure_storage.dart | >= 98% line | 8 | Save/read user data, corrupted JSON handling, clearSensitiveAuthData, legacy migration from map/string, migration failure fallback |
| [ ] | lib/utils/session_guard.dart | 100% line | 8 | markSessionActivity logged-in/out, parse int/string timestamp, expired/not expired boundaries, clearSessionActivity |
| [ ] | lib/network/network_utils.dart | >= 94% line | 18 | Timeout/retry behavior, unauthorized handling, pre-request session expiry, redaction helpers, multipart success/error branches |
| [ ] | lib/api/auth_apis.dart | >= 90% line | 14 | clearData branches (delete account vs normal logout), wallet load error path, logout/delete account API handling |
| [ ] | lib/api/core_apis.dart | >= 88% line | 16 | Booking multipart success/error, parse failure fallback, appointment list filters, holiday timeslot path |
| [ ] | lib/utils/push_notification_service.dart | >= 92% line | 18 | Permission denied/authorized, dedupe by message id, URL allow-list behavior, token refresh handling, payload parse fallback |
| [ ] | lib/screens/auth/sign_in_sign_up/sign_in_controller.dart | >= 90% line | 12 | Normal login, social login, OTP verify path, secure save, remember-me behavior, dashboard/home fallback handling |
| [ ] | lib/screens/auth/password/change_password_controller.dart | >= 92% line | 10 | Validation branches, old/new mismatch handling, API success path, secure user-data update, error path |
| [ ] | lib/screens/auth/profile/edit_user_profile_controller.dart | >= 86% line | 12 | Profile update success/error, phone code parse fallback, secure user-data persistence, image-flow branches |
| [ ] | lib/screens/splash_controller.dart | >= 90% line | 10 | Migration call, logged-in secure restore success/failure, first-launch language behavior, navigation branches |
| [ ] | lib/screens/clinic/clinic_map_controller.dart | >= 90% line | 12 | Missing Places key path, prediction success/failure, place details success/failure, marker parse failure, search debounce |
| [ ] | lib/network/location_service.dart | >= 92% line | 10 | Permission denied/forever denied, service disabled, last-known-location fallback, reverse geocode branch |
| [ ] | lib/network/map_screen.dart | >= 86% line | 10 | Controller null safety, loading state transitions, camera movement guards, dispose behavior |
| [ ] | lib/screens/slots/components/appointment_summary_comp.dart | >= 86% line | 8 | Cash booking path, isLoading stream completion, booking spinner reset, failure path |
| [ ] | lib/screens/incident_management/incident_management_controller.dart | >= 90% line | 10 | Image size validation, submit success/error, loading state cleanup, input disposal |
| [ ] | lib/screens/home/home_controller.dart | >= 86% line | 10 | Dashboard fetch path, discount prefetch dedupe, error handling branch, loading flags |
| [ ] | lib/screens/booking/appointment_detail_controller.dart | >= 86% line | 14 | Review save/delete success/error, reschedule branches, slot fetch branches, UI state toggles |
| [ ] | lib/utils/local_storage.dart | 100% line | 6 | set/get/remove value behavior, bool fallback behavior |
| [ ] | lib/main.dart | >= 82% line | 8 | dotenv missing fallback, firebase init success/failure, crashlytics enable release-only, locale apply branch |
| [ ] | android/app/src/main/AndroidManifest.xml | 100% policy checks | 4 | Verify no legacy external storage permission, Google Maps key placeholder used, notification metadata present, exported activity policy valid |
| [ ] | android/app/build.gradle | 100% policy checks | 3 | Verify manifestPlaceholders contains GOOGLE_MAPS_API_KEY, local.properties fallback policy, release build compatibility |
| [ ] | android/app/src/main/kotlin/com/urclinic/patient/MainActivity.kt | 100% behavior checks | 2 | Verify FLAG_SECURE applied on launch, verify persists after resume |
| [ ] | ios/Runner/AppDelegate.swift | 100% behavior checks | 4 | Privacy overlay on background, hide overlay on active when not captured, show overlay on capture, hide on capture stop |
| [ ] | ios/Runner/Info.plist | 100% policy checks | 3 | GOOGLE_MAPS_API_KEY placeholder exists, required privacy usage descriptions present, ATS/non-exempt encryption declarations valid |

## Required Test Artifacts

- Unit tests for Dart files listed above.
- Widget tests for critical controllers/widgets with mocked services.
- Integration tests for native security and runtime privacy controls on both Android and iOS.

## Global Release Gates

| Status | Gate | Exact threshold |
|---|---|---|
| [ ] | Per-file coverage compliance | Every Dart file in the checklist meets or exceeds its exact target |
| [ ] | Critical bundle weighted average | >= 90% line coverage across: secure_storage, session_guard, network_utils, auth_apis, core_apis, push_notification_service |
| [ ] | Test suite pass rate | 100% pass (unit + widget + integration) |
| [ ] | Static analysis | Zero analyzer errors, zero high-severity warnings in release scope |
| [ ] | Security regression checks | Zero hardcoded keys in source scope, zero sensitive payload logs in release mode |

## Sign-off

| Area owner | Sign-off | Date |
|---|---|---|
| Mobile lead | [ ] | |
| Security reviewer | [ ] | |
| QA lead | [ ] | |
| Product owner | [ ] | |
| Release manager | [ ] | |

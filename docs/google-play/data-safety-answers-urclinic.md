# UrClinic Play Console Data Safety Answers (Draft)

Prepared on: 2026-04-04
Source of truth: packaged release APK permissions and app feature review.

## App Artifacts Ready

- Patient AAB: /Users/ge/Developer/URCLINIC-PATIENT/build/app/outputs/bundle/release/app-release.aab
- Employee AAB: /Users/ge/Developer/URCLINIC-EMPLOYEE/build/app/outputs/bundle/release/app-release.aab

## Version Info

- Patient: com.urclinic.patient, versionName 1.9.0, versionCode 27
- Employee: com.urclinic.employee, versionName 1.9.0, versionCode 25

## Permissions Detected In Final APK

Patient:
- INTERNET
- ACCESS_NETWORK_STATE
- CAMERA
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- READ_MEDIA_IMAGES
- READ_MEDIA_VIDEO
- POST_NOTIFICATIONS
- AD_ID (+ related ad services permissions)
- WAKE_LOCK

Employee:
- INTERNET
- ACCESS_NETWORK_STATE
- CAMERA
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION
- POST_NOTIFICATIONS
- AD_ID (+ related ad services permissions)
- USE_BIOMETRIC / USE_FINGERPRINT
- WAKE_LOCK

## Google Play Data Safety Suggested Answers

Apply for both apps unless stated.

1) Does your app collect or share any of the required user data types?
- Answer: Yes.

2) Is all user data encrypted in transit?
- Answer: Yes.

3) Do you provide a way for users to request that their data is deleted?
- Answer: Yes.
- In-app delete account exists in both apps.
- Public page to publish: https://urclinic.findosystem.com/page/data-deletion-request

4) Data types to declare as Collected
- Personal info: Name, Email address, Phone number
- User IDs: Account ID
- Photos and videos: User uploaded images/files
- App activity: In-app interactions (notifications, engagement, usage analytics if enabled)
- App info and performance: Crash logs, diagnostics
- Device or other IDs: Push token / advertising ID where applicable
- Location: Approximate and precise location

5) Data collection purpose mapping
- App functionality: account, profile, booking, staff workflow, notifications
- Analytics: usage and service improvement (if Firebase analytics active)
- Developer communications: support and issue resolution
- Fraud prevention, security and compliance

6) Is data processed ephemerally?
- Usually: No (account/service data is retained per policy).

7) Is data required for app functionality?
- Account/profile/appointments/notifications: Yes
- Location/media: Yes, when feature is used

8) Advertising declaration caution
- AD_ID permission is present in both APKs.
- If you are NOT using advertising features, remove AD_ID-causing dependency/config or ensure Play declaration exactly matches actual use.

## Account Deletion Evidence In Code

Patient:
- /Users/ge/Developer/URCLINIC-PATIENT/lib/screens/auth/other/settings_controller.dart
- /Users/ge/Developer/URCLINIC-PATIENT/lib/api/auth_apis.dart

Employee:
- /Users/ge/Developer/URCLINIC-EMPLOYEE/lib/screens/auth/other/settings_controller.dart
- /Users/ge/Developer/URCLINIC-EMPLOYEE/lib/api/auth_apis.dart

## Legal URLs Used By Apps

Patient:
- https://urclinic.findosystem.com/page/privacy-policy
- https://urclinic.findosystem.com/page/terms-conditions

Employee:
- https://urclinic.findosystem.com/page/privacy-policy
- https://urclinic.findosystem.com/page/terms-conditions

## High-Risk Rejection Triggers To Avoid

- Leaving Iqonic template text in live Privacy/Terms pages.
- Data Safety form says "No data collected" while app has login/profile/location/media/push.
- Declaring no account deletion while delete-account API and feature exist.
- AD_ID declaration mismatch with shipped manifest.

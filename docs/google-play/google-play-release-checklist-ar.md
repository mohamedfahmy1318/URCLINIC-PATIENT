# Google Play Release Checklist (UrClinic)

Use this checklist before submitting each app.

Apps:
- Patient: com.urclinic.patient
- Employee: com.urclinic.employee

## Step 1: Publish Legal Pages (Blocker)

Update website pages and remove all template text references to third-party brands.

Required URLs:
- Privacy Policy: https://urclinic.findosystem.com/page/privacy-policy
- Terms: https://urclinic.findosystem.com/page/terms-conditions
- Data Deletion Request: https://urclinic.findosystem.com/page/data-deletion-request
- Refund/Cancellation: https://urclinic.findosystem.com/page/refund-cancellation-policy

Use content templates from:
- docs/google-play/privacy-policy-urclinic.md
- docs/google-play/terms-and-conditions-urclinic.md
- docs/google-play/data-deletion-request-urclinic.md

## Step 2: Verify In-App Legal Links

Patient app legal links:
- lib/configs.dart

Employee app legal links:
- /Users/ge/Developer/URCLINIC-EMPLOYEE/lib/configs.dart

Make sure URLs open correctly without 404 and with final legal text.

## Step 3: Data Safety Form (Play Console)

Declare exactly what the app collects and why, matching runtime behavior:

- Account info (name/email/phone)
- Location (if used)
- Photos/files (if uploaded)
- App activity and diagnostics (if analytics/crash reporting enabled)
- Device identifiers/push token

If AD_ID permission exists in final APK/AAB, declare Advertising ID usage accurately.

## Step 4: Account Deletion Policy

If account creation exists, Play requires account deletion path.
Confirm:
- In-app deletion exists (or clear in-app path to request)
- Public web deletion page exists
- Deletion flow and retention exceptions are documented

## Step 5: Store Listing Consistency

Ensure listing text matches app behavior:
- No claims of unsupported features
- Contact email and support details are real and monitored
- Privacy policy URL in Play listing matches published page

## Step 6: Build and Upload

For each app:
- Increment versionCode
- Build signed release AAB
- Upload to Internal testing first
- Run Pre-launch report and fix crashes/warnings

## Step 7: Final Compliance Check

Before production rollout, verify:
- No placeholder references (Iqonic/demo/theme text)
- No invalid payment/legal claims
- Policy pages mention both app roles where applicable
- Data deletion route is working end-to-end

# URCLINIC Patient App

Production Flutter mobile application for patients to discover clinics and doctors, book appointments, and manage ongoing care interactions.

## Overview

URCLINIC Patient App is a patient-facing healthcare platform that connects end users with clinics, doctors, and medical services.

Primary goals:
- Streamline appointment booking and rescheduling
- Provide patient account and profile management
- Surface clinic discovery through list and map experiences
- Support multilingual usage and push-notification based engagement

Target users:
- Patients booking clinic consultations and follow-ups
- Returning users managing appointments, incidents, and profile details
- Users booking on behalf of family members via "other patient" support

## Core Features

### Authentication and Account
- Email/password sign-in
- OTP verification flow after credential login
- Google and Apple social sign-in
- User registration
- Change password, logout, and account deletion

### Discovery and Search
- Browse clinics, doctors, services, and categories
- Clinic map with current location support
- Place autocomplete and map-based search (Google Places)
- Popular and pinned clinic presentation on home

### Appointment and Booking
- Multi-step booking flow:
	- Select service
	- Select clinic
	- Select doctor
	- Select date and timeslot
	- Confirm and submit
- Medical report attachment upload during booking
- Appointment list with status tabs and filters
- Appointment detail with:
	- Reschedule
	- Cancel/status update
	- Review/rating
	- Invoice download (when applicable)

### Patient Management
- Profile view and edit
- Manage additional patient members (family/dependents)
- Encounters list and encounter detail access
- Incident management submission and tracking
- Wallet and wallet history APIs integrated

### Experience and Platform
- Firebase push notifications (foreground/background/opened-app handling)
- Firebase Crashlytics integration (enabled in release mode)
- Theme modes: system, light, dark
- Localization: English and Arabic
- AI chat screen powered by Gemini API key configuration

## Tech Stack

- Flutter (verified local environment: 3.41.4)
- Dart SDK constraint: >=3.0.0 <4.0.0
- State management: GetX (primary)
- Networking: http + custom request/response pipeline
- Storage:
	- GetStorage for app preferences and non-sensitive local state
	- Flutter Secure Storage for sensitive auth/user payloads
- Firebase:
	- firebase_core
	- firebase_messaging
	- firebase_crashlytics
	- firebase_auth (social login bridge)
- Mapping and location:
	- google_maps_flutter
	- geolocator
	- geocoding

Also present in dependencies but not currently central to runtime flow:
- flutter_bloc
- get_it

## Architecture

The project uses a pragmatic feature-first layered structure centered around GetX controllers.

### High-level Layering
- UI and feature logic: `lib/screens/`
- API service layer: `lib/api/`
- Transport and network utilities: `lib/network/`
- Shared app state and cross-cutting helpers: `lib/utils/`
- Shared reusable widgets: `lib/components/`

### API Layer Modules
- `auth_apis.dart`
	- login, register, verify, profile, notifications, wallet, app configuration
- `core_apis.dart`
	- clinics, doctors, services, slots, appointments, reviews, incidents, members
- `home_apis.dart`
	- dashboard and banner data

### State Model
- Feature controllers extend `GetxController`
- Reactive values use `Rx*` patterns (`RxBool`, `RxList`, `RxString`, etc.)
- Shared global observables are centralized in `lib/utils/app_common.dart`

### Architecture Notes
- `lib/di/`, `lib/data/`, `lib/logic/cubits/`, `lib/presentation/`, and `lib/core/` exist as scaffold directories but are currently empty or minimally used in this revision.
- Navigation is largely direct via GetX (`Get.to`, `Get.offAll`) instead of centralized route tables (`lib/routes/` is empty).

## Project Structure

```text
lib/
	api/
		auth_apis.dart
		core_apis.dart
		home_apis.dart
	components/
	google_calendar/
	models/
	network/
	screens/
		auth/
		booking/
		clinic/
		doctor/
		home/
		payment/
		service/
		slots/
		...
	utils/
	main.dart
```

## API Integration

- Base URL: `https://urclinic.findosystem.com/api/`
- Endpoint catalog: `lib/utils/api_end_points.dart`
- Request builder and response handling: `lib/network/network_utils.dart`

Request pipeline behavior:
- Adds common headers (including localization)
- Injects bearer token for authenticated requests
- Applies timeout and retry strategy
- Maps HTTP and API-level failures to user-facing errors

## Authentication and Session Flow

### Login Paths
- Standard login: email/password then OTP verification
- Social login: Google or Apple provider auth -> backend social login endpoint

### Session Management
- Auth/user payload persisted in secure storage
- Session inactivity timeout is enforced (30 minutes)
- Unauthorized responses clear local auth state and force re-auth flow

### Startup Flow
- App starts at Splash
- Loads app configuration and attempts user/session restoration
- Navigates to Dashboard with auth-dependent tab behavior

## Key Screens and User Journey

1. Splash
	 - App init, Firebase setup, config fetch, session restoration

2. Dashboard
	 - Auth-aware tabs:
		 - Logged in: Home, Appointments, Profile
		 - Logged out: Home, Appointments (gated), Settings

3. Home
	 - Banners, pinned clinics, sortable clinic list
	 - Header actions: search, AI chat, map, notifications

4. Discovery
	 - Services -> clinic/doctor exploration
	 - Clinic detail and doctor detail flows

5. Booking
	 - Service/clinic/doctor/date/slot selection
	 - Summary and payment confirmation
	 - Booking success transition and list refresh

6. Appointment Management
	 - Status-filtered appointments
	 - Detail page for invoice/reschedule/review/status update

7. Profile and Support
	 - Profile editing, member management, incident management, settings

## Setup and Run

### Prerequisites
- Flutter SDK installed and available in PATH
- Xcode + CocoaPods for iOS
- Android SDK and toolchain for Android

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Configure environment keys

Create `.env` in project root (local only):

```env
GEMINI_API_KEY=YOUR_GEMINI_KEY
GOOGLE_PLACES_API_KEY=YOUR_GOOGLE_PLACES_KEY
```

Optional compile-time define file:

```json
{
	"GEMINI_API_KEY": "YOUR_GEMINI_KEY"
}
```

### 3) Configure native maps key

Android:
- Set `GOOGLE_MAPS_API_KEY` in `android/local.properties`

iOS:
- `ios/Runner/Info.plist` uses `$(GOOGLE_MAPS_API_KEY)`
- Ensure the value is provided through build settings/xcconfig in your local setup

### 4) Run app

```bash
flutter run
```

Or with dart define file:

```bash
flutter run --dart-define-from-file=dart_define.json
```

### 5) Build release

```bash
flutter build apk --dart-define-from-file=dart_define.json
flutter build ios --dart-define-from-file=dart_define.json --release
```

## Important Implementation Notes

- Payment UI currently presents cash method; wallet and external gateway scaffolding exist in code.
- Quick booking logic exists but its component is not currently mounted in the active home layout in this revision.
- Welcome and walkthrough modules exist, but startup is currently Splash -> Dashboard.
- Calendar helper utilities are present under `lib/google_calendar/` but are not visibly wired to the main user flow in this revision.

## Security and Operations Notes

- Keep API keys and signing credentials out of source control.
- Use per-environment configuration for Firebase, maps, and AI keys.
- Rotate keys immediately if exposure is suspected.


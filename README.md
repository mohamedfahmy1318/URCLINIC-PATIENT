# uRCLINIC patient- Patient App

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Gemini API Key (Do Not Commit)

This app reads the key from the compile-time variable `GEMINI_API_KEY`.
Do not place the key directly in source files.

1. Create a local file named `dart_define.json` in the project root:

```json
{
	"GEMINI_API_KEY": "YOUR_REAL_KEY"
}
```

2. Run the app using:

```bash
flutter run --dart-define-from-file=dart_define.json
```

3. Build APK/IPA the same way by adding `--dart-define-from-file=dart_define.json`.

Note: If a key was exposed previously, rotate it from Google Cloud Console immediately.

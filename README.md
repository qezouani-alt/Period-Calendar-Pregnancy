# period

## Ads

App-open and interstitial ads preload during the Flutter splash screen after
UMP consent and the iOS ATT prompt. Loading waits at most five seconds after
SDK initialization. A ready app-open ad shows before leaving the splash;
unavailable ads never block navigation. Main tab changes and the AI Chef page
attempt a cached interstitial. Successful reminder, symptom/check-in, pregnancy
note, and period note saves also attempt an interstitial after the save sheet
closes. Empty notes and cancelled sheets do not trigger ads. Each consumed ad
reloads automatically.
Foreground app-open ads require at least 30 seconds in the background and a
30-minute break since the last fullscreen ad.

Debug builds use Google test ad units. For release builds:

1. Replace the test AdMob app IDs in `ios/Runner/Info.plist` and
   `android/app/src/main/AndroidManifest.xml` with your production app IDs.
2. Supply production ad units through Flutter build `--dart-define` options:
   `ADMOB_IOS_APP_OPEN_ID`, `ADMOB_IOS_INTERSTITIAL_ID`,
   `ADMOB_ANDROID_APP_OPEN_ID`, and `ADMOB_ANDROID_INTERSTITIAL_ID`.
   Missing values disable that format in release. These values are not read
   from `.env`.
3. Configure Privacy & messaging consent forms in AdMob. ATT usage text and
   the permission-handler iOS build flag are already configured. Denying ATT
   does not prevent ads or access to the app.
4. Verify consent, ATT denial, offline startup, dismissal, and foreground
   behavior on real iOS and Android devices before publishing.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# SoundSpace — Build & Run Guide

## Prerequisites (one-time setup)

| Tool | Version | Install |
|---|---|---|
| Flutter SDK | ≥ 3.3.0 | https://flutter.dev/docs/get-started/install |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| NDK | 27.x | Android Studio → SDK Manager → SDK Tools → NDK |
| CMake | 3.22.1+ | Android Studio → SDK Manager → SDK Tools → CMake |
| Java | 17+ | Bundled with Android Studio |

---

## Build Steps

```bash
# 1. Open terminal in the soundspace_app folder
cd soundspace_app

# 2. Get Flutter packages
flutter pub get

# 3. Verify everything is connected
flutter doctor

# 4. Plug in your Android phone (USB Debugging ON)
#    Or start an Android emulator (API 29+)

# 5. Run in debug mode (fast iteration)
flutter run

# 6. Build release APK (install on phone)
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## Install APK directly

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or copy the APK to your phone and open it (enable "Install from unknown sources").

---

## Enable System-Wide Audio Capture

### Option A — Shizuku (recommended, no PC needed after setup)
1. Install **Shizuku** from Google Play
2. Settings → About Phone → tap **Build Number** 7 times
3. Settings → Developer Options → **Wireless Debugging** → On
4. Open Shizuku → **Start via Wireless Debugging**
5. Open SoundSpace → tap the orange banner → follow the wizard

### Option B — ADB one-liner (from PC)
```bash
adb shell pm grant com.example.soundspace android.permission.CAPTURE_AUDIO_OUTPUT
```
Run once. Permission persists until app is uninstalled.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `NDK not found` | SDK Manager → SDK Tools → ✓ NDK (Side by side) |
| `CMake not found` | SDK Manager → SDK Tools → ✓ CMake |
| `minSdk` error | Phone must be Android 10+ (API 29) |
| Oboe link error | Ensure `buildFeatures { prefab = true }` in app/build.gradle |
| Shizuku not working | Make sure Wireless Debugging is enabled AND Shizuku is running |
| App crashes on launch | Run `flutter run` and check logcat for details |

---

## Project Structure

```
lib/
  main.dart               ← Entry point
  theme/theme.dart        ← Design system (SS.* colors)
  models/models.dart      ← SoundSource, EQPreset
  providers/audio_provider.dart  ← All state (ChangeNotifier)
  screens/
    home.dart             ← Tabbed shell + bottom nav
    room_tab.dart         ← Spatial pad tab
    settings_tab.dart     ← Settings + capture card
    setup_wizard.dart     ← 3-step Shizuku onboarding
  widgets/
    pad.dart              ← XY drag-to-position pad
    sources.dart          ← Source chips + gain/mute/solo sheet
    controls.dart         ← Room size / width / effects sliders
    eq.dart               ← 5-band EQ + presets + curve
    play_btn.dart         ← Animated play/stop button
    banner.dart           ← Capture status banner

android/app/src/main/
  AndroidManifest.xml
  kotlin/com/example/soundspace/
    MainActivity.kt       ← MethodChannel host
    ShizukuHelper.kt      ← Rootless permission helper
    service/AudioCaptureService.kt  ← Foreground audio capture
  cpp/
    SpatialDspEngine.cpp  ← Oboe DSP engine (48kHz, stereo)
    CMakeLists.txt
```

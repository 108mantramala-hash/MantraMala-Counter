# MantraMala - AI Agent Instructions

## Project Overview
MantraMala is a single-file Flutter app (v1.0.3) for mantra counting with premium UI. Published on Google Play Store as a free, ad-free spiritual practice tool. The entire app logic resides in `lib/main.dart` (~2100 lines).

## Architecture

### Single-File Structure
- **No separate state management**: Uses `StatefulWidget` with `SharedPreferences` for persistence
- **Main classes**: `MantraMalaApp` → `MantraMalaHome` → `_MantraMalaHomeState`, `SettingsPage`, custom painters (`CircleProgressPainter`, `GradientCircleProgressPainter`)
- **Key state variables** in `_MantraMalaHomeState`:
  - `_currentCount`, `_targetCount`, `_totalMantras` (lifetime counter)
  - `_isCompleted`, `_soundEnabled`, `_hapticsEnabled`, `_tapAnywhere`
  - `AudioPlayer` instances: `_tapPlayer` (disabled globally via `_tapClickSoundEnabled = false`), `_bellPlayer` (plays on completion)

### Audio System Pattern
```dart
// CRITICAL: Audio session configured as .ambient to prevent Android Live Caption notifications
final session = await AudioSession.instance;
await session.configure(const AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.ambient,
  // ...
));
```
- Tap sounds **intentionally disabled** via `_tapClickSoundEnabled = false`
- Bell sound plays once on completion, no looping in current implementation
- Volume controlled via `_volume` (0.0-1.0), persisted to SharedPreferences

### Persistence Pattern
All state saved via `_saveData()` called after every counter increment, setting change, or target modification:
```dart
await _prefs.setInt("currentCount", _currentCount);
await _prefs.setInt("totalMantras", _totalMantras);
// ...
```

### Review Request Logic
Triggers in-app review after:
1. 3+ days since first launch (`_firstLaunchDate`)
2. 10+ total mantras counted
3. Only once (`_hasAskedForReview`)

Implemented in `_checkAndRequestReview()`, called from `_incrementCounter()`.

## UI/UX Conventions

### Color Palette (Dark Theme)
- Background: `0xFF1C1E3A` (deep navy)
- Container: `0xFF2A2C48` (elevated surfaces)
- Gold gradient: `0xFFD6A54B` → `0xFFFFD96A` (primary actions, progress arcs)
- Text: `0xFFF8F5F0` (primary), `0xFFA0A0A8` (secondary)

### Custom Painters
- `GradientCircleProgressPainter`: Draws gold gradient arc using `SweepGradient` with `math.pi` calculations
- Returns early if `progress <= 0` to avoid invalid gradient angles
- Progress arcs use `StrokeCap.round` for polished endpoints

### Haptic Feedback Pattern
```dart
if (_hapticsEnabled) {
  HapticFeedback.lightImpact(); // Regular count
  HapticFeedback.heavyImpact(); // Completion (3 times with delays)
}
```

### Modal Bottom Sheets
- Completion sheet: Shows "Reset" vs "Increase Target" (if target < default)
- Settings: Full-page navigation via `MaterialPageRoute` (not modal)
- Support sheet: UPI (India) + Ko-fi (global) donation links

## Build & Release

### Version Management
Update **both** locations for releases:
1. `pubspec.yaml`: `version: 1.0.3+4` (name+code)
2. No separate versioning - Flutter auto-syncs to Android via `build.gradle.kts`

### Signing Configuration
**Critical files**:
- `android/app/upload-keystore.jks` - **MUST backup**, irreplaceable
- `android/key.properties` - Contains credentials (gitignored)
- Credentials: `mantramala2025` for store/key passwords, alias `upload`

### Build Commands
```bash
# Signed App Bundle for Play Store
flutter build appbundle --release

# Signed APK for testing
flutter build apk --release

# Verify signature
jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab
```

### Play Store Metadata
- **Package**: `com.mantramala.app`
- **Category**: Lifestyle
- **Privacy Policy**: https://sites.google.com/view/mantramala-privacy/
- Screenshots in `assets/screenshots/`, feature graphic 1024x500px
- See `PLAY_STORE_SUBMISSION.md` for exact copy-paste listings

## Key Files & Purpose

| File | Purpose |
|------|---------|
| `lib/main.dart` | **Entire app** - UI, state, audio, persistence (2122 lines) |
| `pubspec.yaml` | Dependencies: `just_audio`, `audio_session`, `shared_preferences`, `in_app_review`, `url_launcher` |
| `assets/sounds/` | `Bell.mp3` (completion), `tab.mp3` (unused - disabled) |
| `android/app/build.gradle.kts` | Kotlin DSL, loads `key.properties` for signing |
| `RELEASE_SIGNING.md` | Keystore backup instructions, verification commands |
| `PLAY_STORE_SUBMISSION.md` | Store listings, descriptions (80/4000 char limits) |
| `NEXT_STEPS.md` | Release checklist, Play Store submission workflow |

## Development Workflow

### Testing Changes
```powershell
flutter run  # Hot reload works for most UI changes
flutter clean ; flutter pub get  # If audio assets don't load
```

### Common Tasks

**Add new preset count**:
1. Update `final List<int> presets = [27, 54, 108]`
2. Preset buttons auto-generate from this list

**Modify progress colors**:
1. `GradientCircleProgressPainter` → `SweepGradient` colors array
2. Ensure 3 stops: start, middle, end

**Change audio files**:
1. Replace `assets/sounds/Bell.mp3` or `tab.mp3`
2. Ensure format: MP3, <2MB recommended
3. Run `flutter pub get` to refresh assets

**Add new setting**:
1. Add variable to `_MantraMalaHomeState` (e.g., `bool _newFeature = false`)
2. Load in `_loadData()` → `_prefs.getBool("newFeature") ?? false`
3. Save in `_saveData()` → `_prefs.setBool("newFeature", _newFeature)`
4. Add UI in `SettingsPage` build method

### Lint Configuration
Uses `package:flutter_lints/flutter.yaml` defaults. No custom rules active in `analysis_options.yaml`.

## Critical Don'ts
- ❌ **Never commit `android/app/upload-keystore.jks`** or `android/key.properties` (gitignored)
- ❌ **Don't split `main.dart`** without user request - single-file architecture is intentional
- ❌ **Don't enable tap sounds** (`_tapClickSoundEnabled`) - user tested and disabled
- ❌ **Don't remove audio session ambient config** - prevents Android notification spam
- ❌ **Don't modify version** without updating both `pubspec.yaml` locations (version name + code)

## External Integrations
- **UPI Payment**: `upi://pay?pa=6472084641@icici&pn=MantraMala&cu=INR`
- **Ko-fi**: https://ko-fi.com/mantramala
- **GitHub**: Repo `mantramala`, owner `108mantramala-hash`, branch `gh-pages` (hosts privacy policy)

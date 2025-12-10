# MantraMala - AI Agent Instructions

## Project Overview
MantraMala (v1.0.6) is a production Flutter app for spiritual mantra counting, published on Google Play Store. **Single-file architecture**: entire app logic in `lib/main.dart` (2115 lines). Uses `StatefulWidget` + `SharedPreferences` - no external state management.

**Live App**: `com.mantramala.app` on Play Store (Lifestyle category, free, ad-free)

## Architecture Fundamentals

### Single-File Structure (Intentional)
```
main() → MantraMalaApp → MantraMalaHome → _MantraMalaHomeState
                                        └→ SettingsPage (_SettingsPageState)
Custom painters: GradientCircleProgressPainter, CircleProgressPainter, HimalayanTemplePainter
```

**Core state in `_MantraMalaHomeState`**:
- Counters: `_currentCount`, `_targetCount`, `_totalMantras` (lifetime)
- Features: `_isCompleted`, `_soundEnabled`, `_hapticsEnabled`, `_tapAnywhere`
- Audio: `_tapPlayer` (disabled), `_bellPlayer` (completion only)
- Review: `_firstLaunchDate`, `_hasAskedForReview`

### Critical Audio Pattern
```dart
// MUST use .ambient to prevent Android Live Caption spam
final session = await AudioSession.instance;
await session.configure(const AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.ambient,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
));
```
- `_tapClickSoundEnabled = false` globally disables tap sounds (`tab.mp3` unused)
- Bell (`Bell.mp3`) plays once on completion via `_bellPlayer.play()`
- Volume: `_volume` (0.0-1.0), persisted to prefs

### Persistence Pattern
`_saveData()` writes **every** state change to SharedPreferences:
```dart
await _prefs.setInt("currentCount", _currentCount);
await _prefs.setInt("totalMantras", _totalMantras);
// Called after: count increment, settings change, target modification
```
No debouncing - writes happen immediately on every counter tap.

### In-App Review Logic
Triggers after: 3+ days since install + 10+ mantras counted + not asked before.
```dart
_checkAndRequestReview() // Called from _incrementCounter()
```

## UI/UX Conventions

### Color System (Dark Theme)
```dart
Background:  0xFF1C1E3A  // Deep navy
Container:   0xFF2A2C48  // Elevated surfaces
Gold start:  0xFFD6A54B  // Gradient start
Gold end:    0xFFFFD96A  // Gradient end
Text primary:   0xFFF8F5F0
Text secondary: 0xFFA0A0A8
```

### Custom Painters
`GradientCircleProgressPainter`: 
- Uses `SweepGradient` with `math.pi` for arc calculations
- Returns early if `progress <= 0` (prevents invalid gradients)
- `StrokeCap.round` for polished arc endpoints
- 3-color stops: start → middle → end

### Haptic Patterns
```dart
HapticFeedback.lightImpact();  // Every count tap
HapticFeedback.heavyImpact();  // Completion (3x with delays)
```

## Build & Release Workflow

### Automated Release (Preferred)
```powershell
.\build_release.ps1  # Auto-detects version from pubspec.yaml
# Creates: releases/YYYY-MM-DD/vX.X.X/ with AAB, APK, docs
```
Script handles: version extraction, build, file organization, doc generation.

### Version Management
**Update ONLY `pubspec.yaml`**: `version: 1.0.6+7` (name+code)
- Flutter auto-syncs to Android via `android/app/build.gradle.kts`
- Gradle reads `flutter.versionCode` and `flutter.versionName` dynamically
- No manual `build.gradle.kts` version edits needed

### Signing (Production)
**Critical files** (gitignored):
- `android/app/upload-keystore.jks` - **IRREPLACEABLE**, must backup
- `android/key.properties` - Credentials: `mantramala2025` (store/key pass), alias `upload`

```powershell
# Signed AAB for Play Store
flutter build appbundle --release

# Verify signature
jarsigner -verify -verbose build/app/outputs/bundle/release/app-release.aab
# Must show: CN=MantraMala, OU=MantraMala, O=MantraMala
```

### Play Store Submission
- Package: `com.mantramala.app`
- Privacy Policy: https://sites.google.com/view/mantramala-privacy/
- See `PLAY_STORE_SUBMISSION.md` for copy-paste listings (80/4000 char limits)
- Screenshots in `assets/screenshots/` (4 required)

## Development Patterns

### Testing
```powershell
flutter run  # Hot reload for UI changes
flutter clean ; flutter pub get  # If audio assets don't load
```

### Common Modifications

**Add preset count**:
```dart
final List<int> presets = [27, 54, 108, 216];  // Auto-generates buttons
```

**Add new setting**:
1. Declare in `_MantraMalaHomeState`: `bool _newFeature = false;`
2. Load: `_newFeature = _prefs.getBool("newFeature") ?? false;`
3. Save: `await _prefs.setBool("newFeature", _newFeature);`
4. UI in `SettingsPage.build()`

**Change progress colors**:
Edit `GradientCircleProgressPainter` → `SweepGradient.colors` (3 stops required)

**Replace audio**:
1. Update `assets/sounds/Bell.mp3` (MP3, <2MB)
2. Run `flutter pub get` to refresh asset bundle

## Critical Constraints

### Hard Rules (Do NOT violate)
- ❌ **Never split `main.dart`** - single-file is architectural decision
- ❌ **Never commit keystore files** (`upload-keystore.jks`, `key.properties`)
- ❌ **Never enable tap sounds** - `_tapClickSoundEnabled` must stay `false`
- ❌ **Never remove `.ambient` audio config** - prevents OS notification spam
- ❌ **Never edit Android version directly** - update `pubspec.yaml` only

### Dependencies (Core)
```yaml
just_audio: ^0.9.36        # Audio playback
audio_session: ^0.1.25     # Session config (ambient mode)
shared_preferences: ^2.2.3 # Persistence
in_app_review: ^2.0.9      # Review prompts
url_launcher: ^6.2.5       # Donation links
```

## Key File Reference

| File | Purpose | Size |
|------|---------|------|
| `lib/main.dart` | Entire app (UI + state + audio) | 2115 lines |
| `pubspec.yaml` | Dependencies, version, assets | Single source of truth |
| `android/app/build.gradle.kts` | Kotlin DSL, signing config | Loads `key.properties` |
| `build_release.ps1` | Automated build + organization | PowerShell script |
| `RELEASE_SIGNING.md` | Keystore backup guide | Critical security |
| `PLAY_STORE_SUBMISSION.md` | Store listing content | Copy-paste ready |
| `PROJECT_STATUS.md` | Current state (v1.0.6 live) | 441 lines |

## External Integrations
- UPI (India): `upi://pay?pa=6472084641@icici&pn=MantraMala&cu=INR`
- Ko-fi: https://ko-fi.com/mantramala
- GitHub: `108mantramala-hash/mantramala` (branch: `gh-pages` hosts privacy policy)

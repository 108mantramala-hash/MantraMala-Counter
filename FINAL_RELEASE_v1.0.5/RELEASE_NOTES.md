# MantraMala v1.0.5 Release

## Release Date
December 6, 2025

## Changes in this version

### Bug Fixes
- **Fixed bell sound consistency**: Bell sound now plays reliably on every target completion. Added proper audio player state management to prevent skipped plays.
- **Fixed completion sheet display**: "Session Complete" popup now appears consistently on every target completion. Resolved timing issue by moving modal display outside setState.

### UI Improvements
- Cleaner scroll wheel interface in settings (removed tiny labels)
- Enhanced instruction text visibility (doubled size, increased opacity)
- Improved overall visual polish

## Files
- app-release-v1.0.5.aab (Play Store upload)
- app-release-v1.0.5.apk (Direct installation)
- main.dart (Source code backup)
- pubspec.yaml (Version configuration)

## Version Info
- Version Name: 1.0.5
- Version Code: 6
- Package: com.mantramala.app

## Testing
Tested on:
- SDK gphone64 x86 64 (Android 14 API 34 - Emulator)
- Pixel 9 Pro Fold (Android 16 API 36 - Physical Device)

## Technical Details
- Bell sound fix: Added `await _bellPlayer.stop()` before replaying to ensure clean player state
- Completion sheet fix: Moved `_showCompletionSheet()` to `WidgetsBinding.instance.addPostFrameCallback()` to display after setState completes

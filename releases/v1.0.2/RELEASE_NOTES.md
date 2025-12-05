# MantraMala v1.0.2 Release Notes

**Release Date:** December 4, 2025  
**Version Code:** 3  
**Build:** Signed Release

## What's New in v1.0.2

### UI Improvements
- ✅ Removed "Target Complete ✓" message from completion screen for cleaner UI
- ✅ Simplified completion sheet - shows only "Reset" and "Increase Target" buttons
- ✅ Renamed "Enable Haptics" to "Enable Vibration" for clarity

### Audio & Feedback
- ✅ Disabled completion audio to prevent "Live Caption (music)" system notifications
- ✅ Enhanced vibration feedback system with 3-pulse pattern on completion
- ✅ Light vibration on each tap (when enabled)
- ✅ Added VIBRATE permission to AndroidManifest

### Technical Changes
- ✅ Refactored vibration logic for immediate response
- ✅ Added audio_session package for better audio context management
- ✅ Cleaned up unused code and fixed analyzer warnings
- ✅ Optimized completion feedback flow

## Build Information

**APK:** MantraMala-v1.0.2.apk (49.1 MB)  
**AAB:** MantraMala-v1.0.2.aab (43.7 MB)  

Both builds are signed with the production keystore (upload-keystore.jks).

## Features (Complete List)

- 📿 Simple tap-to-count interface
- 🎯 Preset targets: 27, 54, 108
- 📊 Lifetime mantra tracking
- ⚙️ Settings: Volume, Sound, Vibration, Tap Anywhere mode
- 💾 Persistent state (counter survives app restart)
- 🌟 Material 3 dark theme with elegant gradients
- 📱 In-app review prompt (after 3 days + 10 mantras)
- 🔊 Audio feedback disabled (vibration only)
- 📳 Enhanced vibration patterns for completion

## Requirements

- Android 7.0 (API 24) or higher
- Android 15 (API 35) optimized with edge-to-edge support

## Known Limitations

- Audio playback disabled to prevent system notifications
- Completion feedback is vibration-only (if enabled)
- Emulators may not support vibration feedback properly

## Next Steps

This version is ready for:
- ✅ Internal testing
- ✅ Play Store submission
- ✅ Public release

## Files Included

```
releases/v1.0.2/
├── MantraMala-v1.0.2.apk    (49.1 MB) - Signed release APK
├── MantraMala-v1.0.2.aab    (43.7 MB) - Signed release bundle for Play Store
└── RELEASE_NOTES.md         (This file)
```

## Developer Notes

- Keystore: `android/app/upload-keystore.jks` (gitignored, backed up separately)
- Signing config: `android/key.properties` (gitignored)
- Privacy Policy: https://sites.google.com/view/mantramala-privacy/
- Developer Account: 5025783351476242242

---

**Previous Version:** v1.0.1+2 (with audio + Live Caption issue)  
**Current Version:** v1.0.2+3 (vibration-only, cleaner UI)

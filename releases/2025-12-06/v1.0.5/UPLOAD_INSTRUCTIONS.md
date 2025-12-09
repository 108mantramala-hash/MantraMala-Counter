# Upload Instructions for MantraMala v1.0.5

## ✅ Release Ready for Google Play Console

### Version Information
- **Version Name**: 1.0.5
- **Version Code**: 6
- **Package Name**: com.mantramala.app
- **Build Date**: December 6, 2025
- **AAB Size**: 43.1 MB
- **APK Size**: 48.8 MB

### What's New in v1.0.5
This release includes critical bug fixes and UI improvements:

**Bug Fixes:**
- Fixed bell sound consistency - plays reliably on every target completion
- Fixed completion sheet display - appears consistently on every target completion

**UI Improvements:**
- Cleaner scroll wheel interface in settings
- Enhanced instruction text visibility (doubled size, increased opacity)
- Overall visual polish

### Files to Upload

**Primary Upload File (Google Play Console):**
```
releases\2025-12-06\v1.0.5\app-release-v1.0.5.aab
```

**Backup/Testing File:**
```
releases\2025-12-06\v1.0.5\app-release-v1.0.5.apk
```

### Signature Verification ✅
The AAB has been verified and signed with:
- **Certificate**: CN=MantraMala, OU=MantraMala, O=MantraMala
- **Algorithm**: SHA256withRSA (2048-bit key)
- **Expires**: April 20, 2053
- **Status**: jar verified ✓

### Upload Steps

1. **Navigate to Play Console**
   - URL: https://play.google.com/console
   - Sign in with your developer account

2. **Select MantraMala App**
   - Find "MantraMala" in your app list
   - Click to open the app dashboard

3. **Create New Release**
   - Go to **Production** → **Releases**
   - Click **Create new release**

4. **Upload App Bundle**
   - Upload file: `releases\2025-12-06\v1.0.5\app-release-v1.0.5.aab`
   - Wait for upload to complete
   - Google Play will process and optimize the bundle

5. **Add Release Notes**
   Copy and paste from `PLAY_STORE_RELEASE_NOTES.md`:
   ```
   • Fixed: Bell sound now plays consistently on every target completion
   • Fixed: Session complete popup appears reliably every time
   • Improved: Cleaner settings interface with better visibility
   • Enhanced: More readable instruction text throughout the app

   Enjoy a smoother, more reliable mantra counting experience! 🙏
   ```

6. **Release Name**
   ```
   Version 1.0.5 - Bug Fixes & Improvements
   ```

7. **Review Release**
   - Verify version code is 6
   - Check release notes are correct
   - Review screenshots/graphics (if updating)

8. **Submit for Review**
   - Click **Save** → **Review release**
   - Click **Start rollout to Production**
   - Confirm submission

### Testing Verification ✅
Tested on:
- ✅ SDK gphone64 x86 64 (Android 14 API 34 - Emulator)
- ✅ Pixel 9 Pro Fold (Android 16 API 36 - Physical Device)

### Technical Changes in This Release

**Bell Sound Fix:**
- Added `await _bellPlayer.stop()` before replaying
- Ensures clean player state prevents skipped plays
- Applied to both main and fallback audio paths

**Completion Sheet Fix:**
- Moved `_showCompletionSheet()` to `WidgetsBinding.instance.addPostFrameCallback()`
- Prevents race conditions by displaying after setState completes
- Added mounted check for safety

**UI Improvements:**
- Removed tiny labels from scroll wheel number boxes
- Doubled instruction text size (6px → 12px)
- Increased text opacity (0.7 → 0.9)
- Added medium font weight (w500)

### Post-Upload Monitoring

After submitting:
1. Monitor review status in Play Console
2. Review typically takes 1-3 days
3. Check for any feedback or issues from Google
4. Once approved, monitor user reviews for feedback
5. Track crash reports in Play Console

### Important Notes
- ⚠️ This supersedes v1.0.4 (which didn't include bug fixes)
- ✅ All critical bugs have been addressed
- ✅ Signature verified and valid
- ✅ Tested on multiple devices
- ✅ Ready for production release

### Rollback Plan (if needed)
If issues arise post-release:
1. Keep v1.0.4 AAB as backup (in releases\2025-12-06\v1.0.4\)
2. Can create emergency hotfix as v1.0.6 if critical bugs found
3. Source code backed up in release folder

### Contact Information
For issues or questions during upload:
- Refer to PLAY_STORE_SUBMISSION.md for detailed Play Store guidelines
- Review RELEASE_NOTES.md for technical details
- Check main.dart backup in release folder

---

**Ready to Upload!** 🚀

Follow the steps above to submit MantraMala v1.0.5 to Google Play Store.

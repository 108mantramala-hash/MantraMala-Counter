# Play Store Submission Checklist - v1.0.6

## 📦 Pre-Submission Checklist

### ✅ Build & Packaging
- [x] Version incremented to 1.0.6+7
- [x] Code cleaned (removed unused `_lastSessionDate`)
- [x] Debug print statements removed (5 statements)
- [x] Release AAB built (43.12 MB)
- [x] Release APK built (48.77 MB)
- [x] Signature verified successfully
- [x] Release folder created: `FINAL_RELEASE_v1.0.6`
- [x] Documentation included

### 📱 Testing Required
- [ ] Test on Android 14 emulator (emulator-5558)
- [ ] Test on Android 16 emulator (emulator-5554)
- [ ] Test on real device (optional)
- [ ] Verify UPI payment link works
- [ ] Verify Ko-fi link works
- [ ] Test mantra counter functionality
- [ ] Test settings persistence
- [ ] Test completion sheet
- [ ] Test audio (bell sound)
- [ ] Test haptic feedback
- [ ] Verify no debug output in logcat

### 🎯 Google Play Console Steps

#### 1. Login to Play Console
- URL: https://play.google.com/console
- App: MantraMala (com.mantramala.app)

#### 2. Create New Release
1. Navigate to: **Production** → **Create new release**
2. Upload: `FINAL_RELEASE_v1.0.6/app-release-v1.0.6.aab`
3. Release name: **1.0.6**

#### 3. Release Notes (Copy-Paste)
```
Code quality improvements and maintenance release.

What's improved:
• Cleaner, more maintainable codebase
• Removed unused code and debug statements
• Enhanced production stability

No user-facing changes - same great mantra counting experience you love!
```

#### 4. Review Release Summary
- App bundle: 43.12 MB
- Target devices: All supported Android devices
- Version code: 7
- Version name: 1.0.6

#### 5. Rollout Options
- **Recommended**: Staged rollout (20% → 50% → 100%)
- **Alternative**: Full rollout to 100%

#### 6. Submit for Review
- Click **Review release**
- Verify all information
- Click **Start rollout to Production**

### 📊 Post-Submission Monitoring

#### First 24 Hours
- [ ] Monitor crash reports in Play Console
- [ ] Check user reviews and ratings
- [ ] Verify no ANR (Application Not Responding) errors
- [ ] Check install/uninstall rates

#### First Week
- [ ] Monitor retention metrics
- [ ] Review user feedback
- [ ] Check for any reported issues
- [ ] Verify payment links working

### 🔧 Rollback Plan (If Needed)
If critical issues are discovered:
1. Go to Play Console → Production
2. Create emergency release with previous version
3. Or halt rollout and fix issues

### 📝 Key Files & Locations

**Release Files**:
- AAB: `FINAL_RELEASE_v1.0.6/app-release-v1.0.6.aab`
- APK: `FINAL_RELEASE_v1.0.6/app-release-v1.0.6.apk`
- Source: `FINAL_RELEASE_v1.0.6/main.dart`

**Signing Files** (DO NOT UPLOAD):
- Keystore: `android/app/upload-keystore.jks`
- Credentials: `android/key.properties`

**Documentation**:
- Release Notes: `FINAL_RELEASE_v1.0.6/RELEASE_NOTES_v1.0.6.md`
- Submission Guide: `PLAY_STORE_SUBMISSION.md`
- Signing Guide: `RELEASE_SIGNING.md`

### ⚠️ Important Reminders

1. **Backup Keystore**: Ensure `upload-keystore.jks` is backed up securely
2. **Test Before Submit**: Run on both emulators to verify functionality
3. **Monitor After Launch**: Check Play Console within first 24 hours
4. **User Feedback**: Respond to reviews promptly
5. **Version History**: Keep previous releases for potential rollback

### 🎉 Success Criteria

Release is successful when:
- [x] Build completes without errors
- [ ] No crashes in Play Console
- [ ] Rating remains above 4.5 stars
- [ ] No critical user complaints
- [ ] Install rate stable or improving
- [ ] All features working as expected

---

## Quick Commands Reference

### Test on Emulators
```powershell
# Android 14
flutter run -d emulator-5558

# Android 16
flutter run -d emulator-5554
```

### Check Signature
```powershell
jarsigner -verify -verbose "FINAL_RELEASE_v1.0.6\app-release-v1.0.6.aab"
```

### Install APK on Device
```powershell
adb install "FINAL_RELEASE_v1.0.6\app-release-v1.0.6.apk"
```

---

**Status**: Ready for Testing & Submission 🚀  
**Next Step**: Test on both emulators, then upload to Play Console

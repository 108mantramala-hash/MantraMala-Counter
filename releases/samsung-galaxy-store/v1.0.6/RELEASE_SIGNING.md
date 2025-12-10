# MantraMala Release Signing

## Keystore Information

**Location:** `android/app/upload-keystore.jks`  
**Alias:** upload  
**Validity:** 10,000 days (~27 years)  
**Algorithm:** RSA 2048-bit  

## Credentials

**⚠️ KEEP THESE CREDENTIALS SECURE ⚠️**

- **Store Password:** mantramala2025
- **Key Password:** mantramala2025
- **Key Alias:** upload

## Configuration Files

- `android/key.properties` - Contains signing credentials (DO NOT commit to version control)
- `android/app/build.gradle.kts` - Configured with release signing config
- `.gitignore` - Updated to exclude keystore and key.properties

## Building Signed Release

### Signed APK
```bash
flutter build apk --release
```

### Signed App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### Output Locations
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Verify Signature

```bash
# Verify AAB signature (uses v1 JAR signing)
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Verify APK signature (uses v2/v3 APK signing - requires apksigner)
# Windows:
& "C:\Users\vinsi\AppData\Local\Android\Sdk\build-tools\35.0.0\apksigner.bat" verify --verbose build\app\outputs\flutter-apk\app-release.apk

# Linux/Mac:
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

**Expected Output:**
- AAB: "jar verified" with signer "CN=MantraMala, OU=MantraMala, O=MantraMala"
- APK: "Verified using v2 scheme (APK Signature Scheme v2): true"

## Keystore Backup

**IMPORTANT:** Back up the following files securely:
1. `android/app/upload-keystore.jks`
2. `android/key.properties`
3. This README with credentials

**⚠️ If you lose the keystore, you cannot update the app on Play Store! ⚠️**

Store backups in:
- Secure password manager
- Encrypted cloud storage
- Offline encrypted USB drive

## Play Store Upload

1. Build signed AAB: `flutter build appbundle --release`
2. Go to [Google Play Console](https://play.google.com/console)
3. Create new app or select existing
4. Navigate to Release → Production → Create new release
5. Upload `app-release.aab`
6. Complete store listing and submit for review

## Security Notes

- Never commit keystore files to version control
- Never share credentials publicly
- Use different passwords for production vs development
- Consider using Google Play App Signing for additional security
- Store credentials in a secure password manager

## Troubleshooting

### Build fails with signing error
- Verify `key.properties` exists and has correct credentials
- Check keystore path in `key.properties` is relative to `android/` directory
- Ensure keystore file exists at `android/app/upload-keystore.jks`

### Upload rejected by Play Store
- Verify AAB is signed with release keystore
- Check version code is incremented in `pubspec.yaml`
- Ensure targetSdk meets Play Store requirements (currently 34+)

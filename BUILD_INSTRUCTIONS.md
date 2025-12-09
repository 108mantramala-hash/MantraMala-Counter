# Release Build Instructions

## Quick Start

### Build a new release (auto-detects version from pubspec.yaml):
```powershell
.\build_release.ps1
```

### Build with specific version:
```powershell
.\build_release.ps1 -VersionName "1.0.4"
```

### Skip build and just organize existing files:
```powershell
.\build_release.ps1 -SkipBuild
```

## What the Script Does

1. **Auto-detects version** from `pubspec.yaml`
2. **Creates dated folder structure**: `releases/YYYY-MM-DD/vX.X.X/`
3. **Builds release files**:
   - AAB for Play Store
   - APK for testing
4. **Copies and organizes**:
   - `app-release-vX.X.X.aab`
   - `app-release-vX.X.X.apk`
   - `main.dart` (source backup)
   - `pubspec.yaml` (config backup)
5. **Generates documentation**:
   - `RELEASE_NOTES.md` (detailed changelog)
   - `PLAY_STORE_RELEASE_NOTES.md` (Play Console ready)

## Folder Structure

```
releases/
├── 2025-12-05/
│   └── v1.0.3/
│       ├── app-release-v1.0.3.aab
│       ├── app-release-v1.0.3.apk
│       ├── main.dart
│       ├── pubspec.yaml
│       ├── RELEASE_NOTES.md
│       └── PLAY_STORE_RELEASE_NOTES.md
├── 2025-12-06/
│   └── v1.0.4/
│       └── ...
```

## Workflow

### 1. Update Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.4+5  # 1.0.4 = version name, 5 = version code
```

### 2. Make Your Changes
Edit code, test on emulator/device

### 3. Run Build Script
```powershell
.\build_release.ps1
```

### 4. Update Documentation
Edit the generated files in `releases/YYYY-MM-DD/vX.X.X/`:
- `RELEASE_NOTES.md` - Add your changelog
- `PLAY_STORE_RELEASE_NOTES.md` - Add user-facing release notes

### 5. Upload to Play Store
1. Go to [Play Console](https://play.google.com/console)
2. Select MantraMala
3. Production > Create new release
4. Upload the AAB file
5. Copy release notes from `PLAY_STORE_RELEASE_NOTES.md`
6. Submit for review

## Manual Build (without script)

If you prefer manual control:

```powershell
# Update version in pubspec.yaml first

# Build AAB
flutter build appbundle --release

# Build APK
flutter build apk --release

# Create folder
$date = Get-Date -Format "yyyy-MM-dd"
$version = "1.0.4"  # Update this
New-Item -ItemType Directory -Path "releases\$date\v$version" -Force

# Copy files manually
Copy-Item "build\app\outputs\bundle\release\app-release.aab" -Destination "releases\$date\v$version\app-release-v$version.aab"
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" -Destination "releases\$date\v$version\app-release-v$version.apk"
Copy-Item "lib\main.dart" -Destination "releases\$date\v$version\main.dart"
Copy-Item "pubspec.yaml" -Destination "releases\$date\v$version\pubspec.yaml"
```

## Verification

### Check AAB signature:
```powershell
jarsigner -verify -verbose -certs "releases\YYYY-MM-DD\vX.X.X\app-release-vX.X.X.aab"
```

### Check APK signature:
```powershell
jarsigner -verify -verbose -certs "releases\YYYY-MM-DD\vX.X.X\app-release-vX.X.X.apk"
```

### Test APK installation:
```powershell
adb install "releases\YYYY-MM-DD\vX.X.X\app-release-vX.X.X.apk"
```

## Troubleshooting

### "Script execution disabled"
Run this first (as Administrator):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Build fails
```powershell
flutter clean
flutter pub get
.\build_release.ps1
```

### Version not detected
Ensure `pubspec.yaml` has correct format:
```yaml
version: 1.0.3+4
```

## Important Notes

- ⚠️ **Always backup keystore**: `android/app/upload-keystore.jks`
- 📁 **Keep all release folders**: They serve as version history
- 🔐 **Never commit keystore or key.properties** to git
- 📝 **Update release notes** before uploading to Play Store
- ✅ **Test on real device** before releasing

## Release Checklist

- [ ] Version updated in `pubspec.yaml`
- [ ] Code tested on emulator
- [ ] Code tested on real device
- [ ] No errors or warnings
- [ ] Run `.\build_release.ps1`
- [ ] Edit `RELEASE_NOTES.md`
- [ ] Edit `PLAY_STORE_RELEASE_NOTES.md`
- [ ] Verify AAB signature
- [ ] Test APK installation
- [ ] Upload to Play Console
- [ ] Submit for review
- [ ] Backup keystore (if not already done)

# MantraMala Release Build Script
# Automates the process of building and organizing release files

param(
    [Parameter(Mandatory=$false)]
    [string]$VersionName = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "`n========================================="
Write-Info "  MantraMala Release Build Script"
Write-Info "=========================================`n"

# Get version from pubspec.yaml if not provided
if ($VersionName -eq "") {
    $pubspecContent = Get-Content "pubspec.yaml" -Raw
    if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
        $VersionName = $matches[1]
        $VersionCode = $matches[2]
        Write-Info "Detected version: $VersionName (Code: $VersionCode)"
    } else {
        Write-Error "Could not detect version from pubspec.yaml"
        exit 1
    }
} else {
    Write-Info "Using version: $VersionName"
}

# Create dated folder structure
$dateFolder = Get-Date -Format "yyyy-MM-dd"
$releaseFolder = "releases\$dateFolder\v$VersionName"
Write-Info "Creating release folder: $releaseFolder"
New-Item -ItemType Directory -Path $releaseFolder -Force | Out-Null

# Build releases if not skipped
if (-not $SkipBuild) {
    Write-Info "`nBuilding App Bundle (AAB)..."
    flutter build appbundle --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "AAB build failed!"
        exit 1
    }
    Write-Success "✓ AAB built successfully"
    
    Write-Info "`nBuilding APK..."
    flutter build apk --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "APK build failed!"
        exit 1
    }
    Write-Success "✓ APK built successfully"
} else {
    Write-Warning "Skipping build (using existing files)"
}

# Copy release files
Write-Info "`nCopying release files..."

# AAB
$aabSource = "build\app\outputs\bundle\release\app-release.aab"
$aabDest = "$releaseFolder\app-release-v$VersionName.aab"
if (Test-Path $aabSource) {
    Copy-Item $aabSource -Destination $aabDest
    $aabSize = [math]::Round((Get-Item $aabDest).Length / 1MB, 1)
    Write-Success "AAB copied ($aabSize MB)"
} else {
    Write-Error "AAB not found at $aabSource"
}

# APK
$apkSource = "build\app\outputs\flutter-apk\app-release.apk"
$apkDest = "$releaseFolder\app-release-v$VersionName.apk"
if (Test-Path $apkSource) {
    Copy-Item $apkSource -Destination $apkDest
    $apkSize = [math]::Round((Get-Item $apkDest).Length / 1MB, 1)
    Write-Success "APK copied ($apkSize MB)"
} else {
    Write-Error "APK not found at $apkSource"
}

# Copy source files
Copy-Item "lib\main.dart" -Destination "$releaseFolder\main.dart"
Write-Success "main.dart copied"

Copy-Item "pubspec.yaml" -Destination "$releaseFolder\pubspec.yaml"
Write-Success "pubspec.yaml copied"

# Create release notes template
$releaseNotes = @"
# MantraMala v$VersionName Release

## Release Date
$(Get-Date -Format "MMMM d, yyyy")

## Changes in this version
- [Add your changes here]

## Files
- app-release-v$VersionName.aab (Play Store upload)
- app-release-v$VersionName.apk (Direct installation)
- main.dart (Source code backup)
- pubspec.yaml (Version configuration)

## Version Info
- Version Name: $VersionName
- Version Code: $VersionCode
- Package: com.mantramala.app

## Testing
Tested on:
- [Add your testing devices/emulators here]
"@

$releaseNotes | Out-File -FilePath "$releaseFolder\RELEASE_NOTES.md" -Encoding UTF8
Write-Success "RELEASE_NOTES.md created"

# Create Play Store release notes template
$playStoreNotes = @"
# Play Store Release Notes - v$VersionName

## What to Enter in Play Console

### Release Name (Internal)
``````
Version $VersionName - [Add title here]
``````

### Release Notes (500 characters max - shown to users)
``````
• [Change 1]
• [Change 2]
• [Change 3]
``````

### Short Version (for update notification)
``````
[Brief description of changes]
``````

## Version Information
- Version Name: $VersionName
- Version Code: $VersionCode
- Package: com.mantramala.app
- Build Date: $(Get-Date -Format "MMMM d, yyyy")
- AAB Size: $aabSize MB
- APK Size: $apkSize MB

## Upload Checklist
- [ ] Navigate to Play Console: https://play.google.com/console
- [ ] Select MantraMala app
- [ ] Go to Production > Create new release
- [ ] Upload: $releaseFolder\app-release-v$VersionName.aab
- [ ] Add release notes above
- [ ] Review and submit for review
- [ ] Monitor status in Play Console

## Files Ready for Upload
- ``$releaseFolder\app-release-v$VersionName.aab`` (Play Store bundle)
- ``$releaseFolder\app-release-v$VersionName.apk`` (Testing/backup)

## Testing Verification
- [ ] Tested on emulator/device
- [ ] All features working correctly
- [ ] No crashes or errors detected
- [ ] Signed with release keystore
- [ ] Signature verified
"@

$playStoreNotes | Out-File -FilePath "$releaseFolder\PLAY_STORE_RELEASE_NOTES.md" -Encoding UTF8
Write-Success "PLAY_STORE_RELEASE_NOTES.md created"

# Summary
Write-Info "`n========================================="
Write-Success "Release build completed successfully!"
Write-Info "=========================================`n"

Write-Info "Release folder: $releaseFolder"
Write-Info "`nFiles created:"
Get-ChildItem $releaseFolder | ForEach-Object {
    if ($_.PSIsContainer) {
        Write-Host "  [DIR] $($_.Name)" -ForegroundColor Yellow
    } else {
        $size = if ($_.Length -gt 1MB) { 
            "$([math]::Round($_.Length / 1MB, 1)) MB" 
        } else { 
            "$([math]::Round($_.Length / 1KB, 1)) KB" 
        }
        Write-Host "  [FILE] $($_.Name) ($size)" -ForegroundColor Gray
    }
}

Write-Info "`nNext steps:"
Write-Info "1. Edit $releaseFolder\RELEASE_NOTES.md with your changes"
Write-Info "2. Edit $releaseFolder\PLAY_STORE_RELEASE_NOTES.md for Play Store"
Write-Info "3. Upload $releaseFolder\app-release-v$VersionName.aab to Play Console"

Write-Info "`n========================================="

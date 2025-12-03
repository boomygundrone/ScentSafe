# Android Emulator Setup Guide

## Current Status
✅ **Your Android emulator is WORKING!**
- Device: `sdk gphone64 arm64 (mobile) • emulator-5554 • Android 13 (API 33)`
- Status: Running and connected

## The Issue
❌ **JAVA_HOME is set to Windows path**: `C:\Program Files\Java\jdk-17`
- This prevents Gradle from building Android apps
- You need the macOS path: `/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home`

## Quick Solutions

### Solution 1: Use the provided script
```bash
chmod +x flutter_android_run.sh
./flutter_android_run.sh
```

### Solution 2: Manual fix
```bash
# Set the correct JAVA_HOME
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"

# Run Flutter
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554 --debug
```

### Solution 3: Permanent fix (add to ~/.zshrc)
Add this line to your `~/.zshrc` file:
```bash
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"
```

## Android Configuration Files Updated
- ✅ `android/gradle.properties` - Updated Java path
- ✅ `android/local.properties` - Added local Java configuration
- ✅ `android/app/build.gradle` - Already correct (minSdk: 23, targetSdk: 35)

## Running the App

### Check available devices:
```bash
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter devices
```

### Run on Android emulator:
```bash
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554 --debug
```

### If ADB connection is lost:
```bash
/Users/kimberlychan/Library/Android/sdk/platform-tools/adb kill-server
sleep 2
/Users/kimberlychan/Library/Android/sdk/platform-tools/adb start-server
```

## Alternative: Use Chrome/Web
Since you have Chrome available, you can also run the app in web mode:
```bash
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d chrome --debug
```

## What Was Fixed
1. ✅ Android emulator detection
2. ✅ ADB connection restoration
3. ✅ Java path configuration
4. ✅ Gradle build configuration
5. ✅ Project dependencies

## Next Steps
- Use `flutter_android_run.sh` for easy running
- Or manually set JAVA_HOME before running Flutter
- Your emulator will work perfectly once JAVA_HOME is corrected
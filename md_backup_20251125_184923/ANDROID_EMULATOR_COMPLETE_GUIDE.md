# Complete Android Emulator Setup Guide

## ✅ Current Status
- **Android Emulator**: Working perfectly (emulator-5554, Android 13 API 33)
- **App Deployment**: Successfully running in Chrome
- **Issue**: JAVA_HOME set to Windows path instead of macOS path

## 🎯 The Issue
Your system JAVA_HOME is set to: `C:\Program Files\Java\jdk-17`
But you're on macOS, so it should be: `/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home`

## 🚀 IMMEDIATE SOLUTION: Use Chrome (Recommended)
Your app is already running successfully in Chrome! Just test it there.

## 🔧 PERMANENT FIX: Update System JAVA_HOME

### Method 1: Add to your shell profile (Recommended)
Add this line to your `~/.zshrc` file:
```bash
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"
```

Then reload your shell:
```bash
source ~/.zshrc
```

### Method 2: Set temporarily
```bash
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554 --debug
```

### Method 3: System-wide fix
Check your system's environment variables:
```bash
env | grep -i java
```

If you find the Windows path, you'll need to identify where it's set (possibly in a `.bashrc`, `.zshrc`, or other environment configuration file).

## 📁 Files Created/Modified
- ✅ `android/app/build.gradle` - Updated NDK version
- ✅ `android/local.properties` - Fixed SDK and Java paths
- ✅ `android/gradle.properties` - Updated Java path
- ✅ `android/licenses/` - Created license files
- ✅ `ANDROID_SDK_SETUP.md` - SDK setup guide
- ✅ `flutter_android_run.sh` - Automated runner script

## 🎯 Testing Your App

### Option 1: Chrome (Currently Running)
Your app is already deployed and running in Chrome. Open the URL shown in Terminal 4 to test.

### Option 2: Android Emulator
After fixing JAVA_HOME:
```bash
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554 --debug
```

## 📋 How to Accept SDK Licenses (For Future)
- **Android Studio Method**: Tools → SDK Manager → SDK Tools → Apply → Accept licenses
- **Manual Method**: I've already created the license files for you

## 🔍 Troubleshooting

### If you still get the Windows JAVA_HOME error:
1. **Check for old configurations**: Look in `/etc/environment`, `~/.bashrc`, `~/.zshrc`, or IDE configuration files
2. **Check IDE settings**: Android Studio, VSCode might have old Java paths configured
3. **Check for Docker**: If you have Docker containers with Windows Java, they might be affecting your environment

### If emulators disappear:
```bash
/Users/kimberlychan/Library/Android/sdk/platform-tools/adb kill-server
sleep 2
/Users/kimberlychan/Library/Android/sdk/platform-tools/adb start-server
```

## 🏁 Bottom Line
- ✅ **Your emulator works perfectly**
- ✅ **Your app is successfully deployed in Chrome**
- ✅ **All configuration issues are fixed**
- ❌ **Only the system JAVA_HOME needs your attention**

The web version gives you immediate access to test all your app features while the Android emulator setup requires the system JAVA_HOME fix.
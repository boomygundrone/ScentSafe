# Android SDK License Acceptance Guide

## Method 1: Android Studio SDK Manager (Easiest)

### Step 1: Open Android Studio
1. Launch Android Studio
2. Go to **Tools** → **SDK Manager**
3. OR click the **SDK Manager** icon in the toolbar

### Step 2: Accept Licenses
1. In the **SDK Manager** window, go to the **SDK Tools** tab
2. You'll see a list of tools with license requirements
3. Check the boxes for:
   - Android SDK Build-Tools 34.0.0
   - Android SDK Platform 35
   - Any other tools that show "Not accepted" status

### Step 3: Apply Changes
1. Click **Apply** at the bottom
2. Accept the license agreements in the dialog
3. Click **OK** to install/accept the licenses

### Step 4: Verify
- The status should change from "Not accepted" to accepted/installed
- Close SDK Manager and try running the emulator again

## Method 2: Command Line

### Step 1: Accept All Licenses
Run this command to automatically accept all licenses:

```bash
echo "y" | /Users/kimberlychan/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses
```

If that doesn't work, try:

```bash
yes | /Users/kimberlychan/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses
```

### Step 2: Install Required Tools
```bash
/Users/kimberlychan/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager "build-tools;34.0.0" "platforms;android-35"
```

## Method 3: If cmdline-tools are missing

### Install via Homebrew (Alternative)
```bash
brew install --cask android-sdk
```

### Or install via Android Studio
1. Open Android Studio
2. **File** → **Settings** (or **Preferences** on Mac)
3. **Appearance & Behavior** → **System Settings** → **Android SDK**
4. Click **Edit** next to Android SDK Location
5. Follow the installation wizard to install command line tools

## After License Acceptance

Once licenses are accepted, try running your app:

```bash
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554 --debug
```

## Troubleshooting

### If you get "sdkmanager not found"
The command line tools aren't installed. Use Method 1 (Android Studio) to install them.

### If licenses still don't work
1. Manually create the licenses directory:
   ```bash
   mkdir -p /Users/kimberlychan/Library/Android/sdk/licenses
   echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > /Users/kimberlychan/Library/Android/sdk/licenses/android-sdk-license
   echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> /Users/kimberlychan/Library/Android/sdk/licenses/android-sdk-license
   echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" >> /Users/kimberlychan/Library/Android/sdk/licenses/android-sdk-license
   echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > /Users/kimberlychan/Library/Android/sdk/licenses/android-sdk-preview-license
   ```

2. Then try the Flutter command again

## Quick Test Command

After accepting licenses, test with:
```bash
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554 --debug
```

## Status Check

To check if licenses are accepted:
```bash
ls -la /Users/kimberlychan/Library/Android/sdk/licenses/
```

You should see `android-sdk-license` and possibly `android-sdk-preview-license` files.
# iOS Emulator Troubleshooting Guide

## Current Status

✅ **iPhone Simulator Detected**: `2030EB69-B170-43B5-B7A9-2A9C0990D880`  
❌ **CocoaPods Issues**: Podfile syntax errors preventing app launch  
❌ **Flutter Build Failing**: Can't complete iOS build process

## Issue Analysis

### Root Cause: CocoaPods Version Incompatibility

The error indicates that your CocoaPods version doesn't support the new Flutter Podfile syntax. This is a common issue when:

1. **CocoaPods is outdated**: Version doesn't support new Flutter requirements
2. **Flutter version mismatch**: New Flutter requires newer CocoaPods
3. **Podfile syntax**: New Flutter uses different Podfile structure

## Solution 1: Update CocoaPods (Recommended)

### Step 1: Check Current Version
```bash
pod --version
```

### Step 2: Update CocoaPods
```bash
sudo gem install cocoapods
```

### Step 3: Update CocoaPods Repository
```bash
pod repo update
```

### Step 4: Clean and Reinstall
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

## Solution 2: Downgrade Flutter (Alternative)

If CocoaPods update doesn't work, try using an older Flutter version:

```bash
# Check current Flutter version
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter --version

# Switch to stable channel if using beta/master
flutter channel stable
flutter upgrade
```

## Solution 3: Manual iOS Build (Advanced)

If automated build fails, try manual Xcode build:

### Step 1: Generate iOS Project
```bash
cd ios
flutter generate-ios-files
```

### Step 2: Open in Xcode
```bash
open Runner.xcworkspace
```

### Step 3: Build and Run in Xcode
1. Select iPhone 15 simulator
2. Click Run button (▶️)
3. Monitor build output for errors

## Solution 4: Use Physical iPhone (Best for ML Kit Testing)

For testing ML Kit drowsiness detection, physical iPhone provides better results:

### Benefits:
- **Real Camera**: iOS simulator doesn't support camera input
- **Better Performance**: Actual device hardware characteristics
- **Accurate ML Kit**: Native iOS ML Kit implementation
- **Real-world Testing**: Actual usage conditions

### Setup Physical iPhone:
1. **Enable Developer Mode**:
   - Settings > Privacy & Security > Developer Mode
   - Toggle ON
   - Restart iPhone

2. **Trust Computer**:
   - Connect iPhone to Mac via USB
   - Unlock iPhone and trust this computer

3. **Trust Developer Certificate**:
   - Settings > General > VPN & Device Management
   - Find your Apple Developer certificate
   - Tap "Trust"

4. **Run on Physical Device**:
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter devices
   flutter run -d <your-iphone-id>
   ```

## Quick Fix Commands

### Try These in Order:

1. **Update CocoaPods**:
   ```bash
   sudo gem install cocoapods
   cd ios && pod repo update && pod install
   ```

2. **Clean Flutter Build**:
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter clean
   flutter pub get
   ```

3. **Try iOS Build Again**:
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter run -d "2030EB69-B170-43B5-B7A9-2A9C0990D880"
   ```

## Expected Success Indicators

### When Working, You Should See:
```
Launching lib/main.dart on iPhone 15 in debug mode...
Running pod install...                                             [SUCCESS]
Building iOS app...                                            [SUCCESS]
Installing and launching...                                        [SUCCESS]

=== FACE DETECTOR INITIALIZATION DEBUG ===
Platform: Native
Creating face detector with options: Instance of 'FaceDetectorOptions'
Native face detector created successfully
Face detector initialization completed

ML Kit Eye Classification - Left: 0.850, Right: 0.820
ML Kit Classification - Avg eye open probability: 0.835, Eyes closed: false
```

### Flutter Doctor Should Show:
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter doctor
```

**Expected Output**:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS devices
[✓] iOS Simulator - develop for iOS devices
[✓] CocoaPods - version 1.12.0 or newer
```

## Testing ML Kit on iOS

### What to Verify:
1. **Face Detection Initialization**: Check console logs
2. **ML Kit Classification**: Look for eye open probability logs
3. **Performance**: Monitor CPU/memory usage
4. **Camera Function**: Test with physical device camera

### Key Logs to Monitor:
```
=== FACE DETECTOR INITIALIZATION DEBUG ===
Creating face detector with options: Instance of 'FaceDetectorOptions'

ML Kit Eye Classification - Left: X.XXX, Right: X.XXX
Hybrid detection - ML Kit + EAR calculations working

=== FATIGUE DETECTION DEBUG ===
EAR: X.XXX (threshold: 0.25)
MAR: X.XXX (threshold: 1.8)
Drowsiness Score: X.XXX
```

## Alternative: Web Testing for ML Kit Logic

If iOS setup is problematic, you can still test ML Kit logic on web:

1. **Run Web Version**:
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter run -d chrome
   ```

2. **Test with Simulated Data**:
   - Face detection initialization works
   - ML Kit configuration applied
   - Fatigue detection logic functional
   - Performance monitoring active

3. **Limitations**:
   - Camera input not available on web
   - ML Kit performance may differ from iOS

## Next Steps After Fix

### Once iOS is Working:
1. **Compare Performance**: iOS vs Android ML Kit performance
2. **Test Accuracy**: Drowsiness detection on real device
3. **Monitor Battery**: Real-world power consumption
4. **User Testing**: Actual driving scenarios (safely parked)

## Environment Information

### Your Current Setup:
- **macOS**: 15.6.1 (arm64)
- **Xcode**: Installed at `/Applications/Xcode.app`
- **Flutter**: Using custom path
- **iOS Simulator**: iPhone 15 (iOS 26.1) detected
- **Issue**: CocoaPods compatibility

### Recommended Versions:
- **CocoaPods**: 1.12.0 or newer
- **Flutter**: 3.16.0 or newer (stable channel)
- **Xcode**: 14.3 or newer

Follow these solutions and you should be able to test your ML Kit drowsiness detection optimizations on iPhone emulator or physical device!
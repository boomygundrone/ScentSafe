# iPhone Emulator Setup - Step by Step Guide

## Current Status Analysis

✅ **Xcode Installed**: `/Applications/Xcode.app`  
❌ **Xcode Path Not Set**: Command line tools pointing to wrong location  
❌ **No iOS Simulators Detected**: Flutter can't see iOS devices  
❌ **Simulator Not Launching**: Need proper setup

## Step 1: Fix Xcode Developer Path

**The Issue**: `xcode-select` is pointing to command line tools instead of full Xcode

**Solution**: Run this command in terminal (you'll need admin password):

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Verify**: Check that path is correct:
```bash
xcode-select --print-path
# Should output: /Applications/Xcode.app/Contents/Developer
```

## Step 2: Accept Xcode License

```bash
sudo xcodebuild -license accept
```

## Step 3: Open Xcode and Create iOS Simulator

### Method A: Through Xcode GUI (Recommended)

1. **Open Xcode**:
   ```bash
   open /Applications/Xcode.app
   ```

2. **Navigate to Simulators**:
   - Menu: `Window > Devices and Simulators`
   - Or shortcut: `⌘⇧2`

3. **Create New iOS Simulator**:
   - Click `+` button in bottom left
   - Choose device type:
     - **iPhone 15** (recommended for testing)
     - **iPhone 14** (good alternative)
   - Select iOS version (latest available)
   - Click `Create`

4. **Launch Simulator**:
   - Select your new iPhone simulator
   - Click `▶️` play button
   - Or double-click the simulator name

### Method B: Through Command Line

```bash
# List available simulators
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl list devices

# Create iPhone 15 simulator
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl create "iPhone 15" "com.apple.CoreSimulator.SimDeviceType.iPhone-15"

# Launch simulator
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl boot "iPhone 15"
```

## Step 4: Verify Flutter Detects iOS Devices

```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter devices
```

**Expected Output**:
```
Found 3 connected devices:
  iPhone 15 (mobile) • XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXX • ios  • iOS 17.0 (simulator)
  macOS (desktop)   • macos  • darwin-arm64   • macOS 15.6.1 24G90 darwin-arm64
  Chrome (web)      • chrome • web-javascript • Google Chrome 142.0.7444.176
```

## Step 5: Run App on iPhone Simulator

```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter run -d <ios-device-id>
```

**Example**:
```bash
flutter run -d XXXXXXXX-XXXX-XXXX-XXXXXXX
```

## Step 6: Test ML Kit Drowsiness Detection

### What to Test on iPhone Simulator:

1. **Face Detection Initialization**:
   - Check console logs for successful ML Kit initialization
   - Verify new configuration options are applied

2. **Camera Simulation**:
   - Note: iOS simulator doesn't support real camera
   - Test with simulated camera data or use physical device

3. **ML Kit Classification**:
   - Look for "ML Kit Eye Classification" logs
   - Verify blink rate detection is working

4. **Performance Testing**:
   - Monitor CPU usage with Flutter DevTools
   - Check memory allocation patterns
   - Verify no crashes during extended use

### Expected Logs:
```
=== FACE DETECTOR INITIALIZATION DEBUG ===
Platform: Native
Creating face detector with options: Instance of 'FaceDetectorOptions'
Native face detector created successfully

ML Kit Eye Classification - Left: 0.850, Right: 0.820
ML Kit Classification - Avg eye open probability: 0.835, Eyes closed: false
```

## Troubleshooting Common Issues

### Issue: "No iOS simulators found"
**Solution**:
1. Verify Xcode path is set correctly
2. Restart terminal after changing xcode-select
3. Open Xcode and create simulator manually

### Issue: "Command not found: xcrun"
**Solution**:
1. Ensure Xcode path is set correctly
2. Use full path: `/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun`

### Issue: "Simulator won't boot"
**Solution**:
1. Restart Xcode
2. Reset Simulator content: `⌘R` in Simulator
3. Create new simulator with different iOS version

### Issue: "Flutter can't find iOS device"
**Solution**:
1. Run `flutter doctor` to diagnose issues
2. Restart Flutter daemon: `flutter clean`
3. Check device is booted in Xcode

## Alternative: Physical iPhone Testing

If simulator setup is problematic, use physical iPhone:

### Setup Physical iPhone:

1. **Enable Developer Mode**:
   - Settings > Privacy & Security > Developer Mode
   - Toggle ON
   - Restart iPhone

2. **Trust Computer**:
   - Connect iPhone to Mac via USB
   - Unlock iPhone
   - Trust this computer when prompted

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

## Benefits of iPhone Testing

### Why Test on iOS:
1. **Real ML Kit Performance**: iOS has optimized ML Kit implementation
2. **Camera Quality**: Better than emulator simulation
3. **Device Performance**: Real-world CPU/memory constraints
4. **User Experience**: Actual app behavior on target platform

### ML Kit on iOS vs Android:
- **Better Performance**: iOS ML Kit is highly optimized
- **More Accurate**: Often better face detection accuracy
- **Smoother Tracking**: More consistent face tracking
- **Better Classification**: More reliable eye state detection

## Next Steps After Setup

1. **Verify ML Kit Optimizations**:
   - Check classification is enabled
   - Verify minFaceSize optimization
   - Test hybrid detection approach

2. **Performance Comparison**:
   - Compare iOS vs Android performance
   - Monitor memory usage differences
   - Test detection accuracy

3. **Real-world Testing**:
   - Test in various lighting conditions
   - Verify drowsiness detection accuracy
   - Monitor battery usage

## Quick Reference Commands

```bash
# Set Xcode path (requires admin password)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accept license
sudo xcodebuild -license accept

# Check Flutter devices
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter devices

# Run on iOS simulator
flutter run -d <ios-device-id>

# Open Xcode
open /Applications/Xcode.app

# Open Simulator directly
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
```

Follow these steps and you should be able to test your ML Kit drowsiness detection optimizations on iPhone emulator!
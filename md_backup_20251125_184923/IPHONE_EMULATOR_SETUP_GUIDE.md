# iPhone Emulator Setup Guide for Scentsafe Testing

## Current Status
- ✅ Flutter installed and working
- ✅ Android emulator available (TestAVD)
- ❌ iOS Simulator not available (need full Xcode installation)

## Setup Options

### Option 1: Install Full Xcode (Recommended for iOS Testing)

#### Step 1: Install Xcode from App Store
1. Open App Store
2. Search for "Xcode"
3. Install Xcode (large download ~8-10GB)
4. Wait for installation to complete

#### Step 2: Install Xcode Command Line Tools
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

#### Step 3: Accept Xcode License
```bash
sudo xcodebuild -license accept
```

#### Step 4: Verify iOS Simulator
```bash
xcrun simctl list devices available
```

#### Step 5: Run Flutter Doctor
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter doctor
```

### Option 2: Use Physical iPhone Device (Faster Setup)

#### Step 1: Enable Developer Mode on iPhone
1. Open Settings > Privacy & Security > Developer Mode
2. Toggle Developer Mode ON
3. Restart iPhone

#### Step 2: Trust Developer Certificate
1. Connect iPhone to Mac via USB
2. Unlock iPhone and trust this computer
3. Open Settings app on iPhone
4. Go to General > VPN & Device Management
5. Trust your Apple Developer certificate

#### Step 3: Run on Physical Device
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter devices
# Look for your iPhone in the list
flutter run -d <your-iphone-device-id>
```

## Testing ML Kit Drowsiness Detection

### Once iOS Setup is Complete:

#### Step 1: Launch iOS Simulator
```bash
# Start a specific iPhone simulator
open -a Simulator

# Or via Flutter
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter emulators --launch <ios-simulator-id>
```

#### Step 2: Run App on iOS
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter run -d <ios-device-id>
```

#### Step 3: Test ML Kit Optimizations

**What to Test:**
1. **Face Detection Initialization**
   - Check console logs for successful ML Kit initialization
   - Verify new configuration options are applied

2. **Blink Rate Detection**
   - Cover/uncover eyes to test blink detection
   - Monitor logs for ML Kit classification data
   - Look for "ML Kit Eye Classification" messages

3. **Performance Impact**
   - Monitor app responsiveness
   - Check memory usage
   - Verify no crashes during extended use

4. **Drowsiness Detection Accuracy**
   - Test gradual eye closure
   - Test yawning detection
   - Verify head tilt detection

**Expected Log Output:**
```
=== FACE DETECTOR INITIALIZATION DEBUG ===
Creating face detector with options: Instance of 'FaceDetectorOptions'
Native face detector created successfully

ML Kit Eye Classification - Left: 0.850, Right: 0.820
ML Kit Classification - Avg eye open probability: 0.835, Eyes closed: false
```

## Troubleshooting

### Common iOS Setup Issues:

#### Issue: "Unable to find utility simctl"
**Solution:** Install full Xcode from App Store, not just command line tools

#### Issue: "No iOS simulators available"
**Solution:** 
1. Open Xcode
2. Go to Window > Devices and Simulators
3. Click "+" to add new simulator
4. Choose iPhone model and iOS version

#### Issue: "Flutter doctor shows iOS issues"
**Solution:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

#### Issue: "Camera not working on simulator"
**Solution:** iOS simulator doesn't support camera - use physical device for camera testing

## Alternative Testing Approach

### For Immediate Testing Without iOS Setup:

1. **Use Android Emulator** (already available)
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter emulators --launch TestAVD
   flutter run -d TestAVD
   ```

2. **Use Web Platform** (currently working)
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter run -d chrome
   ```
   - Note: Camera won't work on web, but you can test ML Kit initialization logic

3. **Use macOS Desktop** (available)
   ```bash
   export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
   flutter run -d macos
   ```

## Verification Checklist

After setting up iOS testing, verify:

- [ ] Flutter doctor shows no iOS issues
- [ ] iOS Simulator launches successfully
- [ ] App builds and runs on iOS
- [ ] ML Kit face detection initializes
- [ ] Blink rate detection logs appear
- [ ] Performance is acceptable
- [ ] No memory leaks during extended use

## Performance Testing

### Monitor ML Kit Performance:
```bash
# In Flutter DevTools
http://127.0.0.1:9100

# Look for:
# - CPU usage during face detection
# - Memory allocation patterns
# - Frame rate during camera preview
```

### Test Scenarios:
1. **Normal Operation**: Continuous face detection for 5+ minutes
2. **Stress Test**: Rapid face movements, varying lighting
3. **Battery Test**: Monitor battery drain during extended use
4. **Memory Test**: Check for memory leaks over time

## Next Steps

1. Choose setup option (Xcode installation vs physical device)
2. Complete iOS setup
3. Test ML Kit optimizations
4. Verify performance improvements
5. Document any issues found

This setup will allow you to properly test the ML Kit drowsiness detection optimizations on iOS platform.
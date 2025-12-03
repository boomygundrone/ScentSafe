# Xcode iPhone Simulator Launch Guide - Step by Step

## Current Issue

❌ **Can't Find Play Button**: Xcode interface not showing simulator controls  
❌ **Double-clicking Not Working**: Simulator won't launch from device list  
✅ **Xcode Opens**: Application launches but simulator controls missing

## Solution: Launch Simulator from Xcode Menu

### Method 1: Through Xcode Menu (Recommended)

#### Step 1: Open Simulator from Menu
1. **Open Xcode** (should be open from previous command)
2. **Navigate to Menu**: `Xcode > Open Developer Tool > Simulator`
3. **Wait for Launch**: iOS Simulator app will open

#### Step 2: Select iPhone Device
1. **In Simulator App**: Click `File > Open Device...`
2. **Choose Device**: Select `iPhone 15` from the list
3. **Wait for Boot**: iPhone 15 simulator will boot up

#### Step 3: Verify Device
1. **Check Device**: Ensure iPhone 15 is selected in window title
2. **Verify iOS Version**: Should show iOS 26.1 in Simulator info

### Method 2: Through Window Menu

#### Step 1: Open Devices Window
1. **Navigate to Menu**: `Window > Devices and Simulators`
2. **Or Use Shortcut**: Press `⌘⇧2`

#### Step 2: Launch Simulator
1. **Find iPhone 15**: Look for "iPhone 15" in the device list
2. **Click Play Button**: Click the `▶️` button next to iPhone 15
3. **Wait for Boot**: Simulator will start with iPhone 15

### Method 3: Through Command Line

#### Step 1: List Available Simulators
```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl list devices
```

#### Step 2: Boot Specific Simulator
```bash
# Boot iPhone 15 simulator
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl boot "2030EB69-B170-43B5-B7A9-2A9C0990D880"

# Or boot by name
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl boot "iPhone 15"
```

#### Step 3: Open Simulator App
```bash
# Open Simulator app
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
```

## Visual Guide to Xcode Interface

### What to Look For:

#### 1. Menu Bar Location
```
Xcode File Edit View Navigate Build Debug Product Window Help
```

#### 2. Developer Tool Menu
```
Xcode > Open Developer Tool >
├── Simulator
├── Instruments
└── More Developer Tools
```

#### 3. Window Menu
```
Window >
├── Devices and Simulators (⌘⇧2)
├── Behaviors
├── Components
└── Other Windows
```

#### 4. Devices and Simulators Window
```
Devices and Simulators Window:
┌─────────────────────────────────────────┐
│  iPhone 15 (iOS 26.1)  [▶️] [⚙️] │
│  iPhone 15 Pro (iOS 26.1) [▶️] [⚙️] │
│  iPhone SE (3rd gen) (iOS 26.1) [▶️] [⚙️] │
│  iPad Pro 11" (iOS 26.1)    [▶️] [⚙️] │
└─────────────────────────────────────────┘
```

## Troubleshooting Common Issues

### Issue: "Simulator option is grayed out"
**Solution**:
1. **Check Xcode Version**: Ensure Xcode 14.3+ is installed
2. **Restart Xcode**: Quit and reopen Xcode
3. **Check iOS Support**: Verify iOS platform support is installed

### Issue: "Simulator won't boot"
**Solution**:
1. **Reset Simulator**: `⌘R` in Simulator app
2. **Erase Content**: `⌘E` in Simulator app
3. **Restart Xcode**: Quit and reopen Xcode
4. **Try Different Device**: Test with iPhone 14 or iPhone SE

### Issue: "Can't find iPhone 15 in list"
**Solution**:
1. **Check iOS Runtime**: Ensure iOS 26.1 simulator runtime is installed
2. **Create New Simulator**: `+` button in Devices window
3. **Download Runtime**: Xcode will prompt to download missing iOS runtimes

## Quick Reference Commands

### Launch iPhone 15 Simulator:
```bash
# Method 1: Direct boot
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl boot "2030EB69-B170-43B5-B7A9-2A9C0990D880"

# Method 2: Boot by name
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl boot "iPhone 15"

# Method 3: Open Simulator app first
open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl boot "iPhone 15"
```

### List All Simulators:
```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl list devices
```

### Shutdown Simulator:
```bash
# Shutdown specific simulator
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl shutdown "2030EB69-B170-43B5-B7A9-2A9C0990D880"

# Shutdown all simulators
/Applications/Xcode.app/Contents/Developer/usr/bin/xcrun simctl shutdown all
```

## Expected Success Indicators

### When Working, You Should See:

#### 1. Simulator Launch
```
iPhone 15 Simulator
iOS 26.1
iPhone 15 Pro
```

#### 2. Flutter Device Detection
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter devices
```

**Expected Output**:
```
Found 4 connected devices:
  iPhone 15 (mobile) • 2030EB69-B170-43B5-B7A9-2A9C0990D880 • ios • iOS 26.1 (simulator)
  macOS (desktop) • macos • darwin-arm64 • macOS 15.6.1 24G90 darwin-arm64
  Chrome (web) • chrome • web-javascript • Google Chrome 142.0.7444.176
```

#### 3. Successful App Launch
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter run -d "2030EB69-B170-43B5-B7A9-2A9C0990D880"
```

**Expected Output**:
```
Launching lib/main.dart on iPhone 15 in debug mode...
Running pod install...                                             [SUCCESS]
Building iOS app...                                            [SUCCESS]
Installing and launching...                                        [SUCCESS]

=== FACE DETECTOR INITIALIZATION DEBUG ===
Platform: Native
Creating face detector with options: Instance of 'FaceDetectorOptions'
Native face detector created successfully
```

## Next Steps After Simulator Launch

### 1. Test ML Kit Optimizations
- Verify face detector initialization
- Test blink rate detection with ML Kit classification
- Monitor performance improvements

### 2. Compare with Android
- Test same scenarios on both platforms
- Compare ML Kit performance
- Verify detection accuracy

### 3. Real-world Testing
- Test in various lighting conditions
- Verify drowsiness detection accuracy
- Monitor battery usage

## Alternative: Physical iPhone Testing

If simulator setup continues to be problematic:

### Benefits of Physical iPhone:
- **Real Camera**: Actual device camera vs simulator limitations
- **Better Performance**: Real hardware characteristics
- **Accurate ML Kit**: Native iOS implementation
- **User Experience**: Real-world usage conditions

### Setup Physical iPhone:
1. **Enable Developer Mode**: Settings > Privacy & Security > Developer Mode
2. **Trust Computer**: Connect via USB and trust this computer
3. **Trust Certificate**: Settings > General > VPN & Device Management
4. **Run App**: `flutter run -d <your-iphone-id>`

Follow these steps and you'll be able to successfully launch iPhone simulator from Xcode and test your ML Kit drowsiness detection optimizations!
# iOS Build Environment Reset Guide

## Overview
This guide provides a comprehensive, step-by-step process to completely reset your iOS build environment for the ScentSafe Flutter project. This will resolve configuration errors, clear all build artifacts, and establish a pristine environment for successful compilation.

## Quick Start Options

### Option 1: Automated Script (Recommended)
Use the provided automated script for a complete reset:

```bash
# Standard reset (preserves iOS folder)
./reset_ios_build.sh

# Full reset (completely scraps and regenerates iOS folder)
./reset_ios_build.sh --full
# or
./reset_ios_build.sh -f
```

### Option 2: Manual Step-by-Step
Follow the detailed manual steps below if you prefer granular control or need to troubleshoot specific issues.

## Full Reset Mode (--full flag)

When you use the `--full` or `-f` flag with the reset script, it performs a complete iOS folder regeneration:

### What Full Reset Does:
1. **Backs up custom configurations**: Preserves your [`Podfile`](scentsafe/ios/Podfile), [`Info.plist`](scentsafe/ios/Runner/Info.plist), and [`AppDelegate.swift`](scentsafe/ios/Runner/AppDelegate.swift)
2. **Removes entire iOS folder**: Completely deletes the `ios/` directory
3. **Regenerates iOS folder**: Uses `flutter create --platforms=ios .` to create a fresh iOS project structure
4. **Restores custom configurations**: Replaces default files with your backed-up custom configurations

### When to Use Full Reset:
- iOS folder is corrupted or has configuration errors that can't be fixed
- You want to start with a completely fresh iOS project structure
- After major Flutter version upgrades that require iOS project regeneration
- When Xcode project files are damaged or incompatible

### What Gets Preserved:
- Custom Podfile configurations (platform version, post_install hooks, etc.)
- Info.plist customizations (permissions, app settings, etc.)
- AppDelegate.swift custom code (plugin registration, native code, etc.)

### What Gets Regenerated:
- Xcode project files (`.xcodeproj`, `.xcworkspace`)
- Runner target configuration
- Build settings and schemes
- Default iOS project structure
- Generated Flutter iOS configuration files

## Prerequisites
- Xcode installed (version 15.0 or later recommended)
- Flutter SDK installed
- CocoaPods installed
- Active Apple Developer account (for device testing)

---

## Manual Reset Steps

### Step 1: Stop All Running Processes

Before starting, ensure no build processes or simulators are running:

```bash
# Stop any running Flutter processes
pkill -f flutter

# Stop any running Xcode processes
pkill -f Xcode

# Close any open simulators
xcrun simctl shutdown all
```

---

### Step 2: Full iOS Folder Regeneration (Optional)

If you want to completely scrap and regenerate the iOS folder, follow these steps:

```bash
# Backup important iOS configuration files
mkdir -p .ios_backup
cp ios/Podfile .ios_backup/Podfile.backup
cp ios/Runner/Info.plist .ios_backup/Info.plist.backup
cp ios/Runner/AppDelegate.swift .ios_backup/AppDelegate.swift.backup

# Remove entire iOS folder
rm -rf ios

# Regenerate iOS folder using Flutter
flutter create --platforms=ios .

# Restore custom configurations
cp .ios_backup/Podfile.backup ios/Podfile
cp .ios_backup/Info.plist.backup ios/Runner/Info.plist
cp .ios_backup/AppDelegate.swift.backup ios/Runner/AppDelegate.swift

# Clean up backup
rm -rf .ios_backup
```

**Note**: This step is optional. Skip it if you want to preserve your existing iOS folder structure.

---

### Step 3: Clean Flutter Build Artifacts

Navigate to the project root directory and clean all Flutter build artifacts:

```bash
# Clean Flutter build cache
flutter clean

# Remove Flutter-specific cache directories
rm -rf .dart_tool
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf build
```

---

### Step 4: Clear iOS Build Artifacts

Clean all iOS-specific build artifacts:

```bash
cd ios

# Clean Xcode build folder
rm -rf build/

# Remove Pods directory
rm -rf Pods/

# Remove Podfile.lock
rm -f Podfile.lock

# Remove workspace data
rm -rf Runner.xcworkspace/xcuserdata

# Remove project user data
rm -rf Runner.xcodeproj/xcuserdata

# Remove DerivedData for this project
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Remove build intermediates
rm -rf ~/Library/Developer/Xcode/Archives/Runner-*
```

---

### Step 5: Clear CocoaPods Cache

Clear the CocoaPods cache to ensure fresh dependency installation:

```bash
# Clear CocoaPods cache
pod cache clean --all

# Remove CocoaPods master spec repository
pod repo remove master

# Remove CocoaPods trunk cache
pod repo remove trunk
```

---

### Step 6: Update CocoaPods

Ensure you have the latest version of CocoaPods:

```bash
# Check current Ruby version
ruby -v

# Update CocoaPods gem
sudo gem install cocoapods

# Or if using Homebrew
brew upgrade cocoapods

# Verify installation
pod --version
```

**⚠️ Ruby Version Compatibility Issue:**

If you encounter an error like:
```
securerandom requires Ruby version >= 3.1.0. The current ruby version is 2.6.10.210.
```

This means your Ruby version is too old for the latest CocoaPods. You have two options:

**Option 1: Upgrade Ruby (Recommended)**

```bash
# Using Homebrew (recommended for macOS)
brew install ruby

# Using rbenv
brew install rbenv ruby-build
rbenv install 3.3.0
rbenv global 3.3.0

# Using rvm
\curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.3.0
rvm use 3.3.0 --default

# Verify new Ruby version
ruby -v
```

**Option 2: Install Compatible CocoaPods Version**

If you cannot upgrade Ruby, install a compatible CocoaPods version:

```bash
# Install CocoaPods 1.14.3 (compatible with Ruby 2.6+)
sudo gem install cocoapods -v 1.14.3

# Verify installation
pod --version
```

**⚠️ Gem Permission Error:**

If you encounter an error like:
```
Gem::FilePermissionError
You don't have write permissions for /Library/Ruby/Gems/2.6.0 directory.
```

This means you don't have permission to install gems to the system Ruby directory. You have several options:

**Solution 1: Install to User Directory (Recommended)**

```bash
# Install CocoaPods to user directory (no sudo needed)
gem install --user-install cocoapods -v 1.14.3

# Add gem bin directory to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"

# Verify installation
pod --version
```

**Solution 2: Use Homebrew (Recommended for macOS)**

```bash
# Install CocoaPods via Homebrew (no permission issues)
brew install cocoapods

# Verify installation
pod --version
```

**Solution 3: Fix System Ruby Permissions**

```bash
# Take ownership of Ruby gems directory
sudo chown -R $(whoami) /Library/Ruby/Gems/2.6.0

# Now install with sudo
sudo gem install cocoapods -v 1.14.3

# Verify installation
pod --version
```

**Solution 4: Use Bundler (Project-Specific)**

```bash
# Install Bundler
gem install --user-install bundler

# Create Gemfile in project root
cat > Gemfile << 'EOF'
source "https://rubygems.org"
gem "cocoapods", "~> 1.14.3"
EOF

# Install dependencies to project directory
bundle install --path vendor/bundle

# Use bundler for CocoaPods commands
bundle exec pod install
```

---

### Step 7: Reinstall CocoaPods Repository

Set up a fresh CocoaPods repository:

```bash
# Setup CocoaPods master repository
pod setup

# This may take several minutes
```

---

### Step 8: Update Flutter Dependencies

Navigate back to the project root and update Flutter dependencies:

```bash
cd ..

# Get Flutter dependencies
flutter pub get

# Upgrade Flutter dependencies (optional, for latest versions)
flutter pub upgrade

# Check for outdated dependencies
flutter pub outdated
```

---

### Step 9: Regenerate Flutter iOS Configuration

Regenerate Flutter's iOS-specific configuration files:

```bash
cd ios

# Remove Flutter-generated configuration files
rm -f Flutter/Generated.xcconfig
rm -f Flutter/Flutter.podspec
rm -f Flutter/ephemeral/Flutter-Generated.xcconfig

# Regenerate Flutter iOS configuration
cd ..
flutter precache --ios
flutter pub get
```

---

### Step 10: Install CocoaPods Dependencies

Install fresh iOS dependencies using CocoaPods:

```bash
cd ios

# Install pods with verbose output for troubleshooting
pod install --repo-update

# If pod install fails, try with clean install
pod deintegrate
pod install --repo-update
```

---

### Step 11: Verify Pod Installation

Verify that all pods were installed correctly:

```bash
# Check pod installation status
pod outdated

# List installed pods
pod list

# Verify workspace exists
ls -la Runner.xcworkspace
```

---

### Step 12: Clean Xcode Build Settings

Open Xcode and clean the project:

```bash
# Open Xcode workspace
open Runner.xcworkspace

# Or use command line:
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
```

**In Xcode:**
1. Select **Product** → **Clean Build Folder** (Shift+Cmd+K)
2. Select **Product** → **Clean** (Cmd+K)

---

### Step 13: Verify Xcode Configuration

Check and verify Xcode project settings:

**In Xcode:**
1. Open **Runner.xcworkspace**
2. Select the **Runner** project in the navigator
3. Select **Runner** target
4. Verify the following settings:

**General Tab:**
- Deployment Target: iOS 17.0
- Bundle Identifier: matches your team identifier
- Team: Select your development team
- Signing: Automatic or Manual with proper certificates

**Build Settings Tab:**
- Architectures: Standard (arm64)
- Base SDK: Latest iOS (iOS 17.0 or later)
- Valid Architectures: arm64

---

### Step 14: Update Podfile (if needed)

Review and update your Podfile to ensure compatibility:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '17.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Allow both arm64 and x86_64 for simulators
      config.build_settings['EXCLUDED_ARCHS'] = 'i386'
      config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
    end
  end
end

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end
```

---

### Step 15: Reinstall Pods (if Podfile was modified)

If you modified the Podfile, reinstall pods:

```bash
cd ios

# Remove existing pods
rm -rf Pods/
rm -f Podfile.lock

# Reinstall pods
pod install --repo-update
```

---

### Step 16: Verify Flutter iOS Configuration

Verify that Flutter iOS configuration is correct:

```bash
cd ..

# Check Flutter doctor
flutter doctor -v

# Verify iOS toolchain
flutter doctor --verbose | grep -A 20 "iOS"
```

Ensure all iOS-related checks pass:
- ✅ Xcode installed
- ✅ CocoaPods installed
- ✅ iOS development tools available
- ✅ Simulators available

---

### Step 17: Test Build on Simulator

Attempt to build and run on the iOS simulator:

```bash
# List available simulators
flutter devices

# Build for iOS simulator (debug)
flutter build ios --debug --simulator

# Or run directly on simulator
flutter run -d <simulator-id>
```

**Common simulator IDs:**
- iPhone 15 Pro: `com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro`
- iPhone 14 Pro: `com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro`

---

### Step 18: Troubleshooting Common Issues

### Issue 1: Pod Install Fails
```bash
# Clear CocoaPods cache and retry
pod cache clean --all
pod deintegrate
pod install --repo-update
```

### Issue 2: Architecture Mismatch
```bash
# Check current architecture
xcodebuild -showsdks

# Ensure arm64 is included in VALID_ARCHS
# Update Podfile post_install block if needed
```

### Issue 3: Signing Issues
```bash
# Open Xcode and configure signing
open ios/Runner.xcworkspace

# In Xcode: Runner target → Signing & Capabilities
# Select your team and let Xcode manage signing automatically
```

### Issue 4: Flutter iOS Toolchain Issues
```bash
# Reinstall Flutter iOS toolchain
flutter precache --ios
flutter doctor
```

### Issue 5: CocoaPods Repository Issues
```bash
# Remove and recreate CocoaPods repository
pod repo remove master
pod repo remove trunk
pod setup
```

### Issue 6: Ruby Version Compatibility (CocoaPods Installation Fails)

**Error Message:**
```
securerandom requires Ruby version >= 3.1.0. The current ruby version is 2.6.10.210.
```

**Solution 1: Upgrade Ruby (Recommended)**

```bash
# Check current Ruby version
ruby -v

# Using Homebrew (recommended for macOS)
brew install ruby

# Using rbenv
brew install rbenv ruby-build
rbenv install 3.3.0
rbenv global 3.3.0

# Using rvm
\curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.3.0
rvm use 3.3.0 --default

# Verify new Ruby version
ruby -v
```

**Solution 2: Install Compatible CocoaPods Version**

If you cannot upgrade Ruby, install CocoaPods 1.14.3 (compatible with Ruby 2.6+):

```bash
# Uninstall existing CocoaPods
sudo gem uninstall cocoapods

# Install compatible version
sudo gem install cocoapods -v 1.14.3

# Verify installation
pod --version
```

**Solution 3: Use Bundler (For Project-Specific Ruby Version)**

```bash
# Install Bundler
gem install bundler

# Create Gemfile in project root
cat > Gemfile << 'EOF'
source "https://rubygems.org"
gem "cocoapods", "~> 1.14.3"
EOF

# Install dependencies
bundle install

# Use bundler for CocoaPods commands
bundle exec pod install
```

---

### Step 19: Verify Successful Build

After completing all steps, verify a successful build:

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build for iOS simulator
flutter build ios --debug --simulator

# If successful, try running
flutter run -d <simulator-id>
```

---

### Step 20: Additional Cleanup (Optional)

For a more thorough cleanup, you can also:

```bash
# Clear all Xcode DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clear Xcode Archives
rm -rf ~/Library/Developer/Xcode/Archives/*

# Clear iOS Device Support
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*

# Clear CocoaPods cache completely
rm -rf ~/.cocoapods
```

---

### Step 21: Maintenance Commands

Keep your iOS build environment healthy with these maintenance commands:

```bash
# Weekly: Update Flutter
flutter upgrade

# Weekly: Update CocoaPods
pod repo update

# Monthly: Clean build artifacts
flutter clean
cd ios && pod deintegrate && pod install
```

---

## Verification Checklist

After completing the reset, verify:

- [ ] Flutter doctor shows no iOS-related errors
- [ ] CocoaPods installed successfully
- [ ] All pods installed without errors
- [ ] Xcode workspace opens correctly
- [ ] Signing configured in Xcode
- [ ] Build completes successfully for simulator
- [ ] App launches on simulator without crashes
- [ ] All Firebase and ML Kit plugins work correctly

---

## Additional Resources

- [Flutter iOS Build Troubleshooting](https://docs.flutter.dev/platform-integration/ios/building)
- [CocoaPods Documentation](https://guides.cocoapods.org/)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)

---

## Support

If you continue to experience issues after following this guide:

1. Run `flutter doctor -v` and check for errors
2. Check Xcode build logs for specific error messages
3. Review CocoaPods installation logs
4. Ensure all system requirements are met (Xcode version, iOS SDK, etc.)

---

**Last Updated:** 2026-01-09
**Project:** ScentSafe Flutter Application
**Target Platform:** iOS 17.0+

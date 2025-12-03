# Ruby Update Guide for macOS - Fix CocoaPods Compatibility

## Current Situation

❌ **Ruby Version**: 2.6.10 (system Ruby)  
✅ **Required Version**: 3.4.7+ (for latest CocoaPods)  
❌ **Problem**: macOS system Ruby is outdated and hard to update properly

## Solution Options

### Option 1: Use Homebrew Ruby (Recommended)

#### Step 1: Install Ruby via Homebrew
```bash
# Install latest Ruby
brew install ruby

# Add Homebrew Ruby to PATH (add to ~/.zshrc or ~/.bash_profile)
echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/usr/local/lib/ruby/gems/bin:$PATH"' >> ~/.zshrc

# Reload shell configuration
source ~/.zshrc
```

#### Step 2: Verify New Ruby Installation
```bash
# Check which Ruby is being used
which ruby
# Should show: /usr/local/opt/ruby/bin/ruby

# Check Ruby version
ruby -v
# Should show: 3.4.7 or newer
```

#### Step 3: Install CocoaPods with New Ruby
```bash
# Install CocoaPods with new Ruby
gem install cocoapods

# Verify CocoaPods version
pod --version
# Should show: 1.12.0 or newer
```

### Option 2: Use rbenv (Ruby Version Manager)

#### Step 1: Install rbenv
```bash
# Install rbenv
brew install rbenv

# Add rbenv to shell
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

#### Step 2: Install Ruby with rbenv
```bash
# Install latest Ruby
rbenv install 3.4.7

# Set global Ruby version
rbenv global 3.4.7

# Verify installation
ruby -v
# Should show: ruby 3.4.7
```

#### Step 3: Install CocoaPods
```bash
# Install CocoaPods
gem install cocoapods

# Reinstall gems for new Ruby
gem install --user-install bundler
```

### Option 3: Use RVM (Ruby Version Manager)

#### Step 1: Install RVM
```bash
# Install RVM
\curl -sSL https://get.rvm.io | bash -s stable

# Load RVM
source ~/.rvm/scripts/rvm
```

#### Step 2: Install Ruby with RVM
```bash
# Install latest Ruby
rvm install 3.4.7

# Use latest Ruby
rvm use 3.4.7 --default

# Verify installation
ruby -v
```

## Quick Fix Commands

### Try This First (Homebrew Method):
```bash
# 1. Install Ruby
brew install ruby

# 2. Update PATH (run this or add to ~/.zshrc)
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/bin:$PATH"

# 3. Verify
which ruby
ruby -v

# 4. Install CocoaPods
gem install cocoapods
pod --version
```

## Verification Steps

### After Update, Verify:
1. **Ruby Version**: `ruby -v` should show 3.4.7+
2. **Gem Path**: `gem environment` should show Homebrew paths
3. **CocoaPods**: `pod --version` should show 1.12.0+
4. **Flutter Doctor**: `flutter doctor` should show no iOS issues

### Expected Output:
```bash
$ ruby -v
ruby 3.4.7 (2024-04-23 revision 778a6b3d5b)

$ pod --version
1.12.0

$ flutter doctor
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS devices
[✓] CocoaPods - version 1.12.0 or newer
```

## Troubleshooting

### Issue: "command not found: ruby"
**Solution**: Make sure Homebrew Ruby is in PATH before system Ruby

### Issue: "gem install requires admin permissions"
**Solution**: Use `--user-install` flag or fix Homebrew permissions

### Issue: "CocoaPods still using old Ruby"
**Solution**: Restart terminal and verify `which ruby` shows correct path

## Alternative: Skip Ruby Update

If Ruby update is problematic, try this workaround:

### Use System Ruby with Older CocoaPods:
```bash
# Install compatible CocoaPods version
sudo gem install cocoapods -v 1.11.0

# Or use bundler with specific version
gem install bundler -v 2.2.0
```

### Test Flutter Build:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run -d "2030EB69-B170-43B5-B7A9-2A9C0990D880"
```

## Next Steps After Ruby Update

### 1. Clean iOS Project
```bash
cd ios
rm -rf Pods Podfile.lock
flutter clean
```

### 2. Reinstall Dependencies
```bash
cd ios
pod install
```

### 3. Test iOS Build
```bash
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
flutter run -d "2030EB69-B170-43B5-B7A9-2A9C0990D880"
```

## Expected Success

After Ruby update, you should see:
```
Launching lib/main.dart on iPhone 15 in debug mode...
Running pod install...                                             [SUCCESS]
Building iOS app...                                            [SUCCESS]
Installing and launching...                                        [SUCCESS]

=== FACE DETECTOR INITIALIZATION DEBUG ===
Platform: Native
Creating face detector with options: Instance of 'FaceDetectorOptions'
Native face detector created successfully

ML Kit Eye Classification - Left: 0.850, Right: 0.820
Hybrid detection working on iOS!
```

Choose the option that works best for your system. Homebrew Ruby (Option 1) is usually the most straightforward for macOS users.
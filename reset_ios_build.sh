#!/bin/bash

# iOS Build Environment Reset Script for ScentSafe Flutter Project
# This script performs a complete reset of the iOS build environment
#
# Usage:
#   ./reset_ios_build.sh              # Standard reset (preserves ios folder)
#   ./reset_ios_build.sh --full       # Full reset (scraps and regenerates ios folder)
#   ./reset_ios_build.sh -f           # Full reset (short form)

set -e  # Exit on error

# Parse command line arguments
FULL_RESET=false
if [ "$1" = "--full" ] || [ "$1" = "-f" ]; then
    FULL_RESET=true
fi

echo "🚀 Starting iOS Build Environment Reset for ScentSafe..."
if [ "$FULL_RESET" = true ]; then
    echo "⚠️  FULL RESET MODE: Will completely remove and regenerate iOS folder"
fi
echo ""

# Navigate to project root
cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)
echo "📂 Project root: $PROJECT_ROOT"
echo ""

# Step 1: Stop all running processes
echo "📛 Step 1: Stopping running processes..."
pkill -f flutter || true
pkill -f Xcode || true
xcrun simctl shutdown all || true
echo "✅ All processes stopped"
echo ""

# Step 2: Full iOS folder reset (if --full flag is provided)
if [ "$FULL_RESET" = true ]; then
    echo "🗑️  Step 2: Performing FULL RESET - Removing iOS folder..."
    
    # Backup important iOS configuration files (if they exist)
    if [ -d "ios" ]; then
        echo "📦 Backing up iOS configuration files..."
        mkdir -p .ios_backup
        
        # Backup Podfile if it has custom configurations
        if [ -f "ios/Podfile" ]; then
            cp ios/Podfile .ios_backup/Podfile.backup
            echo "✅ Backed up Podfile"
        fi
        
        # Backup Info.plist if it has custom configurations
        if [ -f "ios/Runner/Info.plist" ]; then
            cp ios/Runner/Info.plist .ios_backup/Info.plist.backup
            echo "✅ Backed up Info.plist"
        fi
        
        # Backup AppDelegate.swift if it has custom code
        if [ -f "ios/Runner/AppDelegate.swift" ]; then
            cp ios/Runner/AppDelegate.swift .ios_backup/AppDelegate.swift.backup
            echo "✅ Backed up AppDelegate.swift"
        fi
        
        echo "⚠️  Removing entire iOS folder..."
        rm -rf ios
        echo "✅ iOS folder removed"
    else
        echo "ℹ️  iOS folder does not exist, skipping removal"
    fi
    
    echo ""
    
    # Regenerate iOS folder using Flutter
    echo "🔄 Step 2b: Regenerating iOS folder..."
    flutter create --platforms=ios .
    echo "✅ iOS folder regenerated"
    echo ""
    
    # Restore custom configurations if backups exist
    if [ -f ".ios_backup/Podfile.backup" ]; then
        echo "📦 Restoring custom Podfile..."
        cp .ios_backup/Podfile.backup ios/Podfile
        echo "✅ Podfile restored"
    fi
    
    if [ -f ".ios_backup/Info.plist.backup" ]; then
        echo "📦 Restoring custom Info.plist..."
        cp .ios_backup/Info.plist.backup ios/Runner/Info.plist
        echo "✅ Info.plist restored"
    fi
    
    if [ -f ".ios_backup/AppDelegate.swift.backup" ]; then
        echo "📦 Restoring custom AppDelegate.swift..."
        cp .ios_backup/AppDelegate.swift.backup ios/Runner/AppDelegate.swift
        echo "✅ AppDelegate.swift restored"
    fi
    
    # Clean up backup
    rm -rf .ios_backup
    echo ""
fi

# Step 3: Clean Flutter build artifacts
echo "🧹 Step 3: Cleaning Flutter build artifacts..."
flutter clean
rm -rf .dart_tool
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf build
echo "✅ Flutter build artifacts cleaned"
echo ""

# Step 4: Clean iOS build artifacts
echo "🧹 Step 4: Cleaning iOS build artifacts..."
cd ios
rm -rf build/
rm -rf Pods/
rm -f Podfile.lock
rm -rf Runner.xcworkspace/xcuserdata
rm -rf Runner.xcodeproj/xcuserdata
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* || true
echo "✅ iOS build artifacts cleaned"
echo ""

# Step 5: Clear CocoaPods cache
echo "🧹 Step 5: Clearing CocoaPods cache..."
pod cache clean --all || true
pod repo remove master || true
pod repo remove trunk || true
echo "✅ CocoaPods cache cleared"
echo ""

# Step 6: Update CocoaPods
echo "📦 Step 6: Updating CocoaPods..."

# Check Ruby version
RUBY_VERSION=$(ruby -v | awk '{print $2}')
echo "ℹ️  Current Ruby version: $RUBY_VERSION"

# Check if Ruby version is compatible with latest CocoaPods
if [ "$(echo "$RUBY_VERSION" | cut -d. -f1)" -lt 3 ]; then
    echo "⚠️  WARNING: Ruby version $RUBY_VERSION is outdated"
    echo "   Latest CocoaPods requires Ruby >= 3.1.0"
    echo ""
    echo "🔧 Ruby Upgrade Options:"
    echo ""
    echo "   Option 1: Using Homebrew (recommended for macOS)"
    echo "     brew install ruby"
    echo ""
    echo "   Option 2: Using rbenv"
    echo "     brew install rbenv ruby-build"
    echo "     rbenv install 3.3.0"
    echo "     rbenv global 3.3.0"
    echo ""
    echo "   Option 3: Using rvm"
    echo "     \\curl -sSL https://get.rvm.io | bash -s stable"
    echo "     rvm install 3.3.0"
    echo "     rvm use 3.3.0 --default"
    echo ""
    echo "   Option 4: Install compatible CocoaPods version for current Ruby"
    echo "     sudo gem install cocoapods -v 1.14.3"
    echo ""
    
    read -p "Do you want to continue with compatible CocoaPods version? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Please upgrade Ruby first and run the script again."
        exit 1
    fi
    
    echo "📦 Installing compatible CocoaPods version for Ruby $RUBY_VERSION..."
    
    # Try with sudo first
    if sudo gem install cocoapods -v 1.14.3 2>&1; then
        echo "✅ CocoaPods installed with sudo"
    else
        echo "⚠️  Sudo installation failed. Trying alternative methods..."
        
        # Try installing to user directory
        echo "📦 Installing to user directory..."
        if gem install --user-install cocoapods -v 1.14.3 2>&1; then
            echo "✅ CocoaPods installed to user directory"
            echo "ℹ️  Note: You may need to add ~/.gem/ruby/*/bin to your PATH"
        else
            echo "❌ Failed to install CocoaPods"
            echo ""
            echo "🔧 Manual Installation Required:"
            echo ""
            echo "Please run one of these commands manually:"
            echo ""
            echo "  Option 1: With sudo"
            echo "    sudo gem install cocoapods -v 1.14.3"
            echo ""
            echo "  Option 2: To user directory"
            echo "    gem install --user-install cocoapods -v 1.14.3"
            echo ""
            echo "  Option 3: Use Homebrew"
            echo "    brew install cocoapods"
            echo ""
            echo "After installation, run the script again."
            exit 1
        fi
    fi
else
    echo "✅ Ruby version is compatible"
    
    # Try with sudo first
    if sudo gem install cocoapods 2>&1; then
        echo "✅ CocoaPods installed with sudo"
    else
        echo "⚠️  Sudo installation failed. Trying alternative methods..."
        
        # Try installing to user directory
        echo "📦 Installing to user directory..."
        if gem install --user-install cocoapods 2>&1; then
            echo "✅ CocoaPods installed to user directory"
            echo "ℹ️  Note: You may need to add ~/.gem/ruby/*/bin to your PATH"
        else
            echo "❌ Failed to install CocoaPods"
            echo ""
            echo "🔧 Manual Installation Required:"
            echo ""
            echo "Please run one of these commands manually:"
            echo ""
            echo "  Option 1: With sudo"
            echo "    sudo gem install cocoapods"
            echo ""
            echo "  Option 2: To user directory"
            echo "    gem install --user-install cocoapods"
            echo ""
            echo "  Option 3: Use Homebrew"
            echo "    brew install cocoapods"
            echo ""
            echo "After installation, run the script again."
            exit 1
        fi
    fi
fi

echo "✅ CocoaPods updated"
echo ""

# Step 7: Reinstall CocoaPods repository
echo "📦 Step 7: Reinstalling CocoaPods repository..."
pod setup
echo "✅ CocoaPods repository reinstalled"
echo ""

# Step 8: Update Flutter dependencies
echo "📦 Step 8: Updating Flutter dependencies..."
cd ..
flutter pub get
echo "✅ Flutter dependencies updated"
echo ""

# Step 9: Regenerate Flutter iOS configuration
echo "🔄 Step 9: Regenerating Flutter iOS configuration..."
flutter precache --ios
echo "✅ Flutter iOS configuration regenerated"
echo ""

# Step 10: Install CocoaPods dependencies
echo "📦 Step 10: Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
echo "✅ CocoaPods dependencies installed"
echo ""

# Step 11: Clean Xcode build
echo "🧹 Step 11: Cleaning Xcode build..."
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner || true
echo "✅ Xcode build cleaned"
echo ""

# Step 12: Verify installation
echo "🔍 Step 12: Verifying installation..."
cd ..

echo ""
echo "📊 Flutter Version:"
flutter --version

echo ""
echo "📊 CocoaPods Version:"
pod --version

echo ""
echo "📊 Flutter Doctor (iOS):"
flutter doctor -v | grep -A 20 "iOS" || true

echo ""
echo "✅ iOS Build Environment Reset Complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Configure signing in Xcode:"
echo "   - Select Runner target"
echo "   - Go to Signing & Capabilities"
echo "   - Select your development team"
echo "   - Let Xcode manage signing automatically"
echo ""
echo "3. Build for iOS simulator:"
echo "   flutter build ios --debug --simulator"
echo ""
echo "4. List available simulators:"
echo "   flutter devices"
echo ""
echo "5. Run on simulator:"
echo "   flutter run -d <simulator-id>"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 For detailed troubleshooting, see IOS_BUILD_RESET_GUIDE.md"
echo ""

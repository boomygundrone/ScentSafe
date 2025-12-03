#!/bin/bash

# ============================================
# Flutter Android Emulator Runner
# Fixes JAVA_HOME and runs app on Android emulator
# ============================================

echo "🔧 Setting up Android development environment..."

# Fix JAVA_HOME for macOS
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"
echo "✅ JAVA_HOME set to: $JAVA_HOME"

# Set Flutter path
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"
echo "✅ Flutter path configured"

# Check if emulator is running
echo ""
echo "📱 Checking Android devices..."
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter devices

# Clean and run
echo ""
echo "🧹 Cleaning Flutter project..."
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter clean

echo ""
echo "📦 Getting dependencies..."
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter pub get

echo ""
echo "🚀 Running app on Android emulator..."
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d emulator-5554

echo ""
echo "✅ App deployment complete!"
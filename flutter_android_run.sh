#!/bin/bash

# ============================================
# Flutter Android Emulator Runner
# Runs app on Android emulator using system Flutter
# ============================================

echo "🔧 Setting up Android development environment..."

# Fix JAVA_HOME for macOS
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"
echo "✅ JAVA_HOME set to: $JAVA_HOME"

# Check if emulator is running
echo ""
echo "📱 Checking Android devices..."
flutter devices

# Clean and run
echo ""
echo "🧹 Cleaning Flutter project..."
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🚀 Running app on Android emulator..."
flutter run -d emulator-5554

echo ""
echo "✅ App deployment complete!"

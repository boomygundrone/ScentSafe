#!/bin/bash

# Fix JAVA_HOME for macOS
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home"

# Set the correct Flutter path
export PATH="/Users/kimberlychan/Development/scentsafe-app/flutter/bin:$PATH"

echo "Running Flutter app on Android emulator..."
echo "JAVA_HOME set to: $JAVA_HOME"
echo "Flutter path: $PATH"

# Run Flutter
cd /Users/kimberlychan/Development/scentsafe-app/scentsafe
flutter run -d emulator-5554 --debug
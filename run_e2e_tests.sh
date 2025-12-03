#!/bin/bash

# Script to run Playwright E2E tests for ScentSafe Flutter app

set -e

echo "🎭 Setting up Playwright E2E tests for ScentSafe..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Node.js and npm are installed
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "❌ Node.js and npm are required but not installed"
    exit 1
fi

# Install npm dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
fi

# Install Playwright browsers if not already installed
if [ ! -d "$HOME/.cache/ms-playwright" ]; then
    echo "🌐 Installing Playwright browsers..."
    npx playwright install
fi

# Parse command line arguments
HEADED=false
DEBUG=false
CODEGEN=false
BROWSER="chromium"

while [[ $# -gt 0 ]]; do
  case $1 in
    --headed)
      HEADED=true
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    --codegen)
      CODEGEN=true
      shift
      ;;
    --browser)
      BROWSER="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --headed     Run tests in headed mode (show browser)"
      echo "  --debug      Run tests in debug mode"
      echo "  --codegen    Start Playwright codegen for test creation"
      echo "  --browser    Specify browser (chromium, firefox, webkit)"
      echo "  -h, --help   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Build Flutter web app in release mode for testing
echo "🔨 Building Flutter web app..."
flutter build web --release

# Start the local server in the background
echo "🚀 Starting local server..."
python3 -m http.server 8080 --directory build/web &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Function to cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

if [ "$CODEGEN" = true ]; then
    echo "🎬 Starting Playwright codegen..."
    npx playwright codegen http://localhost:8080 --browser=$BROWSER
else
    # Prepare test command
    TEST_CMD="npx playwright test"
    
    if [ "$HEADED" = true ]; then
        TEST_CMD="$TEST_CMD --headed"
    fi
    
    if [ "$DEBUG" = true ]; then
        TEST_CMD="$TEST_CMD --debug"
    fi
    
    if [ "$BROWSER" != "chromium" ]; then
        TEST_CMD="$TEST_CMD --project=$BROWSER"
    fi
    
    echo "🧪 Running E2E tests with command: $TEST_CMD"
    $TEST_CMD
    
    echo "📊 Generating test report..."
    npx playwright show-report
fi

echo "✅ E2E tests completed!"
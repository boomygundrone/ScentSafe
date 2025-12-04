# ScentSafe: AI-Powered Drowsiness Detection

ScentSafe is an innovative Flutter application that uses AI-powered drowsiness detection combined with aroma therapy to help keep drivers safe on the road. The app monitors driver fatigue levels and automatically triggers aroma diffusers when drowsiness is detected.

## Features

- **Real-time Drowsiness Detection**: Uses advanced AI algorithms to detect signs of driver fatigue
- **Aroma Therapy Integration**: Connects to Bluetooth aroma diffusers to release alertness-enhancing scents
- **Camera-based Monitoring**: Utilizes device camera to monitor driver facial expressions and eye movements
- **Multi-level Alert System**: Provides graduated alerts based on fatigue severity
- **Cross-platform Support**: Works on web, iOS, and Android devices

## Getting Started

### Prerequisites

- Flutter SDK (>=3.5.3)
- Dart SDK
- Node.js and npm (for E2E testing)
- A Bluetooth-enabled aroma diffuser (optional)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/boomygundrone/ScentSafe.git
cd scentsafe
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Install Node.js dependencies for E2E testing:
```bash
npm install
```

4. Install Playwright browsers:
```bash
npx playwright install
```

### Running the App

#### Development Mode

```bash
# Run on web
flutter run -d web-server

# Run on mobile device
flutter run
```

#### Production Build

```bash
# Build for web
flutter build web

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## Testing

### Unit and Widget Tests

Run the built-in Flutter tests:

```bash
flutter test
```

### End-to-End (E2E) Tests

The project includes Playwright E2E tests to verify the application works correctly across different browsers and devices.

#### Quick Start

Use the convenience script to run E2E tests:

```bash
# Run all tests
./run_e2e_tests.sh

# Run with a visible browser
./run_e2e_tests.sh --headed

# Run in debug mode
./run_e2e_tests.sh --debug
```

#### Manual Setup

1. Build the web application:
```bash
flutter build web --release
```

2. Run the E2E tests:
```bash
npm run test:e2e
```

For detailed E2E testing instructions, see [E2E_TESTING.md](E2E_TESTING.md).

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── dashboard_screen.dart
│   ├── test_screen.dart
│   ├── video_screen.dart
│   └── ...
├── services/                 # Business logic
│   ├── detection_service.dart
│   ├── bluetooth_service.dart
│   ├── camera_service.dart
│   └── ...
├── models/                   # Data models
├── blocs/                    # State management
└── config/                   # Configuration

e2e/                          # E2E tests
├── app.spec.ts
├── detection.spec.ts
└── ...

test/                         # Unit and widget tests
```

## Architecture

The app follows a clean architecture pattern with:

- **BLoC Pattern**: For state management using flutter_bloc
- **Service Layer**: Separates business logic from the UI
- **Repository Pattern**: For data access abstraction
- **Dependency Injection**: For better testability

## Firebase Integration

The app integrates with Firebase for:

- User authentication
- Data storage and synchronization
- Analytics

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for setup instructions.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run all tests:
   ```bash
   flutter test
   ./run_e2e_tests.sh
   ```
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Create an issue in the GitHub repository
- Check the [documentation](E2E_TESTING.md)
- Review the Flutter documentation at https://flutter.dev/docs

## Acknowledgments

- Flutter team for the amazing framework
- Playwright team for excellent E2E testing tools
- Firebase for backend services

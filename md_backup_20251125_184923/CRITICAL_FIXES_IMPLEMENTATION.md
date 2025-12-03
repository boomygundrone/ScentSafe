# Critical Fixes Implementation Guide

This guide provides specific code implementations for the most critical issues identified in the deployment readiness assessment.

---

## 1. Fix Missing Dependencies

### Update pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies...
  cupertino_icons: ^1.0.8
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  camera: ^0.11.0+2
  flutter_blue_plus: ^1.32.8
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.2
  cloud_firestore: ^5.6.12
  shared_preferences: ^2.3.2
  sqflite: ^2.3.3+1
  provider: ^6.1.2
  intl: ^0.19.0
  google_ml_kit: ^0.18.0
  
  # CRITICAL: Add missing audio dependency
  audioplayers: ^6.1.0
  
  # Add permission handling
  permission_handler: ^11.3.1
  
  # Add device info for platform-specific optimizations
  device_info_plus: ^10.1.2
  
  # Add battery optimization
  battery_plus: ^6.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  
  # Add integration testing
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/models/
    - assets/images/
    - assets/audio/  # Add audio assets
```

---

## 2. Add Missing Permissions

### Android Permissions (android/app/src/main/AndroidManifest.xml)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- CRITICAL: Add these permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <!-- For Android 12+ -->
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
        android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    
    <!-- Camera features -->
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.front" android:required="true" />
    
    <application
        android:label="scentsafe"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Existing application content -->
    </application>
</manifest>
```

### iOS Permissions (ios/Runner/Info.plist)

```xml
<dict>
    <!-- Existing keys -->
    
    <!-- CRITICAL: Add these permissions -->
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for audio alerts and voice commands.</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access for Bluetooth device discovery.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs location access for Bluetooth device discovery.</string>
    
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>bluetooth-central</string>
        <string>location</string>
    </array>
    
    <!-- Existing keys continue -->
</dict>
```

---

## 3. Implement Runtime Permission Handling

### Create Permission Service (lib/services/permission_service.dart)

```dart
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }
  
  PermissionService._();

  /// Request all required permissions
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      if (!kIsWeb) Permission.locationAlways,
    ];

    final statuses = await permissions.request();
    debugPrint('Permission statuses: $statuses');
    return statuses;
  }

  /// Check if all permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        debugPrint('Permission not granted: $permission');
        return false;
      }
    }
    return true;
  }

  /// Check specific permission
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Get Android SDK version for conditional permissions
  Future<int> getAndroidSdkVersion() async {
    if (!kIsWeb) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  /// Request permissions with explanation
  Future<bool> requestPermissionsWithExplanation() async {
    // Check if permissions are already granted
    if (await areAllPermissionsGranted()) {
      return true;
    }

    // For Android 12+, need to handle Bluetooth permissions differently
    final sdkVersion = await getAndroidSdkVersion();
    if (sdkVersion >= 31) {
      // Android 12+ specific handling
      return await _requestAndroid12PlusPermissions();
    }

    // Standard permission request
    final statuses = await requestAllPermissions();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> _requestAndroid12PlusPermissions() async {
    // Handle Android 12+ Bluetooth permissions
    final bluetoothStatuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final otherStatuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
    ].request();

    return [...bluetoothStatuses.values, ...otherStatuses.values]
        .every((status) => status.isGranted);
  }
}
```

---

## 4. Update Audio Alert Service

### Fix Audio Alert Service (lib/services/audio_alert_service.dart)

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enhanced audio alert service with proper error handling
class AudioAlertService {
  static AudioAlertService? _instance;
  static AudioAlertService get instance {
    _instance ??= AudioAlertService._();
    return _instance!;
  }
  
  AudioAlertService._() {
    // Private constructor for singleton pattern
  }
  
  AudioPlayer? _alertPlayer;
  bool _isPlaying = false;
  bool _isInitialized = false;
  
  /// Initialize audio service with permission check
  Future<void> initialize() async {
    try {
      // Check microphone permission first
      final hasPermission = await PermissionService.instance.isPermissionGranted(Permission.microphone);
      if (!hasPermission) {
        debugPrint('AudioAlertService: Microphone permission not granted');
        return;
      }

      debugPrint('AudioAlertService: Initializing audio player');
      _alertPlayer = AudioPlayer();
      
      // Set up audio session for iOS
      await _alertPlayer!.setPlayerMode(PlayerMode.lowLatency);
      
      // Preload the audio file
      await _alertPlayer!.setAsset('assets/audio/wakeup.mp3');
      
      // Set up completion listener
      _alertPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          debugPrint('AudioAlertService: Alert sound finished playing');
        }
      });
      
      _isInitialized = true;
      debugPrint('AudioAlertService: Audio player initialized successfully');
    } catch (e) {
      debugPrint('AudioAlertService: Failed to initialize audio player: $e');
      _isInitialized = false;
    }
  }
  
  /// Play alert sound once
  Future<void> playAlert() async {
    if (!_isInitialized || _alertPlayer == null || _isPlaying) {
      debugPrint('AudioAlertService: Audio player not ready or already playing');
      return;
    }
    
    try {
      _isPlaying = true;
      await _alertPlayer!.resume();
      debugPrint('AudioAlertService: Alert sound playing');
    } catch (e) {
      debugPrint('AudioAlertService: Error playing alert: $e');
      _isPlaying = false;
    }
  }
  
  /// Play alert sound continuously (loop)
  Future<void> playAlertLoop() async {
    if (!_isInitialized || _alertPlayer == null) {
      debugPrint('AudioAlertService: Audio player not ready');
      return;
    }
    
    try {
      _isPlaying = true;
      await _alertPlayer!.setReleaseMode(ReleaseMode.loop);
      await _alertPlayer!.resume();
      debugPrint('AudioAlertService: Alert sound playing in loop');
    } catch (e) {
      debugPrint('AudioAlertService: Error playing alert loop: $e');
      _isPlaying = false;
    }
  }
  
  /// Stop alert sound
  Future<void> stopAlert() async {
    if (!_isInitialized || _alertPlayer == null) {
      debugPrint('AudioAlertService: Audio player not ready');
      return;
    }
    
    try {
      _isPlaying = false;
      await _alertPlayer!.pause();
      debugPrint('AudioAlertService: Alert sound stopped');
    } catch (e) {
      debugPrint('AudioAlertService: Error stopping alert: $e');
    }
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized || _alertPlayer == null) {
      debugPrint('AudioAlertService: Audio player not ready');
      return;
    }
    
    try {
      await _alertPlayer!.setVolume(volume);
      debugPrint('AudioAlertService: Volume set to $volume');
    } catch (e) {
      debugPrint('AudioAlertService: Error setting volume: $e');
    }
  }
  
  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Dispose audio service
  Future<void> dispose() async {
    try {
      _isPlaying = false;
      _isInitialized = false;
      await _alertPlayer?.dispose();
      _alertPlayer = null;
      debugPrint('AudioAlertService: Audio service disposed');
    } catch (e) {
      debugPrint('AudioAlertService: Error disposing audio service: $e');
    }
  }
}
```

---

## 5. Update Main App with Permission Handling

### Update main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config/firebase_config.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/detection_cubit.dart';
import 'blocs/bluetooth_cubit.dart';
import 'blocs/firebase_cubit.dart';
import 'services/auth_service.dart';
import 'services/detection_service.dart';
import 'services/bluetooth_service.dart';
import 'services/firebase_service.dart';
import 'services/permission_service.dart';
import 'services/audio_alert_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bluetooth_setup_screen.dart';
import 'screens/help_screen.dart';
import 'screens/video_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(options: FirebaseConfig.current);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize services
  final authService = AuthService();
  final detectionService = DetectionService.instance;
  final bluetoothService = BluetoothService();
  final firebaseService = FirebaseService.instance;
  final permissionService = PermissionService.instance;
  final audioService = AudioAlertService.instance;

  // Initialize audio service
  await audioService.initialize();

  runApp(MyApp(
    authService: authService,
    detectionService: detectionService,
    bluetoothService: bluetoothService,
    firebaseService: firebaseService,
    permissionService: permissionService,
    audioService: audioService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final DetectionService detectionService;
  final BluetoothService bluetoothService;
  final FirebaseService firebaseService;
  final PermissionService permissionService;
  final AudioAlertService audioService;

  const MyApp({
    super.key,
    required this.authService,
    required this.detectionService,
    required this.bluetoothService,
    required this.firebaseService,
    required this.permissionService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authService),
        ),
        BlocProvider(
          create: (context) => DetectionCubit(detectionService),
        ),
        BlocProvider(
          create: (context) => BluetoothCubit(bluetoothService),
        ),
        BlocProvider(
          create: (context) => FirebaseCubit(firebaseService),
        ),
      ],
      child: MaterialApp(
        title: 'ScentSafe',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
          useMaterial3: true,
        ),
        home: const PermissionWrapper(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/login': (context) => const LoginScreen(),
          '/bluetooth': (context) => const BluetoothSetupScreen(),
          '/help': (context) => const HelpScreen(),
          '/video': (context) => const VideoScreen(),
        },
      ),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _isCheckingPermissions = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final permissionService = PermissionService.instance;
    
    // Check if permissions are already granted
    if (await permissionService.areAllPermissionsGranted()) {
      setState(() {
        _isCheckingPermissions = false;
        _permissionsGranted = true;
      });
      return;
    }

    // Request permissions
    final granted = await permissionService.requestPermissionsWithExplanation();
    
    setState(() {
      _isCheckingPermissions = false;
      _permissionsGranted = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1B2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
              SizedBox(height: 20),
              Text(
                'Checking permissions...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      return const PermissionDeniedScreen();
    }

    return const DashboardScreen();
  }
}

class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(height: 20),
              const Text(
                'Permissions Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ScentSafe requires camera, microphone, Bluetooth, and location permissions to function properly. Please grant all permissions to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await PermissionService.instance.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text(
                  'Continue Anyway',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Add Performance Optimization

### Create Performance Service (lib/services/performance_service.dart)

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance {
    _instance ??= PerformanceService._();
    return _instance!;
  }
  
  PerformanceService._();

  final Battery _battery = Battery();
  Timer? _performanceMonitorTimer;
  bool _isLowPowerMode = false;
  int _currentBatteryLevel = 100;
  
  /// Initialize performance monitoring
  Future<void> initialize() async {
    // Get initial battery level
    _currentBatteryLevel = await _battery.batteryLevel;
    
    // Listen to battery changes
    _battery.onBatteryStateChanged.listen((state) {
      _handleBatteryStateChange(state);
    });
    
    // Start performance monitoring
    _startPerformanceMonitoring();
  }
  
  /// Handle battery state changes
  void _handleBatteryStateChange(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        _isLowPowerMode = false;
        break;
      case BatteryState.discharging:
        _currentBatteryLevel = _battery.batteryLevel as int;
        _isLowPowerMode = _currentBatteryLevel < 20;
        break;
      case BatteryState.unknown:
        break;
    }
    
    debugPrint('Battery state changed: $state, Level: $_currentBatteryLevel%');
  }
  
  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPerformanceMetrics();
    });
  }
  
  /// Check performance metrics and adjust accordingly
  void _checkPerformanceMetrics() async {
    if (_isLowPowerMode) {
      debugPrint('Low power mode detected, optimizing performance');
      // Reduce processing frequency
      // Lower camera resolution
      // Reduce ML processing frequency
    }
  }
  
  /// Get optimal camera resolution based on device performance
  String getOptimalCameraResolution() {
    if (_isLowPowerMode) {
      return 'low';
    } else if (_currentBatteryLevel < 50) {
      return 'medium';
    } else {
      return 'high';
    }
  }
  
  /// Get optimal detection frequency based on device performance
  int getOptimalDetectionFrequency() {
    if (_isLowPowerMode) {
      return 1000; // 1 second
    } else if (_currentBatteryLevel < 50) {
      return 500; // 500ms
    } else {
      return 100; // 100ms
    }
  }
  
  /// Check if device is low-end
  Future<bool> isLowEndDevice() async {
    if (kIsWeb) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final totalMemory = androidInfo.totalMemory;
        // Consider devices with less than 4GB RAM as low-end
        return totalMemory < 4 * 1024 * 1024 * 1024;
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        final model = iosInfo.model;
        // Consider older iPhone models as low-end
        return model.contains('iPhone 6') || 
               model.contains('iPhone 7') || 
               model.contains('iPhone 8');
      }
    } catch (e) {
      debugPrint('Error checking device performance: $e');
    }
    
    return false;
  }
  
  /// Dispose performance service
  void dispose() {
    _performanceMonitorTimer?.cancel();
    _performanceMonitorTimer = null;
  }
}
```

---

## 7. Update Detection Service with Performance Optimization

### Update Detection Service (lib/services/detection_service.dart)

```dart
// Add these imports at the top
import 'performance_service.dart';

// Update the _startUnifiedDetectionTimer method
void _startUnifiedDetectionTimer() {
  // Cancel existing timer first
  if (_detectionTimer != null) {
    _detectionTimer!.cancel();
    _detectionTimer = null;
  }
  
  // Get optimal detection frequency
  final performanceService = PerformanceService.instance;
  final detectionFrequency = performanceService.getOptimalDetectionFrequency();
  
  debugPrint('Starting unified detection timer with frequency: ${detectionFrequency}ms');
  
  _detectionTimer = Timer.periodic(Duration(milliseconds: detectionFrequency), (timer) async {
    // Existing timer logic...
  });
}
```

---

## 8. Add Security Implementation

### Create Security Service (lib/services/security_service.dart)

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance {
    _instance ??= SecurityService._();
    return _instance!;
  }
  
  SecurityService._();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  /// Encrypt sensitive data
  String encryptData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error storing secure data: $e');
    }
  }
  
  /// Retrieve sensitive data securely
  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Error retrieving secure data: $e');
      return null;
    }
  }
  
  /// Delete sensitive data
  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('Error deleting secure data: $e');
    }
  }
  
  /// Clear all secure data
  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing secure data: $e');
    }
  }
}
```

---

## 9. Testing Implementation

### Add Comprehensive Tests (test/comprehensive_test.dart)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:scentsafe/services/permission_service.dart';
import 'package:scentsafe/services/audio_alert_service.dart';
import 'package:scentsafe/services/performance_service.dart';
import 'package:scentsafe/services/security_service.dart';

void main() {
  group('PermissionService Tests', () {
    test('service initializes correctly', () {
      final service = PermissionService.instance;
      expect(service, isNotNull);
    });
  });

  group('AudioAlertService Tests', () {
    test('service initializes correctly', () {
      final service = AudioAlertService.instance;
      expect(service, isNotNull);
      expect(service.isInitialized, false);
    });
  });

  group('PerformanceService Tests', () {
    test('service initializes correctly', () {
      final service = PerformanceService.instance;
      expect(service, isNotNull);
    });
  });

  group('SecurityService Tests', () {
    test('service initializes correctly', () {
      final service = SecurityService.instance;
      expect(service, isNotNull);
    });

    test('encrypts data correctly', () {
      final service = SecurityService.instance;
      final data = 'test data';
      final encrypted = service.encryptData(data);
      
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(equals(data)));
    });
  });
}
```

---

## 10. Build Configuration Updates

### Android Build Configuration (android/app/build.gradle)

```gradle
android {
    // Existing configuration...
    
    buildTypes {
        release {
            // Enable code shrinking and obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Add your own signing config for the release build
            // signingConfig signingConfigs.release
        }
        debug {
            // Debug configuration
            minifyEnabled false
        }
    }
    
    // Add ProGuard rules
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

### ProGuard Rules (android/app/proguard-rules.pro)

```proguard
# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }

# Camera
-keep class androidx.camera.** { *; }

# Audio
-keep class androidx.media.** { *; }
```

---

## Implementation Priority

### Phase 1 (Critical - Week 1)
1. Add missing dependencies to pubspec.yaml
2. Add all required permissions
3. Implement permission service
4. Fix audio alert service
5. Update main.dart with permission handling

### Phase 2 (Important - Week 2)
1. Implement performance service
2. Add security service
3. Update detection service with optimizations
4. Add comprehensive tests
5. Update build configurations

### Phase 3 (Enhancement - Week 3)
1. Add error handling improvements
2. Implement offline support
3. Add user preferences
4. Optimize UI/UX
5. Add analytics and crash reporting

---

## Testing Checklist

After implementing these fixes:

- [ ] Run `flutter pub get` and verify no dependency conflicts
- [ ] Test permission requests on both Android and iOS
- [ ] Test audio alerts on actual devices
- [ ] Verify camera functionality with new permissions
- [ ] Test Bluetooth connectivity
- [ ] Run comprehensive test suite
- [ ] Test app on various device configurations
- [ ] Verify performance optimizations
- [ ] Test security implementations
- [ ] Build release versions for both platforms

This implementation guide addresses the most critical issues identified in the deployment readiness assessment. Following these steps will significantly improve the app's readiness for production deployment.
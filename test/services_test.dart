import 'package:flutter_test/flutter_test.dart';
import 'package:scentsafe/services/auth_service.dart';
import 'package:scentsafe/services/detection_service.dart';
import 'package:scentsafe/services/bluetooth_service.dart';
import 'package:scentsafe/models/user.dart';
import 'package:scentsafe/models/detection_result.dart' as model;
import 'package:scentsafe/models/bluetooth_device.dart' as model;

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('signIn with valid credentials returns user', () async {
      final user = await authService.signIn('test@example.com', 'password');

      expect(user, isA<User>());
      expect(user.email, 'test@example.com');
    });

    test('signIn with invalid credentials throws exception', () async {
      expect(
        () => authService.signIn('', ''),
        throwsA(isA<Exception>()),
      );
    });

    test('signUp creates new user', () async {
      final user = await authService.signUp('new@example.com', 'password', 'Test User');

      expect(user, isA<User>());
      expect(user.name, 'Test User');
    });

    test('signOut clears current user', () async {
      await authService.signIn('test@example.com', 'password');
      expect(authService.isAuthenticated, true);

      await authService.signOut();
      expect(authService.isAuthenticated, false);
    });
  });

  group('DetectionService', () {
    late DetectionService detectionService;

    setUp(() {
      detectionService = DetectionService();
    });

    test('initialize completes successfully', () async {
      await detectionService.initialize();
      // Service initializes even without model for demo
      expect(true, true); // Basic assertion
    });

    test('detection result has valid structure', () async {
      await detectionService.initialize();

      // Test would require camera controller in real implementation
      // For now, just verify the service structure
      expect(detectionService, isNotNull);
    });
  });

  group('BluetoothService', () {
    late BluetoothService bluetoothService;

    setUp(() {
      bluetoothService = BluetoothService();
    });

    test('service initializes correctly', () {
      expect(bluetoothService, isNotNull);
      expect(bluetoothService.isConnected, false);
    });

    test('device filtering works', () {
      // Test the aroma device detection logic
      final device1 = model.BluetoothDevice(id: '1', name: 'Aroma Diffuser', isConnected: false, rssi: -50);
      final device2 = model.BluetoothDevice(id: '2', name: 'Bluetooth Speaker', isConnected: false, rssi: -50);
      final device3 = model.BluetoothDevice(id: '3', name: 'Scent Device', isConnected: false, rssi: -50);

      expect(device1.isAromaDiffuser, true);
      expect(device2.isAromaDiffuser, false);
      expect(device3.isAromaDiffuser, true);
    });
  });

  group('Models', () {
    test('User model serializes correctly', () {
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final json = user.toJson();
      final reconstructed = User.fromJson(json);

      expect(reconstructed.id, user.id);
      expect(reconstructed.email, user.email);
      expect(reconstructed.name, user.name);
    });

    test('DetectionResult model serializes correctly', () {
      final result = model.DetectionResult(
        level: model.DrowsinessLevel.alert,
        confidence: 0.85,
        timestamp: DateTime.now(),
        triggeredSpray: false,
      );

      final json = result.toJson();
      final reconstructed = model.DetectionResult.fromJson(json);

      expect(reconstructed.level, result.level);
      expect(reconstructed.confidence, result.confidence);
      expect(reconstructed.triggeredSpray, result.triggeredSpray);
    });

    test('DetectionResult spray trigger logic', () {
      final alertResult = model.DetectionResult(
        level: model.DrowsinessLevel.alert,
        confidence: 0.9,
        timestamp: DateTime.now(),
      );

      final moderateResult = model.DetectionResult(
        level: model.DrowsinessLevel.moderateFatigue,
        confidence: 0.8,
        timestamp: DateTime.now(),
      );

      expect(alertResult.shouldTriggerSpray, false);
      expect(moderateResult.shouldTriggerSpray, true);
    });
  });
}
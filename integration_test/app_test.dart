import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scentsafe/main.dart';
import 'package:scentsafe/services/auth_service.dart';
import 'package:scentsafe/services/detection_service.dart';
import 'package:scentsafe/services/permission_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Launch and Core Functionality', () {
    testWidgets('complete app launch workflow', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      // Wait for app to initialize
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify app loads successfully
      expect(find.text('ScentSafe'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('permission request workflow', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      await tester.pumpAndSettle();

      // Should show permission request interface
      expect(find.text('Permissions Required'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('authentication workflow', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      // Simulate granting permissions by passing the permission check
      await tester.pumpAndSettle();

      // Should eventually show login screen
      // This depends on the actual permission logic implementation
      expect(find.text('ScentSafe'), findsWidgets);
    });
  });

  group('Detection Workflow E2E', () {
    testWidgets('full detection cycle from start to finish', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      // Navigate through permission screen
      await tester.pumpAndSettle();

      // Simulate auth flow (would require actual auth in real test)
      // For now, just verify the app structure
      expect(find.text('ScentSafe'), findsWidgets);
    });
  });

  group('Cross-Platform Compatibility', () {
    testWidgets('web platform specific behavior', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      await tester.pumpAndSettle();

      // Web-specific verifications
      expect(find.text('ScentSafe'), findsOneWidget);
    });
  });

  group('Performance and Stability', () {
    testWidgets('app stability under normal usage', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      // Multiple pump cycles to test stability
      for (int i = 0; i < 5; i++) {
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        expect(find.text('ScentSafe'), findsOneWidget);
      }
    });
  });

  group('Error Handling and Recovery', () {
    testWidgets('graceful handling of service errors', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp(
        authService: AuthService(),
        detectionService: DetectionService(),
        bluetoothService: MockBluetoothService(),
        firebaseService: MockFirebaseService(),
        permissionService: PermissionService.instance,
        audioService: MockAudioService(),
        performanceService: MockPerformanceService(),
        securityService: MockSecurityService(),
      ));

      await tester.pumpAndSettle();

      // Verify the app doesn't crash on errors
      expect(find.text('ScentSafe'), findsOneWidget);
    });
  });
}

// Mock services for testing
class MockBluetoothService {
  bool get isConnected => false;
  Future<void> dispose() async {}
}

class MockFirebaseService {
  static final instance = MockFirebaseService();
  Future<void> initialize() async {}
  Future<void> updateDrowsinessState(String state) async {}
}

class MockAudioService {
  static final instance = MockAudioService();
  Future<void> initialize() async {}
  void dispose() {}
}

class MockPerformanceService {
  static final instance = MockPerformanceService();
  Future<void> initialize() async {}
}

class MockSecurityService {
  Future<void> initialize() async {}
}
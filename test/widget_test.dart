import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scentsafe/main.dart';
import 'package:scentsafe/services/auth_service.dart';
import 'package:scentsafe/services/detection_service.dart';
import 'package:scentsafe/services/bluetooth_service.dart';
import 'package:scentsafe/services/firebase_service.dart';
import 'package:scentsafe/services/permission_service.dart';
import 'package:scentsafe/services/audio_alert_service.dart';
import 'package:scentsafe/services/performance_service.dart';
import 'package:scentsafe/services/security_service.dart';

void main() {
  testWidgets('App starts with loading screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      authService: AuthService(),
      detectionService: DetectionService.instance,
      bluetoothService: BluetoothService(),
      firebaseService: FirebaseService.instance,
      permissionService: PermissionService.instance,
      audioService: AudioAlertService.instance,
      performanceService: PerformanceService.instance,
      securityService: SecurityService.instance,
    ));

    // Verify that the loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('ScentSafe'), findsNothing);
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      authService: AuthService(),
      detectionService: DetectionService.instance,
      bluetoothService: BluetoothService(),
      firebaseService: FirebaseService.instance,
      permissionService: PermissionService.instance,
      audioService: AudioAlertService.instance,
      performanceService: PerformanceService.instance,
      securityService: SecurityService.instance,
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

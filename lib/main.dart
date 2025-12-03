import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart'; // Firebase ENABLED
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
import 'services/performance_service.dart';
import 'services/security_service.dart';
import 'services/camera_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bluetooth_setup_screen.dart';
import 'screens/help_screen.dart';
import 'screens/video_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Request permissions before initializing services
  try {
    final permissionService = PermissionService.instance;
    final permissionsGranted =
        await permissionService.requestPermissionsWithExplanation();
    if (!permissionsGranted) {
      print(
          '⚠️  Some permissions were not granted. App functionality may be limited.');
    } else {
      print('✅ All permissions granted successfully');
    }
  } catch (e) {
    print('❌ Permission request failed: $e');
  }

  // Initialize Firebase first
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.current,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // Initialize Firebase service
  final firebaseService = FirebaseService.instance;
  await firebaseService.initialize();

  // Initialize services with proper dependency injection
  final authService = AuthService(firebaseService);
  final bluetoothService = BluetoothService();
  final permissionService = PermissionService.instance;
  final audioService = AudioAlertService.instance;
  final performanceService = PerformanceService.instance;
  final securityService = SecurityService.instance;

  // CRITICAL FIX: Initialize detection service with proper dependency injection
  final detectionService = DetectionService();

  // Initialize critical services
  await detectionService.initialize();
  await audioService.initialize();
  await performanceService.initialize();

  // CRITICAL: Initialize camera service before app starts
  try {
    await CameraService.initializeService();
    debugPrint('Camera service initialized at app level');
  } catch (e) {
    debugPrint('Failed to initialize camera service at app level: $e');
    // Continue without camera service - it will be initialized later if needed
  }

  runApp(MyApp(
    authService: authService,
    detectionService: detectionService,
    bluetoothService: bluetoothService,
    firebaseService: firebaseService,
    permissionService: permissionService,
    audioService: audioService,
    performanceService: performanceService,
    securityService: securityService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final DetectionService detectionService;
  final BluetoothService bluetoothService;
  final FirebaseService firebaseService;
  final PermissionService permissionService;
  final AudioAlertService audioService;
  final PerformanceService performanceService;
  final SecurityService securityService;

  const MyApp({
    super.key,
    required this.authService,
    required this.detectionService,
    required this.bluetoothService,
    required this.firebaseService,
    required this.permissionService,
    required this.audioService,
    required this.performanceService,
    required this.securityService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authService)..checkAuthStatus(),
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
        // FIXED: Go directly to dashboard instead of permission wrapper
        home: const DashboardScreen(),
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

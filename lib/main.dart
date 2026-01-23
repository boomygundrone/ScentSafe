import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Firebase imports commented out - dependencies not available
// import 'package:firebase_core/firebase_core.dart';
// import 'config/firebase_config.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/detection_cubit.dart';
import 'blocs/bluetooth_cubit.dart';
// import 'blocs/firebase_cubit.dart';
import 'blocs/localization_cubit.dart';
import 'services/auth_service.dart';
import 'services/detection_service.dart';
import 'services/bluetooth_service.dart';
// import 'services/firebase_service.dart';
import 'services/mock_firebase_service.dart'; // Use mock instead
import 'services/permission_service.dart';
import 'services/audio_alert_service.dart';
import 'services/performance_service.dart';
import 'services/security_service.dart';
import 'services/camera_service.dart';
import 'services/app_localization_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/bluetooth_setup_screen.dart';
import 'screens/help_screen.dart';
import 'screens/video_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/language_switcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 App starting...');

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

  // Firebase initialization skipped - dependencies not available
  print('ℹ️  Firebase initialization skipped - dependencies not configured');
  print('ℹ️  App will run in limited mode without Firebase');
  // final firebaseService = FirebaseService.instance; // Firebase disabled
  // Firebase service initialization skipped

  // Initialize services with proper dependency injection
  final authService =
      AuthService(MockFirebaseService.instance); // Use mock Firebase service
  final bluetoothService = BluetoothService();
  final permissionService = PermissionService.instance;
  final audioService = AudioAlertService.instance;
  final performanceService = PerformanceService.instance;
  final securityService = SecurityService.instance;

  // Initialize localization service
  final appLocalizationService = AppLocalizationService.instance;
  await appLocalizationService.initialize();

  // CRITICAL FIX: Initialize detection service with proper dependency injection
  final detectionService = DetectionService();

  // Initialize critical services
  await detectionService.initialize();
  await audioService.initialize();
  await performanceService.initialize();

  // CRITICAL: Initialize camera service before app starts
  try {
    await CameraService.initializeService();
    debugPrint('✅ Camera service initialized at app level');
  } catch (e) {
    debugPrint('⚠️  Failed to initialize camera service at app level: $e');
    debugPrint(
        'ℹ️  Note: iOS Simulator may not have physical cameras. Use a physical device for testing.');
    // Continue without camera service - it will be initialized later if needed
    // The UI will handle the absence of camera gracefully
  }

  runApp(MyApp(
    authService: authService,
    detectionService: detectionService,
    bluetoothService: bluetoothService,
    // firebaseService: firebaseService, // Firebase disabled
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
  // final FirebaseService firebaseService; // Firebase disabled
  final PermissionService permissionService;
  final AudioAlertService audioService;
  final PerformanceService performanceService;
  final SecurityService securityService;

  const MyApp({
    super.key,
    required this.authService,
    required this.detectionService,
    required this.bluetoothService,
    // required this.firebaseService, // Firebase disabled
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
        // BlocProvider(
        //   create: (context) => FirebaseCubit(firebaseService),
        // ),
        BlocProvider(
          create: (context) =>
              LocalizationCubit(AppLocalizationService.instance),
        ),
      ],
      child: BlocBuilder<LocalizationCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('zh', 'HK'),
            ],
            title: 'ScentSafe',
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
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
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

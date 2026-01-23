import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io' show Platform;
import '../blocs/detection_cubit.dart';
import '../blocs/bluetooth_cubit.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/localization_cubit.dart';
import '../models/detection_result.dart';
import '../models/user.dart';
import '../services/camera_service.dart';
import '../services/app_localization_service.dart';
import '../constants/layout_constants.dart';
import '../widgets/language_switcher.dart';

/// Extension for String localization
extension StringLocalization on String {
  String tr() {
    return AppLocalizationService.instance.translate(this);
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isVideoActive = false;
  CameraService? _cameraService;
  StreamSubscription<CameraState>? _cameraStateSubscription;
  DetectionCubit? _detectionCubit;

  @override
  void initState() {
    super.initState();
    // Initialize camera service
    _initializeCameraService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to DetectionCubit for safe access in dispose
    _detectionCubit = context.read<DetectionCubit>();
  }

  Future<void> _initializeCameraService() async {
    try {
      // Camera service should already be initialized at app level
      _cameraService = CameraService.instance;
      debugPrint('Camera service instance acquired');

      // Listen to camera state changes
      _cameraStateSubscription =
          _cameraService!.cameraStateStream.listen((state) {
        if (mounted && _detectionCubit != null) {
          setState(() {
            // Update UI based on camera state
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to access camera service: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint(
          'DashboardScreen: Initializing camera through camera service...');
      debugPrint(
          'DashboardScreen: Camera service isServiceInitialized=${_cameraService?.isServiceInitialized ?? false}');
      debugPrint(
          'DashboardScreen: Camera service isInitialized=${_cameraService?.isInitialized ?? false}');

      if (_cameraService == null) {
        throw Exception('Camera service not initialized');
      }

      // CRITICAL FIX: Ensure service is initialized before initializing camera
      if (!_cameraService!.isServiceInitialized) {
        debugPrint(
            'DashboardScreen: Camera service not initialized, attempting service initialization...');
        try {
          await _cameraService!.initialize();
          debugPrint(
              'DashboardScreen: Camera service initialized successfully');
          debugPrint(
              'DashboardScreen: After init - isServiceInitialized=${_cameraService!.isServiceInitialized}, isInitialized=${_cameraService!.isInitialized}');
        } catch (e) {
          debugPrint(
              'DashboardScreen: Camera service initialization failed: $e');
          throw Exception('Failed to initialize camera service: $e');
        }
      }

      // Always initialize camera to ensure it's ready
      // This handles both new initialization and re-initialization
      debugPrint('DashboardScreen: Calling initializeCamera...');
      await _cameraService!.initializeCamera();
      debugPrint('DashboardScreen: Camera controller initialized');
      debugPrint(
          'DashboardScreen: After initializeCamera - isInitialized=${_cameraService!.isInitialized}');

      // Set camera controller in detection service after initialization
      if (_cameraService!.controller != null) {
        await context
            .read<DetectionCubit>()
            .setCameraController(_cameraService!.controller!);
        debugPrint(
            'DashboardScreen: Camera controller set in detection service');
      } else {
        debugPrint(
            'DashboardScreen: WARNING - Camera controller is null after initialization');
      }

      // CRITICAL FIX: Set _isVideoActive to true after successful initialization
      // This ensures the camera preview is displayed when camera is ready
      if (mounted && _cameraService!.isInitialized) {
        setState(() {
          _isVideoActive = true;
        });
        debugPrint(
            'DashboardScreen: Video feed activated after initialization');
      }

      // Always start detection loop after setting controller
      _startDetectionLoop();
    } catch (e) {
      debugPrint('DashboardScreen: Camera initialization error: $e');
      rethrow;
    }
  }

  void _startDetectionLoop() {
    debugPrint('Starting detection loop...');

    // SIMPLIFIED APPROACH: Use centralized DetectionService instead of local timers
    // Start the centralized detection service which handles all timing
    if (mounted && _detectionCubit != null) {
      // Note: Can't access private _detectionService, so we'll use the public methods
      // final detectionService = context.read<DetectionCubit>()._detectionService;
      _detectionCubit!.startDetection();
      debugPrint('Detection started via DetectionCubit');
    } else {
      debugPrint('Widget not mounted, cannot start detection');
    }
  }

  Future<void> _stopDetectionLoop() async {
    debugPrint('Stopping detection loop...');

    // SIMPLIFIED APPROACH: Stop centralized DetectionService
    if (mounted && _detectionCubit != null) {
      // Note: Can't access private _detectionService, so we'll use the public methods
      // final detectionService = context.read<DetectionCubit>()._detectionService;
      _detectionCubit!.stopDetection();
      debugPrint('Detection stopped via DetectionCubit');
    } else {
      debugPrint('Widget not mounted, cannot stop detection');
    }
  }

  @override
  void dispose() {
    _stopDetectionLoop();
    _cameraStateSubscription?.cancel();
    _detectionCubit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🏠 DashboardScreen.build() called - cameraService.isServiceInitialized=${_cameraService?.isServiceInitialized ?? false}');

    // Show loading screen while camera service is initializing
    // CRITICAL FIX: Use isServiceInitialized instead of isInitialized to allow UI to load
    // isInitialized requires camera controller to be ready, but the dashboard should
    // load even when camera is off (controller is null)
    if (_cameraService == null || !_cameraService!.isServiceInitialized) {
      debugPrint('📸 Camera service not ready, showing loading screen');
      return Scaffold(
        backgroundColor: const Color(0xFF1A1B2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1B2E),
          elevation: 0,
          title: Text(
            'app_name'.tr(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: LanguageToggleButton(
                iconColor: Colors.white,
                iconSize: 20,
              ),
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF7C3AED),
              ),
              SizedBox(height: 20),
              Text(
                'Initializing camera service...',
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

    debugPrint('📸 Camera service ready, building main UI');

    return Scaffold(
      backgroundColor:
          const Color(0xFF1A1B2E), // Dark navy/purple background like mockup
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        title: Text(
          'app_name'.tr(),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageToggleButton(
              iconColor: Colors.white,
              iconSize: 20,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: BlocBuilder<LocalizationCubit, Locale>(
        builder: (context, locale) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section (simplified)
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      String userName = 'Marcus';

                      if (authState is AuthAuthenticated) {
                        userName = authState.user.name;
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3250),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile Picture
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1B2E),
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image:
                                      AssetImage('images/profile_avatar.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Greeting Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${'hello'.tr()} $userName,',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'welcome'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  LayoutConstants.sectionSpacer,

                  // Video Section - Always show camera container
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3250),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 2),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child:
                                _buildCameraPreview(), // Uses camera's native aspect ratio
                          ),
                          // Tap to open full screen overlay - only show when camera is active
                          if (_isVideoActive)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/video');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fullscreen,
                                        color: const Color(0xFFFFD700),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'tap_to_expand'.tr(),
                                        style: TextStyle(
                                          color: const Color(0xFFFFD700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  LayoutConstants.sectionSpacer,

                  // Awakeness Level Section
                  BlocBuilder<DetectionCubit, DetectionState>(
                    builder: (context, state) {
                      String levelText;
                      String additionalInfo = '';

                      if (state is DetectionResultUpdated) {
                        switch (state.result.level) {
                          case DrowsinessLevel.alert:
                            levelText = 'alert'.tr();
                            break;
                          case DrowsinessLevel.mildFatigue:
                            levelText = 'mild_fatigue'.tr();
                            break;
                          case DrowsinessLevel.moderateFatigue:
                            levelText = 'moderate_fatigue'.tr();
                            break;
                          case DrowsinessLevel.severeFatigue:
                            levelText = 'severe_fatigue'.tr();
                            break;
                        }

                        // Display additional detection metrics
                        additionalInfo =
                            'EAR: ${state.result.averageEAR?.toStringAsFixed(2) ?? 'N/A'} | '
                            'Blinks: ${state.result.blinkCount} | '
                            'Yawns: ${state.result.yawnCount} | '
                            'Head Tilt: ${state.result.headTilt?.toStringAsFixed(1) ?? 'N/A'}° | '
                            'Audio Alert: ${state.result.level == DrowsinessLevel.moderateFatigue || state.result.level == DrowsinessLevel.severeFatigue ? 'Active' : 'Inactive'}';
                      } else {
                        levelText = 'initializing'.tr();
                      }

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2563EB), // Blue start
                              Color(0xFF1E293B), // Dark blue end
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'awakeness_level'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              levelText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  LayoutConstants.sectionSpacer,

                  // Aroma Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2563EB), // Blue start
                          Color(0xFF1E293B), // Dark blue end
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'current_scent'.tr(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lavender Relax',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  LayoutConstants.sectionSpacer,

                  // Voice Pack Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2563EB), // Blue start
                          Color(0xFF1E293B), // Dark blue end
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Voice Pack Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'voice_pack'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to view all voice packs
                              },
                              child: Text(
                                'view_all'.tr(),
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Voice Pack Cards - Horizontal Scrollable Row
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildVoicePackCard(
                                  'Ado', 'HKD 50', 'images/voice_pack_ado.png'),
                              const SizedBox(width: 16),
                              _buildVoicePackCard(
                                  'Luna', 'Free', 'images/profile_avatar.png'),
                              const SizedBox(width: 16),
                              _buildVoicePackCard(
                                  'Echo', 'HKD 30', 'images/bb8.jpeg'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF2D3250),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, true, () {}),
          TextButton(
            onPressed: () async {
              // Show immediate visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isVideoActive
                      ? 'stopping_camera'.tr()
                      : 'starting_camera'.tr()),
                  backgroundColor: _isVideoActive ? Colors.red : Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );

              // Check if video is currently active (detection running)
              if (_isVideoActive) {
                // Stop detection first before disposing camera
                await _stopDetectionLoop();

                // Dispose camera through camera service
                await _cameraService?.disposeCamera();

                if (mounted && _detectionCubit != null) {
                  setState(() {
                    _isVideoActive = false;
                  });

                  debugPrint(
                      'Camera turned off - all services and memory monitoring stopped');
                }
              } else {
                // Initialize camera with proper error handling
                try {
                  await _initializeCamera();

                  // Only update state after successful initialization
                  // CRITICAL FIX: Use isInitialized here to ensure camera controller is ready
                  if (mounted &&
                      _cameraService != null &&
                      _cameraService!.isInitialized) {
                    setState(() {
                      _isVideoActive = true;
                    });
                  }
                } catch (e) {
                  debugPrint('Error initializing camera: $e');
                  if (mounted && _detectionCubit != null) {
                    setState(() {
                      _isVideoActive = false;
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${'failed_to_initialize_camera'.tr()}: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isVideoActive
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isVideoActive ? Colors.red : Colors.green,
                  width: 2,
                ),
              ),
              child: Icon(
                _isVideoActive ? Icons.stop : Icons.fiber_manual_record,
                color: _isVideoActive ? Colors.red : Colors.green,
                size: 32,
              ),
            ),
          ),
          _buildNavItem(Icons.settings, false,
              () => Navigator.of(context).pushNamed('/settings')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFFD700).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFFD700) : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFD700) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePackCard(String name, String price, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Handle voice pack selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'selected_voice_pack'.tr()} $name')),
        );
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8), // Reduced padding from 12 to 8
        decoration: BoxDecoration(
          color: const Color(0xFF2D3250),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Added to minimize column size
          children: [
            // Circular Avatar
            Container(
              width: 45, // Reduced from 50 to 45
              height: 45, // Reduced from 50 to 45
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8 to 6
            // Name
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13, // Reduced from 14 to 13
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // Added to prevent text overflow
              overflow: TextOverflow.ellipsis, // Added to handle text overflow
            ),
            const SizedBox(height: 3), // Reduced from 4 to 3
            // Price
            Text(
              price,
              style: TextStyle(
                color: price == 'Free' ? Colors.green : const Color(0xFFFFD700),
                fontSize: 11, // Reduced from 12 to 11
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1, // Added to prevent text overflow
              overflow: TextOverflow.ellipsis, // Added to handle text overflow
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    // Use centralized camera service for preview
    final isServiceReady = _cameraService?.isServiceInitialized ?? false;
    final isCameraReady = _cameraService?.isInitialized ?? false;
    final hasController = _cameraService?.controller != null;

    debugPrint(
        '_buildCameraPreview called: _isVideoActive=$_isVideoActive, isServiceReady=$isServiceReady, isCameraReady=$isCameraReady, hasController=$hasController');

    // CRITICAL FIX: Use isInitialized here because we need the actual camera controller
    // to display the preview, not just the service being ready
    if (_cameraService != null && _cameraService!.isInitialized) {
      debugPrint(
          'DashboardScreen: Camera is ready, returning CameraPreview widget from camera service');
      return _cameraService!.buildPreview();
    } else {
      String statusText = 'camera_off'.tr();
      IconData statusIcon = Icons.videocam_off;

      if (_isVideoActive) {
        if (!isServiceReady) {
          statusText = 'initializing_service'.tr();
          statusIcon = Icons.hourglass_empty;
          debugPrint('DashboardScreen: Video active but service not ready');
        } else if (!isCameraReady) {
          statusText = 'initializing_camera'.tr();
          statusIcon = Icons.hourglass_empty;
          debugPrint(
              'DashboardScreen: Video active and service ready, but camera not initialized');
        } else if (!hasController) {
          statusText = 'no_controller'.tr();
          statusIcon = Icons.error_outline;
          debugPrint(
              'DashboardScreen: Video active and camera initialized, but no controller');
        }
      }

      debugPrint('DashboardScreen: Returning status container: $statusText');
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                size: 48,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(height: 12),
              Text(
                statusText,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'use_toolbar_button'.tr(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

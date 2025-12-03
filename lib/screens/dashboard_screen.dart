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
import '../models/detection_result.dart';
import '../models/user.dart';
import '../services/camera_service.dart';
import '../constants/layout_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isVideoActive = false;
  CameraService? _cameraService;
  StreamSubscription<CameraState>? _cameraStateSubscription;
  bool _isCameraServiceReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize camera service
    _initializeCameraService();
  }

  Future<void> _initializeCameraService() async {
    try {
      // Camera service should already be initialized at app level
      _cameraService = CameraService.instance;
      debugPrint('Camera service instance acquired');

      // Listen to camera state changes after initialization
      _cameraStateSubscription =
          _cameraService!.cameraStateStream.listen((state) {
        if (mounted) {
          setState(() {
            // Update UI based on camera state
          });
        }
      });

      // Mark camera service as ready
      setState(() {
        _isCameraServiceReady = true;
      });
    } catch (e) {
      debugPrint('Failed to access camera service: $e');
      // Keep _cameraService as null, UI will handle this gracefully
      setState(() {
        _isCameraServiceReady = true; // Still mark as ready to show error state
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('Initializing camera through camera service...');

      if (_cameraService == null) {
        throw Exception('Camera service not initialized');
      }

      await _cameraService!.initializeCamera();

      // Set camera controller in detection service after initialization
      if (_cameraService!.controller != null) {
        await context
            .read<DetectionCubit>()
            .setCameraController(_cameraService!.controller!);
        debugPrint('Camera controller set in detection service');

        // Start detection when camera is initialized
        _startDetectionLoop();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      rethrow;
    }
  }

  void _startDetectionLoop() {
    debugPrint('Starting detection loop...');

    // SIMPLIFIED APPROACH: Use centralized DetectionService instead of local timers
    // Start the centralized detection service which handles all timing
    if (mounted) {
      // Note: Can't access private _detectionService, so we'll use the public methods
      // final detectionService = context.read<DetectionCubit>()._detectionService;
      context.read<DetectionCubit>().startDetection();
      debugPrint('Detection started via DetectionCubit');
    } else {
      debugPrint('Widget not mounted, cannot start detection');
    }
  }

  Future<void> _stopDetectionLoop() async {
    debugPrint('Stopping detection loop...');

    // SIMPLIFIED APPROACH: Stop centralized DetectionService
    if (mounted) {
      // Note: Can't access private _detectionService, so we'll use the public methods
      // final detectionService = context.read<DetectionCubit>()._detectionService;
      context.read<DetectionCubit>().stopDetection();
      debugPrint('Detection stopped via DetectionCubit');
    } else {
      debugPrint('Widget not mounted, cannot stop detection');
    }
  }

  @override
  void dispose() {
    _stopDetectionLoop();
    _cameraStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while camera service is initializing
    if (!_isCameraServiceReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1B2E),
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

    return Scaffold(
      backgroundColor:
          const Color(0xFF1A1B2E), // Dark navy/purple background like mockup
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        title: const Text(
          'ScentSafe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SingleChildScrollView(
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
                              image: AssetImage('images/profile_avatar.png'),
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
                                'Hello $userName,',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                'Welcome!!',
                                style: TextStyle(
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
              // Dynamic aspect ratio to match camera's native resolution
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3250),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: AspectRatio(
                  // Use a more flexible aspect ratio that adapts to content
                  aspectRatio:
                      16 / 9, // Standard widescreen aspect ratio as fallback
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight:
                          200, // Reduced minimum height for better aspect ratio preservation
                      maxHeight:
                          300, // Reduced maximum height to prevent stretching
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen,
                                      color: Color(0xFFFFD700),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tap to expand',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
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
              ),

              // Alternative camera container options for testing (commented out)
              // To test different aspect ratios, uncomment one of the following:

              // 4:3 Aspect Ratio Option (more square, like many cameras)
              /*
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3250),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF00CED1), width: 2),
                ),
                child: AspectRatio(
                  aspectRatio: 4/3, // 4:3 aspect ratio
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildCameraPreview(),
                      ),
                    ],
                  ),
                ),
              ),
              */

              // 1:1 Aspect Ratio Option (square format)
              /*
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3250),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFFF69B4), width: 2),
                ),
                child: AspectRatio(
                  aspectRatio: 1.0, // 1:1 square aspect ratio
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildCameraPreview(),
                      ),
                    ],
                  ),
                ),
              ),
              */

              LayoutConstants.sectionSpacer,

              // Awakeness Level Section
              BlocBuilder<DetectionCubit, DetectionState>(
                builder: (context, state) {
                  Color backgroundColor;
                  String levelText;
                  String additionalInfo = '';

                  if (state is DetectionResultUpdated) {
                    switch (state.result.level) {
                      case DrowsinessLevel.alert:
                        backgroundColor = Colors.green.withOpacity(0.5);
                        levelText = 'Alert';
                        break;
                      case DrowsinessLevel.mildFatigue:
                        backgroundColor = Colors.yellow.withOpacity(0.5);
                        levelText = 'Mild Fatigue';
                        break;
                      case DrowsinessLevel.moderateFatigue:
                        backgroundColor = Colors.orange.withOpacity(0.5);
                        levelText = 'Moderate Fatigue';
                        break;
                      case DrowsinessLevel.severeFatigue:
                        backgroundColor = Colors.red.withOpacity(0.5);
                        levelText = 'Severe Fatigue';
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
                    backgroundColor = Colors.grey.withOpacity(0.5);
                    levelText = 'Initializing...';
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
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
                          'Awakeness Level',
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
                      Color(0xFF4338CA), // Purple start
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Scent',
                          style: TextStyle(
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
                    Container(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle (full border)
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                width: 4,
                              ),
                            ),
                          ),
                          // Progress arc (only showing percentage)
                          Container(
                            width: 70,
                            height: 70,
                            child: CustomPaint(
                              painter: _CircularProgressPainter(
                                progress: 0.77,
                                strokeWidth: 4,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                          // Percentage text
                          Container(
                            width: 70,
                            height: 70,
                            alignment: Alignment.center,
                            child: Text(
                              '77%',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                      Color(0xFF4338CA), // Purple start
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
                        const Text(
                          'Voice Pack',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to view all voice packs
                          },
                          child: const Text(
                            'view all',
                            style: TextStyle(
                              color: Color(0xFF7C3AED),
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
          _buildNavItem(Icons.shopping_bag, false, () {
            // Navigate to shopping
          }),
          TextButton(
            onPressed: () async {
              // Show immediate visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isVideoActive
                      ? 'Stopping camera...'
                      : 'Starting camera...'),
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

                if (mounted) {
                  setState(() {
                    _isVideoActive = false;
                  });

                  debugPrint(
                      'Camera turned off - all services and memory monitoring stopped');
                }
              } else {
                // Update state first to provide immediate UI feedback
                if (mounted) {
                  setState(() {
                    _isVideoActive = true;
                  });
                } else {
                  return;
                }

                // Initialize camera with proper error handling
                try {
                  await _initializeCamera();
                } catch (e) {
                  debugPrint('Error initializing camera: $e');
                  if (mounted) {
                    setState(() {
                      _isVideoActive = false;
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to initialize camera: $e'),
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
          _buildNavItem(Icons.person, false, () {
            // Navigate to profile
          }),
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
          SnackBar(content: Text('Selected $name voice pack')),
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
    debugPrint(
        '_buildCameraPreview called: _isVideoActive=$_isVideoActive, cameraService.isInitialized=${_cameraService?.isInitialized ?? false}');

    if (_cameraService != null && _cameraService!.isInitialized) {
      debugPrint('Returning CameraPreview widget from camera service');
      return _cameraService!.buildPreview();
    } else {
      String statusText = 'Camera Off';
      IconData statusIcon = Icons.videocam_off;

      if (_isVideoActive &&
          (_cameraService == null || !_cameraService!.isInitialized)) {
        statusText = 'Initializing...';
        statusIcon = Icons.hourglass_empty;
      }

      debugPrint('Returning status container: $statusText');
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
              const Text(
                'Use toolbar button to control camera',
                style: TextStyle(
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

// Custom painter for circular progress arc
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle (very faint)
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}

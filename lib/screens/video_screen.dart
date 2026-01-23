import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../blocs/detection_cubit.dart';
import '../blocs/bluetooth_cubit.dart';
import '../models/detection_result.dart';
import '../services/camera_service.dart';
import 'dart:async';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  CameraService? _cameraService;
  StreamSubscription<CameraState>? _cameraStateSubscription;
  StreamSubscription<DetectionState>? _detectionStateSubscription;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _initializeCameraService();

    // CRITICAL FIX: Check camera state immediately and after delay
    // This ensures video screen detects camera if already initialized from dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraState();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkCameraState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to ScaffoldMessenger for safe use in dispose()
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    // CRITICAL FIX: Check camera state when dependencies change
    // This ensures video screen detects camera when navigating from dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCameraState();
    });
  }

  Future<void> _initializeCameraService() async {
    try {
      // Camera service should already be initialized at app level
      _cameraService = CameraService.instance;
      debugPrint('Camera service instance acquired in video screen');

      // Listen to camera state changes after initialization
      _cameraStateSubscription =
          _cameraService!.cameraStateStream.listen((state) {
        if (mounted) {
          setState(() {
            // Update UI based on camera state
          });
        }
      });

      // CRITICAL FIX: Listen to DetectionCubit state to trigger UI updates
      // This ensures video screen updates when detection state changes
      _detectionStateSubscription =
          context.read<DetectionCubit>().stream.listen((state) {
        if (mounted) {
          setState(() {
            // Trigger UI update when state changes
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to access camera service: $e');
    }
  }

  void _checkCameraState() {
    debugPrint('VideoScreen._checkCameraState() called');
    debugPrint('VideoScreen: mounted=$mounted');
    debugPrint(
        'VideoScreen: _cameraService=${_cameraService != null ? "initialized" : "null"}');
    debugPrint(
        'VideoScreen: isServiceInitialized=${_cameraService?.isServiceInitialized ?? false}');
    debugPrint(
        'VideoScreen: isInitialized=${_cameraService?.isInitialized ?? false}');
    debugPrint(
        'VideoScreen: controller=${_cameraService?.controller != null ? "exists" : "null"}');

    if (mounted && _cameraService != null && _cameraService!.isInitialized) {
      debugPrint('VideoScreen: Camera already initialized, updating UI');
      setState(() {
        // Force UI update to show camera preview
      });
    } else {
      debugPrint(
          'VideoScreen: Camera not initialized, will initialize on demand');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint(
          'Initializing camera through camera service in video screen...');

      if (_cameraService == null) {
        throw Exception('Camera service not initialized');
      }

      // CRITICAL FIX: Only initialize camera if it's not already initialized
      // This prevents re-initialization when navigating from dashboard,
      // which causes app to freeze
      if (!_cameraService!.isInitialized) {
        debugPrint('Camera not initialized, initializing...');
        await _cameraService!
            .initializeCamera(resolution: ResolutionPreset.high);
      } else {
        debugPrint('Camera already initialized, skipping re-initialization');
      }

      // Set camera controller in detection service
      if (_cameraService!.controller != null) {
        await context
            .read<DetectionCubit>()
            .setCameraController(_cameraService!.controller!);
        debugPrint(
            'Camera controller set in detection service from video screen');
      }
    } catch (e) {
      debugPrint('Camera initialization error in video screen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleDetection() async {
    final state = context.read<DetectionCubit>().state;
    if (state is DetectionRunning || state is DetectionResultUpdated) {
      await _stopDetection();
    } else {
      await _startDetection();
    }
  }

  Future<void> _startDetection() async {
    // CRITICAL FIX: Always ensure camera is initialized before starting detection
    // This fixes the issue where detection doesn't start after being stopped
    if (_cameraService == null ||
        !_cameraService!.isInitialized ||
        _cameraService!.controller == null) {
      // Initialize camera if not already initialized
      await _initializeCamera();
    }

    // CRITICAL FIX: Always re-set camera controller in DetectionService when starting detection
    // This ensures DetectionService has the camera reference even after being stopped
    if (_cameraService!.controller != null) {
      await context
          .read<DetectionCubit>()
          .setCameraController(_cameraService!.controller!);
      debugPrint(
          'Camera controller re-set in detection service for detection restart');
    }

    try {
      // Start detection service
      await context.read<DetectionCubit>().startDetection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start detection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopDetection() async {
    try {
      // Stop detection service
      await context.read<DetectionCubit>().stopDetection();

      // CRITICAL FIX: Actually stop camera hardware when stopping detection
      // This turns off the camera, not just hides the video feed
      if (_cameraService != null && _cameraService!.controller != null) {
        await _cameraService!.disposeCamera();
        debugPrint('VideoScreen: Camera disposed (hardware off)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop detection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopDetectionSafely() async {
    try {
      // Stop detection service
      await context.read<DetectionCubit>().stopDetection();
    } catch (e) {
      // Don't show snackbar during disposal to avoid widget tree lock error
      debugPrint('Failed to stop detection: $e');
    }
  }

  @override
  void dispose() {
    _stopDetectionSafely();
    _cameraStateSubscription?.cancel();
    _detectionStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'VideoScreen.build() called - this should always appear when navigating to video screen');
    debugPrint(
        'VideoScreen: _cameraService=${_cameraService != null ? "exists" : "null"}');
    debugPrint(
        'VideoScreen: isInitialized=${_cameraService?.isInitialized ?? false}');

    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        title: const Text(
          'Drowsiness Detection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<DetectionCubit, DetectionState>(
            builder: (context, state) {
              final isActive =
                  state is DetectionRunning || state is DetectionResultUpdated;
              return IconButton(
                icon: Icon(
                  isActive ? Icons.stop : Icons.play_arrow,
                  color: isActive ? Colors.red : Colors.green,
                ),
                onPressed: _toggleDetection,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview Section - Uses camera's native aspect ratio
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3250),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors
                      .green, // Always show green border when camera is active
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildCameraPreview(),
              ),
            ),
          ),

          // Detection Status Section
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3250),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Detection Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<DetectionCubit, DetectionState>(
                    builder: (context, state) {
                      return _buildDetectionStatus(state);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Control Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: BlocBuilder<DetectionCubit, DetectionState>(
                    builder: (context, state) {
                      final isActive = state is DetectionRunning ||
                          state is DetectionResultUpdated;
                      return ElevatedButton(
                        onPressed: _toggleDetection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? Icons.stop : Icons.play_arrow,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'Stop Detection' : 'Start Detection',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    await context.read<BluetoothCubit>().triggerSpray();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aroma spray triggered!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Trigger Spray',
                    style: TextStyle(
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
    );
  }

  Widget _buildCameraPreview() {
    // CRITICAL FIX: Only show camera preview when detection is ACTIVE
    // This ensures camera turns off when detection is stopped
    final detectionState = context.read<DetectionCubit>().state;
    final isDetectionActive = detectionState is DetectionRunning ||
        detectionState is DetectionResultUpdated;
    final isServiceReady = _cameraService?.isServiceInitialized ?? false;
    final isCameraReady = _cameraService?.isInitialized ?? false;
    final hasController = _cameraService?.controller != null;

    debugPrint(
        'VideoScreen._buildCameraPreview: isDetectionActive=$isDetectionActive, isServiceReady=$isServiceReady, isCameraReady=$isCameraReady, hasController=$hasController');

    // Only show camera preview when detection is ACTIVE
    // This ensures camera preview stops when detection is stopped
    if (isDetectionActive &&
        _cameraService != null &&
        _cameraService!.isInitialized &&
        _cameraService!.controller != null) {
      final previewSize = _cameraService!.controller!.value.previewSize;
      debugPrint(
          'VideoScreen: Detection active, showing camera preview directly');
      debugPrint('VideoScreen: Controller previewSize: $previewSize');

      // Let CameraPreview fill container naturally
      // This ensures video feed fills entire available space
      return CameraPreview(_cameraService!.controller!);
    } else {
      // Camera not ready or detection not active - show status
      String statusText;
      IconData statusIcon;

      if (!isDetectionActive) {
        statusText = 'Detection Inactive - Camera Off';
        statusIcon = Icons.videocam_off;
        debugPrint(
            'VideoScreen: Detection not active, showing camera off status');
      } else if (_cameraService == null) {
        statusText = 'Camera service not ready';
        statusIcon = Icons.hourglass_empty;
        debugPrint('VideoScreen: Camera service is null');
      } else if (!_cameraService!.isServiceInitialized) {
        statusText = 'Camera service not initialized';
        statusIcon = Icons.hourglass_empty;
        debugPrint('VideoScreen: Camera service not initialized');
      } else if (!_cameraService!.isInitialized) {
        statusText = 'Camera not initialized';
        statusIcon = Icons.camera_alt;
        debugPrint('VideoScreen: Camera not initialized');
      } else if (_cameraService!.controller == null) {
        statusText = 'No camera controller';
        statusIcon = Icons.error_outline;
        debugPrint('VideoScreen: Camera controller is null');
      } else {
        statusText = 'Camera not ready';
        statusIcon = Icons.videocam_off;
        debugPrint('VideoScreen: Camera not ready (unknown reason)');
      }

      debugPrint('VideoScreen: Showing status: $statusText');
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                size: 64,
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(height: 16),
              Text(
                statusText,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start detection to initialize camera',
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

  Widget _buildDetectionStatus(DetectionState state) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (state is DetectionResultUpdated) {
      switch (state.result.level) {
        case DrowsinessLevel.alert:
          statusColor = Colors.green;
          statusText = 'Alert and Focused';
          statusIcon = Icons.check_circle;
          break;
        case DrowsinessLevel.mildFatigue:
          statusColor = Colors.yellow;
          statusText = 'Mild Fatigue Detected';
          statusIcon = Icons.warning;
          break;
        case DrowsinessLevel.moderateFatigue:
          statusColor = Colors.orange;
          statusText = 'Moderate Fatigue - Stay Alert!';
          statusIcon = Icons.warning_amber;
          break;
        case DrowsinessLevel.severeFatigue:
          statusColor = Colors.red;
          statusText = 'Severe Fatigue - Take a Break!';
          statusIcon = Icons.dangerous;
          break;
      }
    } else if (state is DetectionRunning) {
      statusColor = Colors.blue;
      statusText = 'Detection Active';
      statusIcon = Icons.visibility;
    } else if (state is DetectionError) {
      statusColor = Colors.red;
      statusText = 'Detection Error';
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.grey;
      statusText = 'Detection Inactive';
      statusIcon = Icons.visibility_off;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (state is DetectionResultUpdated) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(state.result.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: statusColor.withOpacity(0.8),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

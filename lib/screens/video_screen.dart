import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../blocs/detection_cubit.dart';
import '../blocs/bluetooth_cubit.dart';
import '../models/detection_result.dart';
import '../services/camera_service.dart';
import 'dart:async';
import 'dart:async';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _isDetectionActive = false;
  CameraService? _cameraService;
  StreamSubscription<CameraState>? _cameraStateSubscription;
  ScaffoldMessengerState? _scaffoldMessenger;
  bool _isCameraServiceReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference to ScaffoldMessenger for safe use in dispose()
    _scaffoldMessenger = ScaffoldMessenger.of(context);
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
      debugPrint(
          'Initializing camera through camera service in video screen...');

      if (_cameraService == null) {
        throw Exception('Camera service not initialized');
      }

      await _cameraService!.initializeCamera(resolution: ResolutionPreset.high);

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
    if (_isDetectionActive) {
      await _stopDetection();
    } else {
      await _startDetection();
    }
  }

  Future<void> _startDetection() async {
    if (_cameraService == null || !_cameraService!.isInitialized) {
      // Initialize camera if not already initialized
      await _initializeCamera();
    }

    try {
      // Start detection service
      await context.read<DetectionCubit>().startDetection();

      setState(() {
        _isDetectionActive = true;
      });
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

      setState(() {
        _isDetectionActive = false;
      });
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

      if (mounted) {
        setState(() {
          _isDetectionActive = false;
        });
      }
    } catch (e) {
      // Don't show snackbar during disposal to avoid widget tree lock error
      debugPrint('Failed to stop detection: $e');
    }
  }

  @override
  void dispose() {
    _stopDetectionSafely();
    _cameraStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: Icon(
              _isDetectionActive ? Icons.stop : Icons.play_arrow,
              color: _isDetectionActive ? Colors.red : Colors.green,
            ),
            onPressed: _toggleDetection,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview Section - OPTION 3: Standardized Container Ratio
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3250),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDetectionActive
                      ? Colors.green
                      : const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio:
                    16 / 9, // Standardized 16:9 aspect ratio for consistency
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildCameraPreview(),
                ),
              ),
            ),
          ),

          // Alternative container options for testing (commented out)
          // To test different aspect ratios, uncomment one of the following:

          // 4:3 Aspect Ratio Option
          /*
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3250),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00CED1),
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 4/3, // 4:3 aspect ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildCameraPreview(),
                ),
              ),
            ),
          ),
          */

          // 1:1 Aspect Ratio Option (square)
          /*
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3250),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF69B4),
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1.0, // 1:1 square aspect ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildCameraPreview(),
                ),
              ),
            ),
          ),
          */

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
                  child: ElevatedButton(
                    onPressed: _toggleDetection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isDetectionActive ? Colors.red : Colors.green,
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
                          _isDetectionActive ? Icons.stop : Icons.play_arrow,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isDetectionActive
                              ? 'Stop Detection'
                              : 'Start Detection',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
    if (_cameraService != null && _cameraService!.isInitialized) {
      return Stack(
        children: [
          _cameraService!.buildPreview(),
          // Detection overlay
          if (_isDetectionActive)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
        ],
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 64,
                color: Color(0xFFFFD700),
              ),
              SizedBox(height: 16),
              Text(
                'Camera Initializing...',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state is DetectionResultUpdated) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(state.result.confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

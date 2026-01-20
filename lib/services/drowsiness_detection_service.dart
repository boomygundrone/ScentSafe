import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'camera_service.dart';

/// Drowsiness detection service with hybrid approach
/// Uses ARKit on iOS for True Depth camera data, falls back to ML Kit
class DrowsinessDetectionService {
  static const MethodChannel _platformChannel =
      MethodChannel('com.scentsafe.drowsiness/arkit');

  static DrowsinessDetectionService? _instance;
  bool _isInitialized = false;
  bool _useARKit = false;
  FaceDetector? _faceDetector;
  CameraService? _cameraService;

  // Detection state
  final StreamController<DrowsinessResult> _resultController =
      StreamController<DrowsinessResult>.broadcast();
  Timer? _detectionTimer;
  int _blinkCount = 0;
  DateTime? _lastBlinkTime;
  DateTime? _eyesClosedStartTime;
  bool _eyesCurrentlyClosed = false;
  double _drowsinessScore = 0.0;

  // Configuration
  static const int _blinkThreshold = 5; // Blinks per 10 seconds
  static const int _eyesClosedThreshold = 3; // Seconds eyes closed
  static const double _drowsinessThreshold = 0.7; // 70% confidence

  static DrowsinessDetectionService get instance {
    _instance ??= DrowsinessDetectionService._();
    return _instance!;
  }

  DrowsinessDetectionService._() {
    _initializeFaceDetector();
  }

  /// Stream of drowsiness detection results
  Stream<DrowsinessResult> get resultStream => _resultController.stream;

  /// Whether ARKit is being used
  bool get isUsingARKit => _useARKit;

  /// Current drowsiness score (0.0 to 1.0)
  double get drowsinessScore => _drowsinessScore;

  /// Initialize the drowsiness detection service
  Future<void> initialize({CameraService? cameraService}) async {
    if (_isInitialized) return;

    _cameraService = cameraService;

    try {
      // Try to initialize ARKit on iOS
      if (Platform.isIOS) {
        final arkitAvailable =
            await _platformChannel.invokeMethod<bool>('checkAvailability') ??
                false;
        _useARKit = arkitAvailable;
        debugPrint('ARKit available: $_useARKit');

        if (_useARKit) {
          await _platformChannel.invokeMethod('initialize');
          debugPrint('ARKit initialized successfully');
        }
      }

      // Initialize ML Kit face detector as fallback
      await _initializeFaceDetector();

      _isInitialized = true;
      debugPrint('DrowsinessDetectionService initialized (ARKit: $_useARKit)');
    } catch (e) {
      debugPrint('Error initializing DrowsinessDetectionService: $e');
      // Fall back to ML Kit if ARKit fails
      _useARKit = false;
      await _initializeFaceDetector();
      _isInitialized = true;
    }
  }

  /// Initialize ML Kit face detector
  Future<void> _initializeFaceDetector() async {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    );

    _faceDetector = GoogleMlKit.vision.faceDetector(options);
    debugPrint('ML Kit Face Detector initialized');
  }

  /// Start drowsiness detection
  Future<void> startDetection() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_useARKit) {
      await _startARKitDetection();
    } else {
      await _startMLKitDetection();
    }
  }

  /// Start ARKit-based detection (iOS only)
  Future<void> _startARKitDetection() async {
    try {
      await _platformChannel.invokeMethod('startDetection');
      debugPrint('ARKit detection started');

      // Listen to ARKit results
      _platformChannel.setMethodCallHandler(_handleARKitMethodCall);
    } catch (e) {
      debugPrint('Error starting ARKit detection: $e');
      // Fall back to ML Kit
      _useARKit = false;
      await _startMLKitDetection();
    }
  }

  /// Handle ARKit method calls from native iOS
  Future<dynamic> _handleARKitMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onFaceDetected':
        final data = Map<String, dynamic>.from(call.arguments);
        _processARKitFaceData(data);
        break;
      case 'onError':
        debugPrint('ARKit error: ${call.arguments}');
        // Fall back to ML Kit
        _useARKit = false;
        await _startMLKitDetection();
        break;
    }
  }

  /// Process face data from ARKit
  void _processARKitFaceData(Map<String, dynamic> data) {
    final leftEyeOpen = data['leftEyeOpen'] as bool? ?? true;
    final rightEyeOpen = data['rightEyeOpen'] as bool? ?? true;
    final blendShapes = data['blendShapes'] as Map<String, double>?;
    final headOrientation = data['headOrientation'] as Map<String, double>?;

    // Calculate drowsiness score based on eye state
    final eyesOpen = leftEyeOpen && rightEyeOpen;
    _updateEyeState(eyesOpen);

    // Additional analysis using blend shapes
    if (blendShapes != null) {
      final eyeBlinkLeft = blendShapes['eyeBlinkLeft'] ?? 0.0;
      final eyeBlinkRight = blendShapes['eyeBlinkRight'] ?? 0.0;
      final jawOpen = blendShapes['jawOpen'] ?? 0.0;

      // Adjust drowsiness score based on facial expressions
      _drowsinessScore = _calculateDrowsinessScore(
        eyeBlinkLeft: eyeBlinkLeft,
        eyeBlinkRight: eyeBlinkRight,
        jawOpen: jawOpen,
        headOrientation: headOrientation,
      );
    }

    // Emit result
    _emitResult();
  }

  /// Start ML Kit-based detection (cross-platform)
  Future<void> _startMLKitDetection() async {
    debugPrint('Starting ML Kit detection');

    // Set up image stream from camera
    if (_cameraService?.controller != null) {
      _cameraService!.controller!.startImageStream((cameraImage) async {
        if (_cameraService!.shouldProcessFrame()) {
          await _processCameraImage(cameraImage);
        }
      });
    }
  }

  /// Process camera image with ML Kit
  Future<void> _processCameraImage(CameraImage cameraImage) async {
    try {
      // Convert CameraImage to InputImage
      final inputImage = _getInputImageFromCameraImage(cameraImage);

      if (inputImage == null) return;

      // Detect faces
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isEmpty) {
        // No face detected
        _drowsinessScore = 0.0;
        _emitResult();
        return;
      }

      // Process first detected face
      final face = faces.first;

      // Check eye state
      final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
      final eyesOpen = leftEyeOpen > 0.5 && rightEyeOpen > 0.5;

      _updateEyeState(eyesOpen);

      // Calculate drowsiness score
      _drowsinessScore = _calculateMLKitDrowsinessScore(
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        headEulerAngleY: face.headEulerAngleY ?? 0.0,
        headEulerAngleZ: face.headEulerAngleZ ?? 0.0,
      );

      _emitResult();
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    }
  }

  /// Update eye state and track blinks
  void _updateEyeState(bool eyesOpen) {
    if (!eyesOpen && !_eyesCurrentlyClosed) {
      // Eyes just closed
      _eyesCurrentlyClosed = true;
      _eyesClosedStartTime = DateTime.now();
    } else if (eyesOpen && _eyesCurrentlyClosed) {
      // Eyes just opened - count as a blink
      _eyesCurrentlyClosed = false;
      _blinkCount++;
      _lastBlinkTime = DateTime.now();
      debugPrint('Blink detected (total: $_blinkCount)');
    }

    // Check for prolonged eye closure
    if (_eyesCurrentlyClosed && _eyesClosedStartTime != null) {
      final closedDuration =
          DateTime.now().difference(_eyesClosedStartTime!).inSeconds;
      if (closedDuration >= _eyesClosedThreshold) {
        debugPrint('Warning: Eyes closed for $closedDuration seconds');
      }
    }
  }

  /// Calculate drowsiness score from ARKit data
  double _calculateDrowsinessScore({
    required double eyeBlinkLeft,
    required double eyeBlinkRight,
    required double jawOpen,
    Map<String, double>? headOrientation,
  }) {
    double score = 0.0;

    // Eye blink contribution
    final avgBlink = (eyeBlinkLeft + eyeBlinkRight) / 2;
    score += avgBlink * 0.4;

    // Jaw open (yawning) contribution
    score += jawOpen * 0.3;

    // Head orientation (nodding) contribution
    if (headOrientation != null) {
      final pitch = headOrientation['pitch'] ?? 0.0;
      if (pitch.abs() > 0.3) {
        score += 0.3;
      }
    }

    // Blink frequency contribution
    if (_lastBlinkTime != null) {
      final timeSinceLastBlink =
          DateTime.now().difference(_lastBlinkTime!).inSeconds;
      if (timeSinceLastBlink < 2) {
        score += 0.2;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate drowsiness score from ML Kit data
  double _calculateMLKitDrowsinessScore({
    required double leftEyeOpen,
    required double rightEyeOpen,
    required double headEulerAngleY,
    required double headEulerAngleZ,
  }) {
    double score = 0.0;

    // Eye state contribution
    final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;
    score += (1.0 - avgEyeOpen) * 0.5;

    // Head orientation contribution
    if (headEulerAngleY.abs() > 20 || headEulerAngleZ.abs() > 20) {
      score += 0.3;
    }

    // Blink frequency contribution
    if (_lastBlinkTime != null) {
      final timeSinceLastBlink =
          DateTime.now().difference(_lastBlinkTime!).inSeconds;
      if (timeSinceLastBlink < 2) {
        score += 0.2;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Emit drowsiness detection result
  void _emitResult() {
    final isDrowsy = _drowsinessScore >= _drowsinessThreshold;
    final eyesClosedDuration =
        _eyesClosedStartTime != null && _eyesCurrentlyClosed
            ? DateTime.now().difference(_eyesClosedStartTime!).inSeconds
            : 0;

    final result = DrowsinessResult(
      isDrowsy: isDrowsy,
      drowsinessScore: _drowsinessScore,
      blinkCount: _blinkCount,
      eyesClosedDuration: eyesClosedDuration,
      eyesCurrentlyClosed: _eyesCurrentlyClosed,
      detectionMethod: _useARKit ? 'ARKit' : 'ML Kit',
      timestamp: DateTime.now(),
    );

    _resultController.add(result);
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _getInputImageFromCameraImage(CameraImage cameraImage) {
    // This is a simplified conversion
    // In production, you'd need proper conversion based on image format
    try {
      final plane = cameraImage.planes[0];
      final bytes = plane.bytes;
      final bytesPerRow = plane.bytesPerRow;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size:
              Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Stop drowsiness detection
  Future<void> stopDetection() async {
    if (_useARKit) {
      await _platformChannel.invokeMethod('stopDetection');
      _platformChannel.setMethodCallHandler(null);
    }

    if (_cameraService?.controller != null) {
      await _cameraService!.controller!.stopImageStream();
    }

    _detectionTimer?.cancel();
    _detectionTimer = null;

    debugPrint('Drowsiness detection stopped');
  }

  /// Reset detection state
  void resetState() {
    _blinkCount = 0;
    _lastBlinkTime = null;
    _eyesClosedStartTime = null;
    _eyesCurrentlyClosed = false;
    _drowsinessScore = 0.0;
    debugPrint('Detection state reset');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopDetection();
    await _faceDetector?.close();
    _faceDetector = null;
    await _resultController.close();
    _isInitialized = false;
    debugPrint('DrowsinessDetectionService disposed');
  }
}

/// Result of drowsiness detection
class DrowsinessResult {
  final bool isDrowsy;
  final double drowsinessScore;
  final int blinkCount;
  final int eyesClosedDuration;
  final bool eyesCurrentlyClosed;
  final String detectionMethod;
  final DateTime timestamp;

  DrowsinessResult({
    required this.isDrowsy,
    required this.drowsinessScore,
    required this.blinkCount,
    required this.eyesClosedDuration,
    required this.eyesCurrentlyClosed,
    required this.detectionMethod,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'DrowsinessResult(isDrowsy: $isDrowsy, score: ${drowsinessScore.toStringAsFixed(2)}, '
        'blinks: $blinkCount, eyesClosed: ${eyesClosedDuration}s, method: $detectionMethod)';
  }
}

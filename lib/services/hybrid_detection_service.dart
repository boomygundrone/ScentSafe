import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'face_detector.dart';
import 'cloud_detection_service.dart';
import 'streaming_service.dart';
import 'image_compression_service.dart';
import '../config/app_config.dart';

/// Hybrid detection service that combines client-side and cloud processing
/// Provides fallback mechanisms for offline operation and OutOfMemoryError prevention
class HybridDetectionService {
  static HybridDetectionService? _instance;
  static HybridDetectionService get instance {
    _instance ??= HybridDetectionService._();
    return _instance!;
  }

  HybridDetectionService._();

  // Service components
  FaceDetectorService? _clientDetector;
  CloudDetectionService? _cloudDetector;
  StreamingService? _streamingService;
  ImageCompressionService? _compressionService;

  // Service state
  bool _isInitialized = false;
  bool _isDetectionRunning = false;
  DetectionMode _currentMode = DetectionMode.auto;
  String? _currentSessionId;
  String? _authToken;

  // Performance tracking
  int _successfulCloudDetections = 0;
  int _successfulClientDetections = 0;
  int _failedDetections = 0;
  Duration _averageCloudProcessingTime = Duration.zero;
  Duration _averageClientProcessingTime = Duration.zero;

  // Fallback configuration
  static const Duration _offlineDetectionTimeout = Duration(seconds: 5);
  static const int _maxConsecutiveFailures = 3;
  static const double _confidenceThreshold = 0.6;
  static const int _performanceCheckInterval = 30; // seconds

  // Stream controllers
  final StreamController<HybridDetectionResult> _resultController =
      StreamController<HybridDetectionResult>.broadcast();
  final StreamController<DetectionMode> _modeController =
      StreamController<DetectionMode>.broadcast();
  final StreamController<HybridError> _errorController =
      StreamController<HybridError>.broadcast();

  Timer? _performanceTimer;

  /// Initialize hybrid detection service
  Future<void> initialize({
    DetectionMode mode = DetectionMode.auto,
    String sessionId = '',
    String authToken = '',
    String cloudProvider = 'custom_backend',
  }) async {
    if (_isInitialized) {
      debugPrint('HybridDetectionService: Already initialized');
      return;
    }

    debugPrint('HybridDetectionService: Initializing in $mode mode');
    debugPrint(
        'HybridDetectionService: Session ID: ${sessionId.isEmpty ? "auto-generated" : sessionId}');

    _currentMode = mode;
    _currentSessionId = sessionId.isNotEmpty ? sessionId : _generateSessionId();
    _authToken = authToken;

    try {
      // Initialize client-side detector (always needed for fallback)
      await _initializeClientDetector();

      // Initialize cloud components if in cloud or auto mode
      if (mode == DetectionMode.cloud || mode == DetectionMode.auto) {
        await _initializeCloudComponents(cloudProvider);
      }

      // Initialize compression service
      _compressionService = ImageCompressionService.instance;

      _isInitialized = true;
      _startPerformanceMonitoring();

      debugPrint('HybridDetectionService: Initialized successfully');
      debugPrint('HybridDetectionService: Client detector ready');
      if (_cloudDetector != null) {
        debugPrint('HybridDetectionService: Cloud detector ready');
      }
      if (_streamingService != null) {
        debugPrint('HybridDetectionService: Streaming service ready');
      }
    } catch (e) {
      debugPrint('HybridDetectionService: Initialization failed: $e');
      // Continue with client-only mode as fallback
      _isInitialized = true;
      _currentMode = DetectionMode.client;
      debugPrint('HybridDetectionService: Falling back to client-only mode');
    }
  }

  /// Start detection with automatic mode switching
  Future<void> startDetection({
    Stream<CameraImage>? imageStream,
    CameraController? cameraController,
    int maxFps = 10,
  }) async {
    if (!_isInitialized) {
      throw Exception('HybridDetectionService not initialized');
    }

    if (_isDetectionRunning) {
      debugPrint('HybridDetectionService: Detection already running');
      return;
    }

    debugPrint(
        'HybridDetectionService: Starting detection in $_currentMode mode');

    _isDetectionRunning = true;

    try {
      switch (_currentMode) {
        case DetectionMode.cloud:
          await _startCloudDetection(imageStream, maxFps);
          break;
        case DetectionMode.client:
          await _startClientDetection(cameraController);
          break;
        case DetectionMode.auto:
          await _startAutoDetection(imageStream, cameraController, maxFps);
          break;
      }
    } catch (e) {
      debugPrint('HybridDetectionService: Detection start failed: $e');
      _isDetectionRunning = false;
      _emitError('Detection start failed: $e');
      rethrow;
    }
  }

  /// Stop detection and cleanup
  Future<void> stopDetection() async {
    if (!_isDetectionRunning) return;

    debugPrint('HybridDetectionService: Stopping detection');

    _isDetectionRunning = false;

    try {
      // Stop streaming if active
      _streamingService?.dispose();

      // Keep client detector running for quick restarts
      debugPrint('HybridDetectionService: Detection stopped');
    } catch (e) {
      debugPrint('HybridDetectionService: Error stopping detection: $e');
    }
  }

  /// Process single image with hybrid approach
  Future<HybridDetectionResult?> processImage(CameraImage image) async {
    if (!_isInitialized) return null;

    final stopwatch = Stopwatch()..start();

    try {
      // Convert image to bytes for processing
      final imageBytes = image.planes.first.bytes;

      // Try cloud processing first if available
      if (_currentMode != DetectionMode.client && _cloudDetector != null) {
        try {
          final cloudResult = await _processWithCloud(imageBytes);
          stopwatch.stop();

          if (cloudResult != null) {
            _successfulCloudDetections++;
            _updateAverageCloudTime(stopwatch.elapsed);

            return HybridDetectionResult(
              result: cloudResult,
              mode: DetectionMode.cloud,
              processingTime: stopwatch.elapsed,
              confidence: cloudResult.confidence,
              timestamp: DateTime.now(),
            );
          }
        } catch (e) {
          debugPrint('HybridDetectionService: Cloud processing failed: $e');
        }
      }

      // Fallback to client processing
      final clientResult = await _processWithClient(image);
      stopwatch.stop();

      if (clientResult != null) {
        _successfulClientDetections++;
        _updateAverageClientTime(stopwatch.elapsed);

        return HybridDetectionResult(
          result: clientResult,
          mode: DetectionMode.client,
          processingTime: stopwatch.elapsed,
          confidence: 0.8, // Client detection confidence
          timestamp: DateTime.now(),
        );
      }

      _failedDetections++;
      return null;
    } catch (e) {
      stopwatch.stop();
      _failedDetections++;
      _emitError('Hybrid processing failed: $e');
      return null;
    }
  }

  /// Start cloud-based detection
  Future<void> _startCloudDetection(
    Stream<CameraImage>? imageStream,
    int maxFps,
  ) async {
    if (_streamingService == null) {
      throw Exception('Streaming service not initialized');
    }

    if (imageStream != null) {
      await _streamingService!.streamCameraImages(imageStream, maxFps: maxFps);
    } else {
      throw Exception('Image stream required for cloud detection');
    }
  }

  /// Start client-side detection
  Future<void> _startClientDetection(CameraController? cameraController) async {
    if (_clientDetector == null) {
      throw Exception('Client detector not initialized');
    }

    if (cameraController != null) {
      // Start camera image stream
      await cameraController.startImageStream((image) async {
        if (_isDetectionRunning) {
          final result = await _processWithClient(image);
          if (result != null) {
            _emitResult(HybridDetectionResult(
              result: result,
              mode: DetectionMode.client,
              processingTime: Duration(milliseconds: 50), // Estimated
              confidence: 0.8,
              timestamp: DateTime.now(),
            ));
          }
        }
      });
    } else {
      throw Exception('Camera controller required for client detection');
    }
  }

  /// Start automatic mode detection
  Future<void> _startAutoDetection(
    Stream<CameraImage>? imageStream,
    CameraController? cameraController,
    int maxFps,
  ) async {
    debugPrint('HybridDetectionService: Starting auto-detection mode');

    // Start with cloud detection if available
    if (_cloudDetector != null &&
        _streamingService != null &&
        imageStream != null) {
      try {
        debugPrint('HybridDetectionService: Attempting cloud detection first');
        await _startCloudDetection(imageStream, maxFps);
        _currentMode = DetectionMode.cloud;
        _emitModeChange(DetectionMode.cloud);
      } catch (e) {
        debugPrint(
            'HybridDetectionService: Cloud detection failed, falling back to client: $e');
        await _startClientDetection(cameraController);
        _currentMode = DetectionMode.client;
        _emitModeChange(DetectionMode.client);
      }
    } else {
      // Use client detection as primary
      await _startClientDetection(cameraController);
      _currentMode = DetectionMode.client;
      _emitModeChange(DetectionMode.client);
    }
  }

  /// Process image with cloud service
  Future<CloudDetectionResult?> _processWithCloud(Uint8List imageBytes) async {
    if (_cloudDetector == null) return null;

    final compressedImage = await _compressionService!.compressCameraImage(
      _convertBytesToCameraImage(imageBytes),
    );

    return await _cloudDetector!.processImage(compressedImage.data);
  }

  /// Process image with client service
  Future<FatigueDetectionResult?> _processWithClient(CameraImage image) async {
    if (_clientDetector == null) return null;

    final imageBytes = _concatenatePlanes(image.planes);
    final inputImage = _createInputImage(imageBytes, image.width, image.height);

    return await _clientDetector!.processImage(imageBytes, inputImage);
  }

  /// Initialize client-side detector
  Future<void> _initializeClientDetector() async {
    _clientDetector = FaceDetectorService();
    await _clientDetector!.initialize();
    debugPrint('HybridDetectionService: Client detector initialized');
  }

  /// Initialize cloud components
  Future<void> _initializeCloudComponents(String provider) async {
    try {
      _cloudDetector = CloudDetectionService.instance;
      await _cloudDetector!.initialize(
        provider: provider,
        authToken: _authToken,
      );

      // Initialize streaming service for real-time processing
      _streamingService = StreamingService.instance;
      await _streamingService!.initialize(
        sessionId: _currentSessionId!,
        authToken: _authToken!,
      );

      debugPrint('HybridDetectionService: Cloud components initialized');
    } catch (e) {
      debugPrint('HybridDetectionService: Cloud initialization failed: $e');
      // Continue without cloud components
      _cloudDetector = null;
      _streamingService = null;
    }
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceTimer =
        Timer.periodic(Duration(seconds: _performanceCheckInterval), (_) {
      _checkPerformanceAndAdapt();
    });
  }

  /// Check performance and adapt detection mode
  void _checkPerformanceAndAdapt() {
    if (_currentMode == DetectionMode.auto) {
      final cloudSuccessRate = _successfulCloudDetections > 0
          ? _successfulCloudDetections /
              (_successfulCloudDetections + _failedDetections)
          : 0.0;

      final clientSuccessRate = _successfulClientDetections > 0
          ? _successfulClientDetections /
              (_successfulClientDetections + _failedDetections)
          : 0.0;

      debugPrint('HybridDetectionService: Performance check');
      debugPrint(
          '  Cloud success rate: ${(cloudSuccessRate * 100).toStringAsFixed(1)}%');
      debugPrint(
          '  Client success rate: ${(clientSuccessRate * 100).toStringAsFixed(1)}%');
      debugPrint(
          '  Cloud avg time: ${_averageCloudProcessingTime.inMilliseconds}ms');
      debugPrint(
          '  Client avg time: ${_averageClientProcessingTime.inMilliseconds}ms');

      // Adapt mode based on performance
      if (cloudSuccessRate < 0.5 && clientSuccessRate > 0.8) {
        debugPrint(
            'HybridDetectionService: Switching to client mode due to cloud issues');
        _switchToClientMode();
      } else if (cloudSuccessRate > 0.8 && _cloudDetector != null) {
        debugPrint(
            'HybridDetectionService: Switching to cloud mode due to good performance');
        _switchToCloudMode();
      }
    }
  }

  /// Switch to client-only mode
  void _switchToClientMode() {
    if (_currentMode != DetectionMode.client) {
      _currentMode = DetectionMode.client;
      _emitModeChange(DetectionMode.client);
      debugPrint('HybridDetectionService: Switched to client mode');
    }
  }

  /// Switch to cloud mode
  void _switchToCloudMode() {
    if (_currentMode != DetectionMode.cloud && _cloudDetector != null) {
      _currentMode = DetectionMode.cloud;
      _emitModeChange(DetectionMode.cloud);
      debugPrint('HybridDetectionService: Switched to cloud mode');
    }
  }

  /// Update average cloud processing time
  void _updateAverageCloudTime(Duration time) {
    _averageCloudProcessingTime = Duration(
      milliseconds: ((_averageCloudProcessingTime.inMilliseconds *
                  _successfulCloudDetections) +
              time.inMilliseconds) ~/
          (_successfulCloudDetections + 1),
    );
  }

  /// Update average client processing time
  void _updateAverageClientTime(Duration time) {
    _averageClientProcessingTime = Duration(
      milliseconds: ((_averageClientProcessingTime.inMilliseconds *
                  _successfulClientDetections) +
              time.inMilliseconds) ~/
          (_successfulClientDetections + 1),
    );
  }

  /// Convert bytes to CameraImage (helper method)
  CameraImage _convertBytesToCameraImage(Uint8List bytes) {
    // This is a simplified conversion - in real implementation,
    // you would properly construct a CameraImage object
    return CameraImage(
      planes: [CameraPlane(bytes: bytes, bytesPerRow: 640, height: 480)],
      format: ImageFormatGroup.unknown,
      width: 640,
      height: 480,
    );
  }

  /// Concatenate image planes
  Uint8List _concatenatePlanes(List<CameraPlane> planes) {
    final buffer = BytesBuilder();
    for (final plane in planes) {
      buffer.add(plane.bytes);
    }
    return buffer.toBytes();
  }

  /// Create InputImage from bytes
  dynamic _createInputImage(Uint8List bytes, int width, int height) {
    // Placeholder for InputImage creation
    // In real implementation, use proper InputImage.fromBytes
    return null;
  }

  /// Emit detection result
  void _emitResult(HybridDetectionResult result) {
    _resultController.add(result);
  }

  /// Emit mode change
  void _emitModeChange(DetectionMode mode) {
    _modeController.add(mode);
  }

  /// Emit error
  void _emitError(String error) {
    _errorController.add(HybridError(error, DateTime.now()));
  }

  /// Generate session ID
  String _generateSessionId() {
    return 'hybrid_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get current detection mode
  DetectionMode get currentMode => _currentMode;

  /// Get service statistics
  Map<String, dynamic> get statistics {
    return {
      'isInitialized': _isInitialized,
      'isDetectionRunning': _isDetectionRunning,
      'currentMode': _currentMode.toString(),
      'successfulCloudDetections': _successfulCloudDetections,
      'successfulClientDetections': _successfulClientDetections,
      'failedDetections': _failedDetections,
      'averageCloudProcessingTimeMs':
          _averageCloudProcessingTime.inMilliseconds,
      'averageClientProcessingTimeMs':
          _averageClientProcessingTime.inMilliseconds,
      'cloudDetectorAvailable': _cloudDetector != null,
      'streamingServiceAvailable': _streamingService != null,
      'compressionServiceAvailable': _compressionService != null,
    };
  }

  /// Get streams
  Stream<HybridDetectionResult> get resultStream => _resultController.stream;
  Stream<DetectionMode> get modeStream => _modeController.stream;
  Stream<HybridError> get errorStream => _errorController.stream;

  /// Dispose all resources
  void dispose() {
    debugPrint('HybridDetectionService: Disposing...');

    _performanceTimer?.cancel();

    stopDetection();

    _clientDetector?.dispose();
    _cloudDetector?.dispose();
    _streamingService?.dispose();
    _compressionService?.dispose();

    _resultController.close();
    _modeController.close();
    _errorController.close();

    _isInitialized = false;
    _instance = null;

    debugPrint('HybridDetectionService: Disposed');
  }
}

/// Detection mode enum
enum DetectionMode {
  client, // Client-side only
  cloud, // Cloud processing only
  auto, // Automatic mode switching
}

/// Hybrid detection result
class HybridDetectionResult {
  final dynamic result; // Can be CloudDetectionResult or FatigueDetectionResult
  final DetectionMode mode;
  final Duration processingTime;
  final double confidence;
  final DateTime timestamp;

  HybridDetectionResult({
    required this.result,
    required this.mode,
    required this.processingTime,
    required this.confidence,
    required this.timestamp,
  });

  /// Get drowsiness level if available
  String? get drowsinessLevel {
    if (result is CloudDetectionResult) {
      return result.drowsinessLevel.toString().split('.').last;
    } else if (result is FatigueDetectionResult) {
      return result.detectionResult.level.toString().split('.').last;
    }
    return null;
  }

  /// Get confidence score
  double get drowsinessConfidence => confidence;

  @override
  String toString() {
    return 'HybridDetectionResult('
        'mode: $mode, '
        'drowsiness: ${drowsinessLevel ?? "unknown"}, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'time: ${processingTime.inMilliseconds}ms)';
  }
}

/// Hybrid service error
class HybridError {
  final String message;
  final DateTime timestamp;

  HybridError(this.message, this.timestamp);
}

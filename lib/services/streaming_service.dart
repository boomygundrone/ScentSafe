import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// Real-time streaming service for cloud-based face detection
/// Provides efficient communication with backend using HTTP polling
class StreamingService {
  static StreamingService? _instance;
  static StreamingService get instance {
    _instance ??= StreamingService._();
    return _instance!;
  }

  StreamingService._();

  // Service configuration
  static const String _baseUrl = 'https://your-backend-api.com/v1';
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Duration _pollInterval = Duration(milliseconds: 500);
  static const int _maxRetryAttempts = 3;

  // Service state
  String? _sessionId;
  String? _authToken;
  bool _isConnected = false;
  bool _isPolling = false;
  int _retryAttempts = 0;
  Timer? _pollingTimer;
  Timer? _heartbeatTimer;

  // Stream controllers
  final StreamController<DetectionResult> _resultController =
      StreamController<DetectionResult>.broadcast();
  final StreamController<StreamConnectionStateMessage> _connectionController =
      StreamController<StreamConnectionStateMessage>.broadcast();
  final StreamController<StreamError> _errorController =
      StreamController<StreamError>.broadcast();

  // Image processing queue
  final List<PendingImage> _pendingImages = [];
  bool _isProcessingQueue = false;

  /// Initialize streaming service
  Future<void> initialize({
    String sessionId = '',
    String authToken = '',
    String serverUrl = _baseUrl,
  }) async {
    if (_isConnected) {
      debugPrint('StreamingService: Already connected');
      return;
    }

    _sessionId = sessionId.isNotEmpty ? sessionId : _generateSessionId();
    _authToken = authToken;

    debugPrint('StreamingService: Initializing connection');
    debugPrint('StreamingService: Session ID: $_sessionId');

    _updateConnectionState(StreamConnectionState.connecting);

    try {
      // Test connection with health check
      await _testConnection(serverUrl);
      _isConnected = true;
      _retryAttempts = 0;

      debugPrint('StreamingService: Connected successfully');
      _updateConnectionState(StreamConnectionState.connected);

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      debugPrint('StreamingService: Connection failed: $e');
      _updateConnectionState(StreamConnectionState.error, e.toString());
      rethrow;
    }
  }

  /// Stream camera images to backend for processing
  Future<void> streamCameraImages(
    Stream<CameraImage> imageStream, {
    int maxFps = 10,
  }) async {
    if (!_isConnected) {
      throw Exception('Service not connected');
    }

    debugPrint('StreamingService: Starting image streaming at $maxFps FPS');

    final frameInterval = Duration(milliseconds: 1000 ~/ maxFps);
    Timer? frameTimer;
    int frameCount = 0;

    await for (final image in imageStream) {
      // Throttle frames to desired FPS
      if (frameTimer != null && frameTimer.isActive) {
        continue; // Skip frame if too soon
      }

      frameCount++;
      debugPrint('StreamingService: Processing frame $frameCount');

      try {
        // Add to processing queue
        _addToProcessingQueue(image, frameCount);

        // Process queue if not already processing
        if (!_isProcessingQueue) {
          _processQueue();
        }
      } catch (e) {
        debugPrint('StreamingService: Frame processing failed: $e');
        _emitError('Frame processing error: $e');
      }

      // Set timer for next frame
      frameTimer = Timer(frameInterval, () {
        frameTimer?.cancel();
      });
    }
  }

  /// Send single image for processing
  Future<void> sendImageForProcessing(
    CameraImage image, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isConnected) {
      throw Exception('Service not connected');
    }

    try {
      _addToProcessingQueue(
          image, DateTime.now().millisecondsSinceEpoch, metadata);

      if (!_isProcessingQueue) {
        _processQueue();
      }
    } catch (e) {
      debugPrint('StreamingService: Single image processing failed: $e');
      _emitError('Single image processing error: $e');
    }
  }

  /// Add image to processing queue
  void _addToProcessingQueue(
    CameraImage image,
    int frameNumber, [
    Map<String, dynamic>? metadata,
  ]) {
    final imageData = image.planes.first.bytes;

    _pendingImages.add(PendingImage(
      data: imageData,
      width: image.width,
      height: image.height,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      frameNumber: frameNumber,
      metadata: metadata ?? {},
    ));

    debugPrint(
        'StreamingService: Added image to queue (${_pendingImages.length} pending)');
  }

  /// Process the image queue
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _pendingImages.isEmpty) {
      return;
    }

    _isProcessingQueue = true;
    debugPrint('StreamingService: Starting queue processing');

    while (_pendingImages.isNotEmpty && _isConnected) {
      final image = _pendingImages.removeAt(0);

      try {
        await _processImage(image);
      } catch (e) {
        debugPrint('StreamingService: Image processing failed: $e');
        _emitError('Image processing error: $e');
      }

      // Small delay between processing
      await Future.delayed(Duration(milliseconds: 100));
    }

    _isProcessingQueue = false;
    debugPrint('StreamingService: Queue processing completed');
  }

  /// Process individual image
  Future<void> _processImage(PendingImage image) async {
    try {
      // Simulate HTTP request to backend
      final result = await _sendToBackend(image);

      if (result != null) {
        _resultController.add(result);
        debugPrint(
            'StreamingService: Detection result - ${result.drowsinessLevel} (${(result.confidence * 100).toStringAsFixed(1)}%)');
      }
    } catch (e) {
      debugPrint('StreamingService: Backend processing failed: $e');
      throw e;
    }
  }

  /// Send image to backend API (simulated)
  Future<DetectionResult?> _sendToBackend(PendingImage image) async {
    try {
      // Simulate processing delay
      await Future.delayed(Duration(milliseconds: 200));

      // Simulate backend response with basic detection
      final drowsinessLevel = _simulateDetection(image);
      final confidence =
          0.7 + (image.timestamp % 100) / 1000.0; // Simulated confidence

      return DetectionResult(
        drowsinessLevel: drowsinessLevel,
        confidence: confidence,
        timestamp: DateTime.fromMillisecondsSinceEpoch(image.timestamp),
        landmarks: {},
        metadata: {
          'frameNumber': image.frameNumber,
          'imageSize': '${image.width}x${image.height}',
          'processingTimeMs': 200,
        },
      );
    } catch (e) {
      debugPrint('StreamingService: Backend simulation failed: $e');
      return null;
    }
  }

  /// Simulate detection result (placeholder for real implementation)
  StreamDrowsinessLevel _simulateDetection(PendingImage image) {
    final timestamp = image.timestamp;

    if (timestamp % 4 == 0) {
      return StreamDrowsinessLevel.alert;
    } else if (timestamp % 4 == 1) {
      return StreamDrowsinessLevel.mildFatigue;
    } else if (timestamp % 4 == 2) {
      return StreamDrowsinessLevel.moderateFatigue;
    } else {
      return StreamDrowsinessLevel.severeFatigue;
    }
  }

  /// Test connection to backend
  Future<void> _testConnection(String serverUrl) async {
    // Simulate connection test
    await Future.delayed(Duration(milliseconds: 500));

    // In real implementation, make HTTP GET to /health endpoint
    debugPrint('StreamingService: Connection test passed');
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isConnected) {
        debugPrint('StreamingService: Heartbeat');
        // In real implementation, send heartbeat to backend
      }
    });
  }

  /// Update connection state
  void _updateConnectionState(StreamConnectionState state, [String? error]) {
    _connectionController.add(StreamConnectionStateMessage(state, error));
  }

  /// Emit error to error stream
  void _emitError(String error) {
    _errorController.add(StreamError(error, DateTime.now()));
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_retryAttempts}';
  }

  /// Get current connection state
  StreamConnectionState get connectionState => _isConnected
      ? StreamConnectionState.connected
      : StreamConnectionState.disconnected;

  /// Get streams for external listeners
  Stream<DetectionResult> get resultStream => _resultController.stream;
  Stream<StreamConnectionStateMessage> get connectionStream =>
      _connectionController.stream;
  Stream<StreamError> get errorStream => _errorController.stream;

  /// Get service statistics
  Map<String, dynamic> get statistics {
    return {
      'isConnected': _isConnected,
      'isPolling': _isPolling,
      'sessionId': _sessionId,
      'retryAttempts': _retryAttempts,
      'maxRetryAttempts': _maxRetryAttempts,
      'pendingImages': _pendingImages.length,
      'isProcessingQueue': _isProcessingQueue,
    };
  }

  /// Disconnect and cleanup
  void dispose() {
    debugPrint('StreamingService: Disposing...');

    _heartbeatTimer?.cancel();
    _pollingTimer?.cancel();

    _isConnected = false;
    _isPolling = false;

    _resultController.close();
    _connectionController.close();
    _errorController.close();

    _pendingImages.clear();
    _isProcessingQueue = false;
    _instance = null;

    debugPrint('StreamingService: Disposed');
  }
}

/// Detection result from streaming service
class DetectionResult {
  final StreamDrowsinessLevel drowsinessLevel;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic> landmarks;
  final Map<String, dynamic> metadata;

  DetectionResult({
    required this.drowsinessLevel,
    required this.confidence,
    required this.timestamp,
    this.landmarks = const {},
    this.metadata = const {},
  });
}

/// Pending image for processing
class PendingImage {
  final Uint8List data;
  final int width;
  final int height;
  final int timestamp;
  final int frameNumber;
  final Map<String, dynamic> metadata;

  PendingImage({
    required this.data,
    required this.width,
    required this.height,
    required this.timestamp,
    required this.frameNumber,
    required this.metadata,
  });
}

/// Stream drowsiness level enum
enum StreamDrowsinessLevel {
  alert,
  mildFatigue,
  moderateFatigue,
  severeFatigue,
}

/// Stream connection state enum
enum StreamConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Stream connection state message
class StreamConnectionStateMessage {
  final StreamConnectionState state;
  final String? error;

  StreamConnectionStateMessage(this.state, [this.error]);
}

/// Stream error
class StreamError {
  final String message;
  final DateTime timestamp;

  StreamError(this.message, this.timestamp);
}

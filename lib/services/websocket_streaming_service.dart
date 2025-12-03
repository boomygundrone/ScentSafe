import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:camera/camera.dart';

/// Real-time WebSocket streaming service for cloud-based face detection
/// Provides low-latency bidirectional communication with backend
class WebSocketStreamingService {
  static WebSocketStreamingService? _instance;
  static WebSocketStreamingService get instance {
    _instance ??= WebSocketStreamingService._();
    return _instance!;
  }

  WebSocketStreamingService._();

  // WebSocket configuration
  static const String _wsBaseUrl = 'wss://your-backend-api.com/v1';
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const int _maxReconnectAttempts = 5;

  // Service state
  WebSocketChannel? _channel;
  String? _sessionId;
  String? _authToken;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _connectionTimer;

  // Stream controllers
  final StreamController<DetectionResult> _resultController =
      StreamController<DetectionResult>.broadcast();
  final StreamController<ConnectionState> _connectionController =
      StreamController<ConnectionState>.broadcast();
  final StreamController<StreamError> _errorController =
      StreamController<StreamError>.broadcast();

  // Image processing queue
  final Queue<PendingImage> _pendingImages = Queue<PendingImage>();
  bool _isProcessingQueue = false;

  /// Initialize WebSocket connection
  Future<void> initialize({
    String sessionId = '',
    String authToken = '',
    String serverUrl = _wsBaseUrl,
  }) async {
    if (_isConnected || _isConnecting) {
      debugPrint('WebSocketStreamingService: Already connected or connecting');
      return;
    }

    _sessionId = sessionId.isNotEmpty ? sessionId : _generateSessionId();
    _authToken = authToken;

    debugPrint('WebSocketStreamingService: Initializing connection');
    debugPrint('WebSocketStreamingService: Session ID: $_sessionId');

    _isConnecting = true;
    _updateConnectionState(ConnectionState.connecting);

    try {
      await _connectToServer(serverUrl);
    } catch (e) {
      debugPrint('WebSocketStreamingService: Initial connection failed: $e');
      _isConnecting = false;
      _updateConnectionState(ConnectionState.error, e.toString());
      rethrow;
    }
  }

  /// Stream camera images to backend for processing
  Future<void> streamCameraImages(
    Stream<CameraImage> imageStream, {
    int maxFps = 10,
  }) async {
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }

    debugPrint(
        'WebSocketStreamingService: Starting image streaming at $maxFps FPS');

    final frameInterval = Duration(milliseconds: 1000 ~/ maxFps);
    Timer? frameTimer;
    int frameCount = 0;

    await for (final image in imageStream) {
      // Throttle frames to desired FPS
      if (frameTimer != null && frameTimer.isActive) {
        continue; // Skip frame if too soon
      }

      frameCount++;
      debugPrint('WebSocketStreamingService: Processing frame $frameCount');

      try {
        // Convert and compress image
        final compressedImage = await _processImageForStreaming(image);
        if (compressedImage != null) {
          // Send to backend
          await _sendImageFrame(compressedImage, frameCount);
        }
      } catch (e) {
        debugPrint('WebSocketStreamingService: Frame processing failed: $e');
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
      throw Exception('WebSocket not connected');
    }

    try {
      final compressedImage = await _processImageForStreaming(image);
      if (compressedImage != null) {
        await _sendImageFrame(
            compressedImage, DateTime.now().millisecondsSinceEpoch, metadata);
      }
    } catch (e) {
      debugPrint(
          'WebSocketStreamingService: Single image processing failed: $e');
      _emitError('Single image processing error: $e');
    }
  }

  /// Process image for streaming (compress + encode)
  Future<StreamImageFrame?> _processImageForStreaming(CameraImage image) async {
    try {
      final imageBytes = image.planes.first.bytes;

      // Compress image if needed
      Uint8List finalBytes;
      if (imageBytes.length > 100000) {
        // 100KB threshold
        finalBytes = await _compressImageData(imageBytes);
      } else {
        finalBytes = imageBytes;
      }

      // Convert to base64 for JSON transmission
      final base64Image = base64Encode(finalBytes);

      return StreamImageFrame(
        data: base64Image,
        width: image.width,
        height: image.height,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        frameNumber: 0, // Will be set by caller
        metadata: {},
      );
    } catch (e) {
      debugPrint('WebSocketStreamingService: Image processing failed: $e');
      return null;
    }
  }

  /// Compress image data for transmission
  Future<Uint8List> _compressImageData(Uint8List data) async {
    // For now, just return data as-is
    // In real implementation, use image_compression package
    return data;
  }

  /// Send image frame to backend
  Future<void> _sendImageFrame(
    StreamImageFrame frame,
    int frameNumber, [
    Map<String, dynamic>? metadata,
  ]) async {
    if (_channel == null) return;

    frame.frameNumber = frameNumber;
    if (metadata != null) {
      frame.metadata.addAll(metadata);
    }

    final message = {
      'type': 'image',
      'sessionId': _sessionId,
      'frame': {
        'data': frame.data,
        'width': frame.width,
        'height': frame.height,
        'frameNumber': frame.frameNumber,
        'timestamp': frame.timestamp,
        'metadata': frame.metadata,
      },
    };

    try {
      _channel!.sink.add(json.encode(message));
      debugPrint(
          'WebSocketStreamingService: Sent frame $frameNumber (${frame.data.length} chars)');
    } catch (e) {
      debugPrint('WebSocketStreamingService: Failed to send frame: $e');
      _emitError('Frame send error: $e');
    }
  }

  /// Connect to WebSocket server
  Future<void> _connectToServer(String serverUrl) async {
    final wsUrl = '$serverUrl/stream/$_sessionId';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Set up connection timeout
      _connectionTimer = Timer(_connectionTimeout, () {
        if (!_isConnected) {
          _channel?.sink.close();
          throw Exception('Connection timeout');
        }
      });

      // Listen for messages
      _channel!.stream.listen(
        (data) => _handleIncomingMessage(data),
        onError: (error) => _handleConnectionError(error),
        onDone: () => _handleConnectionClosed(),
      );

      // Send authentication
      _sendAuthentication();

      // Start heartbeat
      _startHeartbeat();

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      debugPrint('WebSocketStreamingService: Connected successfully');
      _updateConnectionState(ConnectionState.connected);
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _channel = null;
      debugPrint('WebSocketStreamingService: Connection failed: $e');
      rethrow;
    }
  }

  /// Send authentication message
  void _sendAuthentication() {
    if (_channel == null) return;

    final authMessage = {
      'type': 'auth',
      'sessionId': _sessionId,
      'authToken': _authToken,
      'clientInfo': {
        'platform': 'flutter',
        'version': '1.0.0',
        'capabilities': ['real_time_streaming', 'image_processing'],
      },
    };

    _channel!.sink.add(json.encode(authMessage));
    debugPrint('WebSocketStreamingService: Authentication sent');
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(json.encode({
          'type': 'heartbeat',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
      }
    });
  }

  /// Handle incoming messages from server
  void _handleIncomingMessage(dynamic data) {
    try {
      final message = json.decode(data as String);
      final messageType = message['type'];

      debugPrint(
          'WebSocketStreamingService: Received message type: $messageType');

      switch (messageType) {
        case 'result':
          _handleDetectionResult(message['result']);
          break;
        case 'error':
          _handleServerError(message['error']);
          break;
        case 'ack':
          debugPrint('WebSocketStreamingService: Message acknowledged');
          break;
        case 'heartbeat':
          // Respond to server heartbeat
          _channel?.sink.add(json.encode({
            'type': 'heartbeat_ack',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
          break;
        default:
          debugPrint(
              'WebSocketStreamingService: Unknown message type: $messageType');
      }
    } catch (e) {
      debugPrint('WebSocketStreamingService: Failed to parse message: $e');
    }
  }

  /// Handle detection result from server
  void _handleDetectionResult(Map<String, dynamic> result) {
    try {
      final detectionResult = DetectionResult(
        drowsinessLevel: _parseDrowsinessLevel(result['drowsinessLevel']),
        confidence: (result['confidence'] ?? 0.0).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            result['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
        landmarks: result['landmarks'] ?? {},
        metadata: {
          'processingTimeMs': result['processingTimeMs'] ?? 0,
          'frameNumber': result['frameNumber'] ?? 0,
          'provider': result['provider'] ?? 'unknown',
        },
      );

      _resultController.add(detectionResult);
      debugPrint(
          'WebSocketStreamingService: Detection result - ${detectionResult.drowsinessLevel} (${(detectionResult.confidence * 100).toStringAsFixed(1)}%)');
    } catch (e) {
      debugPrint(
          'WebSocketStreamingService: Failed to parse detection result: $e');
    }
  }

  /// Handle server error messages
  void _handleServerError(Map<String, dynamic> error) {
    final errorMessage = error['message'] ?? 'Unknown server error';
    final errorCode = error['code'] ?? 'UNKNOWN';

    debugPrint(
        'WebSocketStreamingService: Server error: $errorCode - $errorMessage');
    _emitError('$errorCode: $errorMessage');
  }

  /// Handle connection errors
  void _handleConnectionError(dynamic error) {
    debugPrint('WebSocketStreamingService: Connection error: $error');
    _isConnected = false;
    _isConnecting = false;
    _updateConnectionState(ConnectionState.error, error.toString());

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      debugPrint(
          'WebSocketStreamingService: Max reconnection attempts reached');
    }
  }

  /// Handle connection closure
  void _handleConnectionClosed() {
    debugPrint('WebSocketStreamingService: Connection closed');
    _isConnected = false;
    _isConnecting = false;
    _updateConnectionState(ConnectionState.disconnected);

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay =
        Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);

    debugPrint(
        'WebSocketStreamingService: Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    Timer(delay, () async {
      if (!_isConnected && !_isConnecting) {
        try {
          await _connectToServer(_wsBaseUrl);
        } catch (e) {
          debugPrint(
              'WebSocketStreamingService: Reconnect attempt $_reconnectAttempts failed: $e');
          if (_reconnectAttempts < _maxReconnectAttempts) {
            _scheduleReconnect();
          }
        }
      }
    });
  }

  /// Update connection state
  void _updateConnectionState(ConnectionState state, [String? error]) {
    _connectionController.add(ConnectionStateMessage(state, error));
  }

  /// Emit error to error stream
  void _emitError(String error) {
    _errorController.add(StreamError(error, DateTime.now()));
  }

  /// Parse drowsiness level from string
  DrowsinessLevel _parseDrowsinessLevel(String level) {
    switch (level.toLowerCase()) {
      case 'alert':
        return DrowsinessLevel.alert;
      case 'mild_fatigue':
        return DrowsinessLevel.mildFatigue;
      case 'moderate_fatigue':
        return DrowsinessLevel.moderateFatigue;
      case 'severe_fatigue':
        return DrowsinessLevel.severeFatigue;
      default:
        return DrowsinessLevel.alert;
    }
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_reconnectAttempts}';
  }

  /// Get current connection state
  ConnectionState get connectionState => _isConnected
      ? ConnectionState.connected
      : _isConnecting
          ? ConnectionState.connecting
          : ConnectionState.disconnected;

  /// Get streams for external listeners
  Stream<DetectionResult> get resultStream => _resultController.stream;
  Stream<ConnectionStateMessage> get connectionStream =>
      _connectionController.stream;
  Stream<StreamError> get errorStream => _errorController.stream;

  /// Get service statistics
  Map<String, dynamic> get statistics {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'sessionId': _sessionId,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'pendingImages': _pendingImages.length,
      'isProcessingQueue': _isProcessingQueue,
    };
  }

  /// Disconnect and cleanup
  void dispose() {
    debugPrint('WebSocketStreamingService: Disposing...');

    _heartbeatTimer?.cancel();
    _connectionTimer?.cancel();

    _channel?.sink.close();
    _channel = null;

    _isConnected = false;
    _isConnecting = false;

    _resultController.close();
    _connectionController.close();
    _errorController.close();

    _pendingImages.clear();
    _isProcessingQueue = false;
    _instance = null;

    debugPrint('WebSocketStreamingService: Disposed');
  }
}

/// Detection result from WebSocket streaming
class DetectionResult {
  final DrowsinessLevel drowsinessLevel;
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

/// Stream image frame data
class StreamImageFrame {
  String data;
  int width;
  int height;
  int timestamp;
  int frameNumber;
  Map<String, dynamic> metadata;

  StreamImageFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.timestamp,
    required this.frameNumber,
    required this.metadata,
  });
}

/// Connection state enum
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Connection state message
class ConnectionStateMessage {
  final ConnectionState state;
  final String? error;

  ConnectionStateMessage(this.state, [this.error]);
}

/// Stream error
class StreamError {
  final String message;
  final DateTime timestamp;

  StreamError(this.message, this.timestamp);
}

/// Simple queue implementation
class Queue<T> {
  final List<T> _items = [];

  void add(T item) => _items.add(item);
  T? remove() => _items.isNotEmpty ? _items.removeAt(0) : null;
  T? get first => _items.isNotEmpty ? _items.first : null;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;
  void clear() => _items.clear();
}

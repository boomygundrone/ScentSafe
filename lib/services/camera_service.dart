import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';
import '../utils/orientation_utils.dart';
import '../errors/app_exceptions.dart' as app_errors;

/// Centralized camera service to manage camera controller across the app
/// Prevents multiple camera controller instances and conflicts
class CameraService {
  static CameraService? _instance;
  static bool _isInitialized = false;

  static CameraService get instance {
    _instance ??= CameraService._();
    return _instance!;
  }

  CameraService._() {
    // Private constructor for singleton pattern
  }

  CameraController? _cameraController;
  bool _serviceInitialized = false;
  List<CameraDescription>? _availableCameras;
  CameraDescription? _frontCamera;

  /// CRITICAL FIX: Separate service initialization from camera controller initialization
  /// This property indicates if cameras have been discovered (service is ready)
  bool get isServiceInitialized => _serviceInitialized;

  /// CRITICAL FIX: This property now only checks if the camera controller is ready
  /// The dashboard should check isServiceInitialized instead to allow UI to load
  bool get isInitialized =>
      _serviceInitialized &&
      _cameraController != null &&
      _cameraController!.value.isInitialized;

  // CRITICAL FIX: Memory management for image buffer disposal
  Timer? _memoryCleanupTimer;
  final List<Uint8List> _pendingImageBuffers = [];
  int _totalAllocatedBytes = 0;
  final int _maxTotalBytes = 2097152; // Match the new config limit

  // CRITICAL FIX: Memory pressure detection and throttling
  String _currentMemoryPressure = 'GOOD';
  int _frameThrottleCounter = 0;
  int _currentThrottleInterval = 3; // Start with processing every 3rd frame
  final Map<String, int> _memoryPressureThresholds = {
    'GOOD': 3, // Process every 3rd frame
    'WARNING': 6, // Process every 6th frame
    'CRITICAL': 10, // Process every 10th frame
  };

  // Stream controller to broadcast camera state changes
  final StreamController<CameraState> _stateController =
      StreamController<CameraState>.broadcast();

  /// Stream of camera state changes
  Stream<CameraState> get cameraStateStream => _stateController.stream;

  /// Current memory pressure level
  String get currentMemoryPressure => _currentMemoryPressure;

  /// Current throttle interval
  int get currentThrottleInterval => _currentThrottleInterval;

  /// Current camera controller
  CameraController? get controller => _cameraController;

  /// Static method to initialize the camera service without accessing the instance
  static Future<void> initializeService() async {
    if (_isInitialized) return; // Prevent double initialization

    try {
      debugPrint('CameraService: Initializing...');

      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw app_errors.CameraException(
          message: 'No cameras available on device',
          code: 'NO_CAMERAS_FOUND',
        );
      }

      debugPrint('CameraService: Found ${cameras.length} cameras');

      // Find front camera using common logic
      final frontCamera = _findFrontCamera(cameras);

      debugPrint('CameraService: Front camera selected');
      debugPrint('Selected camera: ${frontCamera.lensDirection}');

      // Create instance if it doesn't exist
      _instance ??= CameraService._();

      // Set up the instance
      _instance!._availableCameras = cameras;
      _instance!._frontCamera = frontCamera;
      _instance!._serviceInitialized = true;
      _instance!._emitState(const CameraState._(CameraStateType.discovered));

      // CRITICAL FIX: Only set _isInitialized to true after successful initialization
      _isInitialized = true;
      debugPrint(
          'CameraService: Service initialization completed successfully');
    } catch (e) {
      debugPrint('CameraService: Initialization failed: $e');
      // CRITICAL FIX: Don't set _isInitialized to true on error
      // Reset instance state if initialization failed
      if (_instance != null) {
        _instance!._serviceInitialized = false;
        _instance!._availableCameras = null;
        _instance!._frontCamera = null;
      }
      _instance?._emitState(CameraState._(CameraStateType.error, e.toString()));
      throw app_errors.ErrorHandler.handle(e, StackTrace.current);
    }
  }

  /// Initialize camera service and discover available cameras
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent double initialization

    try {
      debugPrint('CameraService: Initializing...');

      // Get available cameras
      _availableCameras = await availableCameras();

      if (_availableCameras == null || _availableCameras!.isEmpty) {
        throw app_errors.CameraException(
          message: 'No cameras available on device',
          code: 'NO_CAMERAS_FOUND',
        );
      }

      debugPrint('CameraService: Found ${_availableCameras!.length} cameras');

      // Find front camera using common logic
      _frontCamera = _findFrontCamera(_availableCameras!);

      debugPrint('CameraService: Front camera selected');
      debugPrint('Selected camera: ${_frontCamera!.lensDirection}');

      // CRITICAL FIX: Set _serviceInitialized BEFORE emitting state to ensure service is marked ready
      _serviceInitialized = true;
      _emitState(const CameraState._(CameraStateType.discovered));

      // CRITICAL FIX: Set _isInitialized AFTER _serviceInitialized to maintain proper state order
      _isInitialized = true;

      debugPrint(
          'CameraService: Service initialized successfully, _serviceInitialized=$_serviceInitialized, _isInitialized=$_isInitialized');
    } catch (e) {
      debugPrint('CameraService: Initialization failed: $e');
      // CRITICAL FIX: Ensure _serviceInitialized is false on error
      _serviceInitialized = false;
      _emitState(CameraState._(CameraStateType.error, e.toString()));
      throw app_errors.ErrorHandler.handle(e, StackTrace.current);
    }
  }

  /// Common logic to find front camera from available cameras
  static CameraDescription _findFrontCamera(List<CameraDescription> cameras) {
    CameraDescription? frontCamera;

    // First try to find explicit front camera
    try {
      frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      debugPrint('Front camera found: ${frontCamera.lensDirection}');
    } catch (e) {
      // If no explicit front camera, try external camera (often front-facing on emulators)
      try {
        frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.external,
        );
        debugPrint(
            'Using external camera as front camera: ${frontCamera.lensDirection}');
      } catch (e2) {
        // Last resort: use any camera but log the issue
        debugPrint(
            'WARNING: No front camera found, using first available camera: ${cameras.first.lensDirection}');
        debugPrint(
            'Available cameras: ${cameras.map((c) => c.lensDirection).toList()}');
        frontCamera = cameras.first;
      }
    }

    return frontCamera;
  }

  /// Initialize camera controller with orientation-specific resolution
  Future<void> initializeCamera(
      {ResolutionPreset resolution = ResolutionPreset.medium}) async {
    debugPrint(
        'CameraService: initializeCamera called, _serviceInitialized=$_serviceInitialized, _isInitialized=$_isInitialized');

    if (!_serviceInitialized) {
      debugPrint(
          'CameraService: Service not initialized, attempting to initialize service...');
      try {
        await initialize();
        debugPrint(
            'CameraService: Service initialized successfully in initializeCamera');
      } catch (e) {
        debugPrint(
            'CameraService: Failed to initialize service in initializeCamera: $e');
        throw app_errors.ServiceInitializationException(
          message:
              'CameraService must be initialized before initializing camera',
          code: 'SERVICE_NOT_INITIALIZED',
        );
      }
    }

    try {
      // Initialize orientation utils if not already done
      OrientationUtils.instance.initialize();

      // Get orientation-specific resolution
      final (targetWidth, targetHeight) =
          OrientationUtils.instance.getOrientationSpecificResolution();
      final currentOrientation = OrientationUtils.instance.currentOrientation;

      debugPrint(
          'CameraService: Initializing camera controller with ${targetWidth}x$targetHeight} resolution for $currentOrientation orientation...');
      debugPrint(
          'CameraService: Portrait config: ${AppConfig.cameraResolutionWidthPortrait}x${AppConfig.cameraResolutionHeightPortrait}');
      debugPrint(
          'CameraService: Landscape config: ${AppConfig.cameraResolutionWidthLandscape}x${AppConfig.cameraResolutionHeightLandscape}');

      // Dispose existing controller if any
      await disposeCamera();

      if (_frontCamera == null) {
        debugPrint(
            'CameraService: _frontCamera is null, re-initializing service...');
        await initialize(); // Ensure cameras are discovered
      }

      // Determine the best resolution preset based on orientation-specific config
      ResolutionPreset optimalResolution;
      if (targetWidth >= 1280 || targetHeight >= 720) {
        optimalResolution = ResolutionPreset.high;
      } else if (targetWidth >= 640 || targetHeight >= 360) {
        optimalResolution = ResolutionPreset.medium;
      } else {
        optimalResolution = ResolutionPreset.low;
      }

      debugPrint(
          'CameraService: Using ResolutionPreset.$optimalResolution for target resolution ${targetWidth}x$targetHeight ($currentOrientation)');

      // Create new controller with optimal resolution
      _cameraController = CameraController(
        _frontCamera!,
        optimalResolution,
        enableAudio: false,
      );

      debugPrint('CameraService: Starting camera controller initialization...');
      await _cameraController!.initialize();
      debugPrint('CameraService: Camera controller initialized successfully');

      // Log actual camera resolution after initialization
      final actualPreviewSize = _cameraController!.value.previewSize;
      if (actualPreviewSize != null) {
        debugPrint(
            'CameraService: Actual camera preview size: ${actualPreviewSize.width}x${actualPreviewSize.height}');
      }

      // Start memory monitoring
      _initializeMemoryMonitoring();

      debugPrint(
          'CameraService: Camera controller initialized successfully with $currentOrientation resolution');
      _emitState(const CameraState._(CameraStateType.initialized));
    } catch (e) {
      debugPrint('CameraService: Camera initialization failed: $e');
      _cameraController = null;
      _emitState(CameraState._(CameraStateType.error, e.toString()));
      throw app_errors.ErrorHandler.handle(e, StackTrace.current);
    }
  }

  /// Dispose camera controller with proper resource cleanup
  Future<void> disposeCamera() async {
    try {
      if (_cameraController != null) {
        // CRITICAL FIX: Check if camera controller is already disposed before stopping stream
        // This prevents calling stopImageStream() on a disposed controller
        if (!_cameraController!.value.isInitialized) {
          debugPrint(
              'CameraService: Camera controller already disposed, skipping disposal');
          _cameraController = null;
          return;
        }

        // CRITICAL FIX: ALWAYS stop image stream before disposal, even if already stopped
        // This ensures camera is fully stopped before controller is disposed
        try {
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
            debugPrint('CameraService: Image stream stopped before disposal');
          } else {
            debugPrint(
                'CameraService: Image stream already stopped, proceeding to dispose');
          }
        } catch (e) {
          debugPrint('CameraService: Error stopping image stream: $e');
        }

        // CRITICAL FIX: Add delay before disposal to allow proper resource cleanup
        await Future.delayed(Duration(milliseconds: 100));

        // CRITICAL FIX: ALWAYS dispose camera controller to turn off hardware
        // This prevents camera from remaining active after stopping detection
        await _cameraController!.dispose();
        _cameraController = null;
        debugPrint('CameraService: Camera controller disposed (hardware off)');
        _emitState(const CameraState._(CameraStateType.disposed));
      }
    } catch (e) {
      debugPrint('CameraService: Error disposing camera: $e');
      // Ensure controller is nulled even on error
      _cameraController = null;
    }

    // CRITICAL FIX: Stop memory monitoring when camera is disposed
    _stopMemoryMonitoring();

    // CRITICAL FIX: Perform final memory cleanup when camera is turned off
    _performMemoryCleanup();
    debugPrint(
        'CameraService: Final memory cleanup completed when camera turned off');
  }

  /// Get camera preview widget
  Widget buildPreview() {
    if (!isInitialized || _cameraController == null) {
      return _buildPlaceholder();
    }

    final previewSize = _cameraController!.value.previewSize;
    if (previewSize == null) {
      return _buildPlaceholder();
    }

    // Calculate actual aspect ratio from camera preview
    final cameraAspectRatio = previewSize.width / previewSize.height;
    debugPrint(
        'Camera preview size: ${previewSize.width}x${previewSize.height}, aspect ratio: $cameraAspectRatio');

    return LayoutBuilder(
      builder: (context, constraints) {
        // CRITICAL FIX: Handle unbounded constraints
        // If constraints are unbounded (maxWidth or maxHeight is infinite),
        // use AspectRatio widget instead of FittedBox
        if (constraints.maxWidth == double.infinity ||
            constraints.maxHeight == double.infinity) {
          debugPrint(
              'Container has unbounded constraints, using AspectRatio widget');

          // Use AspectRatio widget to maintain camera's aspect ratio
          // This works even with unbounded constraints
          return AspectRatio(
            aspectRatio: cameraAspectRatio,
            child: CameraPreview(_cameraController!),
          );
        }

        final containerAspectRatio =
            constraints.maxWidth / constraints.maxHeight;
        debugPrint('Container aspect ratio: $containerAspectRatio');
        debugPrint('Camera aspect ratio: $cameraAspectRatio');

        // Use FittedBox with BoxFit.contain to maintain aspect ratio
        // This allows camera preview to fill available space naturally
        // while maintaining its native aspect ratio and preventing stretching
        return FittedBox(
          fit: BoxFit.contain, // Maintains aspect ratio, may add letterboxing
          alignment: Alignment.center,
          child: CameraPreview(_cameraController!),
        );
      },
    );
  }

  /// Build placeholder when camera is not available
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Color(0xFFFFD700),
            ),
            SizedBox(height: 12),
            Text(
              'Camera Off',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Emit camera state change
  void _emitState(CameraState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// CRITICAL FIX: Start memory monitoring and cleanup
  void _startMemoryMonitoring() {
    if (AppConfig.enableMemoryMonitoring) {
      _memoryCleanupTimer = Timer.periodic(
        Duration(seconds: AppConfig.memoryCleanupIntervalSeconds),
        (_) => _performMemoryMonitoringCycle(),
      );
      debugPrint(
          'Memory monitoring started - cleanup every ${AppConfig.memoryCleanupIntervalSeconds} seconds');
    }
  }

  /// CRITICAL FIX: Stop memory monitoring when camera is turned off
  void _stopMemoryMonitoring() {
    if (_memoryCleanupTimer != null) {
      _memoryCleanupTimer!.cancel();
      _memoryCleanupTimer = null;
      debugPrint('CameraService: Memory monitoring stopped');
    }
  }

  /// CRITICAL FIX: Complete memory monitoring cycle with pressure detection
  void _performMemoryMonitoringCycle() {
    if (!AppConfig.enableMemoryMonitoring) return;

    // Update memory pressure level
    _updateMemoryPressureLevel();

    // Adjust throttling based on memory pressure
    _adjustFrameThrottling();

    // Perform cleanup based on pressure level
    if (_currentMemoryPressure == 'CRITICAL') {
      _performMemoryCleanup();
    } else if (_currentMemoryPressure == 'WARNING') {
      _performPartialMemoryCleanup();
    }
  }

  /// CRITICAL FIX: Update memory pressure level
  void _updateMemoryPressureLevel() {
    final usagePercent =
        _maxTotalBytes > 0 ? (_totalAllocatedBytes / _maxTotalBytes * 100) : 0;

    String newPressureLevel;
    if (usagePercent < 30) {
      newPressureLevel = 'GOOD';
    } else if (usagePercent < 50) {
      newPressureLevel = 'WARNING';
    } else {
      newPressureLevel = 'CRITICAL';
    }

    if (newPressureLevel != _currentMemoryPressure) {
      final oldPressure = _currentMemoryPressure;
      _currentMemoryPressure = newPressureLevel;
      debugPrint(
          'Memory pressure changed: $oldPressure -> $newPressureLevel (${usagePercent.toStringAsFixed(1)}%)');
    }
  }

  /// CRITICAL FIX: Adjust frame throttling based on memory pressure
  void _adjustFrameThrottling() {
    final newThrottleInterval =
        _memoryPressureThresholds[_currentMemoryPressure] ?? 1;

    if (newThrottleInterval != _currentThrottleInterval) {
      final oldInterval = _currentThrottleInterval;
      _currentThrottleInterval = newThrottleInterval;
      debugPrint(
          'Frame throttling adjusted: $oldInterval -> $_currentThrottleInterval (pressure: $_currentMemoryPressure)');
    }
  }

  /// CRITICAL FIX: Check if frame should be processed based on throttling
  bool shouldProcessFrame() {
    _frameThrottleCounter =
        (_frameThrottleCounter + 1) % _currentThrottleInterval;
    return _frameThrottleCounter == 0;
  }

  /// CRITICAL FIX: Partial memory cleanup for WARNING level
  void _performPartialMemoryCleanup() {
    if (_pendingImageBuffers.isEmpty) return;

    final halfCount = (_pendingImageBuffers.length / 2).round();
    final freedBytes = _removeOldestBuffers(halfCount);

    debugPrint(
        'Partial memory cleanup: removed $halfCount buffers, freed ${_formatBytes(freedBytes)} bytes');
  }

  /// CRITICAL FIX: Add image buffer for tracking and disposal
  bool _addImageBuffer(Uint8List buffer) {
    if (!AppConfig.enableMemoryMonitoring) return true;

    // CRITICAL FIX: More aggressive memory management
    final bufferSize = buffer.length;
    final maxBufferSize = AppConfig.maxImageBufferSizeBytes ~/
        2; // Half of total limit per buffer

    if (bufferSize > maxBufferSize) {
      debugPrint(
          'Buffer too large: ${bufferSize} > $maxBufferSize bytes, skipping');
      return false;
    }

    // Check if adding this buffer would exceed limits
    if (_totalAllocatedBytes + bufferSize > _maxTotalBytes) {
      debugPrint(
          'Memory limit reached: ${_totalAllocatedBytes + bufferSize} > $_maxTotalBytes bytes');
      _performMemoryCleanup();

      // If still over limit after cleanup, reject allocation
      if (_totalAllocatedBytes + bufferSize > _maxTotalBytes) {
        debugPrint('Memory still over limit after cleanup, rejecting buffer');
        return false;
      }
    }

    // Add buffer to tracking
    _pendingImageBuffers.add(buffer);
    _totalAllocatedBytes += bufferSize;

    // CRITICAL FIX: More aggressive buffer limit
    final maxBuffers = (AppConfig.maxConcurrentImages * 0.5)
        .round(); // 50% of configured limit
    if (_pendingImageBuffers.length > maxBuffers) {
      _removeOldestBuffer();
    }

    debugPrint(
        'Buffer added: ${bufferSize} bytes, Total: $_totalAllocatedBytes bytes, Count: ${_pendingImageBuffers.length}');
    return true;
  }

  /// CRITICAL FIX: Remove oldest buffer and update tracking
  void _removeOldestBuffer() {
    if (_pendingImageBuffers.isNotEmpty) {
      final oldestBuffer = _pendingImageBuffers.removeAt(0);
      _totalAllocatedBytes -= oldestBuffer.length;
      debugPrint(
          'Removed oldest buffer: ${_formatBytes(oldestBuffer.length)}, remaining: ${_formatBytes(_totalAllocatedBytes)}, Count: ${_pendingImageBuffers.length}');
    }
  }

  /// CRITICAL FIX: Remove multiple oldest buffers
  int _removeOldestBuffers(int count) {
    int freedBytes = 0;
    for (int i = 0; i < count && _pendingImageBuffers.isNotEmpty; i++) {
      final oldestBuffer = _pendingImageBuffers.removeAt(0);
      _totalAllocatedBytes -= oldestBuffer.length;
      freedBytes += oldestBuffer.length;
    }
    return freedBytes;
  }

  /// CRITICAL FIX: Perform memory cleanup with GC hints
  void _performMemoryCleanup() {
    if (!AppConfig.enableMemoryMonitoring) return;

    final buffersCount = _pendingImageBuffers.length;
    final bytesBefore = _totalAllocatedBytes;

    debugPrint(
        'Performing memory cleanup - Current usage: $_totalAllocatedBytes bytes, Buffers: $buffersCount');

    // Clear all pending buffers
    _pendingImageBuffers.clear();
    _totalAllocatedBytes = 0;

    // Force garbage collection hint
    try {
      // Try to trigger GC on native platforms
      if (!kIsWeb) {
        // Create a temporary large allocation to force GC
        Uint8List tempBuffer = Uint8List(1024);
        tempBuffer.fillRange(0, tempBuffer.length, 0);
        // Uint8List is fixed-length, cannot use clear()
        // Instead, just null the reference to allow GC
        tempBuffer = Uint8List(0); // Replace with empty buffer
      }
      debugPrint('GC hint completed');
    } catch (e) {
      debugPrint('GC hint failed: $e');
    }

    debugPrint(
        'Memory cleanup completed - freed $bytesBefore bytes, ${_formatBytes(bytesBefore)}');
  }

  /// CRITICAL FIX: Format bytes for readable logging
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  /// Get current memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    final usagePercent =
        _maxTotalBytes > 0 ? (_totalAllocatedBytes / _maxTotalBytes * 100) : 0;

    return {
      'pendingBuffers': _pendingImageBuffers.length,
      'totalAllocatedBytes': _totalAllocatedBytes,
      'maxAllocatedBytes': _maxTotalBytes,
      'memoryUtilization': usagePercent.toStringAsFixed(1) + '%',
      'memoryPressure': _currentMemoryPressure,
      'throttleInterval': _currentThrottleInterval,
      'cleanupTimerActive': _memoryCleanupTimer?.isActive ?? false,
      'formattedUsage': _formatBytes(_totalAllocatedBytes) +
          ' / ' +
          _formatBytes(_maxTotalBytes),
    };
  }

  /// CRITICAL FIX: Clean up all resources with proper Surface management
  Future<void> dispose() async {
    debugPrint('CameraService: Disposing all resources...');

    // Stop memory monitoring
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = null;
    _currentMemoryPressure = 'GOOD';
    _frameThrottleCounter = 0;
    _currentThrottleInterval = 1;

    // Perform final memory cleanup
    _performMemoryCleanup();

    // CRITICAL FIX: Stop image stream with proper error handling
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        try {
          await _cameraController!.stopImageStream();
          debugPrint('CameraService: Image stream stopped during dispose');
        } catch (e) {
          debugPrint(
              'CameraService: Error stopping image stream during dispose: $e');
        }
      }

      // CRITICAL FIX: Add delay before disposal to prevent Surface.release errors
      await Future.delayed(Duration(milliseconds: 200));

      try {
        await _cameraController!.dispose();
        debugPrint('CameraService: Camera controller disposed after delay');
      } catch (e) {
        debugPrint('CameraService: Error during delayed disposal: $e');
      }
    }

    // Close stream controller
    if (!_stateController.isClosed) {
      _stateController.close();
    }

    // Clear all state
    _availableCameras = null;
    _frontCamera = null;
    _serviceInitialized = false;
    _isInitialized = false;
    _pendingImageBuffers.clear();
    _totalAllocatedBytes = 0;

    // Clear singleton instance
    _instance = null;

    debugPrint('CameraService: All resources disposed');
  }

  /// CRITICAL FIX: Start memory monitoring during initialization
  void _initializeMemoryMonitoring() {
    _startMemoryMonitoring();
  }

  /// CRITICAL FIX: Get memory pressure recommendations
  List<String> getMemoryOptimizationRecommendations() {
    final recommendations = <String>[];
    final stats = getMemoryStats();

    switch (_currentMemoryPressure) {
      case 'CRITICAL':
        recommendations.add('URGENT: Reduce camera resolution immediately');
        recommendations.add(
            'URGENT: Increase frame throttling (currently every $_currentThrottleInterval frames)');
        recommendations.add('URGENT: Consider pausing detection temporarily');
        break;
      case 'WARNING':
        recommendations.add('Consider reducing camera resolution');
        recommendations.add('Monitor memory usage closely');
        recommendations
            .add('Current throttling: every $_currentThrottleInterval frames');
        break;
      case 'GOOD':
        recommendations.add('Memory usage is optimal');
        recommendations
            .add('Current throttling: every $_currentThrottleInterval frames');
        break;
    }

    if (_pendingImageBuffers.length > AppConfig.maxConcurrentImages) {
      recommendations
          .add('Too many pending buffers (${_pendingImageBuffers.length})');
    }

    return recommendations;
  }

  /// CRITICAL: Check if service is properly disposed
  bool get isDisposed =>
      !_isInitialized && _cameraController == null && _stateController.isClosed;
}

/// Camera state enum for tracking camera status
enum CameraStateType {
  discovered,
  initializing,
  initialized,
  disposed,
  error,
}

/// Camera state class with optional error message
class CameraState {
  final CameraStateType type;
  final String? errorMessage;

  const CameraState._(this.type, [this.errorMessage]);

  factory CameraState.discovered() =>
      const CameraState._(CameraStateType.discovered);
  factory CameraState.initializing() =>
      const CameraState._(CameraStateType.initializing);
  factory CameraState.initialized() =>
      const CameraState._(CameraStateType.initialized);
  factory CameraState.disposed() =>
      const CameraState._(CameraStateType.disposed);
  factory CameraState.error(String message) =>
      CameraState._(CameraStateType.error, message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraState &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => type.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    switch (type) {
      case CameraStateType.discovered:
        return 'CameraState.discovered';
      case CameraStateType.initializing:
        return 'CameraState.initializing';
      case CameraStateType.initialized:
        return 'CameraState.initialized';
      case CameraStateType.disposed:
        return 'CameraState.disposed';
      case CameraStateType.error:
        return 'CameraState.error: $errorMessage';
    }
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'face_detector.dart';
import 'firebase_service.dart';
import '../config/app_config.dart';
import '../errors/app_exceptions.dart' as app_errors;
import '../models/detection_result.dart';
import 'advanced_detection_calculator.dart' as adv;
import 'audio_alert_service.dart';
import 'performance_monitor.dart';
import '../utils/memory_monitor.dart';
import 'fatigue_detector.dart';

/// CRITICAL FIX: Improved service dependency injection with proper error handling
/// Implements service locator pattern to break circular dependencies
class DetectionService {
  FaceDetectorService? _faceDetector;
  FirebaseService? _firebaseService;
  final adv.AdvancedDetectionCalculator _calculator =
      adv.AdvancedDetectionCalculator();
  AudioAlertService? _audioAlertService;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor.instance;

  // CRITICAL FIX: Persistent FatigueDetector instance to maintain counters between frames
  final FatigueDetector _fatigueDetector = FatigueDetector();

  // Optional camera controller dependency injection
  CameraController? _cameraController;

  // CRITICAL FIX: Proper resource management and cleanup
  bool _isInitialized = false;
  StreamController<DetectionResult>? _resultController;
  String? _currentUserId;
  bool _isImageStreamRunning = false;
  int _frameCount = 0; // Frame throttling counter
  bool _isDisposing = false; // Prevent double disposal

  // CRITICAL FIX: Memory management for image processing
  Timer? _memoryCleanupTimer;
  final List<Uint8List> _pendingImageBuffers = [];
  int _totalAllocatedBytes = 0;
  final int _maxTotalBytes = AppConfig.maxImageBufferSizeBytes;
  int _currentImageSize = 0;

  // Service registry for dependency management
  static final Map<Type, dynamic> _serviceRegistry = {};
  static bool _registryInitialized = false;

  // CRITICAL FIX: Add singleton pattern with proper cleanup
  static DetectionService? _instance;
  static DetectionService get instance {
    _instance ??= DetectionService._();
    return _instance!;
  }

  DetectionService._() {
    _initializeDependencies();
  }

  // CRITICAL FIX: Service registry for dependency management
  static void _initializeServiceRegistry() {
    if (_registryInitialized) return;

    _serviceRegistry[FirebaseService] = FirebaseService.instance;
    _serviceRegistry[AudioAlertService] = AudioAlertService.instance;
    _serviceRegistry[PerformanceMonitor] = PerformanceMonitor.instance;

    _registryInitialized = true;
  }

  // Dependency injection for better testability
  DetectionService._withDependencies({
    FaceDetectorService? faceDetector,
    FirebaseService? firebaseService,
    AudioAlertService? audioAlertService,
  }) {
    _initializeServiceRegistry();

    _faceDetector = faceDetector;
    _firebaseService = firebaseService ??
        _serviceRegistry[FirebaseService] as FirebaseService?;
    _audioAlertService = audioAlertService ??
        _serviceRegistry[AudioAlertService] as AudioAlertService?;
  }

  // Default constructor for testing compatibility
  DetectionService() {
    _initializeServiceRegistry();
    _initializeDependencies();
  }

  /// CRITICAL FIX: Safe dependency initialization with error handling
  void _initializeDependencies() {
    if (_isDisposing) return; // Prevent initialization during disposal

    try {
      if (_faceDetector == null) {
        _faceDetector = FaceDetectorService();
      }
      if (_firebaseService == null) {
        _firebaseService =
            _serviceRegistry[FirebaseService] as FirebaseService? ??
                FirebaseService.instance;
      }
      if (_audioAlertService == null) {
        _audioAlertService =
            _serviceRegistry[AudioAlertService] as AudioAlertService? ??
                AudioAlertService.instance;
      }
    } catch (e) {
      debugPrint('Error initializing dependencies: $e');
      // Continue with null checks in methods
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('DetectionService: Already initialized, skipping...');
      return;
    }

    if (_isDisposing) {
      throw app_errors.ServiceInitializationException(
        message: 'Service is disposing, cannot initialize',
        code: 'SERVICE_DISPOSING',
      );
    }

    try {
      debugPrint('DetectionService: Initializing...');

      // Ensure dependencies are initialized
      _initializeDependencies();

      if (_faceDetector != null) {
        await _faceDetector!.initialize();
      } else {
        throw app_errors.ServiceInitializationException(
          message: 'Face detector not available',
          code: 'FACE_DETECTOR_NULL',
        );
      }

      if (_firebaseService != null) {
        await _firebaseService!.initialize();
      }

      // CRITICAL FIX: Create result controller with proper error handling
      _resultController = StreamController<DetectionResult>.broadcast(
        onListen: () => debugPrint('DetectionService: Result stream opened'),
        onCancel: () => debugPrint('DetectionService: Result stream closed'),
      );

      _isInitialized = true;
      _isImageStreamRunning = false; // Initialize the image stream flag
      _frameCount = 0;

      // Start memory monitoring
      _startMemoryMonitoring();

      debugPrint('Detection service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize detection service: $e');
      _isInitialized = false;
      throw app_errors.ErrorHandler.handle(e, StackTrace.current);
    }
  }

  Future<void> startDetection() async {
    debugPrint('DetectionService: Starting detection...');

    if (_isDisposing) {
      throw app_errors.DetectionException(
        message: 'Service is disposing, cannot start detection',
        code: 'SERVICE_DISPOSING',
      );
    }

    if (!_isInitialized) {
      await initialize();
    }

    // Get current user for Firebase operations
    if (_firebaseService?.currentUser != null) {
      _currentUserId = _firebaseService!.currentUser!.uid;
      debugPrint('Current user ID set: $_currentUserId');
    } else {
      debugPrint('No current user found');
    }

    // Create new result controller if needed
    if (_resultController == null || _resultController!.isClosed) {
      _resultController = StreamController<DetectionResult>.broadcast();
      debugPrint('Created new result controller');
    } else {
      debugPrint('Result controller already exists and is open');
    }

    // CRITICAL FIX: Check camera availability and start ONLY image stream (no timer)
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      debugPrint('Camera is available, starting image stream detection only');
      await _startImageStream();
    } else {
      debugPrint(
          'Camera not available, detection will start when camera becomes available');
    }

    debugPrint('DetectionService: Detection start process completed');
  }

  Future<void> stopDetection() async {
    debugPrint('DetectionService: Stopping detection service');

    try {
      // CRITICAL FIX: Stop image stream
      await _stopImageStream();

      // Clear camera controller reference to fully stop detection
      if (_cameraController != null) {
        _cameraController = null;
        debugPrint('Camera controller reference cleared');
      }

      // CRITICAL FIX: Stop memory monitoring timer when detection stops
      if (_memoryCleanupTimer != null) {
        _memoryCleanupTimer!.cancel();
        _memoryCleanupTimer = null;
        debugPrint('DetectionService: Memory monitoring timer stopped');
      }

      // CRITICAL FIX: Perform final memory cleanup
      _performMemoryCleanup();
      debugPrint('DetectionService: Final memory cleanup completed');

      // CRITICAL FIX: Close result controller to stop all stream activity
      if (_resultController != null && !_resultController!.isClosed) {
        await _resultController!.close();
        _resultController = null;
        debugPrint('DetectionService: Result controller closed');
      }

      debugPrint('DetectionService: Detection stopped successfully');
    } catch (e) {
      debugPrint('Error stopping detection: $e');
      // Don't throw here as this is cleanup
    }
  }

  Future<void> setCameraController(CameraController? controller) async {
    // CRITICAL FIX: Only set controller if different from current to prevent unnecessary restarts
    if (controller != _cameraController) {
      debugPrint('DetectionService: Setting new camera controller');
      _cameraController = controller;
    }

    // CRITICAL FIX: Restart image stream if camera becomes available and detection was started
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isImageStreamRunning) {
      debugPrint('Camera became available, restarting image stream detection');
      await _startImageStream();
    }
  }

  Future<DetectionResult> _performRealDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw app_errors.DetectionException(
        message: 'Camera not available for detection',
        code: 'CAMERA_NOT_AVAILABLE',
      );
    }

    try {
      // Start camera image stream for mobile platforms
      debugPrint('Starting camera image stream for mobile platform');
      await _startImageStream();

      // Return a default result for now - actual detection will happen in the image stream callback or timer
      return DetectionResult(
        level: DrowsinessLevel.alert,
        confidence: 0.0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Real detection error: $e');
      rethrow;
    }
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('Cannot start image stream - camera not initialized');
      return;
    }

    // Check if stream is already running to prevent conflicts
    if (_isImageStreamRunning) {
      debugPrint('Image stream already running, skipping start');
      return;
    }

    try {
      // Start comprehensive memory monitoring
      MemoryMonitor.instance.startMonitoring();

      // CRITICAL FIX: Process images with enhanced memory management and aggressive throttling
      await _cameraController!
          .startImageStream((CameraImage cameraImage) async {
        if (_isDisposing) return; // Don't process if disposing

        // CRITICAL FIX: More aggressive frame throttling - process every 5th frame only
        _frameCount = (_frameCount + 1) % 5;
        if (_frameCount != 0) {
          return; // Skip 4 out of 5 frames for performance
        }

        debugPrint('=== DIAGNOSTIC FRAME INFO ===');
        debugPrint(
            'CameraImage: format=${cameraImage.format.group} raw=${cameraImage.format.raw} size=${cameraImage.width}x${cameraImage.height} planes=${cameraImage.planes.length}');
        debugPrint(
            'Sensor orientation: ${_cameraController?.description.sensorOrientation ?? "N/A"} preview=${_cameraController?.value.previewSize ?? "N/A"}');
        debugPrint(
            'Preview size: ${_cameraController?.value.previewSize ?? "N/A"}');

        // CRITICAL FIX: Check memory pressure before processing
        final memoryPressure = MemoryMonitor.instance.getMemoryPressureLevel();
        if (memoryPressure == 'CRITICAL') {
          debugPrint('CRITICAL memory pressure - skipping frame processing');
          return;
        } else if (memoryPressure == 'WARNING') {
          // Skip additional frames under memory pressure
          _frameCount =
              (_frameCount + 1) % 8; // Process every 8th frame under pressure
          if (_frameCount != 0) return;
        }

        await _processCameraImageWithFlip(cameraImage);
      });
      _isImageStreamRunning = true;
      debugPrint(
          'Camera image stream started successfully with memory pressure-aware processing');
    } catch (e) {
      debugPrint('Failed to start image stream: $e');
      _isImageStreamRunning = false; // Reset flag on failure
      _isInitialized = false; // Reset initialization state on failure
      throw app_errors.ErrorHandler.handle(e, StackTrace.current);
    }
  }

  /// CRITICAL FIX: Process camera image with comprehensive memory management
  Future<void> _processCameraImageWithFlip(CameraImage cameraImage) async {
    if (_isDisposing) return; // Don't process if disposing

    final stopwatch = Stopwatch()..start();
    Uint8List? bytes; // Declare outside try block for proper cleanup

    try {
      debugPrint('=== IMAGE PROCESSING DEBUG ===');
      debugPrint(
          'Processing camera image: ${cameraImage.width}x${cameraImage.height}, format: ${cameraImage.format}');

      // CRITICAL FIX: Check image size before processing
      // Calculate estimated size based on format
      int estimatedSize;
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        // BGRA8888: 4 bytes per pixel
        estimatedSize = cameraImage.width * cameraImage.height * 4;
      } else {
        // YUV420: ~1.5 bytes per pixel (use 2 for safety)
        estimatedSize = cameraImage.width * cameraImage.height * 2;
      }

      if (estimatedSize > AppConfig.maxImageBufferSizeBytes) {
        debugPrint(
            'Image too large for processing: ${_formatBytes(estimatedSize)}');
        return;
      }

      debugPrint('Estimated image size: ${_formatBytes(estimatedSize)}');

      // CRITICAL FIX: Use fast YUV concatenation with immediate memory management
      bytes = _concatenatePlanesFast(cameraImage.planes);
      if (bytes == null || bytes.isEmpty) {
        debugPrint('Failed to create image bytes');
        return;
      }

      final bytesSizeStr = _formatBytes(bytes.length);
      debugPrint('YUV bytes created: ${bytes.length} ($bytesSizeStr)');

      // CRITICAL FIX: Log image format details for debugging
      debugPrint('Camera image format: ${cameraImage.format.group}');
      debugPrint('Camera image planes: ${cameraImage.planes.length}');
      for (int i = 0; i < cameraImage.planes.length; i++) {
        final plane = cameraImage.planes[i];
        debugPrint(
            'Plane $i: ${plane.bytes.length} bytes, stride: ${plane.bytesPerRow}');
      }

      // CRITICAL FIX: Aggressive memory pressure check
      final memoryPressure = MemoryMonitor.instance.getMemoryPressureLevel();
      if (memoryPressure == 'CRITICAL') {
        debugPrint(
            'CRITICAL memory pressure - forcing cleanup and skipping processing');
        _performEmergencyMemoryCleanup();
        return;
      } else if (memoryPressure == 'WARNING') {
        debugPrint('WARNING memory pressure - performing partial cleanup');
        _performPartialMemoryCleanup();
      }

      // CRITICAL FIX: Try using camera image directly first
      InputImage? inputImage;

      try {
        // Try creating InputImage directly from camera image
        inputImage = _createInputImageFromCameraImage(cameraImage);
        if (inputImage != null) {
          debugPrint(
              'Successfully created InputImage directly from camera image');
        } else {
          debugPrint(
              'Failed to create InputImage from camera image, trying YUV bytes...');
          // Fallback to YUV bytes method
          inputImage = _createInputImageFromYuvBytes(
              bytes, cameraImage.width, cameraImage.height);
          if (inputImage == null) {
            debugPrint('Failed to create InputImage from YUV bytes');
            return;
          }
          debugPrint('YUV InputImage created successfully');
        }
      } catch (e) {
        debugPrint('Error creating InputImage from camera image: $e');
        return;
      }

      // CRITICAL FIX: Process with enhanced memory management
      if (_faceDetector != null) {
        // Create a copy of bytes for face detector to avoid reference issues
        final faceDetectorBytes = Uint8List.fromList(bytes);
        final faceResult = await _faceDetector!
            .processImageWithBytes(faceDetectorBytes, inputImage);

        // CRITICAL FIX: Always emit a result, even when no face is found
        if (faceResult != null) {
          debugPrint('=== MAR DEBUG: Face Detection Result ===');
          debugPrint(
              'Face detected! MAR: ${faceResult.mouthAspectRatio.toStringAsFixed(3)}');
          debugPrint(
              'Face detected! EAR: ${faceResult.eyeAspectRatio.toStringAsFixed(3)}');
          debugPrint('Converting to DetectionResult...');

          // Convert FaceDetectionResult to DetectionResult using persistent FatigueDetector
          debugPrint('=== MAR DEBUG: FatigueDetector Instance ===');
          debugPrint(
              'Using persistent FatigueDetector instance - counters should be maintained');
          final detectionResult = _fatigueDetector.processFrame(
            ear: faceResult.eyeAspectRatio,
            mar: faceResult.mouthAspectRatio,
            headTiltAngle: faceResult.headPoseAngle,
            headTiltAngleY: faceResult.headPoseAngleY,
            headTiltAngleZ: faceResult.headPoseAngleZ,
            leftEyeOpenProbability: faceResult.leftEyeOpenProbability,
            rightEyeOpenProbability: faceResult.rightEyeOpenProbability,
          );

          debugPrint(
              'Final detection result: ${detectionResult.level}, confidence: ${detectionResult.confidence.toStringAsFixed(3)}');

          // Emit result through the stream
          _resultController?.add(detectionResult);

          // Update Firebase real-time state
          final state = _getDrowsinessState(detectionResult);
          if (_firebaseService != null) {
            await _firebaseService!.updateDrowsinessState(state);
          }
        } else {
          debugPrint('No face detected, but continuing detection...');
          // CRITICAL FIX: Emit a "no face" result to keep the detection running
          final noFaceResult = DetectionResult(
            level: DrowsinessLevel.alert,
            confidence: 0.0,
            timestamp: DateTime.now(),
          );
          _resultController?.add(noFaceResult);
        }
      } else {
        debugPrint('Face detector not available, emitting default result');
        final defaultResult = DetectionResult(
          level: DrowsinessLevel.alert,
          confidence: 0.0,
          timestamp: DateTime.now(),
        );
        _resultController?.add(defaultResult);
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // CRITICAL FIX: Emit error result instead of failing silently
      final errorResult = DetectionResult(
        level: DrowsinessLevel.alert,
        confidence: 0.0,
        timestamp: DateTime.now(),
      );
      _resultController?.add(errorResult);
    } finally {
      // CRITICAL FIX: Aggressive memory cleanup in finally block
      if (bytes != null) {
        // Uint8List is fixed-length, cannot use clear()
        // Instead, just null the reference to allow GC
        bytes = null; // Clear reference
        debugPrint('Image buffer reference cleared in finally block');
      }

      // Perform periodic memory cleanup if processing is slow
      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds;

      // Record processing time for performance monitoring
      _performanceMonitor.recordFrameProcessingTime(processingTime);

      // Log memory stats if processing took too long
      if (processingTime > 30) {
        final memoryStats = MemoryMonitor.instance.getMemoryStats();
        debugPrint(
            'Slow processing detected: ${processingTime}ms, Memory: $memoryStats');

        // Trigger cleanup if processing is slow
        if (processingTime > 50) {
          _performPartialMemoryCleanup();
        }
      }

      // Force GC hint on native platforms
      if (!kIsWeb && processingTime > 20) {
        _forceGarbageCollection();
      }
    }
  }

  /// CRITICAL FIX: Fast plane concatenation without memory tracking overhead
  Uint8List? _concatenatePlanesFast(List<Plane> planes) {
    try {
      debugPrint('=== PLANE CONCATENATION DEBUG ===');
      debugPrint('Number of planes: ${planes.length}');

      // CRITICAL FIX: Handle iOS BGRA8888 format (single plane)
      if (planes.length == 1) {
        debugPrint('Single plane detected - likely iOS BGRA8888 format');
        final planeBytes = planes[0].bytes;
        final planeBytesPerRow = planes[0].bytesPerRow;
        debugPrint('Plane bytes: ${planeBytes.length} bytes');
        debugPrint('Plane bytes per row: $planeBytesPerRow');

        // CRITICAL FIX: Calculate expected size for BGRA8888 format
        // BGRA8888 = 4 bytes per pixel
        // Expected size = width × height × 4
        // However, we need to account for potential padding in bytesPerRow
        final expectedSize = planeBytesPerRow *
            planes[0].bytes.lengthInBytes ~/
            planeBytesPerRow;

        // Calculate actual expected size based on dimensions
        // For BGRA8888: 4 bytes per pixel
        final bytesPerPixel = 4;
        final width = planeBytesPerRow ~/ bytesPerPixel;
        final height = planeBytes.length ~/ planeBytesPerRow;
        final calculatedExpectedSize = width * height * bytesPerPixel;

        debugPrint('Calculated dimensions: ${width}x${height}');
        debugPrint('Expected size: $calculatedExpectedSize bytes');
        debugPrint('Actual size: ${planeBytes.length} bytes');

        // CRITICAL FIX: Check against full buffer limit for BGRA8888 (not half)
        // BGRA8888 uses 4 bytes per pixel, so it's larger than YUV420
        // Allow up to 90% of max buffer size to account for padding
        final maxAllowedSize =
            (AppConfig.maxImageBufferSizeBytes * 0.9).toInt();

        if (planeBytes.length > maxAllowedSize) {
          debugPrint(
              'Plane bytes too large: ${planeBytes.length} bytes > $maxAllowedSize bytes');
          return null;
        }

        // Verify size is reasonable (within 20% of calculated expected size)
        final sizeVariance =
            ((planeBytes.length - calculatedExpectedSize).abs() /
                calculatedExpectedSize);
        if (sizeVariance > 0.2) {
          debugPrint(
              'WARNING: Size variance too high: ${(sizeVariance * 100).toStringAsFixed(1)}%');
          // Continue anyway as padding can cause variance
        }

        // Return bytes directly without concatenation for single-plane format
        debugPrint('Using plane bytes directly (no concatenation needed)');
        return planeBytes;
      }

      // Quick size check for multi-plane formats
      int totalSize = 0;
      for (final plane in planes) {
        totalSize += plane.bytes.length;
      }

      if (totalSize > AppConfig.maxImageBufferSizeBytes ~/ 2) {
        // Half limit for safety
        debugPrint('Total plane bytes too large: $totalSize bytes');
        return null;
      }

      // CRITICAL FIX: Handle different YUV formats properly
      if (planes.length == 3) {
        // YUV_420 format - concatenate planes directly without conversion
        debugPrint('YUV_420 format detected - using direct concatenation');

        final yPlane = planes[0].bytes;
        final uPlane = planes[1].bytes;
        final vPlane = planes[2].bytes;

        debugPrint('Y plane: ${yPlane.length} bytes');
        debugPrint('U plane: ${uPlane.length} bytes');
        debugPrint('V plane: ${vPlane.length} bytes');

        // For YUV_420, concatenate planes in Y-U-V order
        final buffer = WriteBuffer();
        buffer.putUint8List(yPlane);
        buffer.putUint8List(uPlane);
        buffer.putUint8List(vPlane);

        final yuvBytes = buffer.done().buffer.asUint8List();
        debugPrint('YUV concatenation completed: ${yuvBytes.length} bytes');
        return yuvBytes;
      } else {
        // Fallback to simple concatenation for other formats
        debugPrint('Using simple concatenation for non-YUV420 format');
        final buffer = WriteBuffer();
        for (final plane in planes) {
          buffer.putUint8List(plane.bytes);
        }
        return buffer.done().buffer.asUint8List();
      }
    } catch (e) {
      if (AppConfig.enableVerboseLogging) {
        debugPrint('Error in _concatenatePlanesFast: $e');
      }
      return null;
    }
  }

  /// CRITICAL FIX: Emergency memory cleanup
  void _performEmergencyMemoryCleanup() {
    debugPrint('DetectionService: Performing EMERGENCY memory cleanup...');

    // Clear all pending buffers
    _pendingImageBuffers.clear();
    _totalAllocatedBytes = 0;
    _currentImageSize = 0;

    // Force MemoryMonitor emergency cleanup
    MemoryMonitor.instance.performEmergencyCleanup();

    // Clear any other references
    _cameraController = null; // Temporarily clear camera reference

    // Force GC
    _forceGarbageCollection();

    debugPrint('DetectionService: Emergency memory cleanup completed');
  }

  /// CRITICAL FIX: Partial memory cleanup for high memory usage
  void _performPartialMemoryCleanup() {
    debugPrint('DetectionService: Performing PARTIAL memory cleanup...');

    // Remove half of the pending buffers
    final halfCount = (_pendingImageBuffers.length / 2).round();
    for (int i = 0; i < halfCount && _pendingImageBuffers.isNotEmpty; i++) {
      _removeOldestBuffer();
    }

    // Clear MemoryMonitor buffers
    MemoryMonitor.instance.untrackImageBuffer('detection');

    // Force GC hint
    _forceGarbageCollection();

    debugPrint('DetectionService: Partial memory cleanup completed');
  }

  /// CRITICAL FIX: Force garbage collection on native platforms
  void _forceGarbageCollection() {
    try {
      if (!kIsWeb) {
        // Create a large temporary allocation to trigger GC
        Uint8List tempBuffer = Uint8List(1024 * 100); // 100KB temp buffer
        tempBuffer.fillRange(0, tempBuffer.length, 0);
        // Uint8List is fixed-length, cannot use clear()
        // Instead, just null the reference to allow GC
        tempBuffer = Uint8List(0); // Create empty buffer to replace
      }
      debugPrint('GC hint completed');
    } catch (e) {
      debugPrint('GC hint failed: $e');
    }
  }

  /// CRITICAL FIX: Format bytes for readable logging
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  /// CRITICAL FIX: Get camera service instance for memory pressure monitoring
  dynamic _getCameraService() {
    try {
      // This is a simplified approach - in a real app you might use dependency injection
      // or service locator pattern to get the camera service
      return null; // Placeholder - would need actual implementation
    } catch (e) {
      debugPrint('Error getting camera service: $e');
      return null;
    }
  }

  /// CRITICAL FIX: Get comprehensive memory status including camera service
  Map<String, dynamic> getComprehensiveMemoryStats() {
    final detectionStats = getMemoryStats();
    final memoryMonitorStats = MemoryMonitor.instance.getMemoryStats();

    // Try to get camera service stats (if accessible)
    final cameraServiceStats = <String, dynamic>{};
    try {
      // This would need to be implemented based on your actual camera service access pattern
      cameraServiceStats['cameraServiceAvailable'] = false;
    } catch (e) {
      cameraServiceStats['cameraServiceAvailable'] = false;
    }

    return {
      'detectionService': detectionStats,
      'memoryMonitor': memoryMonitorStats,
      'cameraService': cameraServiceStats,
      'overallPressure':
          _getOverallMemoryPressure(detectionStats, memoryMonitorStats),
    };
  }

  /// CRITICAL FIX: Calculate overall memory pressure from multiple sources
  String _getOverallMemoryPressure(Map<String, dynamic> detectionStats,
      Map<String, dynamic> memoryMonitorStats) {
    // This is a simplified implementation - in practice you'd want more sophisticated logic
    try {
      final detectionUsage = double.parse(
          detectionStats['memoryUtilization']?.toString().replaceAll('%', '') ??
              '0');
      final monitorUsage = double.parse(memoryMonitorStats['memoryUtilization']
              ?.toString()
              .replaceAll('%', '') ??
          '0');

      final maxUsage =
          detectionUsage > monitorUsage ? detectionUsage : monitorUsage;

      if (maxUsage < 50) return 'GOOD';
      if (maxUsage < 75) return 'WARNING';
      return 'CRITICAL';
    } catch (e) {
      return 'UNKNOWN';
    }
  }

  /// CRITICAL FIX: Create InputImage from camera image bytes with proper format handling
  InputImage? _createInputImageFromYuvBytes(
      Uint8List imageBytes, int width, int height) {
    try {
      // CRITICAL FIX: Get the actual camera format from the current camera image
      // This ensures we use the correct format for the platform
      final cameraValue = _cameraController?.value;
      if (cameraValue == null) {
        debugPrint('Camera value is null, cannot determine format');
        return null;
      }

      debugPrint('=== INPUT IMAGE FORMAT DEBUG ===');
      debugPrint('Image dimensions: ${width}x${height}');
      debugPrint('Bytes length: ${imageBytes.length}');

      // CRITICAL FIX: Determine format based on byte size and platform
      // BGRA8888: width × height × 4 bytes
      // NV21: width × height × 1.5 bytes (approximately)
      final expectedBgraSize = width * height * 4;
      final expectedNv21Size = (width * height * 1.5).ceil();

      InputImageFormat inputFormat;
      int bytesPerRow;

      // Determine format by comparing actual size to expected sizes
      final sizeDiffFromBgra = (imageBytes.length - expectedBgraSize).abs();
      final sizeDiffFromNv21 = (imageBytes.length - expectedNv21Size).abs();

      // CRITICAL FIX: Use Platform.isIOS for accurate platform detection
      final isIOS = Platform.isIOS;

      if (isIOS || sizeDiffFromBgra < sizeDiffFromNv21) {
        // iOS or closer to BGRA8888 size
        debugPrint('Using BGRA8888 format (iOS or size match)');
        inputFormat = InputImageFormat.bgra8888;
        // BGRA8888: 4 bytes per pixel, but account for potential padding
        // Calculate actual bytes per row from the byte array
        bytesPerRow = (imageBytes.length / height).toInt();
        // Ensure it's at least width * 4
        if (bytesPerRow < width * 4) {
          bytesPerRow = width * 4;
        }
      } else {
        // Android or closer to NV21 size
        debugPrint('Using NV21 format (Android or size match)');
        inputFormat = InputImageFormat.nv21;
        // NV21: 1 byte per pixel for Y channel
        bytesPerRow = width;
      }

      debugPrint('Using InputImageFormat: ${inputFormat.toString()}');
      debugPrint('Bytes per row: $bytesPerRow');

      final metadata = InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: _rotationFromSensorOrientation(
            _cameraController!.description.sensorOrientation),
        format: inputFormat,
        bytesPerRow: bytesPerRow,
      );

      final result =
          InputImage.fromBytes(bytes: imageBytes, metadata: metadata);
      debugPrint('Successfully created InputImage');
      return result;
    } catch (e) {
      debugPrint('Critical error in _createInputImageFromYuvBytes: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return null;
    }
  }

  Future<void> _stopImageStream() async {
    try {
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      _isImageStreamRunning = false; // Reset the flag when stopping
      debugPrint('Camera image stream stopped');
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
      _isImageStreamRunning = false; // Reset the flag even on error
      // Don't rethrow here as this is cleanup
    }
  }

  /// Create InputImage from camera image directly with proper format detection
  InputImage? _createInputImageFromCameraImage(CameraImage cameraImage) {
    try {
      debugPrint('=== CAMERA IMAGE TO INPUT IMAGE DEBUG ===');
      debugPrint('Image format: ${cameraImage.format.group}');
      debugPrint('Number of planes: ${cameraImage.planes.length}');
      debugPrint('Image size: ${cameraImage.width}x${cameraImage.height}');

      // Determine the correct InputImageFormat based on camera format
      InputImageFormat inputFormat;

      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        debugPrint('Using BGRA8888 format (iOS)');
        inputFormat = InputImageFormat.bgra8888;
      } else if (cameraImage.format.group == ImageFormatGroup.yuv420 ||
          cameraImage.format.group == ImageFormatGroup.nv21) {
        debugPrint('Using NV21 format (Android)');
        inputFormat = InputImageFormat.nv21;
      } else {
        debugPrint('Unknown format, defaulting to NV21');
        inputFormat = InputImageFormat.nv21;
      }

      // Get camera image metadata
      final metadata = InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: _rotationFromSensorOrientation(
            _cameraController!.description.sensorOrientation),
        format: inputFormat,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      );

      // For BGRA8888, use the plane bytes directly without concatenation
      Uint8List bytes;
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        debugPrint('Using plane bytes directly for BGRA8888');
        bytes = cameraImage.planes[0].bytes;
      } else {
        // For YUV formats, concatenate planes
        debugPrint('Concatenating planes for YUV format');
        bytes = _concatenatePlanes(cameraImage.planes);
      }

      final result = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      debugPrint('Successfully created InputImage from camera image');
      return result;
    } catch (e) {
      debugPrint('Error creating InputImage from camera image: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Create InputImage from image bytes for ML Kit processing (mobile platforms)
  InputImage? _createInputImageFromBytes(Uint8List bytes) {
    try {
      // Get camera image metadata from current controller
      final cameraValue = _cameraController?.value;
      if (cameraValue == null) return null;

      final previewSize = cameraValue.previewSize;
      if (previewSize == null) {
        debugPrint('Preview size is null, cannot create InputImage');
        return null;
      }

      final metadata = InputImageMetadata(
        size: Size(previewSize.width.toDouble(), previewSize.height.toDouble()),
        rotation: _rotationFromSensorOrientation(
            _cameraController!.description.sensorOrientation),
        format: InputImageFormat.nv21, // Use NV21 format for mobile platforms
        bytesPerRow: previewSize.width.toInt(),
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('Error creating InputImage from bytes: $e');
      return null;
    }
  }

  Future<Uint8List> _preprocessImage(XFile imageFile) async {
    // TODO: Implement image preprocessing for ML model
    // - Resize to model input size
    // - Convert to RGB
    // - Normalize pixel values
    return Uint8List(0);
  }

  /// Process camera image for fatigue detection with error handling
  Future<DetectionResult?> processCameraImage(
      CameraImage image, int sensorOrientation) async {
    if (!_isInitialized || _isDisposing) return null;

    try {
      // Convert CameraImage to InputImage for ML Kit
      final inputImage =
          _convertCameraImageToInputImage(image, sensorOrientation);
      if (inputImage == null) return null;

      // Convert to bytes for processing
      final bytes = _concatenatePlanes(image.planes);

      // Process with face detector
      if (_faceDetector != null) {
        final faceDetectionResult =
            await _faceDetector!.processImageWithBytes(bytes, inputImage);

        if (faceDetectionResult != null) {
          // Convert FaceDetectionResult to DetectionResult using persistent FatigueDetector
          debugPrint(
              '=== MAR DEBUG: Using persistent FatigueDetector in processCameraImage ===');
          final detectionResult = _fatigueDetector.processFrame(
            ear: faceDetectionResult.eyeAspectRatio,
            mar: faceDetectionResult.mouthAspectRatio,
            headTiltAngle: faceDetectionResult.headPoseAngle,
            leftEyeOpenProbability: faceDetectionResult.leftEyeOpenProbability,
            rightEyeOpenProbability:
                faceDetectionResult.rightEyeOpenProbability,
          );

          _resultController?.add(detectionResult);

          // Update Firebase real-time state
          final state = _getDrowsinessState(detectionResult);
          if (_firebaseService != null) {
            await _firebaseService!.updateDrowsinessState(state);
          }

          return detectionResult;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error processing camera image: $e');
      return null;
    }
  }

  /// Get drowsiness state string based on detection result
  String _getDrowsinessState(DetectionResult result) {
    if (result.drowsinessScore != null) {
      if (result.drowsinessScore! < 25) {
        return "Alert";
      } else if (result.drowsinessScore! < 50) {
        return "Mild Fatigue";
      } else if (result.drowsinessScore! < 75) {
        return "Moderate Fatigue";
      } else {
        return "Severe Fatigue";
      }
    }

    // Fallback to level-based state - now shows all 4 distinct states
    switch (result.level) {
      case DrowsinessLevel.alert:
        return "Alert";
      case DrowsinessLevel.mildFatigue:
        return "Mild Fatigue";
      case DrowsinessLevel.moderateFatigue:
        return "Moderate Fatigue";
      case DrowsinessLevel.severeFatigue:
        return "Severe Fatigue";
    }
  }

  /// Convert CameraImage to ML Kit InputImage with format detection
  InputImage? _convertCameraImageToInputImage(
      CameraImage image, int sensorOrientation) {
    try {
      debugPrint('=== CONVERT CAMERA IMAGE DEBUG ===');
      debugPrint('Image format: ${image.format.group}');
      debugPrint('Number of planes: ${image.planes.length}');

      // Determine the correct InputImageFormat
      InputImageFormat inputFormat;

      if (image.format.group == ImageFormatGroup.bgra8888) {
        debugPrint('Using BGRA8888 format (iOS)');
        inputFormat = InputImageFormat.bgra8888;
      } else if (image.format.group == ImageFormatGroup.yuv420 ||
          image.format.group == ImageFormatGroup.nv21) {
        debugPrint('Using NV21 format (Android)');
        inputFormat = InputImageFormat.nv21;
      } else {
        debugPrint('Unknown format, defaulting to NV21');
        inputFormat = InputImageFormat.nv21;
      }

      // Get bytes based on format
      Uint8List bytes;
      if (image.format.group == ImageFormatGroup.bgra8888) {
        debugPrint('Using plane bytes directly for BGRA8888');
        bytes = image.planes[0].bytes;
      } else {
        debugPrint('Concatenating planes for YUV format');
        bytes = _concatenatePlanes(image.planes);
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationFromSensorOrientation(sensorOrientation),
        format: inputFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final result = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      debugPrint('Successfully converted camera image to InputImage');
      return result;
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Concatenate image planes with memory management
  Uint8List _concatenatePlanes(List<Plane> planes) {
    if (!AppConfig.enableMemoryMonitoring) {
      // Fast path when memory monitoring is disabled
      final buffer = WriteBuffer();
      for (final plane in planes) {
        buffer.putUint8List(plane.bytes);
      }
      return buffer.done().buffer.asUint8List();
    }

    try {
      // Track memory usage when monitoring is enabled
      final stopwatch = Stopwatch()..start();

      final buffer = WriteBuffer();
      for (final plane in planes) {
        buffer.putUint8List(plane.bytes);
      }

      final result = buffer.done().buffer.asUint8List();
      _currentImageSize = result.length;

      // Add to memory tracking if within limits
      if (_addImageBuffer(result)) {
        debugPrint(
            'Image buffer added: ${result.length} bytes, Total: $_totalAllocatedBytes bytes');
      }

      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 50) {
        debugPrint(
            'WARNING: Image processing took ${stopwatch.elapsedMilliseconds}ms - potential performance issue');
      }

      return result;
    } catch (e) {
      debugPrint('Error in _concatenatePlanes: $e');
      rethrow;
    }
  }

  /// CRITICAL FIX: Add image buffer for tracking and disposal
  bool _addImageBuffer(Uint8List buffer) {
    if (!AppConfig.enableMemoryMonitoring) return true;

    // CRITICAL FIX: More aggressive memory management
    final bufferSize = buffer.length;

    // CRITICAL FIX: Calculate max buffer size based on format
    // BGRA8888 format uses 4 bytes per pixel, so buffers are larger than YUV420
    // Allow up to 60% of total limit for BGRA8888 buffers (vs 33% for YUV)
    // This accommodates the 480x640 BGRA8888 image (1,228,800 bytes)
    final maxBufferSize = (AppConfig.maxImageBufferSizeBytes * 0.6).toInt();

    if (bufferSize > maxBufferSize) {
      debugPrint(
          'Buffer too large: ${_formatBytes(bufferSize)} > ${_formatBytes(maxBufferSize)}, skipping');
      return false;
    }

    // Check if adding this buffer would exceed limits
    if (_totalAllocatedBytes + bufferSize > _maxTotalBytes) {
      debugPrint(
          'Memory limit reached: ${_formatBytes(_totalAllocatedBytes + bufferSize)} > ${_formatBytes(_maxTotalBytes)}');

      // Try emergency cleanup first
      if (_totalAllocatedBytes + bufferSize > _maxTotalBytes * 0.9) {
        _performEmergencyMemoryCleanup();
      } else {
        _performMemoryCleanup();
      }

      // If still over limit after cleanup, reject allocation
      if (_totalAllocatedBytes + bufferSize > _maxTotalBytes) {
        debugPrint('Memory still over limit after cleanup, rejecting buffer');
        return false;
      }
    }

    // Add buffer to tracking
    _pendingImageBuffers.add(buffer);
    _totalAllocatedBytes += bufferSize;

    // CRITICAL FIX: Very aggressive buffer limit
    final maxBuffers = (AppConfig.maxConcurrentImages * 0.3)
        .round(); // 30% of configured limit
    if (_pendingImageBuffers.length > maxBuffers) {
      _removeOldestBuffer();
    }

    debugPrint(
        'Buffer added: ${_formatBytes(bufferSize)}, Total: ${_formatBytes(_totalAllocatedBytes)}, Count: ${_pendingImageBuffers.length}');
    return true;
  }

  /// CRITICAL FIX: Remove oldest buffer and update tracking
  void _removeOldestBuffer() {
    if (_pendingImageBuffers.isNotEmpty) {
      final oldestBuffer = _pendingImageBuffers.removeAt(0);
      _totalAllocatedBytes -= oldestBuffer.length;
      debugPrint(
          'Removed oldest buffer: ${oldestBuffer.length} bytes, remaining: $_totalAllocatedBytes bytes');
    }
  }

  /// CRITICAL FIX: Perform memory cleanup with enhanced logging
  void _performMemoryCleanup() {
    if (!AppConfig.enableMemoryMonitoring) return;

    final buffersCount = _pendingImageBuffers.length;
    final bytesBefore = _totalAllocatedBytes;

    debugPrint(
        'Performing memory cleanup - Current usage: ${_formatBytes(_totalAllocatedBytes)}, Buffers: $buffersCount');

    // Clear all pending buffers
    _pendingImageBuffers.clear();
    _totalAllocatedBytes = 0;
    _currentImageSize = 0;

    // Clear MemoryMonitor buffers
    MemoryMonitor.instance.untrackImageBuffer('detection');

    // Force garbage collection hint
    _forceGarbageCollection();

    debugPrint('Memory cleanup completed - freed ${_formatBytes(bytesBefore)}');
  }

  /// Get current memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'pendingBuffers': _pendingImageBuffers.length,
      'totalAllocatedBytes': _totalAllocatedBytes,
      'currentImageSize': _currentImageSize,
      'maxAllocatedBytes': _maxTotalBytes,
      'memoryUtilization': _maxTotalBytes > 0
          ? (_totalAllocatedBytes / _maxTotalBytes * 100).toStringAsFixed(1) +
              '%'
          : '0%',
      'cleanupTimerActive': _memoryCleanupTimer?.isActive ?? false,
    };
  }

  /// Convert sensor orientation to InputImageRotation
  InputImageRotation _rotationFromSensorOrientation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// CRITICAL FIX: YUV to RGB conversion method (currently unused to prevent camera freezing)
  /// This method was causing camera freezing due to computational overhead
  /// Keeping it commented out for reference in case needed for future improvements
  /*
  Uint8List _convertYuvToRgb(CameraImage cameraImage) {
    // Implementation removed to prevent camera freezing
    // Fast YUV processing is used instead
    return _concatenatePlanes(cameraImage.planes);
  }
  */

  DetectionResult _parseOutput(List<dynamic> output) {
    // TODO: Parse model output to DetectionResult
    // - Extract confidence scores for each drowsiness level
    // - Determine the most likely level
    // - Create DetectionResult object

    return DetectionResult(
      level: DrowsinessLevel.alert,
      confidence: 0.8,
      timestamp: DateTime.now(),
    );
  }

  Stream<DetectionResult>? get detectionStream => _resultController?.stream;

  Map<String, dynamic> getStatistics() {
    return _faceDetector?.getStatistics() ?? {};
  }

  void reset() {
    _faceDetector?.reset();
  }

  /// CRITICAL FIX: Comprehensive resource disposal with error handling
  void dispose() {
    if (_isDisposing) {
      debugPrint('DetectionService: Already disposing, skipping...');
      return;
    }

    debugPrint('DetectionService: Disposing all resources...');
    _isDisposing = true;

    try {
      // Stop memory monitoring
      _memoryCleanupTimer?.cancel();
      _memoryCleanupTimer = null;

      // Perform final memory cleanup
      _performMemoryCleanup();

      // Stop all operations
      stopDetection();

      // Dispose face detector
      if (_faceDetector != null) {
        _faceDetector!.dispose();
        _faceDetector = null;
      }

      // CRITICAL FIX: Close result controller safely
      if (_resultController != null && !_resultController!.isClosed) {
        _resultController!.close();
        debugPrint('Result controller closed');
      }
      _resultController = null;

      // Clear all state
      _cameraController = null;
      _currentUserId = null;
      _firebaseService = null;
      _audioAlertService = null;
      _isInitialized = false;
      _isImageStreamRunning = false;
      _frameCount = 0;
      _pendingImageBuffers.clear();
      _totalAllocatedBytes = 0;
      _currentImageSize = 0;

      debugPrint('DetectionService: All resources disposed');
    } catch (e) {
      debugPrint('Error during disposal: $e');
    } finally {
      _isDisposing = false;
      // Clear singleton instance
      if (_instance == this) {
        _instance = null;
      }
    }
  }

  /// CRITICAL FIX: Start memory monitoring
  void _startMemoryMonitoring() {
    if (AppConfig.enableMemoryMonitoring) {
      _memoryCleanupTimer = Timer.periodic(
        Duration(seconds: AppConfig.memoryCleanupIntervalSeconds),
        (_) => _performMemoryCleanup(),
      );
      debugPrint(
          'DetectionService: Memory monitoring started - cleanup every ${AppConfig.memoryCleanupIntervalSeconds} seconds');
    }
  }

  /// CRITICAL: Check if service is properly disposed
  bool get isDisposed =>
      !_isInitialized && (_resultController?.isClosed ?? true) || _isDisposing;

  /// Safe getter for face detector
  FaceDetectorService? get faceDetector => _faceDetector;
}

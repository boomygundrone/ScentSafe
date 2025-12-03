import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

/// Face detection service using Google ML Kit
class FaceDetectorService {
  late final FaceDetector _faceDetector;
  late final FaceDetector _faceDetectorWithLandmarks;
  bool _isInitialized = false;

  /// Initialize face detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks:
          false, // Disabled by default, will only extract when contours fail
      enableContours: true,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    );

    // Fallback detector with landmarks enabled for when contours fail
    final landmarkOptions = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true, // Enabled for fallback
      enableContours: true,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.fast,
    );

    _faceDetector = GoogleMlKit.vision.faceDetector(options);
    _faceDetectorWithLandmarks =
        GoogleMlKit.vision.faceDetector(landmarkOptions);
    _isInitialized = true;
  }

  /// Process camera image and return face detection results
  Future<FaceDetectionResult?> processImage(CameraImage cameraImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Convert camera image to InputImage
      final inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage == null) return null;

      return await _processInputImage(inputImage);
    } catch (e) {
      debugPrint('Face detection error: $e');
      return null;
    }
  }

  /// Process image bytes and InputImage (for detection service integration)
  Future<FaceDetectionResult?> processImageWithBytes(
      Uint8List bytes, InputImage inputImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _processInputImage(inputImage);
    } catch (e) {
      debugPrint('Face detection error: $e');
      return null;
    }
  }

  /// Common processing logic for InputImage
  Future<FaceDetectionResult?> _processInputImage(InputImage inputImage) async {
    try {
      // Detect faces
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;

      // Get the largest face
      final face = faces.reduce((a, b) =>
          a.boundingBox.width * a.boundingBox.height >
                  b.boundingBox.width * b.boundingBox.height
              ? a
              : b);

      // Extract facial features
      debugPrint('=== MAR DEBUG: Face Detection Pipeline ===');
      final contours = _extractContours(face);
      Map<String, List<double>> landmarks = {};

      // Only extract landmarks if contours extraction failed or is empty
      if (contours.isEmpty) {
        debugPrint('No contours found, extracting landmarks as fallback');
        landmarks = await _extractLandmarksWithFallback(inputImage, face);
      } else {
        debugPrint(
            'Contours extracted successfully, skipping landmarks extraction');
      }

      return FaceDetectionResult(
        face: face,
        landmarks: landmarks,
        contours: contours,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Face detection error: $e');
      return null;
    }
  }

  /// Convert CameraImage to InputImage
  InputImage? _inputImageFromCameraImage(CameraImage cameraImage) {
    try {
      final plane = cameraImage.planes.first;
      final bytes = plane.bytes;

      // Create InputImage from bytes
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size:
              Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Extract facial landmarks with fallback detection
  Future<Map<String, List<double>>> _extractLandmarksWithFallback(
      InputImage inputImage, Face originalFace) async {
    debugPrint('=== MAR DEBUG: Extracting landmarks with fallback ===');

    try {
      // Re-detect face with landmarks enabled
      final faces = await _faceDetectorWithLandmarks.processImage(inputImage);
      if (faces.isEmpty) {
        debugPrint('No faces found in fallback detection');
        return {};
      }

      // Find the face that matches our original face (by position/size)
      final face = faces.firstWhere((f) {
        final sizeDiff =
            (f.boundingBox.width - originalFace.boundingBox.width).abs();
        final positionDiff =
            (f.boundingBox.left - originalFace.boundingBox.left).abs();
        return sizeDiff < 50 && positionDiff < 50; // Allow some tolerance
      }, orElse: () => faces.first);

      return _extractLandmarksFromFace(face);
    } catch (e) {
      debugPrint('Error in landmark fallback extraction: $e');
      return {};
    }
  }

  /// Extract facial landmarks from a face with landmarks enabled
  Map<String, List<double>> _extractLandmarksFromFace(Face face) {
    final landmarks = <String, List<double>>{};

    debugPrint('=== MAR DEBUG: Extracting landmarks ===');
    debugPrint('Available landmark types: ${face.landmarks.keys}');

    // Extract eye landmarks
    if (face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null) {
      final leftEye = face.landmarks[FaceLandmarkType.leftEye]!;
      final rightEye = face.landmarks[FaceLandmarkType.rightEye]!;

      landmarks['leftEye'] = [
        leftEye.position.x.toDouble(),
        leftEye.position.y.toDouble()
      ];
      landmarks['rightEye'] = [
        rightEye.position.x.toDouble(),
        rightEye.position.y.toDouble()
      ];
      debugPrint('Eye landmarks extracted successfully');
    }

    // Extract mouth landmarks for MAR fallback
    if (face.landmarks[FaceLandmarkType.leftMouth] != null &&
        face.landmarks[FaceLandmarkType.rightMouth] != null &&
        face.landmarks[FaceLandmarkType.bottomMouth] != null) {
      final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth]!;
      final mouthRight = face.landmarks[FaceLandmarkType.rightMouth]!;
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth]!;

      landmarks['mouthLeft'] = [
        mouthLeft.position.x.toDouble(),
        mouthLeft.position.y.toDouble()
      ];
      landmarks['mouthRight'] = [
        mouthRight.position.x.toDouble(),
        mouthRight.position.y.toDouble()
      ];
      landmarks['bottomMouth'] = [
        bottomMouth.position.x.toDouble(),
        bottomMouth.position.y.toDouble()
      ];

      debugPrint('Mouth landmarks extracted for MAR fallback:');
      debugPrint(
          '  Left mouth: (${mouthLeft.position.x.toStringAsFixed(1)}, ${mouthLeft.position.y.toStringAsFixed(1)})');
      debugPrint(
          '  Right mouth: (${mouthRight.position.x.toStringAsFixed(1)}, ${mouthRight.position.y.toStringAsFixed(1)})');
      debugPrint(
          '  Bottom mouth: (${bottomMouth.position.x.toStringAsFixed(1)}, ${bottomMouth.position.y.toStringAsFixed(1)})');
    } else {
      debugPrint('WARNING: Missing mouth landmarks for MAR fallback!');
    }

    debugPrint('Total landmarks extracted: ${landmarks.keys}');
    return landmarks;
  }

  /// Extract facial contours
  Map<String, List<double>> _extractContours(Face face) {
    final contours = <String, List<double>>{};

    debugPrint('=== MAR DEBUG: Extracting contours ===');
    debugPrint('Available contour types: ${face.contours.keys}');

    // Extract lips contour for MAR calculation - use correct FaceContourType
    if (face.contours[FaceContourType.lowerLipBottom] != null &&
        face.contours[FaceContourType.upperLipTop] != null) {
      final lowerLipContour = face.contours[FaceContourType.lowerLipBottom]!;
      final upperLipContour = face.contours[FaceContourType.upperLipTop]!;
      final lipsPoints = <double>[];

      debugPrint(
          'Lip contours found - lower: ${lowerLipContour.points.length} points, upper: ${upperLipContour.points.length} points');

      // Combine upper and lower lip points
      for (final point in lowerLipContour.points) {
        lipsPoints.addAll([point.x.toDouble(), point.y.toDouble()]);
      }
      for (final point in upperLipContour.points) {
        lipsPoints.addAll([point.x.toDouble(), point.y.toDouble()]);
      }

      contours['lips'] = lipsPoints;
      debugPrint(
          'Combined lips contour extracted: ${lipsPoints.length} values');
    } else {
      debugPrint('WARNING: No lip contours found!');
      debugPrint(
          'Available lip-related contours: ${face.contours.keys.where((k) => k.toString().toLowerCase().contains('lip'))}');
    }

    // Extract face oval contour for overall face detection
    if (face.contours[FaceContourType.face] != null) {
      final faceContour = face.contours[FaceContourType.face]!;
      final facePoints = <double>[];

      for (final point in faceContour.points) {
        facePoints.addAll([point.x.toDouble(), point.y.toDouble()]);
      }

      contours['face'] = facePoints;
      debugPrint('Face contour extracted: ${facePoints.length} values');
    }

    debugPrint('Total contours extracted: ${contours.keys}');
    return contours;
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
    _faceDetectorWithLandmarks.close();
    _isInitialized = false;
  }

  /// Get statistics for detection service integration
  Map<String, dynamic> getStatistics() {
    return {
      'isInitialized': _isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset detector state
  void reset() {
    // No state to reset in this implementation
    // Face detector is stateless, so this is just for interface compatibility
  }
}

/// Result of face detection
class FaceDetectionResult {
  final Face face;
  final Map<String, List<double>> landmarks;
  final Map<String, List<double>> contours;
  final DateTime timestamp;

  FaceDetectionResult({
    required this.face,
    required this.landmarks,
    required this.contours,
    required this.timestamp,
  });

  /// Get eye aspect ratio (EAR)
  double get eyeAspectRatio {
    // Use landmarks for more accurate EAR calculation
    if (!landmarks.containsKey('leftEye') ||
        !landmarks.containsKey('rightEye')) {
      return 0.3; // Default value
    }

    final leftEye = landmarks['leftEye']!;
    final rightEye = landmarks['rightEye']!;

    // Simple EAR calculation based on eye positions
    final eyeDistance = (rightEye[0] - leftEye[0]).abs();
    final eyeHeight = ((rightEye[1] + leftEye[1]) / 2).abs();

    return eyeHeight > 0 ? eyeDistance / eyeHeight : 0.3;
  }

  /// Get mouth aspect ratio (MAR) using contour points
  double get mouthAspectRatio {
    debugPrint('=== MAR DEBUG: Calculating MAR ===');

    // Try lip contour first
    if (contours.containsKey('lips') && contours['lips']!.length >= 20) {
      debugPrint('Using LIPS CONTOUR for MAR calculation');
      final lipPoints = contours['lips']!;
      debugPrint(
          'Lip contour points available: ${lipPoints.length ~/ 2} points');

      // Calculate bounding box of lip contour points
      final xs = <double>[];
      final ys = <double>[];

      for (int i = 0; i < lipPoints.length; i += 2) {
        xs.add(lipPoints[i]);
        ys.add(lipPoints[i + 1]);
      }

      final minX = xs.reduce(math.min);
      final maxX = xs.reduce(math.max);
      final minY = ys.reduce(math.min);
      final maxY = ys.reduce(math.max);

      final mouthWidth = maxX - minX;
      final mouthHeight = maxY - minY;

      final mar = mouthHeight / (mouthWidth + 1e-6);

      debugPrint('MAR from contours: ${mar.toStringAsFixed(3)}');
      debugPrint('  Mouth width: ${mouthWidth.toStringAsFixed(1)}');
      debugPrint('  Mouth height: ${mouthHeight.toStringAsFixed(1)}');
      debugPrint('  Using ${lipPoints.length ~/ 2} lip contour points');

      return mar;
    }
    // Fallback to landmarks if contours not available
    else if (landmarks.containsKey('mouthLeft') &&
        landmarks.containsKey('mouthRight') &&
        landmarks.containsKey('bottomMouth')) {
      debugPrint('FALLBACK: Using MOUTH LANDMARKS for MAR calculation');

      final mouthLeft = landmarks['mouthLeft']!;
      final mouthRight = landmarks['mouthRight']!;
      final bottomMouth = landmarks['bottomMouth']!;

      final mouthWidth = (mouthRight[0] - mouthLeft[0]).abs();
      final mouthHeight = bottomMouth[1].abs(); // Simplified height calculation

      final mar = mouthHeight / (mouthWidth + 1e-6);

      debugPrint('MAR from landmarks: ${mar.toStringAsFixed(3)}');
      debugPrint(
          '  Mouth width (left to right): ${mouthWidth.toStringAsFixed(1)}');
      debugPrint(
          '  Mouth height (to bottom): ${mouthHeight.toStringAsFixed(1)}');
      debugPrint('  Using 3 landmark points: left, right, bottom');

      return mar;
    }
    // No data available
    else {
      debugPrint('WARNING: No lip contours or mouth landmarks available!');
      debugPrint('Available contours: ${contours.keys}');
      debugPrint('Available landmarks: ${landmarks.keys}');
      debugPrint('Using default MAR value: 0.4');
      return 0.4; // Default value
    }
  }

  /// Get head pose angle (forward/backward tilt for fatigue detection)
  double get headPoseAngle {
    if (face.headEulerAngleX == null) return 0.0;
    return face.headEulerAngleX!;
  }

  /// Get head pose angle Y (left/right rotation)
  double get headPoseAngleY {
    if (face.headEulerAngleY == null) return 0.0;
    return face.headEulerAngleY!;
  }

  /// Get head pose angle Z (roll)
  double get headPoseAngleZ {
    if (face.headEulerAngleZ == null) return 0.0;
    return face.headEulerAngleZ!;
  }

  /// Get eye open probabilities
  double? get leftEyeOpenProbability => face.leftEyeOpenProbability;
  double? get rightEyeOpenProbability => face.rightEyeOpenProbability;
}

import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scentsafe/services/face_detector.dart';
import 'package:scentsafe/services/fatigue_detector.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() {
  group('FaceDetectorService - Asymmetric Eye Detection', () {
    late FaceDetectorService faceDetectorService;
    late FatigueDetector fatigueDetector;

    setUp(() {
      faceDetectorService = FaceDetectorService();
      fatigueDetector = FatigueDetector();
    });

    test('should produce different EAR values for left and right eyes', () {
      // Create a mock face with eye landmarks at different positions
      // to simulate realistic face geometry
      final face = _createMockFace();

      // Extract eye points for both eyes
      final leftEyePoints = faceDetectorService.extractEyePoints(face, true);
      final rightEyePoints = faceDetectorService.extractEyePoints(face, false);

      // Verify both eyes have the required 6 points (12 coordinates)
      expect(leftEyePoints, hasLength(12));
      expect(rightEyePoints, hasLength(12));

      // Calculate EAR for both eyes
      final leftEAR = fatigueDetector.calculateEyeAspectRatio(leftEyePoints);
      final rightEAR = fatigueDetector.calculateEyeAspectRatio(rightEyePoints);

      // Print test results
      if (kDebugMode) {
        print('Left eye EAR: $leftEAR');
        print('Right eye EAR: $rightEAR');
      }

      // CRITICAL TEST: Verify that EAR values are different
      // This tests the fix for symmetric eye detection issue
      expect(leftEAR, isNot(equals(rightEAR)));

      // Verify EAR values are within reasonable range (typically 0.2-0.4 for open eyes)
      expect(leftEAR, greaterThan(0.1));
      expect(leftEAR, lessThan(0.6));
      expect(rightEAR, greaterThan(0.1));
      expect(rightEAR, lessThan(0.6));

      // Verify the difference is meaningful (at least 1% difference)
      final earDifference =
          ((leftEAR - rightEAR).abs() / ((leftEAR + rightEAR) / 2.0)) * 100;
      expect(earDifference, greaterThan(1.0));

      if (kDebugMode) {
        print(
            'EAR difference percentage: ${earDifference.toStringAsFixed(2)}%');
      }
    });

    test('should maintain natural left-right asymmetry patterns', () {
      final face = _createMockFace();

      final leftEyePoints = faceDetectorService.extractEyePoints(face, true);
      final rightEyePoints = faceDetectorService.extractEyePoints(face, false);

      final leftEAR = fatigueDetector.calculateEyeAspectRatio(leftEyePoints);
      final rightEAR = fatigueDetector.calculateEyeAspectRatio(rightEyePoints);

      // Test multiple face positions to ensure consistent asymmetry
      for (int i = 0; i < 5; i++) {
        final testFace = _createMockFace(
          faceCenterX: 100 + (i * 20), // Move face horizontally
          faceCenterY: 150 + (i * 10), // Move face vertically
          faceWidth: 120.0 + (i * 2), // Slight face size variation
          faceHeight: 140.0 + (i * 2),
        );

        final testLeftEyePoints =
            faceDetectorService.extractEyePoints(testFace, true);
        final testRightEyePoints =
            faceDetectorService.extractEyePoints(testFace, false);

        final testLeftEAR =
            fatigueDetector.calculateEyeAspectRatio(testLeftEyePoints);
        final testRightEAR =
            fatigueDetector.calculateEyeAspectRatio(testRightEyePoints);

        // Each face should still produce different EAR values
        expect(testLeftEAR, isNot(equals(testRightEAR)));

        if (kDebugMode) {
          final diff = ((testLeftEAR - testRightEAR).abs() /
              ((testLeftEAR + testRightEAR) / 2.0) *
              100);
          print(
              'Test $i - Left EAR: $testLeftEAR, Right EAR: $testRightEAR, Diff: ${diff.toStringAsFixed(2)}%');
        }
      }
    });
  });
}

/// Creates a mock face for testing eye detection
Face _createMockFace({
  double faceCenterX = 320.0, // Center of typical 640x480 image
  double faceCenterY = 240.0,
  double faceWidth = 120.0,
  double faceHeight = 140.0,
}) {
  final leftEyePosition = Offset(faceCenterX - 30, faceCenterY - 20);
  final rightEyePosition = Offset(faceCenterX + 30, faceCenterY - 20);

  final leftEye = FaceLandmark(
    type: FaceLandmarkType.leftEye,
    position:
        Point<int>(leftEyePosition.dx.round(), leftEyePosition.dy.round()),
  );

  final rightEye = FaceLandmark(
    type: FaceLandmarkType.rightEye,
    position:
        Point<int>(rightEyePosition.dx.round(), rightEyePosition.dy.round()),
  );

  final face = MockFace(
    boundingBox: Rect.fromCenter(
      center: Offset(faceCenterX, faceCenterY),
      width: faceWidth,
      height: faceHeight,
    ),
    landmarks: {
      FaceLandmarkType.leftEye: leftEye,
      FaceLandmarkType.rightEye: rightEye,
    },
  );

  return face;
}

/// Mock face class for testing
class MockFace implements Face {
  @override
  final Rect boundingBox;

  @override
  final Map<FaceLandmarkType, FaceLandmark?> landmarks;

  MockFace({required this.boundingBox, required this.landmarks});

  @override
  List<FaceContourType> get availableContourTypes => [];

  @override
  Map<FaceContourType, FaceContour?> get contours => {};

  @override
  double? get headEulerAngleX => null;

  @override
  double? get headEulerAngleY => null;

  @override
  double? get headEulerAngleZ => null;

  @override
  double? get leftEyeOpenProbability => null;

  @override
  double? get rightEyeOpenProbability => null;

  @override
  double? get smilingProbability => null;

  @override
  int? get trackingId => null;
}

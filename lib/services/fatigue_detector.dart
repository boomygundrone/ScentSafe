import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/detection_result.dart';

/// Fatigue detection service that implements the core algorithm
/// from the Python version, adapted for mobile/Dart
class FatigueDetector {
  // Use configuration for mobile-optimized thresholds
  static const double earThreshold = AppConfig.earThreshold;
  static const double marThreshold = AppConfig.marThreshold;
  static const int earConsecutiveFrames = AppConfig.earConsecutiveFrames;
  static const int marConsecutiveFrames = AppConfig.marConsecutiveFrames;
  static const int blinkResetTime = AppConfig.blinkResetTimeSeconds;

  // Scoring weights from AppConfig
  static const double blinkWeight = AppConfig.blinkWeight;
  static const double yawnWeight = AppConfig.yawnWeight;
  static const double headTiltWeight = AppConfig.headTiltWeight;
  static const int headTiltThresh = AppConfig.headTiltThresholdDegrees;

  // State variables
  int _eyeClosureCounter = 0;
  int _mouthOpenCounter = 0;
  int _blinkCount = 0;
  int _yawnCount = 0;
  DateTime _lastResetTime = DateTime.now();
  final List<double> _earHistory = [];

  // Instance tracking for debugging
  static int _instanceCount = 0;
  final int _instanceId;

  // State persistence for smoothing
  final List<DrowsinessLevel> _levelHistory = [];
  static const int _historySize = 5;
  DrowsinessLevel _lastStableLevel = DrowsinessLevel.alert;

  /// Constructor with instance tracking
  FatigueDetector() : _instanceId = ++_instanceCount {
    debugPrint('=== MAR DEBUG: FatigueDetector Constructor ===');
    debugPrint('Creating FatigueDetector instance #$_instanceId');
    debugPrint('Total instances created: $_instanceCount');
    debugPrint(
        'Initial counters - MouthOpen: $_mouthOpenCounter, BlinkCount: $_blinkCount, YawnCount: $_yawnCount');
  }

  /// Calculate Eye Aspect Ratio (EAR) from eye landmarks
  /// Expects 6 points: [x0,y0, x1,y1, x2,y2, x3,y3, x4,y4, x5,y5]
  double calculateEyeAspectRatio(List<double> eyePoints) {
    if (eyePoints.length != 12) {
      throw ArgumentError(
          'Eye points must contain 6 coordinate pairs (12 values)');
    }

    // Convert to points for distance calculation
    final points = <math.Point<double>>[];
    for (int i = 0; i < eyePoints.length; i += 2) {
      points.add(math.Point(eyePoints[i], eyePoints[i + 1]));
    }

    // EAR formula: (A + B) / (2 * C)
    // A = distance between points 1-5 (vertical)
    // B = distance between points 2-4 (vertical)
    // C = distance between points 0-3 (horizontal)

    final A = _euclideanDistance(points[1], points[5]);
    final B = _euclideanDistance(points[2], points[4]);
    final C = _euclideanDistance(points[0], points[3]);

    return (A + B) / (2.0 * C);
  }

  /// Calculate Mouth Aspect Ratio (MAR) from dense lip contour points
  /// Uses geometric height/width ratio for accurate mouth opening detection
  double calculateMouthAspectRatio(List<double> mouthPoints) {
    if (mouthPoints.length < 20) {
      // Require at least 10 contour points (20 coordinates)
      throw ArgumentError(
          'Mouth contour points must contain at least 10 coordinate pairs (20 values)');
    }

    // Convert to points
    final points = <math.Point<double>>[];
    for (int i = 0; i < mouthPoints.length; i += 2) {
      points.add(math.Point(mouthPoints[i], mouthPoints[i + 1]));
    }

    // Calculate bounding box of all contour points
    final xs = points.map((p) => p.x).toList();
    final ys = points.map((p) => p.y).toList();
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    final mouthWidth = maxX - minX;
    final mouthHeight = maxY - minY;

    // MAR = height / width ratio (open mouth has higher ratio)
    final mar = mouthHeight /
        (mouthWidth + 1e-6); // Add epsilon to prevent division by zero

    // Optional: Add minimal debug logging
    if (kDebugMode) {
      debugPrint(
          'MAR: ${mar.toStringAsFixed(3)} (H:${mouthHeight.toStringAsFixed(1)}/W:${mouthWidth.toStringAsFixed(1)})');
    }

    return mar;
  }

  /// Calculate weighted drowsiness score with multi-axis head pose (from Python version)
  double _calculateDrowsinessScore(int blinks, int yawns, double headTilt,
      double headTiltY, double headTiltZ) {
    final blinkScore =
        (blinks / AppConfig.maxBlinkCountForScoring).clamp(0.0, 1.0) *
            blinkWeight *
            100;
    final yawnScore =
        (yawns / AppConfig.maxYawnCountForScoring).clamp(0.0, 1.0) *
            yawnWeight *
            100;

    // Calculate head tilt score focusing on individual axes, especially Z-axis (ear to shoulder)
    // Use the maximum absolute value from any axis to detect any type of significant tilt
    final maxHeadTilt =
        [headTilt.abs(), headTiltY.abs(), headTiltZ.abs()].reduce(math.max);
    final headTiltScore =
        (maxHeadTilt / headTiltThresh).clamp(0.0, 1.0) * headTiltWeight * 100;
    return blinkScore + yawnScore + headTiltScore;
  }

  /// Calculate confidence based on multiple fatigue indicators with enhanced shoulder tilt detection
  double _calculateConfidence(double ear, double mar, double headTilt,
      double headTiltY, double headTiltZ, int blinks, int yawns) {
    double confidence = 0.0;

    debugPrint('=== MAR DEBUG: Confidence Calculation Details ===');
    debugPrint(
        'Input values - EAR: ${ear.toStringAsFixed(3)}, MAR: ${mar.toStringAsFixed(3)}, HeadTilt: ${headTilt.toStringAsFixed(3)} (magnitude: ${headTilt.abs().toStringAsFixed(3)})');
    debugPrint('Input counters - Blinks: $blinks, Yawns: $yawns');
    debugPrint(
        'EAR threshold: ${earThreshold.toStringAsFixed(3)}, ${(AppConfig.earConfidenceThreshold * 100).toInt()}% = ${(earThreshold * AppConfig.earConfidenceThreshold).toStringAsFixed(3)}');
    debugPrint(
        'MAR threshold: ${marThreshold.toStringAsFixed(3)}, ${(AppConfig.marConfidenceThreshold * 100).toInt()}% = ${(marThreshold * AppConfig.marConfidenceThreshold).toStringAsFixed(3)}');
    debugPrint(
        'HeadTilt threshold: ${headTiltThresh.toStringAsFixed(3)}, ${(AppConfig.headTiltConfidenceThreshold * 100).toInt()}% = ${(headTiltThresh * AppConfig.headTiltConfidenceThreshold).toStringAsFixed(3)}');

    // EAR-based confidence (only if significantly below threshold)
    if (ear < earThreshold * AppConfig.earConfidenceThreshold) {
      // Only if significantly below threshold
      confidence += 0.3;
      debugPrint(
          'EAR confidence: +0.3 (ear is significantly low: ${ear.toStringAsFixed(3)} < ${(earThreshold * AppConfig.earConfidenceThreshold).toStringAsFixed(3)})');
    } else {
      debugPrint(
          'EAR confidence: +0.0 (ear not significantly low: ${ear.toStringAsFixed(3)} >= ${(earThreshold * AppConfig.earConfidenceThreshold).toStringAsFixed(3)})');
    }

    // MAR-based confidence (only if significantly above threshold)
    if (mar > marThreshold * AppConfig.marConfidenceThreshold) {
      // Only if significantly above threshold
      confidence += 0.3;
      debugPrint(
          'MAR confidence: +0.3 (mar is significantly high: ${mar.toStringAsFixed(3)} > ${(marThreshold * AppConfig.marConfidenceThreshold).toStringAsFixed(3)})');
    } else {
      debugPrint(
          'MAR confidence: +0.0 (mar not significantly high: ${mar.toStringAsFixed(3)} <= ${(marThreshold * AppConfig.marConfidenceThreshold).toStringAsFixed(3)})');
    }

    // Head tilt-based confidence (only if significantly above threshold in magnitude)
    // Use absolute value since head tilt can be positive or negative depending on direction
    final headTiltMagnitude = headTilt.abs();

    // ENHANCED: Check individual axes for better shoulder tilt detection
    // Z-axis (ear to shoulder) is most important for detecting shoulder tilts
    final shoulderTiltThreshold =
        headTiltThresh * 0.6; // Lower threshold for Z-axis (shoulder tilts)
    final headTiltConfidenceThreshold =
        headTiltThresh * AppConfig.headTiltConfidenceThreshold;

    bool headTiltDetected = false;
    String tiltType = '';

    // Check if any axis exceeds threshold, with special handling for Z-axis (shoulder tilts)
    if (headTilt.abs() > headTiltConfidenceThreshold) {
      headTiltDetected = true;
      tiltType = 'X-axis (forward/backward)';
    } else if (headTiltY.abs() > headTiltConfidenceThreshold) {
      headTiltDetected = true;
      tiltType = 'Y-axis (left/right rotation)';
    } else if (headTiltZ.abs() > shoulderTiltThreshold) {
      // ENHANCED: Lower threshold for Z-axis to detect shoulder tilts more easily
      headTiltDetected = true;
      tiltType = 'Z-axis (ear to shoulder)';
    }

    if (headTiltDetected) {
      confidence += 0.4;
      debugPrint(
          'HeadTilt confidence: +0.4 (head tilt detected: $tiltType, X: ${headTilt.toStringAsFixed(1)}°, Y: ${headTiltY.toStringAsFixed(1)}°, Z: ${headTiltZ.toStringAsFixed(1)}°)');
    } else {
      debugPrint(
          'HeadTilt confidence: +0.0 (no significant head tilt detected: X: ${headTilt.toStringAsFixed(1)}°, Y: ${headTiltY.toStringAsFixed(1)}°, Z: ${headTiltZ.toStringAsFixed(1)}°)');
    }

    final finalConfidence = confidence.clamp(0.0, 1.0);
    debugPrint(
        'Raw confidence: ${confidence.toStringAsFixed(3)}, Final confidence: ${finalConfidence.toStringAsFixed(3)}');

    return finalConfidence;
  }

  /// Check if multiple indicators suggest fatigue before upgrading level
  bool _shouldUpgradeToModerate(double ear, double mar, double headTilt,
      double headTiltY, double headTiltZ, int blinks, int yawns) {
    int fatigueIndicators = 0;

    // Check each indicator with more lenient thresholds
    if (ear < earThreshold * AppConfig.multiIndicatorEarThreshold) {
      fatigueIndicators++; // More lenient EAR
    }
    if (mar > marThreshold * AppConfig.multiIndicatorMarThreshold) {
      fatigueIndicators++; // More lenient MAR
    }
    if (_isSignificantHeadTilt(headTilt, headTiltY, headTiltZ)) {
      fatigueIndicators++; // Multi-axis head tilt detection
    }
    if (blinks > AppConfig.multiIndicatorBlinkThreshold) {
      fatigueIndicators++; // Higher blink threshold
    }
    if (yawns > AppConfig.multiIndicatorYawnThreshold) {
      fatigueIndicators++; // Higher yawn threshold
    }

    return fatigueIndicators >=
        AppConfig.multiIndicatorMinIndicators; // Require minimum indicators
  }

  /// Process a frame and return detection result
  DetectionResult processFrame({
    required double ear,
    required double mar,
    double? headTiltAngle, // Optional head pose (X-axis - forward/backward)
    double? headTiltAngleY, // ENHANCED: Y-axis - left/right rotation
    double? headTiltAngleZ, // ENHANCED: Z-axis - ear to shoulder tilt
    double? leftEyeOpenProbability, // ENHANCED: From ML Kit classification
    double? rightEyeOpenProbability, // ENHANCED: From ML Kit classification
  }) {
    debugPrint('=== MAR DEBUG: Processing Frame ===');
    debugPrint(
        'Input MAR: ${mar.toStringAsFixed(3)} (threshold: ${marThreshold.toStringAsFixed(3)})');
    debugPrint(
        'Input EAR: ${ear.toStringAsFixed(3)} (threshold: ${earThreshold.toStringAsFixed(3)})');

    final now = DateTime.now();
    _earHistory.add(ear);

    // Keep only recent history (last 100 frames)
    if (_earHistory.length > 100) {
      _earHistory.removeAt(0);
    }

    // Reset counters periodically
    if (now.difference(_lastResetTime).inSeconds > blinkResetTime) {
      _blinkCount = 0;
      _yawnCount = 0;
      _lastResetTime = now;
    }

    // Calculate weighted drowsiness score with multi-axis head pose
    final drowsinessScore = _calculateDrowsinessScore(_blinkCount, _yawnCount,
        headTiltAngle ?? 0.0, headTiltAngleY ?? 0.0, headTiltAngleZ ?? 0.0);

    // Determine drowsiness level based on improved multi-indicator logic
    DrowsinessLevel drowsinessLevel = DrowsinessLevel.alert;
    double confidence = 0.0;
    bool shouldTriggerSpray = false;

    // ENHANCED: Eye closure detection with ML Kit classification support
    bool eyesClosed = false;

    // Use ML Kit classification if available, otherwise fall back to EAR
    if (leftEyeOpenProbability != null && rightEyeOpenProbability != null) {
      // ML Kit provides probability of eyes being open (0.0 = closed, 1.0 = open)
      final avgEyeOpenProbability =
          (leftEyeOpenProbability + rightEyeOpenProbability) / 2.0;
      eyesClosed = avgEyeOpenProbability <
          AppConfig
              .mlKitEyeOpenProbabilityThreshold; // Consider eyes closed if below threshold

      if (AppConfig.enableVerboseLogging) {
        debugPrint(
            'ML Kit Classification - Avg eye open probability: $avgEyeOpenProbability, Eyes closed: $eyesClosed');
      }
    } else {
      // Fall back to EAR-based detection
      eyesClosed = ear < (earThreshold - AppConfig.earFallbackThreshold);
    }

    if (eyesClosed) {
      _eyeClosureCounter++;
      if (_eyeClosureCounter >= earConsecutiveFrames) {
        drowsinessLevel = DrowsinessLevel.mildFatigue;
        confidence = 0.7;
      }
    } else {
      if (_eyeClosureCounter >= earConsecutiveFrames) {
        _blinkCount++;
      }
      _eyeClosureCounter = 0;
    }

    if (mar > marThreshold) {
      debugPrint('=== MAR DEBUG: YAWN DETECTED ===');
      debugPrint(
          'MAR: ${mar.toStringAsFixed(3)} > Threshold: ${marThreshold.toStringAsFixed(3)}');

      _mouthOpenCounter++;
      debugPrint(
          'Mouth open counter: $_mouthOpenCounter / $marConsecutiveFrames');

      if (_mouthOpenCounter >= marConsecutiveFrames) {
        _yawnCount++;
        debugPrint('YAWN COUNTED! Total yawns: $_yawnCount');
      }

      // Direct fatigue trigger for sustained mouth opening
      if (_mouthOpenCounter >=
          marConsecutiveFrames * AppConfig.sustainedMouthOpeningMultiplier) {
        if (drowsinessLevel.index < DrowsinessLevel.moderateFatigue.index) {
          drowsinessLevel = DrowsinessLevel.moderateFatigue;
          confidence = 0.8;
          shouldTriggerSpray = true;
          debugPrint('SUSTAINED MOUTH OPENING - Triggering moderate fatigue!');
        }
      }
    } else {
      if (_mouthOpenCounter > 0) {
        debugPrint(
            'MAR DEBUG: Mouth closed - resetting counter (was: $_mouthOpenCounter)');
      }
      _mouthOpenCounter = 0;
    }

    // Use improved multi-indicator logic for fatigue detection with multi-axis support
    if (_shouldUpgradeToModerate(
        ear,
        mar,
        headTiltAngle ?? 0.0,
        headTiltAngleY ?? 0.0,
        headTiltAngleZ ?? 0.0,
        _blinkCount,
        _yawnCount)) {
      drowsinessLevel = DrowsinessLevel.moderateFatigue;
      shouldTriggerSpray = true;
    }

    // Severe fatigue detection - requires multiple strong indicators with multi-axis support
    if ((_yawnCount > AppConfig.severeYawnThreshold ||
            _blinkCount > AppConfig.severeBlinkThreshold) &&
        _isSevereHeadTiltDetected(
            headTiltAngle, headTiltAngleY, headTiltAngleZ)) {
      drowsinessLevel = DrowsinessLevel.severeFatigue;
      shouldTriggerSpray = true;
    }

    // Calculate confidence based on actual measurements
    confidence = _calculateConfidence(ear, mar, headTiltAngle ?? 0.0,
        headTiltAngleY ?? 0.0, headTiltAngleZ ?? 0.0, _blinkCount, _yawnCount);

    debugPrint('=== MAR DEBUG: Confidence Calculation ===');
    debugPrint('Final confidence: ${confidence.toStringAsFixed(3)}');
    debugPrint(
        'Confidence inputs - EAR: ${ear.toStringAsFixed(3)}, MAR: ${mar.toStringAsFixed(3)}, HeadTilt: ${headTiltAngle?.toStringAsFixed(3) ?? "N/A"} (magnitude: ${headTiltAngle?.abs().toStringAsFixed(3) ?? "N/A"})');
    debugPrint('Confidence inputs - Blinks: $_blinkCount, Yawns: $_yawnCount');

    // Apply state smoothing to prevent rapid changes
    drowsinessLevel = _smoothDrowsinessLevel(drowsinessLevel);

    return DetectionResult(
      level: drowsinessLevel,
      confidence: confidence,
      timestamp: now,
      triggeredSpray: shouldTriggerSpray,
      drowsinessScore: drowsinessScore, // Add weighted score to result
    );
  }

  /// Get current statistics
  Map<String, dynamic> getStatistics() {
    final avgEar = _earHistory.isNotEmpty
        ? _earHistory.reduce((a, b) => a + b) / _earHistory.length
        : 0.0;

    return {
      'averageEAR': avgEar,
      'blinkCount': _blinkCount,
      'yawnCount': _yawnCount,
      'eyeClosureCounter': _eyeClosureCounter,
      'mouthOpenCounter': _mouthOpenCounter,
      'earHistoryLength': _earHistory.length,
    };
  }

  /// Smooth drowsiness level to prevent rapid changes
  DrowsinessLevel _smoothDrowsinessLevel(DrowsinessLevel currentLevel) {
    _levelHistory.add(currentLevel);
    if (_levelHistory.length > _historySize) {
      _levelHistory.removeAt(0);
    }

    // If we have enough history, find the most common level
    if (_levelHistory.length >= _historySize) {
      final levelCounts = <DrowsinessLevel, int>{};
      for (final level in _levelHistory) {
        levelCounts[level] = (levelCounts[level] ?? 0) + 1;
      }

      // Find the most frequent level
      final mostFrequentLevel =
          levelCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Only change if we have a clear majority (3+ out of 5)
      if (levelCounts[mostFrequentLevel]! >= 3) {
        _lastStableLevel = mostFrequentLevel;
        return mostFrequentLevel;
      }
    }

    // Fall back to last stable level if no clear majority
    return _lastStableLevel;
  }

  /// Reset all counters and history
  void reset() {
    _eyeClosureCounter = 0;
    _mouthOpenCounter = 0;
    _blinkCount = 0;
    _yawnCount = 0;
    _lastResetTime = DateTime.now();
    _earHistory.clear();
    _levelHistory.clear();
    _lastStableLevel = DrowsinessLevel.alert;
  }

  /// Calculate Euclidean distance between two points
  double _euclideanDistance(math.Point<double> p1, math.Point<double> p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculate combined head tilt magnitude from all axes
  double _calculateHeadTiltMagnitude(
      double headTiltX, double headTiltY, double headTiltZ) {
    // Calculate 3D magnitude of head tilt vector
    return math.sqrt(
        headTiltX * headTiltX + headTiltY * headTiltY + headTiltZ * headTiltZ);
  }

  /// Check if head tilt indicates significant fatigue (multi-axis detection with enhanced shoulder tilt)
  bool _isSignificantHeadTilt(
      double headTiltX, double headTiltY, double headTiltZ) {
    final magnitude =
        _calculateHeadTiltMagnitude(headTiltX, headTiltY, headTiltZ);

    // Check if any axis exceeds threshold for moderate fatigue
    final moderateThreshold =
        headTiltThresh * AppConfig.multiIndicatorHeadTiltThreshold;

    // ENHANCED: Special handling for Z-axis (shoulder tilts) with lower threshold
    final shoulderTiltThreshold =
        headTiltThresh * 0.6; // Lower threshold for Z-axis

    if (headTiltX.abs() > moderateThreshold ||
        headTiltY.abs() > moderateThreshold ||
        headTiltZ.abs() > shoulderTiltThreshold) {
      // Use lower threshold for Z-axis
      return true;
    }

    return false;
  }

  /// Check if head tilt indicates severe fatigue (multi-axis detection with enhanced shoulder tilt)
  bool _isSevereHeadTiltDetected(
      double? headTiltX, double? headTiltY, double? headTiltZ) {
    if (headTiltX == null || headTiltY == null || headTiltZ == null) {
      return false;
    }

    final magnitude =
        _calculateHeadTiltMagnitude(headTiltX!, headTiltY!, headTiltZ!);

    // Check if any axis exceeds severe threshold
    final severeThreshold = headTiltThresh * AppConfig.severeHeadTiltThreshold;

    // ENHANCED: Special handling for Z-axis (shoulder tilts) with lower severe threshold
    final severeShoulderTiltThreshold =
        headTiltThresh * 0.8; // Lower threshold for Z-axis severe detection

    if (headTiltX!.abs() > severeThreshold ||
        headTiltY!.abs() > severeThreshold ||
        headTiltZ!.abs() > severeShoulderTiltThreshold) {
      // Use lower threshold for Z-axis
      return true;
    }

    return false;
  }
}

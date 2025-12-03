import 'package:flutter/foundation.dart';
import '../models/detection_result.dart';

/// Advanced detection calculator for enhanced drowsiness scoring
/// Matches Python implementation with weighted scoring
class AdvancedDetectionCalculator {
  // Scoring weights (from Python version)
  static const double BLINK_WEIGHT = 0.4;
  static const double YAWN_WEIGHT = 0.3;
  static const double HEAD_TILT_WEIGHT = 0.3;
  static const int HEAD_TILT_THRESH = 15; // Head tilt threshold in degrees
  
  /// Calculate weighted drowsiness score (from Python version)
  double _calculateDrowsinessScore(int blinks, int yawns, double headTilt) {
    final blinkScore = (blinks / 25.0).clamp(0.0, 1.0) * BLINK_WEIGHT * 100;
    final yawnScore = (yawns / 3.0).clamp(0.0, 1.0) * YAWN_WEIGHT * 100;
    final headTiltScore = (headTilt.abs() / HEAD_TILT_THRESH).clamp(0.0, 1.0) * HEAD_TILT_WEIGHT * 100;
    return blinkScore + yawnScore + headTiltScore;
  }
  
  /// Process detection result with enhanced metrics
  DetectionResult processDetectionResult({
    required double ear,
    required double mar,
    double? headTiltAngle,
    int? blinkCount,
    int? yawnCount,
  }) {
    final now = DateTime.now();
    
    // Calculate weighted drowsiness score
    final drowsinessScore = _calculateDrowsinessScore(
      blinkCount ?? 0,
      yawnCount ?? 0,
      headTiltAngle ?? 0.0,
    );
    
    // Determine drowsiness level based on weighted score
    DrowsinessLevel drowsinessLevel = DrowsinessLevel.alert;
    double confidence = 0.0;
    bool shouldTriggerSpray = false;
    
    if (drowsinessScore > 50) {
      confidence = drowsinessScore / 100.0;
      drowsinessLevel = DrowsinessLevel.severeFatigue;
      shouldTriggerSpray = true;
    } else if (drowsinessScore > 40) {
      confidence = drowsinessScore / 100.0;
      drowsinessLevel = DrowsinessLevel.moderateFatigue;
      shouldTriggerSpray = true;
    } else if (drowsinessScore > 20) {
      confidence = drowsinessScore / 100.0;
      drowsinessLevel = DrowsinessLevel.mildFatigue;
    }
    
    return DetectionResult(
      level: drowsinessLevel,
      confidence: confidence,
      timestamp: now,
      leftEAR: ear,
      rightEAR: ear,
      averageEAR: ear,
      mar: mar,
      headTilt: headTiltAngle,
      blinkCount: blinkCount,
      yawnCount: yawnCount,
      drowsinessScore: drowsinessScore,
      triggeredSpray: shouldTriggerSpray,
    );
  }
}

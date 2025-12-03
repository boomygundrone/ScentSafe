import 'package:equatable/equatable.dart';

/// Drowsiness levels
enum DrowsinessLevel {
  alert,
  mildFatigue,
  moderateFatigue,
  severeFatigue;
}

/// Enhanced detection result with all metrics
class DetectionResult {
  final DrowsinessLevel level;
  final double confidence;
  final DateTime timestamp;
  
  // Enhanced detection metrics from advanced algorithms
  final double? leftEAR;
  final double? rightEAR;
  final double? averageEAR;
  final double? mar;
  final double? headTilt;
  final int? blinkCount;
  final int? yawnCount;
  final double? drowsinessScore;
  final bool? triggeredSpray; // Add missing property
  
  const DetectionResult({
    required this.level,
    required this.confidence,
    required this.timestamp,
    this.leftEAR,
    this.rightEAR,
    this.averageEAR,
    this.mar,
    this.headTilt,
    this.blinkCount,
    this.yawnCount,
    this.drowsinessScore,
    this.triggeredSpray,
  });
  
  @override
  String toString() {
    return 'DetectionResult(level: $level, confidence: $confidence, timestamp: $timestamp, ear: $averageEAR, mar: $mar, headTilt: $headTilt°, blinks: $blinkCount, yawns: $yawnCount, score: $drowsinessScore)';
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionResult &&
          other.runtimeType == DetectionResult &&
          other.level == level &&
          other.confidence == confidence &&
          other.timestamp == timestamp;
  
  @override
  int get hashCode => level.hashCode ^ confidence.hashCode ^ timestamp.hashCode;
  
  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'level': level.index,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'leftEAR': leftEAR,
      'rightEAR': rightEAR,
      'averageEAR': averageEAR,
      'mar': mar,
      'headTilt': headTilt,
      'blinkCount': blinkCount,
      'yawnCount': yawnCount,
      'drowsinessScore': drowsinessScore,
      'triggeredSpray': triggeredSpray,
    };
  }
  
  /// Create DetectionResult from JSON
  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      level: DrowsinessLevel.values[json['level'] as int],
      confidence: json['confidence'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      leftEAR: json['leftEAR'] as double?,
      rightEAR: json['rightEAR'] as double?,
      averageEAR: json['averageEAR'] as double?,
      mar: json['mar'] as double?,
      headTilt: json['headTilt'] as double?,
      blinkCount: json['blinkCount'] as int?,
      yawnCount: json['yawnCount'] as int?,
      drowsinessScore: json['drowsinessScore'] as double?,
      triggeredSpray: json['triggeredSpray'] as bool?,
    );
  }
  
  /// Create legacy DetectionResult for backward compatibility
  factory DetectionResult.legacy({
    required DrowsinessLevel level,
    required double confidence,
    required DateTime timestamp,
  }) {
    return DetectionResult(
      level: level,
      confidence: confidence,
      timestamp: timestamp,
    );
  }
}
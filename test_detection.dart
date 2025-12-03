import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'lib/services/face_detector.dart';
import 'lib/services/fatigue_detector.dart';
import 'lib/models/detection_result.dart';

void main() async {
  debugPrint('Testing face detection and awakeness level calculation...');
  
  // Initialize face detector
  final faceDetector = FaceDetectorService();
  await faceDetector.initialize();
  
  // Test fatigue detector directly
  final fatigueDetector = FatigueDetector();
  
  // Test case 1: Alert state (normal EAR and MAR)
  debugPrint('\n=== Test Case 1: Alert State ===');
  final alertResult = fatigueDetector.processFrame(
    ear: 0.3, // Normal EAR (above threshold)
    mar: 0.3, // Normal MAR (below threshold)
    headTiltAngle: 5.0, // Small head tilt
  );
  debugPrint('Alert Result: Level=${alertResult.level}, Confidence=${alertResult.confidence}');
  
  // Test case 2: Mild fatigue (low EAR)
  debugPrint('\n=== Test Case 2: Mild Fatigue ===');
  final mildResult = fatigueDetector.processFrame(
    ear: 0.2, // Low EAR (below threshold)
    mar: 0.3, // Normal MAR
    headTiltAngle: 5.0,
  );
  debugPrint('Mild Fatigue Result: Level=${mildResult.level}, Confidence=${mildResult.confidence}');
  
  // Test case 3: Moderate fatigue (high MAR)
  debugPrint('\n=== Test Case 3: Moderate Fatigue ===');
  final moderateResult = fatigueDetector.processFrame(
    ear: 0.3, // Normal EAR
    mar: 0.6, // High MAR (above threshold)
    headTiltAngle: 5.0,
  );
  debugPrint('Moderate Fatigue Result: Level=${moderateResult.level}, Confidence=${moderateResult.confidence}');
  
  // Test case 4: Severe fatigue (high head tilt)
  debugPrint('\n=== Test Case 4: Severe Fatigue ===');
  final severeResult = fatigueDetector.processFrame(
    ear: 0.3, // Normal EAR
    mar: 0.3, // Normal MAR
    headTiltAngle: 20.0, // High head tilt
  );
  debugPrint('Severe Fatigue Result: Level=${severeResult.level}, Confidence=${severeResult.confidence}');
  
  // Get statistics
  debugPrint('\n=== Fatigue Detector Statistics ===');
  final stats = fatigueDetector.getStatistics();
  debugPrint('Statistics: $stats');
  
  // Dispose
  faceDetector.dispose();
  debugPrint('\nTest completed successfully!');
}
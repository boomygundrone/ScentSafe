import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../models/detection_result.dart';
import '../services/detection_service.dart';
import '../services/advanced_detection_calculator.dart' as adv;
import '../services/audio_alert_service.dart';

part 'detection_state.dart';

class DetectionCubit extends Cubit<DetectionState> {
  final DetectionService _detectionService;
  StreamSubscription<DetectionResult>? _detectionSubscription;

  DetectionCubit(this._detectionService) : super(DetectionInitial()) {
    // CRITICAL FIX: Don't establish stream subscription here - do it when detection starts
    // The detectionStream is null until startDetection() creates the result controller
  }

  Future<void> startDetection() async {
    debugPrint('DetectionCubit: Starting detection');
    emit(DetectionRunning());
    
    try {
      await _detectionService.startDetection();
      debugPrint('DetectionCubit: Detection service started');
      
      // CRITICAL FIX: Establish stream subscription AFTER service starts detection
      _detectionSubscription = _detectionService.detectionStream?.listen((result) {
        debugPrint('DetectionCubit: Received detection result - Level: ${result.level}, Confidence: ${result.confidence}');
        emit(DetectionResultUpdated(result));
      });
      
      if (_detectionSubscription == null) {
        debugPrint('DetectionCubit: WARNING - Failed to establish stream subscription');
        emit(DetectionError('Failed to establish detection stream'));
      }
    } catch (e) {
      debugPrint('DetectionCubit: Error starting detection: $e');
      emit(DetectionError(e.toString()));
    }
    
  }

  Future<void> stopDetection() async {
    debugPrint('DetectionCubit: Stopping detection');
    
    try {
      await _detectionService.stopDetection();
      debugPrint('DetectionCubit: Detection service stopped');
      
      // CRITICAL FIX: Cancel stream subscription when stopping detection
      _detectionSubscription?.cancel();
      _detectionSubscription = null;
      debugPrint('DetectionCubit: Stream subscription cancelled');
      
      // CRITICAL FIX: Emit stopped state with reset result to ensure UI shows proper state
      emit(DetectionStopped());
      
      // Also emit a reset detection result to clear any lingering detection state
      final resetResult = DetectionResult(
        level: DrowsinessLevel.alert,
        confidence: 0.0,
        timestamp: DateTime.now(),
      );
      emit(DetectionResultUpdated(resetResult));
      debugPrint('DetectionCubit: Emitted reset result');
    } catch (e) {
      debugPrint('DetectionCubit: Error stopping detection: $e');
      emit(DetectionError(e.toString()));
    }
    
  }

  void updateDetectionResult(DetectionResult result) {
    emit(DetectionResultUpdated(result));
  }

  void onDrowsinessDetected(DetectionResult result) {
    emit(DrowsinessDetected(result));
  }

  Future<void> setCameraController(CameraController controller) async {
    debugPrint('DetectionCubit: Setting camera controller');
    await _detectionService.setCameraController(controller);
    debugPrint('DetectionCubit: Camera controller set successfully');
  }

  /// Process camera frame from video stream
  Future<void> processCameraFrame(CameraImage cameraImage) async {
    try {
      // Forward camera frame to detection service for processing
      await _detectionService.processCameraImage(cameraImage, 0); // 0 for default orientation
    } catch (e) {
      debugPrint('Error processing camera frame: $e');
      emit(DetectionError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _detectionSubscription?.cancel();
    
    return super.close();
  }
}
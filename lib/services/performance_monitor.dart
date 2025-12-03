import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Performance monitoring service to track app performance metrics
/// Helps identify and resolve performance issues like frame skipping
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance {
    _instance ??= PerformanceMonitor._();
    return _instance!;
  }

  PerformanceMonitor._();

  // Performance metrics
  int _frameCount = 0;
  int _droppedFrameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  DateTime _startTime = DateTime.now();
  List<int> _frameProcessingTimes = [];
  Timer? _metricsTimer;

  // Performance thresholds
  static const int maxAcceptableFrameTimeMs = 16; // ~60 FPS
  static const int warningFrameTimeMs = 20; // Warning threshold
  static const int criticalFrameTimeMs = 33; // Critical threshold (30 FPS)

  /// Start performance monitoring
  void startMonitoring() {
    _startTime = DateTime.now();
    _frameCount = 0;
    _droppedFrameCount = 0;
    _frameProcessingTimes.clear();
    
    // Log performance metrics every 5 seconds
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _logPerformanceMetrics();
    });
    
    developer.log('PerformanceMonitor: Started monitoring', name: 'Performance');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _logPerformanceMetrics();
    developer.log('PerformanceMonitor: Stopped monitoring', name: 'Performance');
  }

  /// Record frame processing time
  void recordFrameProcessingTime(int processingTimeMs) {
    _frameCount++;
    _frameProcessingTimes.add(processingTimeMs);
    
    // Keep only last 100 frame times for rolling average
    if (_frameProcessingTimes.length > 100) {
      _frameProcessingTimes.removeAt(0);
    }
    
    // Check for performance issues
    if (processingTimeMs > criticalFrameTimeMs) {
      _droppedFrameCount++;
      _logPerformanceWarning('CRITICAL', processingTimeMs);
    } else if (processingTimeMs > warningFrameTimeMs) {
      _logPerformanceWarning('WARNING', processingTimeMs);
    }
    
    _lastFrameTime = DateTime.now();
  }

  /// Get current FPS
  double get currentFPS {
    final duration = DateTime.now().difference(_lastFrameTime);
    if (duration.inMilliseconds == 0) return 0.0;
    return 1000.0 / duration.inMilliseconds;
  }

  /// Get average frame processing time
  double get averageFrameTime {
    if (_frameProcessingTimes.isEmpty) return 0.0;
    return _frameProcessingTimes.reduce((a, b) => a + b) / _frameProcessingTimes.length;
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'totalFramesProcessed': _frameCount,
      'droppedFrames': _droppedFrameCount,
      'currentFPS': currentFPS,
      'averageFrameTimeMs': averageFrameTime,
      'uptimeSeconds': DateTime.now().difference(_startTime).inSeconds,
      'frameDropRate': _frameCount > 0 ? (_droppedFrameCount / _frameCount * 100) : 0.0,
    };
  }

  /// Log performance metrics
  void _logPerformanceMetrics() {
    if (_frameCount == 0) return;
    
    final summary = getPerformanceSummary();
    developer.log(
      'Performance Metrics: ${summary.toString()}',
      name: 'Performance',
    );
    
    // Check for performance degradation
    if (summary['frameDropRate'] > 10.0) {
      developer.log(
        'ALERT: High frame drop rate detected: ${summary['frameDropRate'].toStringAsFixed(1)}%',
        name: 'Performance',
      );
    }
    
    if (summary['averageFrameTimeMs'] > warningFrameTimeMs) {
      developer.log(
        'WARNING: High average frame time: ${summary['averageFrameTimeMs'].toStringAsFixed(1)}ms',
        name: 'Performance',
      );
    }
  }

  /// Log performance warning
  void _logPerformanceWarning(String level, int processingTime) {
    final message = '$level: Frame processing took ${processingTime}ms (threshold: $warningFrameTimeMs ms)';
    developer.log(message, name: 'Performance');
  }

  /// Check if performance is acceptable
  bool get isPerformanceGood {
    final avgFrameTime = averageFrameTime;
    return avgFrameTime <= warningFrameTimeMs && _droppedFrameCount < 10;
  }

  /// Get performance status
  String get performanceStatus {
    final avgFrameTime = averageFrameTime;
    if (avgFrameTime <= maxAcceptableFrameTimeMs) return 'GOOD';
    if (avgFrameTime <= warningFrameTimeMs) return 'WARNING';
    return 'CRITICAL';
  }

  /// Reset all metrics
  void reset() {
    _frameCount = 0;
    _droppedFrameCount = 0;
    _frameProcessingTimes.clear();
    _startTime = DateTime.now();
    developer.log('PerformanceMonitor: Metrics reset', name: 'Performance');
  }

  /// Dispose resources
  void dispose() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _frameProcessingTimes.clear();
    developer.log('PerformanceMonitor: Disposed', name: 'Performance');
  }
}

/// Frame rate limiter to control processing frequency
class FrameRateLimiter {
  final int _targetFPS;
  final Duration _minFrameTime;
  DateTime _lastProcessedTime = DateTime.now();
  int _framesProcessed = 0;

  FrameRateLimiter(this._targetFPS)
      : _minFrameTime = Duration(milliseconds: (1000 / _targetFPS).round());

  /// Check if a frame should be processed
  bool shouldProcessFrame() {
    final now = DateTime.now();
    final timeSinceLastFrame = now.difference(_lastProcessedTime);
    
    if (timeSinceLastFrame >= _minFrameTime) {
      _lastProcessedTime = now;
      _framesProcessed++;
      return true;
    }
    return false;
  }

  /// Get current target FPS
  int get targetFPS => _targetFPS;

  /// Get frames processed count
  int get framesProcessed => _framesProcessed;

  /// Reset frame counter
  void resetFrameCounter() {
    _framesProcessed = 0;
  }
}
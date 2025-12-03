import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Comprehensive memory monitoring and management utility
/// Provides centralized memory tracking, cleanup, and optimization
class MemoryMonitor {
  static MemoryMonitor? _instance;
  static MemoryMonitor get instance {
    _instance ??= MemoryMonitor._();
    return _instance!;
  }

  MemoryMonitor._();

  // Memory tracking
  final Map<String, int> _componentMemoryUsage = {};
  final Map<String, Uint8List> _trackedBuffers = {};
  Timer? _cleanupTimer;
  int _totalTrackedBytes = 0;
  bool _isMonitoring = false;

  /// Start comprehensive memory monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      Duration(seconds: AppConfig.memoryCleanupIntervalSeconds),
      (_) => _performPeriodicCleanup(),
    );

    debugPrint('MemoryMonitor: Started comprehensive monitoring');

    // Log initial memory stats
    _logMemoryStats('START');
  }

  /// Stop memory monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    // Final cleanup
    _performFullCleanup();

    debugPrint('MemoryMonitor: Stopped monitoring');
  }

  /// Track image buffer with memory management
  bool trackImageBuffer(String component, Uint8List buffer) {
    if (!AppConfig.enableMemoryMonitoring) return true;

    final componentKey = 'image_$component';
    final bufferKey =
        '${componentKey}_${DateTime.now().millisecondsSinceEpoch}';

    // Check memory limits
    if (_totalTrackedBytes + buffer.length >
        AppConfig.maxImageBufferSizeBytes) {
      debugPrint(
          'MemoryMonitor: Memory limit reached for $component, cleaning up...');
      _performPeriodicCleanup();

      // If still over limit, reject new allocation
      if (_totalTrackedBytes + buffer.length >
          AppConfig.maxImageBufferSizeBytes) {
        debugPrint('MemoryMonitor: Rejecting buffer allocation for $component');
        return false;
      }
    }

    // Track the buffer
    _trackedBuffers[bufferKey] = buffer;
    _totalTrackedBytes += buffer.length;

    // Update component usage
    _componentMemoryUsage[componentKey] =
        (_componentMemoryUsage[componentKey] ?? 0) + buffer.length;

    debugPrint(
        'MemoryMonitor: Tracked ${buffer.length} bytes for $component (Total: $_totalTrackedBytes)');
    return true;
  }

  /// Untrack image buffer
  void untrackImageBuffer(String component) {
    if (!AppConfig.enableMemoryMonitoring) return;

    final componentKey = 'image_$component';

    // Find and remove buffers for this component
    final buffersToRemove = <String>[];
    for (final entry in _trackedBuffers.entries) {
      if (entry.key.startsWith('${componentKey}_')) {
        buffersToRemove.add(entry.key);
        _totalTrackedBytes -= entry.value.length;
      }
    }

    // Remove tracked buffers
    for (final key in buffersToRemove) {
      _trackedBuffers.remove(key);
    }

    // Clear component usage
    _componentMemoryUsage.remove(componentKey);

    debugPrint(
        'MemoryMonitor: Untracked ${buffersToRemove.length} buffers for $component');
  }

  /// Get comprehensive memory statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'isMonitoring': _isMonitoring,
      'totalTrackedBytes': _totalTrackedBytes,
      'maxAllowedBytes': AppConfig.maxImageBufferSizeBytes,
      'memoryUtilization': AppConfig.maxImageBufferSizeBytes > 0
          ? (_totalTrackedBytes / AppConfig.maxImageBufferSizeBytes * 100)
                  .toStringAsFixed(1) +
              '%'
          : '0%',
      'trackedBuffersCount': _trackedBuffers.length,
      'componentMemoryUsage': Map.from(_componentMemoryUsage),
      'cleanupTimerActive': _cleanupTimer?.isActive ?? false,
    };
  }

  /// Get component-specific memory usage
  int getComponentMemoryUsage(String component) {
    return _componentMemoryUsage['image_$component'] ?? 0;
  }

  /// Check if memory usage is within acceptable limits
  bool isMemoryUsageAcceptable() {
    final usagePercent =
        _totalTrackedBytes / AppConfig.maxImageBufferSizeBytes * 100;
    return usagePercent < (AppConfig.maxMemoryUsageThreshold * 100);
  }

  /// Get memory pressure level
  String getMemoryPressureLevel() {
    final usagePercent =
        _totalTrackedBytes / AppConfig.maxImageBufferSizeBytes * 100;

    if (usagePercent < 50) return 'GOOD';
    if (usagePercent < 75) return 'WARNING';
    return 'CRITICAL';
  }

  /// Perform emergency memory cleanup
  void performEmergencyCleanup() {
    debugPrint('MemoryMonitor: Performing emergency cleanup...');
    _performFullCleanup();
    _logMemoryStats('EMERGENCY_CLEANUP');
  }

  /// Force garbage collection hint
  void forceGarbageCollection() {
    if (kIsWeb) {
      debugPrint('MemoryMonitor: Web platform - GC hint');
      // Web doesn't have explicit GC control
    } else {
      debugPrint('MemoryMonitor: Native platform - GC hint');
      // Native platforms - could trigger platform-specific GC
    }
  }

  /// Log current memory statistics
  void _logMemoryStats(String event) {
    if (!AppConfig.enablePerformanceLogging) return;

    final stats = getMemoryStats();
    final pressureLevel = getMemoryPressureLevel();

    debugPrint(
        'MemoryMonitor [$event]: ${stats.toString()} (Pressure: $pressureLevel)');

    // Log high memory usage warnings
    if (pressureLevel == 'CRITICAL') {
      debugPrint(
          'MemoryMonitor: CRITICAL memory usage detected! Consider optimization.');
    } else if (pressureLevel == 'WARNING') {
      debugPrint('MemoryMonitor: WARNING memory usage - monitor closely');
    }
  }

  /// Perform periodic cleanup
  void _performPeriodicCleanup() {
    if (!AppConfig.enableMemoryMonitoring) return;

    debugPrint('MemoryMonitor: Performing periodic cleanup...');

    // Clean up old buffers (keep only the most recent)
    final buffersByComponent = <String, List<MapEntry<String, Uint8List>>>{};

    // Group buffers by component
    for (final entry in _trackedBuffers.entries) {
      final component = entry.key.split('_')[1]; // Extract component name
      buffersByComponent[component] ??= [];
      buffersByComponent[component]!.add(entry);
    }

    // Keep only the most recent buffer per component if over limit
    for (final component in buffersByComponent.keys) {
      final buffers = buffersByComponent[component]!;
      if (buffers.length > AppConfig.maxConcurrentImages) {
        buffers.sort((a, b) =>
            b.key.compareTo(a.key)); // Sort by timestamp (newest first)

        // Remove oldest buffers
        for (int i = AppConfig.maxConcurrentImages; i < buffers.length; i++) {
          _trackedBuffers.remove(buffers[i].key);
          _totalTrackedBytes -= buffers[i].value.length;
        }
      }
    }

    _logMemoryStats('PERIODIC_CLEANUP');
  }

  /// Perform full cleanup
  void _performFullCleanup() {
    debugPrint('MemoryMonitor: Performing full cleanup...');

    _trackedBuffers.clear();
    _componentMemoryUsage.clear();
    _totalTrackedBytes = 0;

    // Force GC hint
    forceGarbageCollection();
  }

  /// Get recommendations for memory optimization
  List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    final pressureLevel = getMemoryPressureLevel();
    final stats = getMemoryStats();

    if (pressureLevel == 'CRITICAL') {
      recommendations.add(
          'URGENT: Memory usage is critical - consider reducing image resolution');
      recommendations.add('URGENT: Implement more aggressive frame throttling');
      recommendations.add('URGENT: Consider reducing concurrent processing');
    } else if (pressureLevel == 'WARNING') {
      recommendations.add('Memory usage is high - monitor closely');
      recommendations.add('Consider reducing image buffer size if possible');
    }

    if (stats['trackedBuffersCount'] > AppConfig.maxConcurrentImages * 2) {
      recommendations.add('Too many tracked buffers - consider faster cleanup');
    }

    if (stats['totalTrackedBytes'] > AppConfig.maxImageBufferSizeBytes * 0.8) {
      recommendations.add('Close to memory limit - prepare for cleanup');
    }

    return recommendations;
  }

  /// Dispose all resources
  void dispose() {
    stopMonitoring();
    _trackedBuffers.clear();
    _componentMemoryUsage.clear();
    _totalTrackedBytes = 0;
    _instance = null;
    debugPrint('MemoryMonitor: Disposed');
  }
}

/// Extension for easier memory monitoring integration
extension MemoryMonitorExtension on Object {
  /// Track this object as a memory-managed buffer
  bool trackAsBuffer(String component, Uint8List buffer) {
    return MemoryMonitor.instance.trackImageBuffer(component, buffer);
  }

  /// Untrack buffers for this component
  void untrackBuffer(String component) {
    MemoryMonitor.instance.untrackImageBuffer(component);
  }

  /// Get memory statistics for this component
  int get memoryUsage {
    return MemoryMonitor.instance
        .getComponentMemoryUsage(runtimeType.toString());
  }
}

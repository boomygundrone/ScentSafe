import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance {
    _instance ??= PerformanceService._();
    return _instance!;
  }
  
  PerformanceService._();

  final Battery _battery = Battery();
  Timer? _performanceMonitorTimer;
  bool _isLowPowerMode = false;
  int _currentBatteryLevel = 100;
  
  /// Initialize performance monitoring
  Future<void> initialize() async {
    // Get initial battery level
    _currentBatteryLevel = await _battery.batteryLevel;
    
    // Listen to battery changes
    _battery.onBatteryStateChanged.listen((state) {
      _handleBatteryStateChange(state);
    });
    
    // Start performance monitoring
    _startPerformanceMonitoring();
  }
  
  /// Handle battery state changes
  Future<void> _handleBatteryStateChange(BatteryState state) async {
    switch (state) {
      case BatteryState.charging:
        _isLowPowerMode = false;
        break;
      case BatteryState.discharging:
        _currentBatteryLevel = await _battery.batteryLevel;
        _isLowPowerMode = _currentBatteryLevel < 20;
        break;
      case BatteryState.full:
        _isLowPowerMode = false;
        _currentBatteryLevel = 100;
        break;
      case BatteryState.connectedNotCharging:
        _currentBatteryLevel = await _battery.batteryLevel;
        _isLowPowerMode = _currentBatteryLevel < 20;
        break;
      case BatteryState.unknown:
        break;
    }
    
    debugPrint('Battery state changed: $state, Level: $_currentBatteryLevel%');
  }
  
  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPerformanceMetrics();
    });
  }
  
  /// Check performance metrics and adjust accordingly
  void _checkPerformanceMetrics() async {
    if (_isLowPowerMode) {
      debugPrint('Low power mode detected, optimizing performance');
      // Reduce processing frequency
      // Lower camera resolution
      // Reduce ML processing frequency
    }
  }
  
  /// Get optimal camera resolution based on device performance
  String getOptimalCameraResolution() {
    if (_isLowPowerMode) {
      return 'low';
    } else if (_currentBatteryLevel < 50) {
      return 'medium';
    } else {
      return 'high';
    }
  }
  
  /// Get optimal detection frequency based on device performance
  int getOptimalDetectionFrequency() {
    if (_isLowPowerMode) {
      return 1000; // 1 second
    } else if (_currentBatteryLevel < 50) {
      return 500; // 500ms
    } else {
      return 100; // 100ms
    }
  }
  
  /// Check if device is low-end
  Future<bool> isLowEndDevice() async {
    if (kIsWeb) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        // Use a heuristic based on device model and SDK version for low-end detection
        final sdkInt = androidInfo.version.sdkInt;
        final model = androidInfo.model;
        // Consider Android devices with SDK < 29 or specific low-end models as low-end
        return sdkInt < 29 || _isKnownLowEndAndroidModel(model);
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        final model = iosInfo.model;
        // Consider older iPhone models as low-end
        return model.contains('iPhone 6') || 
               model.contains('iPhone 7') || 
               model.contains('iPhone 8');
      }
    } catch (e) {
      debugPrint('Error checking device performance: $e');
    }
    
    return false;
  }
  
  /// Check if Android model is known low-end device
  bool _isKnownLowEndAndroidModel(String model) {
    final lowEndModels = [
      'Galaxy J2',
      'Galaxy J3',
      'Galaxy J5',
      'Galaxy J7',
      'Galaxy A10',
      'Galaxy A20',
      'Moto E4',
      'Moto G5',
      'Moto G6',
      'Nokia 2',
      'Nokia 3',
      'Redmi 5',
      'Redmi 6',
      'Redmi 7',
    ];
    
    return lowEndModels.any((lowEndModel) =>
        model.toLowerCase().contains(lowEndModel.toLowerCase()));
  }
  
  /// Dispose performance service
  void dispose() {
    _performanceMonitorTimer?.cancel();
    _performanceMonitorTimer = null;
  }
}
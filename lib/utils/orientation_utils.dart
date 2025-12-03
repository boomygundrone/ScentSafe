import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

/// Utility class for device orientation detection and management
class OrientationUtils {
  static OrientationUtils? _instance;
  static OrientationUtils get instance {
    _instance ??= OrientationUtils._();
    return _instance!;
  }

  OrientationUtils._();

  // Stream controller to broadcast orientation changes
  final StreamController<Orientation> _orientationController =
      StreamController<Orientation>.broadcast();

  /// Stream of orientation changes
  Stream<Orientation> get orientationStream => _orientationController.stream;

  /// Current device orientation
  Orientation _currentOrientation = Orientation.portrait;

  /// Get current device orientation
  Orientation get currentOrientation => _currentOrientation;

  /// Initialize orientation monitoring
  void initialize() {
    // Set initial orientation based on current device orientation
    _updateCurrentOrientation();

    // Listen for orientation changes
    WidgetsBinding.instance.addObserver(_OrientationObserver(this));
  }

  /// Update current orientation from device
  void _updateCurrentOrientation() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final newOrientation = view.physicalSize.width > view.physicalSize.height
        ? Orientation.landscape
        : Orientation.portrait;

    if (newOrientation != _currentOrientation) {
      _currentOrientation = newOrientation;
      _orientationController.add(_currentOrientation);
      debugPrint(
          'OrientationUtils: Orientation changed to $_currentOrientation');
    }
  }

  /// Check if device is in portrait mode
  bool get isPortrait => _currentOrientation == Orientation.portrait;

  /// Check if device is in landscape mode
  bool get isLandscape => _currentOrientation == Orientation.landscape;

  /// Get appropriate resolution based on current orientation
  (int width, int height) getOrientationSpecificResolution() {
    if (isPortrait) {
      return (
        AppConfig.cameraResolutionWidthPortrait,
        AppConfig.cameraResolutionHeightPortrait
      );
    } else {
      return (
        AppConfig.cameraResolutionWidthLandscape,
        AppConfig.cameraResolutionHeightLandscape
      );
    }
  }

  /// Get aspect ratio based on current orientation
  double getOrientationSpecificAspectRatio() {
    final (width, height) = getOrientationSpecificResolution();
    return width / height;
  }

  /// Dispose resources
  void dispose() {
    if (!_orientationController.isClosed) {
      _orientationController.close();
    }
  }
}

/// Observer for device orientation changes
class _OrientationObserver with WidgetsBindingObserver {
  final OrientationUtils orientationUtils;

  _OrientationObserver(this.orientationUtils);

  @override
  void didChangeMetrics() {
    orientationUtils._updateCurrentOrientation();
  }
}

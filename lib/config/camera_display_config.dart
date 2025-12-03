/// Camera Display Configuration
/// Provides easy switching between different camera feed display options
/// for testing and comparison purposes

import 'package:flutter/material.dart';
import '../utils/orientation_utils.dart';

/// Display mode options for camera feed
enum DisplayMode {
  option1_letterbox, // Quick Fix: BoxFit.contain with letterboxing
  option2_dynamic, // Dynamic aspect ratio matching
  option3_standardized, // Standardized 16:9 containers
  option4_native, // Native camera aspect ratio (FIXED: Best for preventing stretch)
  original_stretch, // Original with BoxFit.cover (for comparison)
}

class CameraDisplayConfig {
  /// Current display mode - FIXED: Use native aspect ratio to prevent stretching
  static DisplayMode currentMode = DisplayMode.option4_native;

  /// Aspect ratio options for standardized containers
  static final Map<DisplayMode, double> aspectRatios = {
    DisplayMode.option1_letterbox: 16 / 9,
    DisplayMode.option2_dynamic: 16 / 9,
    DisplayMode.option3_standardized: 16 / 9,
    DisplayMode.option4_native:
        0, // 0 indicates use camera's native aspect ratio
    DisplayMode.original_stretch: 16 / 9,
  };

  /// Get orientation-specific aspect ratio
  static double getOrientationSpecificAspectRatio() {
    return OrientationUtils.instance.getOrientationSpecificAspectRatio();
  }

  /// Get orientation-specific standardized aspect ratio
  static double getOrientationSpecificStandardizedRatio() {
    final orientation = OrientationUtils.instance.currentOrientation;
    return orientation == Orientation.portrait ? 9 / 16 : 16 / 9;
  }

  /// BoxFit options for each display mode
  static final Map<DisplayMode, BoxFit> boxFits = {
    DisplayMode.option1_letterbox: BoxFit.contain,
    DisplayMode.option2_dynamic: BoxFit.contain,
    DisplayMode.option3_standardized: BoxFit.contain,
    DisplayMode.option4_native:
        BoxFit.contain, // FIXED: Use contain to prevent stretching
    DisplayMode.original_stretch: BoxFit.cover,
  };

  /// Get description for each display mode
  static String getDescription(DisplayMode mode) {
    final orientation = OrientationUtils.instance.currentOrientation;
    final aspectRatio = orientation == Orientation.portrait ? '9:16' : '16:9';

    switch (mode) {
      case DisplayMode.option1_letterbox:
        return 'Quick Fix: Letterboxing with BoxFit.contain - Prevents stretching, adds padding';
      case DisplayMode.option2_dynamic:
        return 'Dynamic: Adapts to container proportions - Most flexible option';
      case DisplayMode.option3_standardized:
        return 'Standardized: $aspectRatio aspect ratio containers - Most consistent UI';
      case DisplayMode.option4_native:
        return 'FIXED: Native camera aspect ratio - Best option to prevent stretching';
      case DisplayMode.original_stretch:
        return 'Original: BoxFit.cover stretching - Shows the original problem for comparison';
    }
  }

  /// Get display mode name
  static String getModeName(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.option1_letterbox:
        return 'Option 1: Letterboxing';
      case DisplayMode.option2_dynamic:
        return 'Option 2: Dynamic Matching';
      case DisplayMode.option3_standardized:
        return 'Option 3: Standardized';
      case DisplayMode.option4_native:
        return 'Option 4: Native (FIXED)';
      case DisplayMode.original_stretch:
        return 'Original: Stretching';
    }
  }

  /// Switch to a different display mode
  static void setDisplayMode(DisplayMode mode) {
    currentMode = mode;
    debugPrint('Camera display mode changed to: ${getModeName(mode)}');
  }

  /// Get current display mode
  static DisplayMode get currentDisplayMode => currentMode;

  /// Get current aspect ratio
  static double get currentAspectRatio => aspectRatios[currentMode]!;

  /// Get current BoxFit
  static BoxFit get currentBoxFit => boxFits[currentMode]!;

  /// Get all available modes for testing UI
  static List<DisplayMode> get allModes => DisplayMode.values;

  /// Test results storage
  static Map<DisplayMode, String> testResults = {};

  /// Record test result for a display mode
  static void recordTestResult(DisplayMode mode, String result) {
    testResults[mode] = result;
  }

  /// Get test result for a display mode
  static String? getTestResult(DisplayMode mode) {
    return testResults[mode];
  }

  /// Clear all test results
  static void clearTestResults() {
    testResults.clear();
  }

  /// Check if a display mode is the current active mode
  static bool isCurrentMode(DisplayMode mode) {
    return currentMode == mode;
  }
}

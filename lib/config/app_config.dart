/// Centralized application configuration management
/// Extracts all magic numbers and settings for better maintainability
class AppConfig {
  // Camera Configuration - CRITICAL FIX: Reduced resolution for memory optimization
  // Landscape resolution (default)
  static const int cameraResolutionWidthLandscape = 640;
  static const int cameraResolutionHeightLandscape = 360;
  // Portrait resolution for vertical orientation
  static const int cameraResolutionWidthPortrait = 360;
  static const int cameraResolutionHeightPortrait = 640;
  // Legacy properties for backward compatibility
  static const int cameraResolutionWidth = cameraResolutionWidthLandscape;
  static const int cameraResolutionHeight = cameraResolutionHeightLandscape;
  static const int defaultCameraOrientation = 0;

  // Detection Configuration - Optimized for performance
  static const int detectionTimerIntervalMs =
      2000; // CRITICAL FIX: Increased to 2000ms to reduce processing load
  static const int frameThrottleEveryNFrames =
      5; // CRITICAL FIX: Increased from 3 to 5 for better memory management
  static const int earHistoryMaxLength = 100;

  // Detection Thresholds - Optimized for mobile conditions
  static const double earThreshold = 0.25;
  static const double marThreshold =
      0.65; // FIXED: Realistic MAR threshold for height/width ratio (open mouth >0.65)
  static const int earConsecutiveFrames =
      2; // CRITICAL FIX: Reduced from 3 to 2 for faster response
  static const int marConsecutiveFrames =
      2; // Reduced from 3 to 2 for faster yawn detection
  static const int headTiltThresholdDegrees =
      8; // Reduced from 15 to 8 based on real-world testing
  static const int blinkResetTimeSeconds = 60;

  // Fatigue Scoring - Lowered thresholds for better mobile detection
  static const int blinkThresholdForFatigue =
      10; // CRITICAL FIX: Reduced from 15 to 10
  static const int yawnThresholdForFatigue =
      2; // CRITICAL FIX: Reduced from 3 to 2
  static const double drowsinessScoreThreshold =
      40.0; // CRITICAL FIX: Reduced from 50 to 40
  static const double blinkWeight = 0.4;
  static const double yawnWeight = 0.3;
  static const double headTiltWeight = 0.3;
  static const int maxBlinkCountForScoring = 25; // From Python version
  static const int maxYawnCountForScoring = 3; // From Python version

  // Advanced Fatigue Detection Thresholds
  static const double earConfidenceThreshold =
      0.8; // 80% of EAR threshold for confidence
  static const double marConfidenceThreshold =
      1.5; // 150% of MAR threshold for confidence
  static const double headTiltConfidenceThreshold =
      1.5; // 150% of head tilt threshold for confidence

  // Multi-indicator fatigue thresholds
  static const double multiIndicatorEarThreshold = 0.8; // 80% of EAR threshold
  static const double multiIndicatorMarThreshold = 1.5; // 150% of MAR threshold
  static const double multiIndicatorHeadTiltThreshold =
      1.5; // 150% of head tilt threshold
  static const int multiIndicatorBlinkThreshold = 25; // Higher blink threshold
  static const int multiIndicatorYawnThreshold = 8; // Higher yawn threshold
  static const int multiIndicatorMinIndicators =
      2; // Require at least 2 indicators

  // Severe fatigue thresholds
  static const int severeBlinkThreshold = 30;
  static const int severeYawnThreshold = 8;
  static const double severeHeadTiltThreshold =
      1.2; // 120% of head tilt threshold

  // ML Kit eye detection thresholds
  static const double mlKitEyeOpenProbabilityThreshold =
      0.3; // Consider eyes closed if < 30% open probability
  static const double earFallbackThreshold =
      0.05; // EAR threshold adjustment for fallback detection

  // Sustained mouth opening thresholds
  static const int sustainedMouthOpeningMultiplier =
      2; // 2x MAR_CONSECUTIVE_FRAMES

  // Face Detection Configuration
  static const double minFaceSize =
      0.01; // CRITICAL FIX: Increased from 0.001 for stability
  static const int eyePointCount = 6; // 6 points for EAR calculation
  static const int mouthPointCount = 12; // 12 points for MAR calculation
  static const double approximateEyeWidth = 20.0;
  static const double approximateEyeHeight = 10.0;
  static const double approximateMouthHeight = 30.0;

  // Performance Configuration - Optimized for frame rate
  static const int maxConsecutiveErrors = 5;
  static const Duration errorRetryDelay = Duration(milliseconds: 1000);
  static const Duration serviceInitializationTimeout = Duration(seconds: 10);
  static const int targetFPS = 30; // Target 30 FPS for better performance
  static const int maxFrameProcessingTimeMs =
      20; // Maximum acceptable frame processing time
  static const bool enablePerformanceMonitoring =
      true; // Enable performance tracking
  static const int performanceLogIntervalSeconds =
      5; // Log metrics every 5 seconds

  // Audio Configuration
  static const int audioBufferSize = 1024;
  static const double audioAlertVolume = 0.8;
  static const Duration audioAlertDuration = Duration(seconds: 2);

  // Bluetooth Configuration
  static const Duration bluetoothScanTimeout = Duration(seconds: 10);
  static const Duration bluetoothConnectionTimeout = Duration(seconds: 5);
  static const int minRssiThreshold = -80;

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;

  // Development/Testing - PRODUCTION OPTIMIZATION
  static const bool enableVerboseLogging =
      true; // CRITICAL FIX: Enabled for debugging face detection issues
  static const bool enablePerformanceLogging = true;
  static const bool enableDebugScreenshots = false;

  // Memory Management Configuration - PERFORMANCE OPTIMIZATION
  static const int maxImageBufferSizeBytes =
      2097152; // OPTIMIZED: Reduced to 2MB for better performance
  static const int maxConcurrentImages =
      3; // OPTIMIZED: Increased to 3 for better throughput
  static const int imageProcessingTimeoutMs =
      3000; // OPTIMIZED: Increased to 3 second timeout
  static const bool enableMemoryMonitoring =
      true; // Enable memory leak detection
  static const int memoryCleanupIntervalSeconds =
      30; // OPTIMIZED: Increased to 30 seconds to reduce GC pressure
  static const double maxMemoryUsageThreshold =
      0.8; // OPTIMIZED: Increased to 80% to reduce premature cleanup
}

/// Feature flags for development and testing
class FeatureFlags {
  static const bool useMockServices = true;
  static const bool enableExperimentalFeatures = false;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableMemoryLeakDetection = true;
  static const bool enableStrictMode = false; // Enable strict null checks
}

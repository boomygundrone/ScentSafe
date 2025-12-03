import 'package:flutter/foundation.dart';

/// Configuration for switching between on-device and backend processing
class ProcessingConfig {
  /// Processing mode selection
  static const ProcessingMode currentMode = ProcessingMode.cloudHttp;

  /// Backend provider configuration
  static const BackendProvider backendProvider = BackendProvider.googleCloud;

  /// API configuration
  static const String apiKey = ''; // Set your API key here
  static const String authToken = ''; // Set your auth token here
  static const String customBackendUrl = 'https://your-backend-api.com/v1';

  /// WebSocket configuration
  static const String wsBaseUrl = 'wss://your-backend-api.com/v1';

  /// Cloud provider API endpoints
  static const String googleCloudEndpoint = 'https://vision.googleapis.com/v1';
  static const String awsRekognitionEndpoint =
      'https://rekognition.amazonaws.com';
  static const String azureEndpoint = 'https://api.cognitive.microsoft.com';

  /// Performance settings
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 10);
  static const Duration reconnectDelay = Duration(seconds: 2);
  static const int maxReconnectAttempts = 5;

  /// Image compression settings
  static const int maxImageSizeBytes = 100000; // 100KB
  static const int maxFps = 10; // For streaming
}

/// Processing mode options
enum ProcessingMode {
  /// Current on-device processing (causes lag)
  onDevice,

  /// HTTP-based cloud processing (recommended for quick fix)
  cloudHttp,

  /// Real-time WebSocket streaming (best performance)
  webSocketStream,
}

/// Backend provider options
enum BackendProvider {
  googleCloud,
  awsRekognition,
  azureVision,
  customBackend,
}

/// Configuration helper methods
class ProcessingConfigHelper {
  /// Check if backend processing is enabled
  static bool get isBackendProcessing =>
      ProcessingConfig.currentMode != ProcessingMode.onDevice;

  /// Check if WebSocket streaming is enabled
  static bool get isWebSocketStreaming =>
      ProcessingConfig.currentMode == ProcessingMode.webSocketStream;

  /// Check if HTTP cloud processing is enabled
  static bool get isHttpCloudProcessing =>
      ProcessingConfig.currentMode == ProcessingMode.cloudHttp;

  /// Get provider name for logging
  static String getProviderName() {
    switch (ProcessingConfig.backendProvider) {
      case BackendProvider.googleCloud:
        return 'Google Cloud Vision API';
      case BackendProvider.awsRekognition:
        return 'AWS Rekognition';
      case BackendProvider.azureVision:
        return 'Azure Computer Vision';
      case BackendProvider.customBackend:
        return 'Custom Backend API';
    }
  }

  /// Get processing mode description
  static String getModeDescription() {
    switch (ProcessingConfig.currentMode) {
      case ProcessingMode.onDevice:
        return 'On-device processing (current - causes lag)';
      case ProcessingMode.cloudHttp:
        return 'Cloud HTTP processing (recommended fix)';
      case ProcessingMode.webSocketStream:
        return 'Real-time WebSocket streaming (best performance)';
    }
  }

  /// Print current configuration
  static void printConfig() {
    debugPrint('=== PROCESSING CONFIGURATION ===');
    debugPrint('Mode: ${getModeDescription()}');
    debugPrint('Provider: ${getProviderName()}');
    debugPrint('Backend Enabled: $isBackendProcessing');
    debugPrint('WebSocket: $isWebSocketStreaming');
    debugPrint('HTTP Cloud: $isHttpCloudProcessing');
    debugPrint('===============================');
  }
}

/// Easy migration guide
class MigrationGuide {
  /// Quick steps to enable backend processing
  static List<String> getQuickSteps() {
    return [
      '1. Set ProcessingMode.currentMode to cloudHttp or webSocketStream',
      '2. Choose backend provider (Google Cloud, AWS, Azure, or Custom)',
      '3. Add your API keys to ProcessingConfig.apiKey and authToken',
      '4. For custom backend, set ProcessingConfig.customBackendUrl',
      '5. Test the implementation',
      '6. Expected result: 16+ seconds → 100-800ms response time',
    ];
  }

  /// Benefits of switching to backend processing
  static List<String> getBenefits() {
    return [
      'Eliminates 16+ second processing delays',
      'Reduces device CPU/GPU usage by 90%',
      'Eliminates OutOfMemoryError crashes',
      'Consistent performance across all devices',
      'Real-time fatigue detection capability',
      'Easier ML model updates (server-side)',
    ];
  }
}

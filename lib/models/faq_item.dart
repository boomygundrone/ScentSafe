/// FAQ Category enum for categorizing questions
enum FAQCategory {
  general,
  detection,
  aroma,
  bluetooth,
  privacy,
  troubleshooting,
}

/// FAQ Item model containing question, answer, and category
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final FAQCategory category;
  final List<String> tags;

  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
  });

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case FAQCategory.general:
        return 'General';
      case FAQCategory.detection:
        return 'Detection';
      case FAQCategory.aroma:
        return 'Aroma';
      case FAQCategory.bluetooth:
        return 'Bluetooth';
      case FAQCategory.privacy:
        return 'Privacy & Security';
      case FAQCategory.troubleshooting:
        return 'Troubleshooting';
    }
  }

  /// Get category icon
  String get categoryIcon {
    switch (category) {
      case FAQCategory.general:
        return 'info';
      case FAQCategory.detection:
        return 'visibility';
      case FAQCategory.aroma:
        return 'spa';
      case FAQCategory.bluetooth:
        return 'bluetooth';
      case FAQCategory.privacy:
        return 'security';
      case FAQCategory.troubleshooting:
        return 'build';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category.name,
      'tags': tags,
    };
  }

  /// Create FAQItem from JSON
  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: FAQCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FAQCategory.general,
      ),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

/// FAQ Data Repository containing all FAQ items
class FAQRepository {
  static List<FAQItem> getAllFAQs() {
    return [
      // General Questions
      FAQItem(
        id: 'gen_001',
        question: 'What is ScentSafe?',
        answer:
            'ScentSafe is an AI-powered driver safety application that detects drowsiness through facial analysis and automatically activates aroma diffusers to help keep you alert while driving.',
        category: FAQCategory.general,
        tags: ['overview', 'introduction', 'about'],
      ),
      FAQItem(
        id: 'gen_002',
        question: 'How does ScentSafe work?',
        answer:
            'ScentSafe uses your device\'s camera to monitor facial features in real-time. It analyzes eye movements, blink patterns, and head position to detect signs of drowsiness. When fatigue is detected, it can trigger alerts and activate connected aroma diffusers.',
        category: FAQCategory.general,
        tags: ['how it works', 'overview', 'features'],
      ),
      FAQItem(
        id: 'gen_003',
        question: 'What devices are compatible with ScentSafe?',
        answer:
            'ScentSafe works on Android and iOS devices with a front-facing camera. For best results, we recommend devices with at least 2GB RAM and running Android 8.0+ or iOS 13.0+.',
        category: FAQCategory.general,
        tags: ['compatibility', 'requirements', 'devices'],
      ),
      FAQItem(
        id: 'gen_004',
        question: 'Does ScentSafe work offline?',
        answer:
            'Yes! All drowsiness detection happens locally on your device. You don\'t need an internet connection for the core functionality. However, some features like cloud sync and updates require internet access.',
        category: FAQCategory.general,
        tags: ['offline', 'internet', 'connectivity'],
      ),

      // Detection Questions
      FAQItem(
        id: 'det_001',
        question: 'How accurate is the drowsiness detection?',
        answer:
            'Our AI model has been trained on thousands of facial patterns and achieves approximately 95% accuracy in detecting drowsiness under optimal conditions. Accuracy may vary based on lighting conditions, camera quality, and individual facial characteristics.',
        category: FAQCategory.detection,
        tags: ['accuracy', 'performance', 'ai'],
      ),
      FAQItem(
        id: 'det_002',
        question: 'What lighting conditions work best?',
        answer:
            'ScentSafe works best in moderate to bright lighting. Avoid direct sunlight on the camera lens and ensure your face is well-lit without harsh shadows. The app can adapt to low-light conditions but accuracy may decrease.',
        category: FAQCategory.detection,
        tags: ['lighting', 'environment', 'conditions'],
      ),
      FAQItem(
        id: 'det_003',
        question: 'Can I wear sunglasses while using ScentSafe?',
        answer:
            'Sunglasses can interfere with eye detection. For optimal performance, we recommend removing sunglasses or using non-polarized glasses. Regular prescription glasses typically work fine.',
        category: FAQCategory.detection,
        tags: ['glasses', 'sunglasses', 'accessories'],
      ),
      FAQItem(
        id: 'det_004',
        question: 'What are the drowsiness levels?',
        answer:
            'ScentSafe categorizes drowsiness into four levels:\n\n1. Alert - No signs of fatigue\n2. Mild Fatigue - Slight indicators, monitoring continues\n3. Moderate Fatigue - Clear signs of fatigue, alerts activated\n4. Severe Fatigue - Strong indicators, immediate alerts and aroma activation',
        category: FAQCategory.detection,
        tags: ['levels', 'fatigue', 'classification'],
      ),
      FAQItem(
        id: 'det_005',
        question: 'How does the app detect yawning?',
        answer:
            'The app analyzes mouth movements and facial expressions to identify yawning patterns. It measures mouth opening duration and frequency to distinguish between normal expressions and fatigue-related yawning.',
        category: FAQCategory.detection,
        tags: ['yawning', 'mouth', 'detection'],
      ),
      FAQItem(
        id: 'det_006',
        question: 'Does the app track head position?',
        answer:
            'Yes, ScentSafe monitors head tilt and position. Sudden or prolonged head drooping is a strong indicator of drowsiness and will trigger appropriate alerts.',
        category: FAQCategory.detection,
        tags: ['head', 'position', 'tilt'],
      ),

      // Aroma Questions
      FAQItem(
        id: 'aro_001',
        question: 'What is the aroma diffuser?',
        answer:
            'The aroma diffuser is a Bluetooth-enabled device that releases scents to help stimulate your senses and increase alertness. It connects wirelessly to your phone and activates automatically when drowsiness is detected.',
        category: FAQCategory.aroma,
        tags: ['diffuser', 'device', 'overview'],
      ),
      FAQItem(
        id: 'aro_002',
        question: 'How do I connect my aroma diffuser?',
        answer:
            '1. Ensure Bluetooth is enabled on your device\n2. Navigate to Settings > Bluetooth\n3. Tap "Scan for Devices"\n4. Select your aroma diffuser from the list\n5. Follow the on-screen pairing instructions',
        category: FAQCategory.aroma,
        tags: ['connection', 'pairing', 'setup'],
      ),
      FAQItem(
        id: 'aro_003',
        question: 'What scents are available?',
        answer:
            'ScentSafe offers various scent profiles including:\n- Lavender Relax (calming)\n- Peppermint Alert (stimulating)\n- Citrus Fresh (energizing)\n- Eucalyptus Clear (refreshing)\n\nYou can purchase additional scent packs in the in-app store.',
        category: FAQCategory.aroma,
        tags: ['scents', 'fragrances', 'options'],
      ),
      FAQItem(
        id: 'aro_004',
        question: 'When does the aroma activate?',
        answer:
            'The aroma diffuser activates when moderate or severe drowsiness is detected. This is designed to provide a gentle alert before fatigue becomes dangerous. You can customize the activation threshold in Settings.',
        category: FAQCategory.aroma,
        tags: ['activation', 'timing', 'threshold'],
      ),
      FAQItem(
        id: 'aro_005',
        question: 'How long does the aroma last?',
        answer:
            'Each aroma release lasts approximately 30-60 seconds depending on the diffuser model and scent intensity settings. The device will automatically stop after the alert period.',
        category: FAQCategory.aroma,
        tags: ['duration', 'timing', 'usage'],
      ),
      FAQItem(
        id: 'aro_006',
        question: 'Can I manually trigger the aroma?',
        answer:
            'Yes! You can manually trigger the aroma release from the main dashboard or through quick settings. This is useful for testing or when you want a quick alertness boost.',
        category: FAQCategory.aroma,
        tags: ['manual', 'trigger', 'control'],
      ),

      // Bluetooth Questions
      FAQItem(
        id: 'blu_001',
        question: 'Why won\'t my aroma diffuser connect?',
        answer:
            'Common solutions:\n1. Ensure the diffuser is charged and turned on\n2. Move closer to your device (within 10 feet)\n3. Turn Bluetooth off and on again\n4. Clear Bluetooth cache in your device settings\n5. Try forgetting the device and re-pairing',
        category: FAQCategory.bluetooth,
        tags: ['connection', 'troubleshooting', 'pairing'],
      ),
      FAQItem(
        id: 'blu_002',
        question: 'How do I disconnect my diffuser?',
        answer:
            'Go to Settings > Bluetooth, find your diffuser in the paired devices list, and tap "Forget" or "Unpair". You can also disconnect temporarily from the app without removing the pairing.',
        category: FAQCategory.bluetooth,
        tags: ['disconnect', 'unpair', 'remove'],
      ),
      FAQItem(
        id: 'blu_003',
        question: 'Can I connect multiple diffusers?',
        answer:
            'Currently, ScentSafe supports one aroma diffuser at a time. If you have multiple diffusers, you can switch between them in the Bluetooth settings.',
        category: FAQCategory.bluetooth,
        tags: ['multiple', 'devices', 'switching'],
      ),
      FAQItem(
        id: 'blu_004',
        question: 'What is the Bluetooth range?',
        answer:
            'The typical Bluetooth range is up to 30 feet (10 meters) in optimal conditions. Walls, interference, and other factors can reduce this range. Keep your phone reasonably close to the diffuser for best performance.',
        category: FAQCategory.bluetooth,
        tags: ['range', 'distance', 'connectivity'],
      ),

      // Privacy Questions
      FAQItem(
        id: 'pri_001',
        question: 'Is my video data stored or transmitted?',
        answer:
            'No! All video processing happens locally on your device. We do not store, transmit, or have access to your camera feed. Your privacy is our top priority.',
        category: FAQCategory.privacy,
        tags: ['video', 'storage', 'privacy'],
      ),
      FAQItem(
        id: 'pri_002',
        question: 'What data does ScentSafe collect?',
        answer:
            'ScentSafe only collects:\n- Anonymous usage statistics for app improvement\n- Crash reports for debugging\n- Optional account information (if you create an account)\n\nWe never collect personal video, audio, or location data without explicit consent.',
        category: FAQCategory.privacy,
        tags: ['data', 'collection', 'analytics'],
      ),
      FAQItem(
        id: 'pri_003',
        question: 'Is my detection data shared with third parties?',
        answer:
            'Absolutely not. Your drowsiness detection data, including fatigue levels and alerts, remains on your device. We do not share this information with insurance companies, employers, or any third parties.',
        category: FAQCategory.privacy,
        tags: ['sharing', 'third-party', 'data'],
      ),
      FAQItem(
        id: 'pri_004',
        question: 'Can I delete my data?',
        answer:
            'Yes. You can delete all your data from the app by going to Settings > Privacy > Delete My Data. This will remove all locally stored information and any cloud data associated with your account.',
        category: FAQCategory.privacy,
        tags: ['delete', 'removal', 'gdpr'],
      ),
      FAQItem(
        id: 'pri_005',
        question: 'Is ScentSafe GDPR compliant?',
        answer:
            'Yes, ScentSafe is designed to be GDPR compliant. We provide full data transparency, consent management, and the right to be forgotten. You can request a copy of your data or complete deletion at any time.',
        category: FAQCategory.privacy,
        tags: ['gdpr', 'compliance', 'regulation'],
      ),

      // Troubleshooting Questions
      FAQItem(
        id: 'trb_001',
        question: 'The app isn\'t detecting my face',
        answer:
            'Try these solutions:\n1. Ensure good lighting on your face\n2. Clean your camera lens\n3. Position your phone at eye level\n4. Remove sunglasses or hats\n5. Check that camera permissions are granted\n6. Restart the app',
        category: FAQCategory.troubleshooting,
        tags: ['detection', 'camera', 'face'],
      ),
      FAQItem(
        id: 'trb_002',
        question: 'The app crashes when I start detection',
        answer:
            'This may be due to:\n1. Insufficient device memory - close other apps\n2. Outdated app version - check for updates\n3. Camera in use by another app - close other camera apps\n4. Device compatibility - check minimum requirements\n\nTry restarting your device and the app.',
        category: FAQCategory.troubleshooting,
        tags: ['crash', 'startup', 'error'],
      ),
      FAQItem(
        id: 'trb_003',
        question: 'Battery drains quickly',
        answer:
            'Camera-based detection does use battery. To optimize:\n1. Reduce detection frequency in settings\n2. Lower screen brightness\n3. Close background apps\n4. Use battery saver mode when not driving\n5. Ensure your phone is charged before long trips',
        category: FAQCategory.troubleshooting,
        tags: ['battery', 'performance', 'optimization'],
      ),
      FAQItem(
        id: 'trb_004',
        question: 'Alerts are not triggering',
        answer:
            'Check the following:\n1. Verify alert volume is not muted\n2. Check notification permissions\n3. Ensure drowsiness threshold is set appropriately\n4. Test with manual alert trigger\n5. Restart the app if issues persist',
        category: FAQCategory.troubleshooting,
        tags: ['alerts', 'notifications', 'audio'],
      ),
      FAQItem(
        id: 'trb_005',
        question: 'How do I reset the app to default settings?',
        answer:
            'Go to Settings > Advanced > Reset to Defaults. This will restore all settings to their original values but will not delete your account or detection history.',
        category: FAQCategory.troubleshooting,
        tags: ['reset', 'settings', 'defaults'],
      ),
      FAQItem(
        id: 'trb_006',
        question: 'Where can I get additional help?',
        answer:
            'If you need further assistance:\n1. Email us at support@scentsafe.com\n2. Visit our website at www.scentsafe.com\n3. Check our video tutorials in the Help section\n4. Join our community forum for user discussions\n\nWe typically respond within 24 hours.',
        category: FAQCategory.troubleshooting,
        tags: ['support', 'contact', 'help'],
      ),
    ];
  }

  /// Get FAQs by category
  static List<FAQItem> getFAQsByCategory(FAQCategory category) {
    return getAllFAQs().where((faq) => faq.category == category).toList();
  }

  /// Search FAQs by query
  static List<FAQItem> searchFAQs(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllFAQs().where((faq) {
      return faq.question.toLowerCase().contains(lowerQuery) ||
          faq.answer.toLowerCase().contains(lowerQuery) ||
          faq.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get all unique categories
  static List<FAQCategory> getAllCategories() {
    return FAQCategory.values;
  }
}

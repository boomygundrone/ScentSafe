import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

/// Service for managing application localization and language preferences
class LocalizationService {
  static LocalizationService? _instance;
  static LocalizationService get instance {
    _instance ??= LocalizationService._internal();
    return _instance!;
  }

  LocalizationService._internal();

  // Storage keys
  static const String _languageKey = 'app_language';
  static const String _defaultLanguage = 'en';

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('zh', 'HK'), // Traditional Chinese (Hong Kong)
  ];

  // Language codes
  static const String english = 'en-US';
  static const String traditionalChinese = 'zh-HK';

  // Current locale
  Locale _currentLocale = const Locale('en', 'US');

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;

  /// Get current country code
  String? get currentCountryCode => _currentLocale.countryCode;

  /// Initialize localization service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
      await setLocale(savedLanguage);
      debugPrint(
          '✅ Localization service initialized with language: $savedLanguage');
    } catch (e) {
      debugPrint('❌ Failed to initialize localization service: $e');
      // Fallback to default language
      _currentLocale = const Locale('en', 'US');
    }
  }

  /// Set application locale
  Future<void> setLocale(String languageCode) async {
    try {
      Locale newLocale;

      switch (languageCode) {
        case traditionalChinese:
          newLocale = const Locale('zh', 'HK');
          break;
        case english:
        default:
          newLocale = const Locale('en', 'US');
          break;
      }

      _currentLocale = newLocale;

      // Update Intl locale for date/time/currency formatting
      await _updateIntlLocale(newLocale);

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      debugPrint('✅ Locale set to: ${newLocale.toString()}');
    } catch (e) {
      debugPrint('❌ Failed to set locale: $e');
    }
  }

  /// Update Intl locale for formatting
  Future<void> _updateIntlLocale(Locale locale) async {
    try {
      Intl.defaultLocale = locale.toString();
      debugPrint('✅ Intl locale updated to: ${Intl.defaultLocale}');
    } catch (e) {
      debugPrint('❌ Failed to update Intl locale: $e');
    }
  }

  /// Get display name for language
  String getLanguageDisplayName(String languageCode,
      {String? displayLanguageCode}) {
    try {
      switch (languageCode) {
        case traditionalChinese:
          if (displayLanguageCode?.startsWith('zh') ?? false) {
            return '繁體中文';
          }
          return 'Traditional Chinese';
        case english:
        default:
          if (displayLanguageCode?.startsWith('zh') ?? false) {
            return '英文';
          }
          return 'English';
      }
    } catch (e) {
      debugPrint('❌ Failed to get language display name: $e');
      return languageCode;
    }
  }

  /// Format date according to current locale
  String formatDate(DateTime date, {String? pattern}) {
    try {
      if (pattern != null) {
        return DateFormat(pattern, _currentLocale.toString()).format(date);
      }

      // Use locale-specific default formats
      if (_currentLocale.languageCode == 'zh') {
        // Traditional Chinese format: yyyy年MM月dd日
        return DateFormat('yyyy年MM月dd日', _currentLocale.toString())
            .format(date);
      } else {
        // English format: dd/MM/yyyy
        return DateFormat('dd/MM/yyyy', _currentLocale.toString()).format(date);
      }
    } catch (e) {
      debugPrint('❌ Failed to format date: $e');
      return date.toString();
    }
  }

  /// Format time according to current locale
  String formatTime(DateTime time, {bool use24Hour = false}) {
    try {
      if (use24Hour) {
        return DateFormat('HH:mm', _currentLocale.toString()).format(time);
      }

      // Use locale-specific time format
      if (_currentLocale.languageCode == 'zh') {
        // Traditional Chinese uses 24-hour format by default
        return DateFormat('HH:mm', _currentLocale.toString()).format(time);
      } else {
        // English can use 12-hour format
        return DateFormat('h:mm a', _currentLocale.toString()).format(time);
      }
    } catch (e) {
      debugPrint('❌ Failed to format time: $e');
      return time.toString();
    }
  }

  /// Format date and time according to current locale
  String formatDateTime(DateTime dateTime, {bool use24Hour = false}) {
    try {
      final dateStr = formatDate(dateTime);
      final timeStr = formatTime(dateTime, use24Hour: use24Hour);

      if (_currentLocale.languageCode == 'zh') {
        return '$dateStr $timeStr';
      } else {
        return '$dateStr $timeStr';
      }
    } catch (e) {
      debugPrint('❌ Failed to format date time: $e');
      return dateTime.toString();
    }
  }

  /// Format currency according to Hong Kong standards
  String formatCurrency(double amount, {String? currencyCode}) {
    try {
      // Default to HKD for Hong Kong
      final code = currencyCode ?? 'HKD';
      final String symbol = code == 'HKD' ? r'HK$' : code;

      // Format according to locale
      if (_currentLocale.languageCode == 'zh') {
        // Traditional Chinese: HK$1,000.00
        return NumberFormat.currency(
          locale: 'zh_HK',
          symbol: symbol,
          decimalDigits: 2,
        ).format(amount);
      } else {
        // English: HK$1,000.00
        return NumberFormat.currency(
          locale: 'en_HK',
          symbol: symbol,
          decimalDigits: 2,
        ).format(amount);
      }
    } catch (e) {
      debugPrint('❌ Failed to format currency: $e');
      return '$amount';
    }
  }

  /// Format number according to current locale
  String formatNumber(double number, {int? decimalDigits}) {
    try {
      if (decimalDigits != null) {
        return NumberFormat.decimalPattern(_currentLocale.toString())
            .format(number);
      }
      return NumberFormat.decimalPattern(_currentLocale.toString())
          .format(number);
    } catch (e) {
      debugPrint('❌ Failed to format number: $e');
      return number.toString();
    }
  }

  /// Format percentage according to current locale
  String formatPercentage(double value, {int decimalDigits = 1}) {
    try {
      return NumberFormat.percentPattern(_currentLocale.toString())
          .format(value / 100);
    } catch (e) {
      debugPrint('❌ Failed to format percentage: $e');
      return '${value}%';
    }
  }

  /// Get relative time (e.g., "2 hours ago")
  String getRelativeTime(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        if (_currentLocale.languageCode == 'zh') {
          return '${difference.inDays}天前';
        } else {
          return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        }
      } else if (difference.inHours > 0) {
        if (_currentLocale.languageCode == 'zh') {
          return '${difference.inHours}小時前';
        } else {
          return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        }
      } else if (difference.inMinutes > 0) {
        if (_currentLocale.languageCode == 'zh') {
          return '${difference.inMinutes}分鐘前';
        } else {
          return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
        }
      } else {
        if (_currentLocale.languageCode == 'zh') {
          return '剛剛';
        } else {
          return 'Just now';
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to get relative time: $e');
      return dateTime.toString();
    }
  }

  /// Check if current locale is Traditional Chinese
  bool get isTraditionalChinese => _currentLocale.languageCode == 'zh';

  /// Check if current locale is English
  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Get list of available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {
        'code': english,
        'name': getLanguageDisplayName(english),
        'nativeName': 'English',
      },
      {
        'code': traditionalChinese,
        'name': getLanguageDisplayName(traditionalChinese),
        'nativeName': '繁體中文',
      },
    ];
  }

  /// Reset to default language
  Future<void> resetToDefault() async {
    await setLocale(_defaultLanguage);
  }

  /// Clear language preference
  Future<void> clearPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      debugPrint('✅ Language preference cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear language preference: $e');
    }
  }

  /// Get localization delegates for EasyLocalization
  static List<LocalizationsDelegate<dynamic>> get localizationDelegates {
    return [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
  }
}

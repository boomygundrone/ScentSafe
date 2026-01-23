import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../services/app_localization_service.dart';

/// Cubit for managing application locale state
class LocalizationCubit extends Cubit<Locale> {
  final AppLocalizationService _localizationService;
  bool _isInitialized = false;

  LocalizationCubit(this._localizationService)
      : super(const Locale('en', 'US')) {
    // Start with default locale, will update once async init completes
    _initialize();
  }

  /// Initialize cubit with saved locale
  Future<void> _initialize() async {
    await _localizationService.initialize();
    // Only emit after async initialization completes
    emit(_localizationService.currentLocale);
    _isInitialized = true;
  }

  /// Set application locale
  Future<void> setLocale(String languageCode) async {
    await _localizationService.setLocale(languageCode);

    // Get the new locale
    final newLocale = _localizationService.currentLocale;

    // Emit the new locale state for BlocBuilder to rebuild UI
    emit(newLocale);
  }

  /// Get current locale
  Locale get currentLocale => _localizationService.currentLocale;

  /// Check if current locale is Traditional Chinese
  bool get isTraditionalChinese => _localizationService.isTraditionalChinese;

  /// Check if current locale is English
  bool get isEnglish => !_localizationService.isTraditionalChinese;

  /// Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'en-US', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'zh-HK', 'name': '繁體中文', 'flag': '🇭🇰'},
    ];
  }

  /// Reset to default language
  Future<void> resetToDefault() async {
    await _localizationService.setLocale('en-US');
    emit(_localizationService.currentLocale);
  }

  /// Check if cubit has been initialized (async loading complete)
  bool get isInitialized => _isInitialized;
}

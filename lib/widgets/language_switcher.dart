import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/localization_cubit.dart';
import '../services/app_localization_service.dart';

/// Language switcher widget that allows users to toggle between supported languages
class LanguageSwitcher extends StatelessWidget {
  final bool useDropdown;
  final bool showFlag;
  final bool showNativeName;
  final double? iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const LanguageSwitcher({
    super.key,
    this.useDropdown = false,
    this.showFlag = true,
    this.showNativeName = false,
    this.iconSize,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (useDropdown) {
      return _buildDropdown(context);
    } else {
      return _buildToggle(context);
    }
  }

  /// Build dropdown-style language switcher
  Widget _buildDropdown(BuildContext context) {
    return BlocBuilder<LocalizationCubit, Locale>(
      builder: (context, currentLocale) {
        final cubit = context.read<LocalizationCubit>();
        final availableLanguages = cubit.getAvailableLanguages();

        return Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _getLocaleCode(currentLocale),
              icon: Icon(Icons.arrow_drop_down, color: iconColor),
              iconSize: iconSize ?? 24,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: iconColor ?? Colors.black87,
                  ),
              items: availableLanguages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showFlag) ...[
                        _buildLanguageFlag(lang['code']!),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        showNativeName ? lang['name']! : lang['name']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newLanguage) async {
                if (newLanguage != null) {
                  final cubit = context.read<LocalizationCubit>();
                  await cubit.setLocale(newLanguage);
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// Build toggle-style language switcher
  Widget _buildToggle(BuildContext context) {
    return BlocBuilder<LocalizationCubit, Locale>(
      builder: (context, currentLocale) {
        // Handle both initialized and uninitialized states
        final isChinese = currentLocale.languageCode == 'zh';

        return Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3250),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF3D4250)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageButton(
                context,
                code: 'en',
                label: 'EN',
                isSelected: !isChinese,
                onTap: () async {
                  final cubit = context.read<LocalizationCubit>();
                  await cubit.setLocale('en-US');
                },
              ),
              const SizedBox(width: 4),
              _buildLanguageButton(
                context,
                code: 'zh-HK',
                label: '繁',
                isSelected: isChinese,
                onTap: () async {
                  final cubit = context.read<LocalizationCubit>();
                  await cubit.setLocale('zh-HK');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build individual language button
  Widget _buildLanguageButton(
    BuildContext context, {
    required String code,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showFlag) ...[
              _buildLanguageFlag(code),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build language flag emoji
  Widget _buildLanguageFlag(String languageCode) {
    String flagEmoji;
    switch (languageCode) {
      case 'zh-HK':
        flagEmoji = '🇭🇰';
        break;
      case 'en':
      default:
        flagEmoji = '🇬🇧';
        break;
    }

    return Text(
      flagEmoji,
      style: const TextStyle(fontSize: 18),
    );
  }

  /// Get locale code from Locale object
  String _getLocaleCode(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
      return 'zh-HK';
    }
    return 'en';
  }
}

/// Simple language toggle button for use in app bar or toolbar
class LanguageToggleButton extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;

  const LanguageToggleButton({
    super.key,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationCubit, Locale>(
      builder: (context, currentLocale) {
        final cubit = context.read<LocalizationCubit>();
        final isChinese = cubit.isTraditionalChinese;

        return IconButton(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isChinese ? '🇭🇰' : '🇬🇧',
                style: TextStyle(fontSize: iconSize ?? 20),
              ),
              const SizedBox(width: 4),
              Text(
                isChinese ? '繁' : 'EN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          onPressed: () async {
            final cubit = context.read<LocalizationCubit>();
            final newLanguage = isChinese ? 'en-US' : 'zh-HK';
            await cubit.setLocale(newLanguage);
          },
          tooltip: isChinese ? 'Switch to English' : '切換至繁體中文',
        );
      },
    );
  }
}

/// Language selector dialog
class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocalizationCubit>();
    final availableLanguages = cubit.getAvailableLanguages();

    return AlertDialog(
      title: const Text('Language'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: availableLanguages.map((lang) {
          return BlocBuilder<LocalizationCubit, Locale>(
            builder: (context, currentLocale) {
              final isSelected =
                  currentLocale.languageCode == lang['code']?.split('-')[0];

              return ListTile(
                leading: _buildLanguageFlag(lang['code']!),
                title: Text(lang['name']!),
                trailing: isSelected
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  final cubit = context.read<LocalizationCubit>();
                  await cubit.setLocale(lang['code']!);
                  Navigator.of(context).pop();
                },
              );
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildLanguageFlag(String languageCode) {
    String flagEmoji;
    switch (languageCode) {
      case 'zh-HK':
        flagEmoji = '🇭🇰';
        break;
      case 'en':
      default:
        flagEmoji = '🇬🇧';
        break;
    }

    return Text(
      flagEmoji,
      style: const TextStyle(fontSize: 24),
    );
  }

  String _getLocaleCode(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'HK') {
      return 'zh-HK';
    }
    return 'en';
  }
}

/// Show language selector dialog
Future<void> showLanguageSelector(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const LanguageSelectorDialog(),
  );
}

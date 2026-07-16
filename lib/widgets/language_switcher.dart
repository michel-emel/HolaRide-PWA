import 'package:flutter/material.dart';
import '../main.dart';
import '../services/locale_service.dart';
import '../theme/app_colors.dart';

/// Compact circular flag button for the app headers — tapping toggles
/// between English and French (the only two supported locales), same
/// visual language as [NotificationBell]/[ProfileIconButton].
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final isEn = locale.languageCode == 'en';
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => LocaleService.setLocale(Locale(isEn ? 'fr' : 'en')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(isEn ? '🇬🇧' : '🇫🇷', style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Text(isEn ? 'English' : 'Français',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

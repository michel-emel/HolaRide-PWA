import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// A simple support screen. There's no live support inbox wired up
/// yet — replace [_supportEmail] and [_supportPhone] with your real
/// contact details before launch; until then this is left blank
/// rather than showing a fabricated contact that wouldn't actually
/// reach anyone.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String? _supportEmail = null;
  static const String? _supportPhone = null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _faqTile(
            l.helpQ1,
            l.helpA1,
          ),
          _faqTile(
            l.helpQ2,
            l.helpA2,
          ),
          _faqTile(
            l.helpQ3,
            l.helpA3,
          ),
          const SizedBox(height: 20),
          if (_supportEmail == null && _supportPhone == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                l.helpContactNote,
                style: const TextStyle(color: AppColors.warning, fontSize: 12.5),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_supportEmail != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                    title: Text(l.helpEmail),
                    subtitle: Text(_supportEmail!),
                  ),
                if (_supportPhone != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: Text(l.helpCall),
                    subtitle: Text(_supportPhone!),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(answer, style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

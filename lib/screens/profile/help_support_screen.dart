import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _faqTile(
            'How does payment work?',
            'You pay through Mobile Money once a driver accepts your seat request — either the full fare, or a 20% deposit with the rest due before the trip.',
          ),
          _faqTile(
            'What if my driver cancels?',
            'You\'ll be notified immediately and can search for another trip in one tap from your booking.',
          ),
          _faqTile(
            'How do I become a driver?',
            'Go to Profile → Become a Driver, add your vehicle details and photos, and HolaRide will review and approve it.',
          ),
          const SizedBox(height: 20),
          if (_supportEmail == null && _supportPhone == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Direct support contact isn\'t set up yet in this build — add a real support email or phone number here before launch.',
                style: TextStyle(color: AppColors.warning, fontSize: 12.5),
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
                    title: const Text('Email support'),
                    subtitle: Text(_supportEmail!),
                  ),
                if (_supportPhone != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: const Text('Call support'),
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

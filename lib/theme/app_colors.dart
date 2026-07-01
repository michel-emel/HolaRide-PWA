import 'package:flutter/material.dart';

/// Central color palette for HolaRide.
///
/// Matches the green + cream branding: a deep green for primary
/// actions and chrome across the app, warm cream as the main
/// background, and gold as a sparing accent (ratings stars,
/// highlights). Everything else (status colors, neutrals) follows a
/// standard, accessible scale.
///
/// If you tweak the brand colors later, this is the only file that
/// needs to change — every screen reads from here, nothing is hardcoded
/// inline.
class AppColors {
  AppColors._();

  // Brand
  static const Color navyDark = Color(0xFF0B1F4D); // splash bg top
  static const Color navy = Color(0xFF14306B); // splash bg bottom / hero
  static const Color primary = Color(0xFF0F6E56); // main buttons, links, chrome
  static const Color primaryLight = Color(0xFF4ECCA3); // contrast accent on dark-green surfaces
  static const Color primaryDark = Color(0xFF0B5443);
  static const Color gold = Color(0xFFF6A623); // ratings stars, sparing highlights
  static const Color goldDark = Color(0xFFE0930F);

  // Neutrals
  static const Color background = Color(0xFFF1E9DA); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F8);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFC7D1EA);

  // Status
  static const Color success = Color(0xFF2EA043);
  static const Color successBg = Color(0xFFE6F6EA);
  static const Color warning = Color(0xFFD08B1D);
  static const Color warningBg = Color(0xFFFCF1DD);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerBg = Color(0xFFFBE7E8);
  static const Color info = Color(0xFF0F6E56);
  static const Color infoBg = Color(0xFFE3F2EC);
}
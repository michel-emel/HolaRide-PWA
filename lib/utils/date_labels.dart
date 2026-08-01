import 'package:flutter/widgets.dart';

const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsFr = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// Short month abbreviation ("Jan"/"janv.") for [month] (1-12), in the
/// app's active locale — single source of truth so every screen's date
/// label agrees, instead of each one keeping its own English-only copy.
String monthAbbrev(BuildContext context, int month) {
  final months = Localizations.localeOf(context).languageCode == 'fr' ? _monthsFr : _monthsEn;
  return months[month - 1];
}

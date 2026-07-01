import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking.dart';

/// A small rounded pill showing a booking's status, colored by
/// [BookingStatus.kind] so "Paid" is always green, "Declined" always
/// red, etc. — one place controls that mapping (see booking.dart).
class StatusBadge extends StatelessWidget {
  final BookingStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(status.kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _BadgeColors _colorsFor(String kind) {
    switch (kind) {
      case 'success':
        return _BadgeColors(AppColors.successBg, AppColors.success);
      case 'warning':
        return _BadgeColors(AppColors.warningBg, AppColors.warning);
      case 'danger':
        return _BadgeColors(AppColors.dangerBg, AppColors.danger);
      default:
        return _BadgeColors(AppColors.infoBg, AppColors.info);
    }
  }
}

class _BadgeColors {
  final Color bg;
  final Color fg;
  _BadgeColors(this.bg, this.fg);
}

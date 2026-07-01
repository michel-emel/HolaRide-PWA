import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';
import '../main_tab_screen.dart';
import '../search/search_form_screen.dart';

/// Screen 16 — Rebook screen.
///
/// Shown when a driver cancels a trip the person had already paid for.
/// Softens what would otherwise be a dead end into a clear next step.
class RebookScreen extends StatelessWidget {
  final Trip trip;
  const RebookScreen({super.key, required this.trip});

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: const [ProfileIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: const Icon(Icons.directions_bus_filled_outlined, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 26),
            const Text('Trip cancelled', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'The driver has cancelled this trip.\nWould you like to find another trip?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Original trip', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${trip.originCity} → ${trip.destinationCity}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (trip.originLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(trip.originLocation,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  if (trip.destinationLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 11, color: AppColors.gold),
                        const SizedBox(width: 5),
                        Text(trip.destinationLocation,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text('${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Find Another Trip',
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => SearchFormScreen(
                    initialFrom: trip.originCity,
                    initialTo: trip.destinationCity,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainTabScreen(initialIndex: 1)),
                (route) => false,
              ),
              child: const Text('Go to My Bookings'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

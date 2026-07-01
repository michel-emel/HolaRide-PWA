import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../theme/app_colors.dart';

/// The trip summary card shown in two places: the "available trips near
/// you" list on Home, and the Search Results list. Same data, same
/// layout — kept as one widget so they can't visually drift apart.
///
/// Shows only fields that actually exist on your backend's `TripOut`.
/// There's no driver name/photo/rating or vehicle make/model/plate in
/// that response at all — earlier versions of this card showed all of
/// that as if it were real. The vehicle category (e.g. "Comfort") is
/// the one vehicle-related detail that's genuinely there.
class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _priceLabel(num price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_timeLabel(trip.departureTime),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(trip.originCity,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      if (trip.originLocation.isNotEmpty)
                        Text(trip.originLocation,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 18, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(' ', style: TextStyle(fontSize: 16)),
                      Text(trip.destinationCity,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      if (trip.destinationLocation.isNotEmpty)
                        Text(trip.destinationLocation,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (trip.vehicleCategory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trip.vehicleCategory,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_priceLabel(trip.pricePerSeat)}/seat',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    Text(
                      '${trip.seatsAvailable} seats left',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
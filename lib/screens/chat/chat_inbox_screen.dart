import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../services/driver_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../trip/chat_screen.dart';

/// Screen — Chat inbox.
///
/// Lists every trip you currently have chat access to — as a paid
/// passenger (booking status "paid" or "completed", matching the real
/// access rule enforced server-side) or as the trip's own driver (any
/// of your own non-cancelled trips). Each entry is keyed uniquely by
/// `trip_id`, since that's the real identity chat is actually built
/// around server-side (`GET/POST /trips/{trip_id}/chat/messages`) — not
/// by booking id. Several different bookings could in principle point
/// at the same trip's chat (e.g. booking it more than once), so
/// entries are deduplicated by trip_id to avoid listing the same
/// conversation twice.
///
/// There's no backend endpoint that returns "all my active chats" in
/// one call, so this is built by combining what's already fetched for
/// My Bookings (passenger side) and My Trips (driver side) — both
/// already carry enough route/date info to label each entry without
/// an extra request per chat.
class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatEntry {
  final String tripId;
  final String originCity;
  final String originLocation;
  final String destinationCity;
  final String destinationLocation;
  final DateTime departureTime;
  final bool isDriver;

  _ChatEntry({
    required this.tripId,
    required this.originCity,
    required this.originLocation,
    required this.destinationCity,
    required this.destinationLocation,
    required this.departureTime,
    required this.isDriver,
  });
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  List<_ChatEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Map<String, _ChatEntry> byTripId = {};

    try {
      final bookings = await BookingService.instance.myBookings();
      for (final b in bookings) {
        if (b.status != BookingStatus.paid && b.status != BookingStatus.completed) continue;
        final tripId = b.tripId;
        if (tripId == null || tripId.isEmpty) continue;
        final trip = b.trip;
        byTripId[tripId] = _ChatEntry(
          tripId: tripId,
          originCity: trip?.originCity ?? '',
          originLocation: trip?.originLocation ?? '',
          destinationCity: trip?.destinationCity ?? '',
          destinationLocation: trip?.destinationLocation ?? '',
          departureTime: trip?.departureTime ?? b.createdAt,
          isDriver: false,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/chat/chat_inbox_screen.dart (bookings): $e');
    }

    try {
      final trips = await DriverService.instance.myTrips();
      for (final t in trips) {
        if (t.status.toLowerCase() == 'cancelled') continue;
        byTripId[t.id] = _ChatEntry(
          tripId: t.id,
          originCity: t.originCity,
          originLocation: t.originLocation,
          destinationCity: t.destinationCity,
          destinationLocation: t.destinationLocation,
          departureTime: t.departureTime,
          isDriver: true,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/chat/chat_inbox_screen.dart (trips): $e');
    }

    if (!mounted) return;
    List<String> hiddenIds = const [];
    try {
      hiddenIds = await ChatService.instance.getHiddenChatIds();
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/chat/chat_inbox_screen.dart (hidden): $e');
    }

    if (!mounted) return;
    final entries = byTripId.values.where((e) => !hiddenIds.contains(e.tripId)).toList()
      ..sort((a, b) => b.departureTime.compareTo(a.departureTime));
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _dateLabel(DateTime t) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${months[t.month - 1]} · ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppHeader('Chat'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
                : _entries.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.only(top: 100),
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text('No chats yet',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          ),
                          const SizedBox(height: 6),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Chats open automatically once a booking is paid, or for any trip you publish.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = _entries[i];
                          return Dismissible(
                            key: Key(e.tripId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.danger, size: 24),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Delete chat?'),
                                  content: const Text(
                                      'This removes the chat from your list. The trip and your booking are not affected.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) async {
                              setState(() => _entries.removeAt(i));
                              try {
                                await ChatService.instance.hideChat(e.tripId);
                              } catch (_) {
                                // Re-add if it fails
                                setState(() => _entries.insert(i, e));
                              }
                            },
                            child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ChatScreen(tripId: e.tripId)),
                            ),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                                    child: Icon(
                                      e.isDriver ? Icons.directions_car : Icons.chat_bubble_outline,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${e.originCity} → ${e.destinationCity}',
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                        if (e.originLocation.isNotEmpty || e.destinationLocation.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              if (e.originLocation.isNotEmpty) ...[
                                                const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    e.originLocation,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                              if (e.originLocation.isNotEmpty && e.destinationLocation.isNotEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                                  child: Icon(Icons.arrow_forward, size: 9, color: AppColors.textSecondary),
                                                ),
                                              if (e.destinationLocation.isNotEmpty) ...[
                                                const Icon(Icons.location_on, size: 10, color: AppColors.gold),
                                                const SizedBox(width: 3),
                                                Flexible(
                                                  child: Text(
                                                    e.destinationLocation,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(_dateLabel(e.departureTime),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      e.isDriver ? 'Driver' : 'Passenger',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ), // InkWell
                          ); // Dismissible
                        },
                      ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat_message.dart';
import '../../models/trip.dart';
import '../../services/chat_service.dart';
import '../../services/session_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profile_icon_button.dart';
import 'live_tracking_screen.dart';

/// Screen 23 — Chat (unlocked after a booking is paid).
///
/// This is a real group chat, not a one-on-one thread — confirmed
/// against the backend source: any number of different passengers
/// who've paid for the same trip share this exact conversation with
/// the driver, all in one chat keyed by the trip itself, not by
/// individual bookings. So there's no single "other party" to name in
/// the header — instead the header shows the trip (route + date/time),
/// and every message from someone other than you shows their actual
/// name, since "their bubble is on the left" alone can't tell you
/// which person sent it once there's more than one other participant.
///
/// "Share location" is a one-time pin, like WhatsApp's "Current
/// Location" — sent as a plain text message whose content happens to
/// be a Google Maps URL, detected below and rendered as a tappable
/// row. Tapping it opens the recipient's own maps app (a real Google
/// Maps link, since that's what gets shared) — this stays a plain
/// link rather than an embedded map preview on purpose: a real, in-app
/// Google-style map preview needs the actual Google Maps SDK, which
/// needs a Google Cloud account with billing on it. An embedded
/// OpenStreetMap preview was tried instead, but mixing "free map
/// inside the app" with "the link itself goes to Google" was more
/// confusing than just keeping this a clean tappable link until a
/// real Maps API key exists. Live location sharing was removed for
/// the same reason — it's a clear addition once that key exists, not
/// before.
class ChatScreen extends StatefulWidget {
  final String tripId;
  const ChatScreen({super.key, required this.tripId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  Trip? _trip;
  String? _myUserId;
  bool _loading = true;
  bool _sending = false;
  bool _sharingLocation = false;
  Timer? _poller;

  static const _locationPrefix = 'https://www.google.com/maps?q=';

  bool _isLocationShare(String text) => text.startsWith(_locationPrefix);

  /// Pulls the coordinates back out of a share URL so the chat bubble
  /// can show a real embedded map preview instead of a plain text link.
  ll.LatLng? _parseLatLng(String url) {
    if (!_isLocationShare(url)) return null;
    final coords = url.substring(_locationPrefix.length).split(',');
    if (coords.length != 2) return null;
    final lat = double.tryParse(coords[0]);
    final lng = double.tryParse(coords[1]);
    if (lat == null || lng == null) return null;
    return ll.LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    _init();
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    _myUserId = user?.id;
    _loadTrip();
    await _load();
  }

  Future<void> _loadTrip() async {
    try {
      final trip = await TripService.instance.getById(widget.tripId);
      if (!mounted) return;
      setState(() => _trip = trip);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/chat_screen.dart: $e');
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final messages = await ChatService.instance.getMessages(widget.tripId);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/chat_screen.dart: $e');
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      await ChatService.instance.sendMessage(widget.tripId, text);
      await _load(silent: true);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/chat_screen.dart: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message didn\'t send. Try again.')),
      );
      _textController.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _sharingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are off');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      final url = '$_locationPrefix${position.latitude},${position.longitude}';
      await ChatService.instance.sendMessage(widget.tripId, url);
      await _load(silent: true);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/chat_screen.dart: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location. Check permissions and try again.')),
      );
    } finally {
      if (mounted) setState(() => _sharingLocation = false);
    }
  }

  Future<void> _openLocation(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) throw Exception('launchUrl returned false');
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/chat_screen.dart: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps. Make sure Google Maps (or a browser) is installed.')),
      );
    }
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${t.day} ${months[t.month - 1]} · ${_timeLabel(t)}';
  }

  @override
  void dispose() {
    _poller?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: trip == null
            ? const Text('Trip chat', style: TextStyle(fontSize: 16))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${trip.originCity} → ${trip.destinationCity}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (trip.originLocation.isNotEmpty || trip.destinationLocation.isNotEmpty)
                    Text(
                      [
                        if (trip.originLocation.isNotEmpty) trip.originLocation,
                        if (trip.destinationLocation.isNotEmpty) trip.destinationLocation,
                      ].join(' → '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  Text(_dateLabel(trip.departureTime),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
        actions: [
          if (trip != null)
            IconButton(
              tooltip: 'Live tracking',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LiveTrackingScreen(trip: trip)),
              ),
              icon: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          const ProfileIconButton(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet — say hello!',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          if (m.isSystem) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    m.text,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            );
                          }
                          final mine = _myUserId != null && m.isMine(_myUserId!);

                          if (_isLocationShare(m.text)) {
                            final point = _parseLatLng(m.text);
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                decoration: BoxDecoration(
                                  color: mine ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: mine ? null : Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!mine && m.senderName.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                                          child: Text(m.senderName,
                                              style: const TextStyle(
                                                  fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                        ),
                                      _LocationPreviewCard(point: point, onTap: () => _openLocation(m.text)),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                                        child: Text(
                                          _timeLabel(m.createdAt),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: mine ? AppColors.textOnDarkMuted : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                              decoration: BoxDecoration(
                                color: mine ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: mine ? null : Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sender name shown for anyone else's message —
                                  // necessary since this is a group chat and "not
                                  // mine" could be the driver or any of several
                                  // different passengers.
                                  if (!mine && m.senderName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        m.senderName,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    m.text,
                                    style: TextStyle(color: mine ? Colors.white : AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _timeLabel(m.createdAt),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: mine ? AppColors.textOnDarkMuted : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Share location',
                    onPressed: _sharingLocation ? null : _shareLocation,
                    icon: _sharingLocation
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A real embedded map preview for a shared location — using
/// `flutter_map` + free OpenStreetMap tiles, no Google Maps SDK or API
/// key involved (that would need its own Google Cloud account with
/// billing). Interaction is disabled so it reads as a clean preview
/// and doesn't fight the chat list's own scroll gesture; tapping
/// anywhere on it hands off to [onTap], which opens the real Google
/// Maps link externally — the preview tile and the destination it
/// opens to are two different providers on purpose, since getting an
/// actual Google-rendered preview here would need that API key.
class _LocationPreviewCard extends StatelessWidget {
  final ll.LatLng? point;
  final VoidCallback onTap;
  const _LocationPreviewCard({required this.point, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (point == null) {
      // Couldn't parse coordinates out of this message for some
      // reason — fall back to a plain tappable row rather than
      // showing a broken/blank map area.
      return InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text('Shared location · Tap to open',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point!,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.holaride.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_on, color: AppColors.danger, size: 34),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Required attribution for OpenStreetMap's free tile usage
          // policy — kept small and unobtrusive.
          Positioned(
            right: 6,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 8.5, color: Colors.black54)),
            ),
          ),
          // Sits on top of EVERYTHING above, including the map — this
          // is what actually catches the tap across the whole card.
          // flutter_map keeps its own internal gesture handling even
          // with interactions disabled, which can otherwise "steal"
          // the tap before it reaches an ancestor GestureDetector;
          // putting the tap target as the topmost layer in the Stack
          // means nothing underneath ever gets the chance to intercept
          // it first.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}
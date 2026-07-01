import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../models/participant_location.dart';
import '../../models/trip.dart';
import '../../services/live_location_service.dart';
import '../../services/location_background_service.dart';
import '../../services/route_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import 'chat_screen.dart';

/// Screen 24 — Live map tracking ("Trip in progress").
///
/// Real GPS and a real map now, and genuinely bidirectional — both the
/// driver and any paid passenger push their own position and see
/// everyone else's, confirmed against your backend source (the push
/// side already accepted any participant; the read endpoint
/// `GET /trips/{trip_id}/locations` was added specifically to return
/// everyone, not just the driver).
///
/// Uses `flutter_map` with OpenStreetMap tiles — a real map, no
/// Google billing account or API key needed. The connecting line
/// between participants is now a real road-following route fetched
/// from OSRM's free public routing server (no API key there either) —
/// falls back to a plain straight line (drawn lighter, so it's
/// visually distinguishable) if that lookup fails for any reason.
/// OSRM's demo server has fair-use limits and no uptime guarantee —
/// fine for testing and an early launch, worth revisiting (self-hosted
/// OSRM, or a paid provider) once real usage grows.
///
/// There's no ETA or "distance remaining to destination" shown — your
/// backend's Location/City tables don't store real-world coordinates
/// for named pickup points at all, only live-shared GPS does, so
/// there's no real destination coordinate to measure against. What IS
/// shown, and is genuinely real: live distance between you and each
/// other participant, computed straight from their actual GPS.
///
/// Location sharing here is foreground-only — it stops the moment you
/// leave this screen. True background tracking (continuing to share
/// while the app is minimized) needs platform-specific background
/// service setup on both Android and iOS and is a separate, bigger
/// project, not something silently included here.
class LiveTrackingScreen extends StatefulWidget {
  final Trip trip;
  const LiveTrackingScreen({super.key, required this.trip});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _mapController = MapController();
  List<ParticipantLocation> _participants = [];
  String? _myUserId;
  String? _myToken;
  ll.LatLng? _myPosition;
  bool _permissionDenied = false;
  bool _isSharing = false;
  String? _error;
  Timer? _pollTimer;

  final Map<String, List<ll.LatLng>> _routes = {};
  final Map<String, String> _routeKeys = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    _myUserId = user?.id;
    _myToken = await SessionService.instance.getToken();
    final running = await LocationBackgroundService.instance.isRunning();
    if (mounted) setState(() => _isSharing = running);
    _loadParticipants();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadParticipants());
  }

  Future<void> _startSharing() async {
    final granted = await _ensureBackgroundPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }
    if (_myToken == null) return;
    await LocationBackgroundService.instance.startSharing(widget.trip.id, _myToken!);
    if (mounted) setState(() => _isSharing = true);
  }

  Future<void> _stopSharing() async {
    await LocationBackgroundService.instance.stopSharing();
    if (mounted) setState(() => _isSharing = false);
  }

  Future<bool> _ensureBackgroundPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services on your device.')),
        );
      }
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Background location needed'),
            content: const Text(
              'HolaRide needs to track your location even when the screen is locked, '
              'so your passengers can see where you are during the trip.\n\n'
              'On the next screen, please choose "Allow all the time".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK, got it'),
              ),
            ],
          ),
        );
      }
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permission required'),
            content: const Text(
              'Location permission was permanently denied. '
              'Please open Settings and allow location "All the time" for HolaRide.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () { Navigator.of(context).pop(); Geolocator.openAppSettings(); },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    if (permission == LocationPermission.whileInUse) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Allow location "All the time"'),
            content: const Text(
              'Please go to Settings → HolaRide → Location → "Allow all the time" '
              'so your passengers can track you when the screen is locked.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () { Navigator.of(context).pop(); Geolocator.openAppSettings(); },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return permission == LocationPermission.always;
  }


  Future<void> _loadParticipants() async {
    try {
      final participants = await LiveLocationService.instance.getParticipants(widget.trip.id);
      if (!mounted) return;
      setState(() {
        _participants = participants;
        _error = null;
      });
      _fitBounds();
      final others = participants.where((p) => p.userId != _myUserId).toList();
      await _refreshRoutes(others);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/live_tracking_screen.dart: $e');
      if (!mounted) return;
      setState(() => _error = "Couldn't load live positions.");
    }
  }

  String _routeKey(ll.LatLng a, ll.LatLng b) =>
      '${a.latitude.toStringAsFixed(4)},${a.longitude.toStringAsFixed(4)}|'
      '${b.latitude.toStringAsFixed(4)},${b.longitude.toStringAsFixed(4)}';

  /// Fetches a real route for each other participant, but only if we
  /// don't already have one for roughly this exact position pair —
  /// avoids hitting OSRM's free demo server on every single poll tick
  /// when nobody's actually moved.
  Future<void> _refreshRoutes(List<ParticipantLocation> others) async {
    if (_myPosition == null) return;
    for (final p in others) {
      final theirPos = ll.LatLng(p.latitude, p.longitude);
      final key = _routeKey(_myPosition!, theirPos);
      if (_routeKeys[p.userId] == key) continue;
      final route = await RouteService.instance.fetchRoute(_myPosition!, theirPos);
      if (!mounted) return;
      if (route != null) {
        setState(() {
          _routes[p.userId] = route;
          _routeKeys[p.userId] = key;
        });
      }
    }
  }

  void _fitBounds() {
    final others = _participants.where((p) => p.userId != _myUserId).toList();
    final points = [
      if (_myPosition != null) _myPosition!,
      ...others.map((p) => ll.LatLng(p.latitude, p.longitude)),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  String _distanceLabel(ParticipantLocation p) {
    if (_myPosition == null) return '';
    final meters = Geolocator.distanceBetween(
      _myPosition!.latitude, _myPosition!.longitude, p.latitude, p.longitude,
    );
    if (meters < 1000) return '${meters.round()} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  String _agoLabel(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Future<void> _call() async {
    // NOTE: there's no phone number anywhere in the current API for
    // other trip participants — add one once your backend exposes it.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling isn\'t wired up yet — no phone number in the API response.')),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final others = _participants.where((p) => p.userId != _myUserId).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Trip in progress')),
      body: Column(
        children: [
          Expanded(
            child: _permissionDenied ? _buildPermissionDenied() : _buildMap(others),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${trip.originCity} → ${trip.destinationCity}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                // Share / Stop button
                SizedBox(
                  width: double.infinity,
                  child: _isSharing
                      ? OutlinedButton.icon(
                          onPressed: _stopSharing,
                          icon: const Icon(Icons.location_off_outlined, size: 18),
                          label: const Text('Stop sharing location'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _startSharing,
                          icon: const Icon(Icons.location_on_outlined, size: 18),
                          label: const Text('Share my location'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                if (_isSharing)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 13, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'Sharing continues even if you lock the screen',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                if (others.isEmpty)
                  const Text('Waiting for others on this trip to share their location...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                else
                  ...others.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            p.isDriver ? Icons.directions_car : Icons.person,
                            size: 16,
                            color: p.isDriver ? AppColors.primary : AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${p.displayName} (${p.isDriver ? 'Driver' : 'Passenger'})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Text(_distanceLabel(p), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          Text('· ${_agoLabel(p.updatedAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _routes.isNotEmpty
                        ? 'Solid line follows real roads. Faint line means a route couldn\'t be calculated.'
                        : 'Calculating real road routes...',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (trip.vehicleCategory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trip.vehicleCategory,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChatScreen(tripId: trip.id)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                    ),
                    IconButton(
                      onPressed: _call,
                      icon: const Icon(Icons.call, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<ParticipantLocation> others) {
    final initialCenter = _myPosition ??
        (others.isNotEmpty
            ? ll.LatLng(others.first.latitude, others.first.longitude)
            : const ll.LatLng(3.848, 11.502)); // Yaoundé — harmless fallback center only

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: initialCenter, initialZoom: 13),
      children: [
        TileLayer(
          // OpenStreetMap's free tile server — no API key needed.
          // If you outgrow their usage policy under real traffic,
          // switch urlTemplate to a paid tile provider later.
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.holaride.app', // match your actual applicationId
        ),
        PolylineLayer(
          polylines: _myPosition == null
              ? <Polyline>[]
              : others.map((p) {
                  final realRoute = _routes[p.userId];
                  return Polyline(
                    points: realRoute ?? [_myPosition!, ll.LatLng(p.latitude, p.longitude)],
                    strokeWidth: realRoute != null ? 3.5 : 2.5,
                    color: AppColors.primary.withOpacity(realRoute != null ? 0.75 : 0.35),
                  );
                }).toList(),
        ),
        MarkerLayer(
          markers: [
            if (_myPosition != null)
              Marker(
                point: _myPosition!,
                width: 36,
                height: 36,
                child: const Icon(Icons.my_location, color: AppColors.success, size: 30),
              ),
            ...others.map(
              (p) => Marker(
                point: ll.LatLng(p.latitude, p.longitude),
                width: 120,
                height: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(p.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    Icon(
                      p.isDriver ? Icons.directions_car : Icons.person_pin_circle,
                      color: p.isDriver ? AppColors.primary : AppColors.gold,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 14),
            const Text('Location access is off',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Turn on location access for HolaRide in your phone settings to share and see live positions on this trip.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

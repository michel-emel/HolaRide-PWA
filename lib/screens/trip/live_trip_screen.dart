import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/trip.dart';
import '../../services/driver_service.dart';
import '../../services/location_sharing_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';

/// Screen — Live trip map (Google Maps SDK).
///
/// PASSENGER view: the driver's marker moving in real time (rotated by
/// heading), your own blue marker, and a freshness indicator.
/// DRIVER view: your position + one pin per paid passenger (tap a pin
/// to see the passenger's name).
///
/// The asymmetry isn't decided here: the RLS policies only ever send a
/// passenger the driver's row — this screen just renders whatever
/// arrives on the stream.
///
/// ✅ NOUVEAU (passager uniquement) :
///  - un consentement explicite ("Partager" / "Suivre sans partager")
///    est demandé avant de démarrer le service ;
///  - un toggle dans la carte du bas permet de couper ou reprendre le
///    partage à tout moment ;
///  - dès que [LocationSharingService.tripEnded] émet (le backend a
///    répondu 409 — le trip n'est plus "ongoing"), la carte est
///    remplacée par un état "Trajet terminé" explicite, pour les DEUX
///    rôles (driver et passager) : plus aucune tentative de partage
///    n'a de sens une fois le trip complété.
/// Le flux d'origine du driver (_init, _driverCard) est inchangé en
/// dehors de ce nouvel état terminal partagé.
class LiveTripScreen extends StatefulWidget {
  final Trip trip;
  const LiveTripScreen({super.key, required this.trip});

  @override
  State<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends State<LiveTripScreen> {
  GoogleMapController? _map;
  final _svc = LocationSharingService.instance;

  bool _isDriver = false;
  String? _myId;
  final Map<String, String> _names = {}; // passengerId → name (driver view)

  StreamSubscription<LivePosition>? _posSub;
  StreamSubscription<Position>? _meSub;
  StreamSubscription<void>? _tripEndedSub; // ✅ NOUVEAU
  Timer? _ticker;
  Position? _me;
  bool _follow = true;
  bool _programmaticMove = false;
  bool _hadFix = false; // first GPS fix received → forces the initial zoom
  String? _permError;

  // ✅ NOUVEAU : passe à true dès que le service signale la fin du
  // trajet (409 côté backend). Remplace toute la zone carte + carte du
  // bas par un état terminal simple.
  bool _tripEnded = false;

  // Yaoundé — fallback center before the first position arrives.
  static const _fallbackCenter = LatLng(3.848, 11.502);

  LivePosition? get _driverPos => _svc.lastKnown[widget.trip.driverId];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    _myId = user?.id;
    _isDriver = _myId != null && _myId == widget.trip.driverId;

    // Consentement passager AVANT tout appel à _svc.start(). Le driver
    // n'est jamais concerné par ce bloc (if (!_isDriver)).
    bool shareLocation = true;
    if (!_isDriver) {
      final choice = await _showLocationConsentSheet(context);
      if (!mounted) return;
      if (choice == null) {
        // Fermé sans choisir (back / tap en dehors) → on ne force rien,
        // on quitte l'écran plutôt que de partager par défaut.
        Navigator.of(context).pop();
        return;
      }
      shareLocation = choice;
    }

    // Driver view: map passenger ids to names for the pins.
    if (_isDriver) {
      try {
        final bookings = await DriverService.instance.tripBookings(widget.trip.id);
        for (final b in bookings) {
          final pid = b.passengerId;
          if (pid != null && pid.isNotEmpty) {
            _names[pid] = b.passengerName ?? 'Passenger';
          }
        }
      } catch (_) {
        // Names are cosmetic — pins fall back to "Passenger".
      }
    }

    // ✅ NOUVEAU : écouter le signal de fin de trajet, pour les DEUX
    // rôles — si le driver ferme le trajet pendant que le passager est
    // encore sur cet écran (ou vice-versa), les deux doivent voir le
    // même état terminal, pas une carte qui continue de tourner à vide.
    _tripEndedSub = _svc.tripEnded.listen((_) {
      if (!mounted) return;
      setState(() => _tripEnded = true);
    });

    // Start upload + download for this trip.
    // shareLocation vaut toujours true pour le driver, donc son
    // comportement (upload immédiat) est strictement inchangé.
    _permError = await _svc.start(widget.trip.id, shareLocation: shareLocation);
    if (!mounted) return;

    // ✅ NOUVEAU : si le trajet était déjà terminé au moment où l'écran
    // s'est ouvert (ex. ouverture tardive), refléter ça immédiatement
    // plutôt que d'attendre un premier 409.
    if (_svc.hasTripEnded) {
      setState(() => _tripEnded = true);
      return;
    }

    if (_permError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_permError!)));
        }
      });
    }

    // Re-render on every incoming position; follow the driver if enabled.
    _posSub = _svc.positions.listen((p) {
      if (!mounted) return;
      setState(() {});
      if (!_isDriver && p.userId == widget.trip.driverId) {
        final first = !_hadFix;
        _hadFix = true;
        // The FIRST fix always moves+zooms the camera, even if _follow
        // was wrongly disabled by a spurious camera event on web.
        if (first || _follow) {
          _moveCamera(LatLng(p.latitude, p.longitude));
        }
      }
    });

    // My own blue marker (only if GPS permission was granted).
    if (_permError == null) {
      _meSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _me = pos);
        final target = LatLng(pos.latitude, pos.longitude);
        if (_isDriver || _driverPos == null) {
          // Driver view: always track own position. Passenger view:
          // only until the driver's signal arrives. In both cases the
          // FIRST fix always moves+zooms the camera, even if _follow
          // was wrongly disabled by a spurious camera event on web.
          final first = !_hadFix;
          _hadFix = true;
          if (first || _follow) _moveCamera(target);
        }
      });
    }

    // 1-second tick so the "Updated Xs ago" label stays alive.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _posSub?.cancel();
    _meSub?.cancel();
    _tripEndedSub?.cancel(); // ✅ NOUVEAU
    _svc.stop();
    _map?.dispose();
    super.dispose();
  }

  // Bottom sheet de consentement, passager uniquement. Retourne true
  // (partager), false (suivre sans partager), ou null si fermée sans
  // choix.
  Future<bool?> _showLocationConsentSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 32),
            const SizedBox(height: 12),
            const Text('Partager votre position',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            const Text(
              'Pendant ce trajet, le conducteur pourra voir votre position en '
              'direct. Vous pouvez désactiver le partage à tout moment depuis '
              'l\'écran de suivi.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Suivre sans partager'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Partager'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _moveCamera(LatLng target) async {
    final map = _map;
    if (map == null) return;
    _programmaticMove = true;
    // If we're still at the country-wide overview (no fix yet), jump
    // straight to street level; otherwise just glide, keeping whatever
    // zoom the user chose.
    final zoom = await map.getZoomLevel();
    if (zoom < 12) {
      await map.animateCamera(CameraUpdate.newLatLngZoom(target, 15.5));
    } else {
      await map.animateCamera(CameraUpdate.newLatLng(target));
    }
    // Small delay so onCameraMoveStarted from THIS animation doesn't
    // get mistaken for a user gesture.
    Future.delayed(const Duration(milliseconds: 400), () => _programmaticMove = false);
  }

  void _recenter() {
    setState(() => _follow = true);
    final target = _isDriver
        ? (_me != null ? LatLng(_me!.latitude, _me!.longitude) : null)
        : (_driverPos != null ? LatLng(_driverPos!.latitude, _driverPos!.longitude) : null);
    if (target != null) {
      _programmaticMove = true;
      _map?.animateCamera(CameraUpdate.newLatLngZoom(target, 15.5));
      Future.delayed(const Duration(milliseconds: 400), () => _programmaticMove = false);
    }
  }

  // ── Markers ─────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Driver's marker (green, rotated by heading, flat on the map).
    final d = _driverPos;
    if (d != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(d.latitude, d.longitude),
        rotation: d.heading ?? 0,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.trip.driverName, snippet: widget.trip.vehicleLabel),
        zIndex: 3,
      ));
    }

    // Passenger pins (only ever received in the driver view — RLS).
    for (final entry in _svc.lastKnown.entries) {
      if (entry.key == widget.trip.driverId) continue;
      if (entry.key == _myId) continue; // own marker is drawn separately
      final p = entry.value;
      markers.add(Marker(
        markerId: MarkerId('passenger-${entry.key}'),
        position: LatLng(p.latitude, p.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: _names[entry.key] ?? 'Passenger'),
        zIndex: 2,
      ));
    }

    // My own position (azure marker) — drawn manually because the
    // built-in my-location layer isn't supported on Flutter web.
    if (_me != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_me!.latitude, _me!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
        zIndex: 1,
      ));
    }

    return markers;
  }

  // ── Freshness ───────────────────────────────────────────────────────

  String? get _freshnessLabel {
    final d = _driverPos;
    if (d == null) return null;
    final secs = DateTime.now().difference(d.updatedAt).inSeconds;
    if (secs < 5) return 'Live';
    if (secs < 60) return 'Updated ${secs}s ago';
    final mins = secs ~/ 60;
    return 'Last seen ${mins}m ago';
  }

  bool get _isStale {
    final d = _driverPos;
    if (d == null) return true;
    return DateTime.now().difference(d.updatedAt).inSeconds > 30;
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    // ✅ NOUVEAU : état terminal — remplace tout (carte + carte du bas)
    // dès que le trajet est marqué terminé côté serveur. Commun aux
    // deux rôles : plus aucune action de partage n'a de sens ici.
    if (_tripEnded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
              ),
            ),
          ),
          title: Text('${trip.originCity} → ${trip.destinationCity}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Trajet terminé',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 6),
                const Text(
                  'Le partage de position a été arrêté automatiquement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final initialCenter = _driverPos != null
        ? LatLng(_driverPos!.latitude, _driverPos!.longitude)
        : (_me != null ? LatLng(_me!.latitude, _me!.longitude) : _fallbackCenter);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${trip.originCity} → ${trip.destinationCity}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(_isDriver ? 'Sharing your live position' : 'Following your driver',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialCenter,
            zoom: _driverPos != null || _me != null ? 13 : 7,
          ),
          onMapCreated: (c) => _map = c,
          markers: _buildMarkers(),
          // Any user-initiated camera move disables auto-follow until
          // the re-center button is tapped. Only armed after the first
          // fix: on web this callback also fires during initial render,
          // which used to kill _follow before any GPS signal arrived.
          onCameraMoveStarted: () {
            if (_hadFix && !_programmaticMove && _follow) {
              setState(() => _follow = false);
            }
          },
          myLocationEnabled: false, // manual azure marker instead (web support)
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),

        // Re-center button
        Positioned(
          right: 16,
          bottom: 130,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: AppColors.surface,
            foregroundColor: _follow ? AppColors.primary : AppColors.textSecondary,
            onPressed: _recenter,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Bottom info card
        Positioned(
          left: 16, right: 16, bottom: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: _isDriver ? _driverCard() : _passengerCard(),
          ),
        ),
      ]),
    );
  }

  Widget _passengerCard() {
    final trip = widget.trip;
    final label = _freshnessLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trip.driverName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              Text(trip.vehicleLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          if (label == null)
            const Text('Waiting for signal...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
          else
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _isStale ? AppColors.danger : AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isStale ? AppColors.danger : AppColors.success)),
            ]),
        ]),

        // Séparateur + toggle de partage, uniquement si la permission
        // GPS a bien été obtenue (sinon rien à activer/couper).
        if (_permError == null) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              _svc.isSharing ? Icons.my_location : Icons.location_off,
              size: 16,
              color: _svc.isSharing ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _svc.isSharing
                    ? 'Le conducteur voit votre position'
                    : 'Partage désactivé',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _svc.isSharing ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Switch(
              value: _svc.isSharing,
              activeColor: AppColors.primary,
              onChanged: (v) async {
                if (v) {
                  _svc.resumeSharing();
                } else {
                  await _svc.pauseSharing();
                }
                if (mounted) setState(() {});
              },
            ),
          ]),
        ],
      ],
    );
  }

  Widget _driverCard() {
    final passengerCount = _svc.lastKnown.keys
        .where((id) => id != widget.trip.driverId && id != _myId)
        .length;
    return Row(children: [
      Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
        child: const Icon(Icons.gps_fixed, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('You are sharing your position',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(
            passengerCount == 0
                ? 'No passenger position received yet.'
                : '$passengerCount passenger${passengerCount > 1 ? 's' : ''} visible on the map.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ]),
      ),
    ]);
  }
}
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

/// ── Supabase project config ──────────────────────────────────────────
/// Dashboard → Settings → API :
///   - Project URL  → [_supabaseUrl]
///   - anon public  → [_supabaseAnonKey]  (PAS la service_role !)
/// L'anon key est faite pour être embarquée dans l'app : seule, elle ne
/// donne accès à rien — les lectures live_locations exigent le token
/// signé par le backend (realtime-token) + les policies RLS.
const _supabaseUrl = 'https://TON-REF-PROJET.supabase.co';
const _supabaseAnonKey = 'TON-ANON-KEY';

/// One live position received from the other side of the trip.
class LivePosition {
  final String userId;
  final double latitude;
  final double longitude;
  final double? heading;
  final DateTime updatedAt;

  LivePosition({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.heading,
    required this.updatedAt,
  });
}

/// Live location sharing for an ongoing trip.
///
/// UPLOAD  : geolocator stream → POST /trips/{id}/position (via ApiClient,
///           donc authentifié par ton JWT app). Throttlé : 10 m de
///           déplacement minimum ET 4 s minimum entre deux envois.
/// DOWNLOAD: GET /trips/{id}/realtime-token (pont JWT) → abonnement
///           Supabase Realtime sur live_locations filtré par trip_id.
///           L'asymétrie (passager ne voit que le chauffeur) est
///           garantie par les policies RLS côté base, pas ici.
///
/// Usage (depuis l'écran carte, étape 4) :
///   await LocationSharingService.instance.start(tripId);
///   LocationSharingService.instance.positions.listen((p) { ... });
///   ...
///   await LocationSharingService.instance.stop();
class LocationSharingService {
  LocationSharingService._();
  static final LocationSharingService instance = LocationSharingService._();

  static bool _initialized = false;

  /// À appeler UNE fois au démarrage de l'app (dans main(), avant runApp).
  static Future<void> init() async {
    if (_initialized) return;
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    _initialized = true;
  }

  final _api = ApiClient.instance;

  StreamSubscription<Position>? _gpsSub;
  RealtimeChannel? _channel;
  Timer? _retryTimer;
  String? _tripId;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  int _retrySeconds = 2;
  bool _stopped = true;

  final _controller = StreamController<LivePosition>.broadcast();

  /// Flux des positions reçues (chauffeur si tu es passager ; tous les
  /// membres si tu es chauffeur — la base décide, pas le client).
  Stream<LivePosition> get positions => _controller.stream;

  /// Dernière position connue par user_id — pour peindre la carte
  /// immédiatement sans attendre le prochain événement.
  final Map<String, LivePosition> lastKnown = {};

  // ── Permission GPS ──────────────────────────────────────────────────

  /// Retourne null si OK, sinon un message d'erreur à afficher.
  Future<String?> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return 'Location services are disabled on this device.';
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Location permission was denied.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied — enable it in your phone settings.';
    }
    return null;
  }

  // ── Cycle de vie ────────────────────────────────────────────────────

  /// Démarre l'envoi de MA position + la réception des positions des
  /// autres, pour ce trajet. Retourne null si tout est parti, sinon le
  /// message d'erreur permission.
  Future<String?> start(String tripId) async {
    await stop(); // repartir propre si un ancien trajet traînait
    _stopped = false;
    _tripId = tripId;

    final permissionError = await ensurePermission();
    if (permissionError != null) {
      // On peut quand même RECEVOIR les positions sans envoyer la sienne
      // (utile pour un passager qui refuse le GPS mais veut voir la
      // voiture arriver) — donc on continue le download malgré tout.
      await _startDownload(tripId);
      return permissionError;
    }

    _startUpload(tripId);
    await _startDownload(tripId);
    return null;
  }

  Future<void> stop() async {
    _stopped = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    lastKnown.clear();
    _tripId = null;
    _retrySeconds = 2;
  }

  // ── UPLOAD : ma position vers le backend ────────────────────────────

  void _startUpload(String tripId) {
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // mètres — ne réveille le flux qu'en bougeant
      ),
    ).listen((pos) async {
      // Throttle temporel en plus du distanceFilter : jamais plus d'un
      // envoi toutes les 4 s, même à 110 km/h sur l'axe lourd.
      final now = DateTime.now();
      if (now.difference(_lastSent).inSeconds < 4) return;
      _lastSent = now;
      try {
        await _api.post('/trips/$tripId/position', body: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          if (!pos.heading.isNaN && pos.heading >= 0) 'heading': pos.heading % 360,
        });
      } catch (_) {
        // Réseau coupé ou trajet plus 'ongoing' (409) : on ignore, le
        // prochain point retentera. Pas de spam d'erreurs à l'écran.
      }
    });
  }

  // ── DOWNLOAD : les positions des autres via Realtime ────────────────

  Future<void> _startDownload(String tripId) async {
    // 1. Peindre la carte tout de suite avec les dernières positions
    //    connues (le Realtime ne pousse que les CHANGEMENTS futurs).
    try {
      final res = await _api.get('/trips/$tripId/positions');
      final list = (res as List?) ?? const [];
      for (final row in list.whereType<Map<String, dynamic>>()) {
        final p = _parseApiRow(row);
        if (p != null) _emit(p);
      }
    } catch (_) {
      // Pas bloquant : le Realtime prendra le relais.
    }

    // 2. S'abonner aux changements.
    await _subscribe(tripId);
  }

  Future<void> _subscribe(String tripId) async {
    if (_stopped || tripId != _tripId) return;

    // Token court signé par le backend — c'est LUI qui porte notre
    // user_id jusqu'aux policies RLS (auth.uid()).
    final String token;
    try {
      final res = await _api.get('/trips/$tripId/realtime-token');
      token = (res as Map<String, dynamic>)['token'] as String;
    } catch (_) {
      _scheduleRetry(tripId);
      return;
    }

    final client = Supabase.instance.client;
    client.realtime.setAuth(token);

    _channel = client
        .channel('live-trip-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trip_id',
            value: tripId,
          ),
          callback: (payload) {
            final p = _parseRealtimeRow(payload.newRecord);
            if (p != null) _emit(p);
          },
        )
        .subscribe((status, [error]) {
          if (_stopped) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            _retrySeconds = 2; // reset du backoff après succès
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.closed ||
              status == RealtimeSubscribeStatus.timedOut) {
            // Zone morte / token expiré : on refait tout le cycle
            // (nouveau token inclus) avec backoff exponentiel.
            _scheduleRetry(tripId);
          }
        });
  }

  void _scheduleRetry(String tripId) {
    if (_stopped || tripId != _tripId) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: _retrySeconds), () async {
      if (_stopped || tripId != _tripId) return;
      if (_channel != null) {
        await Supabase.instance.client.removeChannel(_channel!);
        _channel = null;
      }
      await _subscribe(tripId);
    });
    _retrySeconds = (_retrySeconds * 2).clamp(2, 60);
  }

  // ── Parsing ─────────────────────────────────────────────────────────

  void _emit(LivePosition p) {
    lastKnown[p.userId] = p;
    if (!_controller.isClosed) _controller.add(p);
  }

  /// Ligne venue de GET /positions (types propres, clés user_id/latitude…).
  LivePosition? _parseApiRow(Map<String, dynamic> row) {
    final lat = _num(row['latitude']);
    final lng = _num(row['longitude']);
    final uid = row['user_id']?.toString();
    if (lat == null || lng == null || uid == null) return null;
    return LivePosition(
      userId: uid,
      latitude: lat,
      longitude: lng,
      heading: _num(row['heading']),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Ligne venue du Realtime. ⚠️ Les colonnes Postgres `numeric`
  /// (latitude/longitude) arrivent en STRING dans le payload Realtime —
  /// d'où le parsing tolérant via [_num].
  LivePosition? _parseRealtimeRow(Map<String, dynamic> record) {
    if (record.isEmpty) return null;
    return _parseApiRow(record);
  }

  double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
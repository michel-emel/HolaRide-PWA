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
const _supabaseUrl = 'https://nbyhttwacptmbjrvpfec.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ieWh0dHdhY3B0bWJqcnZwZmVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxNDE5MTQsImV4cCI6MjA5NzcxNzkxNH0.YkqP0wIXH0nh1seyPtpfq0Cl_S91xZICCp9fpyE_EHQ';

/// One live position received from the other side of the trip .
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
///   LocationSharingService.instance.tripEnded.listen((_) { ... });
///   ...
///   await LocationSharingService.instance.stop();
///
/// ✅ NOUVEAU (1) : le passager peut couper/reprendre SON upload sans
/// perdre le download (suivre le driver) via [pauseSharing]/[resumeSharing].
/// Le driver n'est pas concerné par ce contrôle — son écran continue
/// d'appeler start() avec shareLocation par défaut (true).
///
/// ✅ NOUVEAU (2) : dès que le backend répond 409 sur POST /position
/// (le trip n'est plus "ongoing" — typiquement "completed"), le service
/// considère le trajet comme terminé : il coupe TOUT (upload ET
/// download/Realtime, pas juste l'upload) et notifie l'UI via [tripEnded]
/// pour qu'elle affiche un état "Trajet terminé" au lieu de figer
/// silencieusement la carte.
///
/// ⚠️ ATTENTION : la détection du 409 ci-dessous suppose que
/// [ApiClient] lève une exception dont le message ou la représentation
/// texte contient le code de statut HTTP (ex. "409" quelque part dans
/// `error.toString()`). Je n'ai pas le contenu de `api_client.dart` —
/// si ton client expose plutôt un type d'exception dédié (ex.
/// `ApiException` avec un champ `statusCode`), remplace `_isConflict`
/// ci-dessous par une vérification directe de ce champ : ce sera plus
/// fiable que le pattern-matching sur le texte.
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

  // Upload mis en pause volontairement (indépendant de _stopped, qui
  // coupe TOUT — upload et download). Un trajet peut être actif avec
  // _uploadPaused == true : on reçoit toujours la position du driver.
  bool _uploadPaused = false;

  // ✅ NOUVEAU : passe à true dès qu'un 409 est reçu — empêche de
  // relancer l'upload par erreur (ex. si resumeSharing() est appelé
  // juste après) et sert de garde pour n'émettre l'événement tripEnded
  // qu'une seule fois.
  bool _tripHasEnded = false;

  final _controller = StreamController<LivePosition>.broadcast();

  // ✅ NOUVEAU : émet une seule fois quand le backend signale que le
  // trajet n'est plus "ongoing" (409 sur /position). L'UI (LiveTripScreen)
  // doit écouter ce flux pour remplacer la carte par un état "Trajet
  // terminé" plutôt que de laisser une carte figée sans explication.
  final _tripEndedController = StreamController<void>.broadcast();

  /// Flux des positions reçues (chauffeur si tu es passager ; tous les
  /// membres si tu es chauffeur — la base décide, pas le client).
  Stream<LivePosition> get positions => _controller.stream;

  /// ✅ NOUVEAU : flux à écouter pour savoir quand le partage a été
  /// arrêté côté serveur (trip plus "ongoing"), par opposition à un
  /// arrêt volontaire de l'utilisateur (pauseSharing/stop).
  Stream<void> get tripEnded => _tripEndedController.stream;

  /// Dernière position connue par user_id — pour peindre la carte
  /// immédiatement sans attendre le prochain événement.
  final Map<String, LivePosition> lastKnown = {};

  /// true si un trajet est actif ET que l'upload n'est pas en pause
  /// ET que le trajet n'est pas terminé côté serveur.
  bool get isSharing => !_stopped && !_uploadPaused && !_tripHasEnded && _gpsSub != null;

  /// ✅ NOUVEAU : true si le dernier événement connu est que le trajet
  /// est terminé côté serveur (409). Utile pour l'UI qui construit son
  /// état initial sans attendre un nouvel événement sur [tripEnded].
  bool get hasTripEnded => _tripHasEnded;

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
  ///
  /// [shareLocation] — si false, le download (suivre l'autre partie)
  /// démarre quand même, mais l'upload de MA position ne démarre pas.
  /// Par défaut true (comportement inchangé pour le driver et pour tout
  /// appelant existant).
  Future<String?> start(String tripId, {bool shareLocation = true}) async {
    await stop(); // repartir propre si un ancien trajet traînait
    _stopped = false;
    _tripId = tripId;
    _uploadPaused = !shareLocation;
    _tripHasEnded = false; // ✅ NOUVEAU : reset pour ce nouveau trajet

    final permissionError = await ensurePermission();
    if (permissionError != null) {
      // On peut quand même RECEVOIR les positions sans envoyer la sienne
      // (utile pour un passager qui refuse le GPS mais veut voir la
      // voiture arriver) — donc on continue le download malgré tout.
      await _startDownload(tripId);
      return permissionError;
    }

    if (shareLocation) _startUpload(tripId);
    await _startDownload(tripId);
    return null;
  }

  Future<void> stop() async {
    _stopped = true;
    _uploadPaused = false;
    _tripHasEnded = false; // reset propre pour le prochain trajet
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

  /// Coupe l'upload sans toucher au channel Realtime (le download —
  /// suivre le driver — continue normalement). Ne fait rien si aucun
  /// trajet n'est actif. Choix VOLONTAIRE de l'utilisateur (toggle) —
  /// différent de l'arrêt automatique déclenché par [_handleTripEnded].
  Future<void> pauseSharing() async {
    if (_stopped || _tripHasEnded) return;
    _uploadPaused = true;
    await _gpsSub?.cancel();
    _gpsSub = null;
  }

  /// Relance l'upload sur le trajet en cours, si applicable. Refuse si
  /// le trajet est déjà marqué terminé côté serveur — pas de sens à
  /// reprendre un partage que le backend refusera de toute façon.
  void resumeSharing() {
    if (_stopped || _tripId == null || !_uploadPaused || _tripHasEnded) return;
    _uploadPaused = false;
    _startUpload(_tripId!);
  }

  // ── ✅ NOUVEAU : gestion de la fin de trajet ──────────────────────────

  /// Coupe tout (upload + download) et notifie l'UI une seule fois.
  /// Appelé dès qu'un 409 est détecté sur l'upload — le trajet n'est
  /// plus "ongoing" côté serveur (typiquement "completed").
  Future<void> _handleTripEnded() async {
    if (_tripHasEnded) return; // déjà géré, on n'émet qu'une fois
    _tripHasEnded = true;

    _retryTimer?.cancel();
    _retryTimer = null;
    await _gpsSub?.cancel();
    _gpsSub = null;
    if (_channel != null) {
      await Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }

    if (!_tripEndedController.isClosed) _tripEndedController.add(null);
  }

  /// Best-effort : cherche un indice de code 409 dans l'exception levée
  /// par ApiClient. À remplacer par une vérification de type/champ
  /// dédié si `api_client.dart` expose un statusCode explicite — voir
  /// la note en tête de fichier.
  bool _isConflict(Object error) {
    final text = error.toString();
    return text.contains('409');
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
      } catch (e) {
        // ✅ NOUVEAU : un 409 veut dire "le trip n'est plus ongoing" —
        // ce n'est plus une erreur réseau transitoire à ignorer, c'est
        // le signal de fin de trajet. Toute autre erreur (réseau coupé,
        // etc.) reste ignorée comme avant : le prochain point retentera.
        if (_isConflict(e)) {
          await _handleTripEnded();
        }
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
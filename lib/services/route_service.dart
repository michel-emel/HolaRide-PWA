import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/google_maps_config.dart';

/// Distance + ETA for a route between two points, plus the road-following
/// polyline points to draw it on a map.
class RouteResult {
  final int distanceMeters;
  final Duration duration;
  final List<LatLng> points;

  const RouteResult({
    required this.distanceMeters,
    required this.duration,
    required this.points,
  });
}

/// Computes a real, road-following route's distance/duration using the
/// Google Routes API (`computeRoutes`) — same API key already used for
/// the Maps SDK (works fine with a Maps Demo Key: Compute Routes is a
/// supported feature).
///
/// https://developers.google.com/maps/documentation/routes/compute-route-over
class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();

  static const _endpoint = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// Returns null if anything goes wrong (missing key, offline, no
  /// route found) — callers should just skip showing an ETA in that
  /// case rather than crashing.
  Future<RouteResult?> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (GoogleMapsConfig.apiKey.isEmpty) return null;
    try {
      final res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
              // Tight field mask — Compute Routes is billed per call,
              // only ask for what we actually render.
              'X-Goog-FieldMask':
                  'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
            },
            body: jsonEncode({
              'origin': {
                'location': {
                  'latLng': {'latitude': originLat, 'longitude': originLng},
                },
              },
              'destination': {
                'location': {
                  'latLng': {'latitude': destLat, 'longitude': destLng},
                },
              },
              'travelMode': 'DRIVE',
              'routingPreference': 'TRAFFIC_AWARE',
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;

      // Duration comes back as a protobuf-style string, e.g. "248s".
      final durationStr = route['duration'] as String?;
      final seconds =
          durationStr == null ? 0 : int.tryParse(durationStr.replaceAll('s', '')) ?? 0;

      final encoded = (route['polyline'] as Map<String, dynamic>?)?['encodedPolyline'] as String?;

      return RouteResult(
        distanceMeters: (route['distanceMeters'] as num?)?.toInt() ?? 0,
        duration: Duration(seconds: seconds),
        points: encoded == null ? const [] : _decodePolyline(encoded),
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes Google's Encoded Polyline Algorithm Format
  /// (https://developers.google.com/maps/documentation/utilities/polylinealgorithm).
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

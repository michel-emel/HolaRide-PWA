import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Persistent background location service.
/// 
/// Key design decisions:
/// - Notification channel is created in the MAIN thread (initialize()),
///   not inside onStart() — Android requires this before the foreground
///   service starts, or it crashes with "invalid channel" error.
/// - GPS and HTTP calls use dart:io http directly in the background
///   isolate — geolocator and ApiClient both throw "main isolate only"
///   errors when used in background isolates, so we bypass them.
/// - Position is pushed every 15 seconds via a simple Timer — no
///   stream subscription needed in background.

const _notificationChannelId = 'holaride_location_channel';
const _notificationChannelName = 'HolaRide Location Sharing';
const _notificationId = 888;
const _prefKeyTripId = 'bg_service_trip_id';
const _prefKeyToken = 'bg_service_token';
const _prefKeyBaseUrl = 'bg_service_base_url';
const _apiBaseUrl = 'https://hola-ride-api-v2.vercel.app';

class LocationBackgroundService {
  LocationBackgroundService._();
  static final instance = LocationBackgroundService._();

  /// Must be called once in main() before runApp().
  /// Creates the notification channel in the main thread — required
  /// before any foreground service can start on Android 8+.
  Future<void> initialize() async {
    // Create notification channel in main thread FIRST.
    final notifications = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await notifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Shows while HolaRide is sharing your location during a trip.',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );
    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Now configure the background service.
    final service = FlutterBackgroundService();
    final androidConfig = AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _notificationChannelId,
      initialNotificationTitle: 'HolaRide',
      initialNotificationContent: 'Location sharing active',
      foregroundServiceNotificationId: _notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    );
    final iosConfig = IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: _onIosBackground,
    );
    await service.configure(
      androidConfiguration: androidConfig,
      iosConfiguration: iosConfig,
    );
  }

  Future<void> startSharing(String tripId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyTripId, tripId);
    await prefs.setString(_prefKeyToken, token);
    await prefs.setString(_prefKeyBaseUrl, _apiBaseUrl);
    await FlutterBackgroundService().startService();
  }

  Future<void> stopSharing() async {
    FlutterBackgroundService().invoke('stopService');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyTripId);
    await prefs.remove(_prefKeyToken);
    await prefs.remove(_prefKeyBaseUrl);
  }

  Future<bool> isRunning() => FlutterBackgroundService().isRunning();
}

/// Runs in its own isolate — no BuildContext, no widgets, no singletons.
/// Uses raw http and dart:io directly instead of ApiClient/Geolocator
/// which both require the main isolate.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'HolaRide · Location sharing active',
      content: 'Your passengers can see your position.',
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final tripId = prefs.getString(_prefKeyTripId);
  final token = prefs.getString(_prefKeyToken);
  final baseUrl = prefs.getString(_prefKeyBaseUrl) ?? _apiBaseUrl;

  if (tripId == null || token == null) {
    service.stopSelf();
    return;
  }

  Timer? pushTimer;

  Future<void> pushPosition() async {
    try {
      // Use Geolocator.getLastKnownPosition() first (fast, no blocking),
      // fall back to getCurrentPosition if null.
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (position == null) return;

      await http.post(
        Uri.parse('$baseUrl/trips/$tripId/location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
    } catch (_) {
      // Silently swallow — don't crash the service on a single failure.
    }
  }

  // Push immediately, then every 15 seconds.
  await pushPosition();
  pushTimer = Timer.periodic(const Duration(seconds: 15), (_) => pushPosition());

  service.on('stopService').listen((_) {
    pushTimer?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
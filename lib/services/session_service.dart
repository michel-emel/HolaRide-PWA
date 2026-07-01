import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Persists the JWT and the logged-in user across app restarts.
///
/// No password exists in this app (phone + OTP only), so the token is
/// the entire credential — losing it just means logging in again with
/// a fresh OTP, nothing more dangerous than that.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _tokenKey = 'holaride_token';
  static const _userKey = 'holaride_user';
  static const _driverModeKey = 'holaride_driver_mode';

  AppUser? _cachedUser;

  /// Bumped every time login state actually changes (login, logout, or
  /// a profile update). The bottom-nav tabs sit inside an `IndexedStack`
  /// in `MainTabScreen`, which keeps every tab alive and never reruns
  /// `initState()` on a plain tab switch — so a screen that checked
  /// login status once at startup (My Bookings, Profile, Home's
  /// greeting) would otherwise stay stuck showing stale state forever
  /// after logging in or out from somewhere else. Screens that need to
  /// stay in sync add a listener here in `initState` and refresh
  /// themselves whenever it fires.
  final ValueNotifier<int> authChanged = ValueNotifier<int>(0);

  /// Bumped whenever "driver mode" is toggled — see [setDriverMode].
  final ValueNotifier<int> driverModeChanged = ValueNotifier<int>(0);

  Future<void> saveSession({required String token, required AppUser user}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _cachedUser = user;
    authChanged.value++;
  }

  /// Saves just the token, before the user profile is known yet.
  /// Used right after OTP verify, since the verify response only
  /// contains tokens — the actual profile has to be fetched separately
  /// via `GET /me`, which itself needs the token already saved to
  /// authenticate that request.
  ///
  /// Doesn't bump [authChanged] — a token alone (before the profile is
  /// fetched) isn't a complete login yet; `saveSession` right after
  /// this does that once the full session is actually ready.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> updateCachedUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _cachedUser = user;
    authChanged.value++;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<AppUser?> getUser() async {
    if (_cachedUser != null) return _cachedUser;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    _cachedUser = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cachedUser;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// "Driver mode" is purely a local UI preference — which set of
  /// bottom-nav tabs and which version of "My Trips" you're currently
  /// looking at (your own published trips vs. your bookings). It's
  /// deliberately separate from the backend's `can_drive` flag: that
  /// flag only flips true once admin approves a vehicle, but someone
  /// should land in driver mode the moment they register a vehicle —
  /// even while it's still pending — since they're clearly trying to
  /// be a driver at that point, approved or not. Switching modes never
  /// changes what the backend will actually let you do.
  Future<bool> isDriverMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_driverModeKey) ?? false;
  }

  Future<void> setDriverMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_driverModeKey, value);
    driverModeChanged.value++;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_driverModeKey);
    _cachedUser = null;
    authChanged.value++;
  }
}

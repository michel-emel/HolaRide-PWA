import '../models/user.dart';
import 'api_client.dart';
import 'session_service.dart';

/// Wraps the phone + OTP auth flow. No passwords anywhere in this app —
/// match that assumption in every screen that touches auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;

  /// Step 1: request an OTP be sent to [phone] (E.164, e.g. +237675123456).
  ///
  /// Returns the dev-mode code if your backend's `OTP_DEV_MODE` env var
  /// is on — it echoes `dev_otp_code` straight in the response instead
  /// of actually sending an SMS. Returns null once that's turned off for
  /// production, at which point this just does nothing extra.
  Future<String?> requestOtp(String phone) async {
    final res = await _api.post('/auth/otp/request', body: {'phone_number': phone}, auth: false);
    if (res is Map && res['dev_otp_code'] != null) {
      return res['dev_otp_code'].toString();
    }
    return null;
  }

  /// Step 2: verify the code. Returns whether this is a brand-new account
  /// that still needs a name (so the caller knows to push the name-entry
  /// screen) vs an existing one that can go straight to Home.
  ///
  /// CONFIRMED against the real response: `/auth/otp/verify` returns
  /// only `access_token` / `refresh_token` / `token_type` — there is no
  /// `user` object and no `is_new_user` flag in the actual response,
  /// despite earlier code assuming both existed. That gap was the bug
  /// behind "logging back in with the same number re-registers me": the
  /// app always treated `firstName` as missing (since it had no profile
  /// to read it from) and routed every login through name-entry as if
  /// brand new, every single time.
  ///
  /// The token has to be saved first, then `GET /me` fetched separately
  /// to find out who this actually is.
  ///
  /// NOTE: a `refresh_token` is also present in the response but isn't
  /// used anywhere yet — there's no token-refresh handling in this app,
  /// so once the access token expires the person will simply be logged
  /// out and need to verify by OTP again. Worth revisiting before launch
  /// if sessions need to last longer than the access token's lifetime.
  Future<OtpVerifyResult> verifyOtp(String phone, String code) async {
    final res = await _api.post(
      '/auth/otp/verify',
      body: {'phone_number': phone, 'code': code},
      auth: false,
    );
    final map = res as Map<String, dynamic>;
    final token = map['access_token']?.toString() ?? map['token']?.toString() ?? '';

    await SessionService.instance.saveToken(token);
    final profile = await _api.get('/me');
    final user = AppUser.fromJson(profile as Map<String, dynamic>);
    await SessionService.instance.saveSession(token: token, user: user);

    final isNew = map['is_new_user'] == true || user.firstName == null || user.firstName!.isEmpty;
    return OtpVerifyResult(user: user, needsName: isNew);
  }

  /// Step 3 (first-time signup only): set the display name.
  ///
  /// BEST GUESS on the endpoint shape — confirm against `/docs` that
  /// updating the current user's profile is `PATCH /me`. If it's a
  /// dedicated endpoint instead, this is the only line to change.
  Future<AppUser> completeProfile({required String firstName, String? lastName}) async {
    final res = await _api.patch('/me', body: {
      'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
    });
    final user = AppUser.fromJson(res as Map<String, dynamic>);
    await SessionService.instance.updateCachedUser(user);
    return user;
  }

  Future<void> logout() async {
    await SessionService.instance.clear();
  }
}

class OtpVerifyResult {
  final AppUser user;
  final bool needsName;
  OtpVerifyResult({required this.user, required this.needsName});
}
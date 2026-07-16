import '../models/user.dart';
import 'api_client.dart';
import 'session_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final _api = ApiClient.instance;

  /// Check if a phone number already has an account.
  /// Returns true if account exists, false if new.
  Future<bool> checkPhoneExists(String phone) async {
    final res = await _api.post(
      '/auth/check-phone',
      body: {'phone_number': phone},
      auth: false,
    );
    return (res as Map)['exists'] == true;
  }

  Future<String?> requestOtp(String phone, {String? firstName, String? lastName}) async {
    final body = <String, dynamic>{'phone_number': phone};
    if (firstName != null && firstName.isNotEmpty) body['first_name'] = firstName;
    if (lastName != null && lastName.isNotEmpty) body['last_name'] = lastName;
    final res = await _api.post('/auth/otp/request', body: body, auth: false);
    if (res is Map && res['dev_otp_code'] != null) {
      return res['dev_otp_code'].toString();
    }
    return null;
  }

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

    final isNewUser = map['is_new_user'] == true;
    final needsName = user.firstName == null || user.firstName!.isEmpty;

    return OtpVerifyResult(user: user, needsName: needsName, isNewUser: isNewUser);
  }

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
  final bool isNewUser;
  OtpVerifyResult({required this.user, required this.needsName, required this.isNewUser});
}
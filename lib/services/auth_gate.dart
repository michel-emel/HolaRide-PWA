import 'package:flutter/material.dart';
import 'session_service.dart';
import '../screens/onboarding/welcome_screen.dart';

/// Gate for anything that needs an account — booking a seat,
/// publishing a trip, viewing bookings, becoming a driver, editing the
/// profile. Browsing and searching trips deliberately never call this;
/// guests can look around freely and only get asked to log in once
/// they try to do something that actually requires an account.
///
/// Returns true immediately if already logged in. Otherwise it pushes
/// the phone-entry flow on top of whatever screen called this, and
/// resolves to true only once that flow completes successfully (login
/// or fresh registration) — false if the person backs out, so the
/// caller knows not to proceed with the gated action.
///
/// [reason] is shown on the phone-entry screen so the ask makes sense
/// in context (e.g. "Log in to book this trip") instead of a bare
/// phone-number form appearing out of nowhere.
Future<bool> requireLogin(BuildContext context, {String? reason}) async {
  if (await SessionService.instance.isLoggedIn()) return true;
  if (!context.mounted) return false;
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => WelcomeScreen(isGate: true, gateReason: reason)),
  );
  return result == true;
}
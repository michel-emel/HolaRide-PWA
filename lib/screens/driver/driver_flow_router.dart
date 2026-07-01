import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../services/auth_gate.dart';
import '../../services/vehicle_service.dart';
import 'my_trips_screen.dart';
import 'vehicle_registration_screen.dart';
import 'vehicle_status_screen.dart';

/// Checks the person's vehicle status and pushes whichever driver
/// screen makes sense — used from both Home ("Publish a Trip") and
/// Profile ("My Vehicle" / "Become a Driver"), so the routing logic
/// only lives in one place.
///
/// Becoming a driver needs an account, so this is gated — a guest
/// tapping "Publish a Trip" gets sent to log in or sign up first, and
/// only continues into the actual driver flow once that succeeds.
Future<void> openDriverFlow(BuildContext context) async {
  final loggedIn = await requireLogin(context, reason: 'Log in to publish a trip as a driver.');
  if (!loggedIn || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  Vehicle? vehicle;
  try {
    vehicle = await VehicleService.instance.getMyVehicle();
  } catch (e) {
    // ignore: avoid_print
    print('Error in lib/screens/driver/driver_flow_router.dart: $e');
    // Fall through — treat as "no vehicle yet" rather than blocking the
    // person entirely if this check fails.
  }
  if (!context.mounted) return;
  Navigator.of(context).pop(); // close the loading dialog

  if (vehicle == null) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
    );
  } else if (vehicle.status == VehicleStatus.approved) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyTripsScreen()),
    );
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VehicleStatusScreen()),
    );
  }
}
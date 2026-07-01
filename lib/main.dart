import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/location_background_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize background location service once at startup.
  // This registers the service with Android — it doesn't start
  // sharing yet, just makes it ready to be started later when the
  // driver taps "Share location" in LiveTrackingScreen.
  await LocationBackgroundService.instance.initialize();
  runApp(const HolaRideApp());
}

class HolaRideApp extends StatelessWidget {
  const HolaRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HolaRide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

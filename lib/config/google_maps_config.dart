/// Single source of truth for the Google Maps / Routes API key used from
/// Dart code (web script injection, Routes API HTTP calls).
///
/// Prefers the `--dart-define=GOOGLE_MAPS_API_KEY=...` already used for
/// the web build (see vercel.json), falling back to the same key already
/// committed for Android (AndroidManifest.xml) and local dev (env.json)
/// so mobile builds keep working without a new dart-define step. This
/// isn't a new exposure — same key, same trust model as today; just one
/// place to read it from instead of two.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB0mITD2MWzmdNhcKbhy5Zg7-eKYTUO3_4',
  );
}

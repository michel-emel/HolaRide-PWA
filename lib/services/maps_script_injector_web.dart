import 'dart:html' as html;

void injectGoogleMapsScript() {
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  if (apiKey.isEmpty) {
    // ignore: avoid_print
    print('⚠️ GOOGLE_MAPS_API_KEY est vide — vérifie ton --dart-define');
    return;
  }
  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..async = true;
  html.document.head?.append(script);
}
void injectGoogleMapsScript() {
  // No-op sur mobile : le SDK natif Google Maps gère déjà la clé
  // via AndroidManifest.xml / AppDelegate.swift, pas besoin d'injecter de script JS.
}
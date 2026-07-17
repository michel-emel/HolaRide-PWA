#!/bin/bash
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
  echo "Erreur : GOOGLE_MAPS_API_KEY n'est pas défini"
  exit 1
fi

flutter build web

sed -i "s/%GOOGLE_MAPS_API_KEY%/$GOOGLE_MAPS_API_KEY/g" build/web/index.html

echo "Build terminé avec la clé injectée."

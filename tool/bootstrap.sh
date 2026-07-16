#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Brak Flutter SDK. Zainstaluj Flutter stable i dodaj polecenie flutter do PATH." >&2
  exit 1
fi

cd "$(dirname "$0")/.."
flutter create --platforms=android,ios --org pl.glogdz --project-name glo_mobile .
flutter pub get
dart format lib test
flutter analyze
flutter test

echo "Projekt gotowy. Uruchom: flutter run"

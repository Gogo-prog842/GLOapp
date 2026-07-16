# GLO Mobile — Flutter app

Startowa aplikacja mobilna Grudziądzkiej Ligi Orlikowej przygotowana pod budowanie przez GitHub Actions.

## Co jest w środku

- Flutter/Dart UI aplikacji GLO
- Połączenie z Supabase przez publiczny publishable/anon key
- Ekrany: start, mecze, szczegóły meczu, tabela, zawodnicy, konto
- Fundament LIVE: zegar 2 × 30 minut, przerwa, doliczony czas, gole i kartki
- Testy tabeli oraz zegara LIVE
- Workflow `.github/workflows/build-android.yml`, który buduje APK na serwerze GitHuba

## Ważne

Ten ZIP jest przygotowany tak, żeby nie trzeba było instalować Fluttera ani Android SDK lokalnie. GitHub Actions tworzy czysty projekt Flutter na runnerze, kopiuje do niego kod GLO i buduje APK.

## Jak wrzucić na GitHuba

W folderze projektu:

```powershell
git init
git add .
git commit -m "Initial GLO mobile app"
git branch -M main
git remote add origin https://github.com/Gogo-prog842/GLOapp.git
git push -u origin main
```

Jeżeli repo już istnieje i ma ustawiony origin:

```powershell
git add .
git commit -m "Replace with complete GitHub build project"
git push
```

## Jak pobrać APK

Po pushu wejdź:

```text
GitHub → GLOapp → Actions → Build GLO Android APK → Artifacts → GLO-Android-debug
```

W środku będzie plik:

```text
app-debug.apk
```

## Supabase

Konfiguracja jest w:

```text
lib/core/config/app_config.dart
```

Do aplikacji można wkładać tylko publiczny `publishable/anon key`. Nie wkładaj `service_role key`.

## V3 mobile changes

- Fixed the player list source so league player counts no longer depend on incomplete `season_players` rows.
- Added a mobile Transfers screen backed by `player_transfers`.
- Added a first Captain Panel view available from Account for captain/admin roles.
- Updated GitHub Actions to set up Android SDK before calling `sdkmanager`.

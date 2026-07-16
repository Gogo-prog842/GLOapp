# GLO Mobile – Flutter

Natywna aplikacja mobilna Grudziądzkiej Ligi Orlikowej budowana przez GitHub Actions.

## Build bez Fluttera lokalnie

Ten projekt jest przygotowany pod tryb GitHub-only. Nie musisz trzymać Flutter SDK ani Android SDK na swoim komputerze.

Po wrzuceniu kodu do repo GitHub Actions:

1. instaluje Java 17,
2. konfiguruje Android SDK,
3. instaluje Flutter stable,
4. generuje folder Android,
5. pobiera zależności,
6. robi `flutter analyze`,
7. odpala testy,
8. buduje `app-debug.apk`,
9. wrzuca APK do `Artifacts`.

## V4

Dodane w tej wersji:

- dynamiczne zakładki zależne od roli,
- panel admina,
- panel sędziego LIVE,
- rozbudowane centrum meczu,
- szybkie dodawanie wydarzeń osobno dla gospodarzy i gości,
- ustawianie MVP meczu,
- podgląd składów obu drużyn,
- workflow GitHub Actions z Android SDK.

## Wrzucenie na GitHub

```powershell
git init
git branch -M main
git remote add origin https://github.com/Gogo-prog842/GLOapp.git
git add -A
git commit -m "Add GLO mobile v4"
git push -u origin main --force
```

APK znajdziesz potem w:

```text
GitHub → Actions → Build GLO Android APK → Artifacts → GLO-Android-debug
```

## Ważne bezpieczeństwo

Aplikacja używa publicznego `publishable/anon key`. Krytyczne operacje admina muszą być chronione przez Supabase RLS albo Edge Functions. Ukrywanie przycisków w UI nie jest zabezpieczeniem bazy.

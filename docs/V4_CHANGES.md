# V4 – role, admin, sędzia i centrum meczu

## Dodane

- Dynamiczna dolna nawigacja zależna od roli użytkownika:
  - admin widzi zakładki `LIVE` i `Admin`,
  - sędzia widzi zakładkę `LIVE`,
  - kapitan widzi zakładkę `Kapitan`.
- Nowy panel admina:
  - liczba drużyn,
  - liczba zawodników z przypisaną drużyną,
  - liczba meczów ligowych,
  - mecze LIVE,
  - mecze wymagające uwagi,
  - ostatnie transfery,
  - top zawodników.
- Nowy panel sędziego:
  - mecze LIVE,
  - najbliższe/przypisane mecze,
  - szybkie wejście do centrum meczu.
- Rozbudowane centrum meczu:
  - podział działań LIVE na gospodarzy i gości,
  - szybkie dodawanie gola/kartki po lewej i prawej stronie,
  - podgląd zawodników obu drużyn,
  - ustawianie MVP gospodarzy i gości z aplikacji,
  - zapis MVP do tabeli `matches`.
- Workflow GitHub Actions działa w trybie `GitHub-only`:
  - generuje Android platform files na runnerze,
  - instaluje Android SDK,
  - buduje `app-debug.apk`,
  - wrzuca APK do artifactów.

## Ważne

- Aplikacja nadal korzysta z tych samych danych Supabase co strona.
- Uprawnienia krytyczne muszą być zabezpieczone po stronie Supabase RLS / Edge Functions.
- Ukrycie przycisków w aplikacji nie jest zabezpieczeniem bazy.

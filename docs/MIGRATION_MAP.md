# Mapa migracji strony GLO do Fluttera

## Już przeniesione w fazie 1

| Strona / plik webowy | Flutter |
|---|---|
| `data.js` – połączenie Supabase | `lib/data/repositories/*` |
| `schedule.html` – terminarz i filtry | `features/matches/matches_screen.dart` |
| `match-details.html` – protokół | `features/matches/match_details_screen.dart` |
| LIVE 2×30 min + przerwa | `MatchRepository` + `LiveClockState` |
| częściowe odświeżanie wyniku | Supabase Realtime streams |
| `table.html` – tabela | `StandingsCalculator` + `standings_screen.dart` |
| `players.html` – statystyki | `PlayerRepository` + `players_screen.dart` |
| role admin/sędzia/kapitan | `AuthRepository` + `UserRole` |
| kolory i identyfikacja GLO | `core/theme/app_theme.dart` |

## Kolejne moduły

1. Panel kapitana: skład, formacja, oceny i transfery.
2. Pełny panel sędziego: pauza/wznowienie zegara, korekta minut i cofanie zdarzeń.
3. Panel administratora: akceptacje, widoczność według lig i audyt zmian.
4. Profile drużyn i zawodników z pełną historią sezonów.
5. Powiadomienia push o spotkaniach, golach i zmianach terminarza.
6. AI: wydzielenie logiki z `ai_chat.js` do Edge Function lub API Python.
7. Cache offline w lokalnej bazie i kolejka synchronizacji.

## Zasada architektury

HTML i manipulacje DOM nie są kopiowane. Flutter odtwarza funkcje jako natywne widoki, a Supabase pozostaje wspólnym źródłem prawdy dla strony i aplikacji.

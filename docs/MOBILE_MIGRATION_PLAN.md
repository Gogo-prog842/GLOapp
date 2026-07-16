# Plan migracji GLO web → Flutter

## Założenie

Strona webowa zostaje publiczna. Aplikacja Flutter jest drugim klientem tej samej bazy Supabase. Nie robimy osobnego backendu ani osobnej bazy.

```text
Web HTML/CSS/JS ─┐
                 ├── Supabase PostgreSQL + Auth + RLS + Realtime
Flutter Mobile ──┘
```

## Co zostało przeniesione w Phase 1

| Obszar | Status |
|---|---|
| Supabase init | gotowe |
| Ligi/sezony | gotowe |
| Terminarz | gotowe |
| Tabela | gotowe |
| Zawodnicy/statystyki | gotowe |
| Szczegóły meczu | gotowe |
| LIVE clock | gotowe |
| Gole/kartki LIVE | gotowe |
| Logowanie | gotowe |
| Role admin/sędzia/kapitan | baza gotowa |
| Panel kapitana | do zrobienia |
| Transfery | do zrobienia |
| Profil zawodnika | do zrobienia |
| TOTW | do zrobienia |
| Powiadomienia push | do zrobienia |
| AI chat | do wydzielenia do API/Edge Function |

## Uwaga o bezpieczeństwie

Aplikacja mobilna nie zabezpiecza danych samym ukryciem przycisków. Wszystkie krytyczne operacje muszą być chronione przez RLS, RPC albo Edge Functions:

- zatwierdzanie transferów,
- kończenie meczu,
- usuwanie goli/kartek,
- nadawanie adminów,
- zmiana aktywnego sezonu,
- hurtowe przeliczanie statystyk.

## Proponowane moduły docelowe

```text
lib/
  core/
  data/
    models/
    repositories/
  features/
    account/
    admin/
    captain/
    home/
    live_match/
    matches/
    players/
    standings/
    teams/
    transfers/
```

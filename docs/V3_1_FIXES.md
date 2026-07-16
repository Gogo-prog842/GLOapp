# V3.1 fixes

- Fixed `flutter analyze` errors caused by missing `GloColors.primary` and `GloColors.textMuted` aliases.
- Removed unnecessary null-aware fallback in captain panel because `Team.leagueId` is non-nullable.
- Keeps the V3 player-count fix: players are loaded by team/league instead of relying only on `season_players`.

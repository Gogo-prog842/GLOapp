# GLO app V3 changes

## Fixed player count

The previous mobile app version could show too few players in a league because it preferred `season_players`. If that table was incomplete, the app displayed only the membership rows.

V3 now loads visible players from:

1. `players.team_id` matched against teams in the selected league/season,
2. plus fallback `players.league_id`,
3. then merges by `player.id`.

This should make the app match the website much more closely for cases like L1 showing 184 players instead of 105.

## Added app part

Added:

- Transfers screen (`player_transfers`),
- search and transfer type filter,
- Captain Panel skeleton: team header, squad, upcoming matches, latest results,
- GitHub Actions Android SDK setup fix.

Next recommended part: real captain actions — submit lineup, formation, bench, transfer request and match confirmation.

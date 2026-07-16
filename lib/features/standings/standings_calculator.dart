import '../../data/models/glo_match.dart';
import '../../data/models/standing_row.dart';
import '../../data/models/team.dart';

abstract final class StandingsCalculator {
  static List<StandingRow> calculate(List<Team> teams, List<GloMatch> matches) {
    final rows = <int, StandingRow>{
      for (final team in teams) team.id: StandingRow(team: team),
    };

    for (final match in matches) {
      if (!match.isCompleted || !match.isLeagueMatch) continue;
      if (match.roundNumber == null) continue;
      final home = rows[match.homeTeamId];
      final away = rows[match.awayTeamId];
      if (home == null && away == null) continue;

      final homeScore = match.homeScore ?? 0;
      final awayScore = match.awayScore ?? 0;

      if (home != null) {
        rows[match.homeTeamId] = home.copyWith(
          played: home.played + 1,
          goalsFor: home.goalsFor + homeScore,
          goalsAgainst: home.goalsAgainst + awayScore,
          wins: home.wins + (homeScore > awayScore ? 1 : 0),
          draws: home.draws + (homeScore == awayScore ? 1 : 0),
          losses: home.losses + (homeScore < awayScore ? 1 : 0),
          points: home.points + (homeScore > awayScore ? 3 : homeScore == awayScore ? 1 : 0),
        );
      }
      if (away != null) {
        rows[match.awayTeamId] = away.copyWith(
          played: away.played + 1,
          goalsFor: away.goalsFor + awayScore,
          goalsAgainst: away.goalsAgainst + homeScore,
          wins: away.wins + (awayScore > homeScore ? 1 : 0),
          draws: away.draws + (awayScore == homeScore ? 1 : 0),
          losses: away.losses + (awayScore < homeScore ? 1 : 0),
          points: away.points + (awayScore > homeScore ? 3 : awayScore == homeScore ? 1 : 0),
        );
      }
    }

    final result = rows.values.toList(growable: false);
    result.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byDifference = b.goalDifference.compareTo(a.goalDifference);
      if (byDifference != 0) return byDifference;
      final byGoals = b.goalsFor.compareTo(a.goalsFor);
      if (byGoals != 0) return byGoals;
      return a.team.name.compareTo(b.team.name);
    });
    return result;
  }
}

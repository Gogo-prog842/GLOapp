import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/glo_match.dart';
import '../lib/data/models/team.dart';
import '../lib/features/standings/standings_calculator.dart';

void main() {
  const feniksy = Team(id: 1, name: 'FC Feniksy', leagueId: 1);
  const rywale = Team(id: 2, name: 'Rywale', leagueId: 1);
  const trzeci = Team(id: 3, name: 'Trzeci zespół', leagueId: 1);

  test('liczy punkty, bilans i kolejność tabeli', () {
    final rows = StandingsCalculator.calculate(
      const [feniksy, rywale, trzeci],
      const [
        GloMatch(
          id: 10,
          leagueId: 1,
          homeTeamId: 1,
          awayTeamId: 2,
          status: 'completed',
          roundNumber: 1,
          homeScore: 4,
          awayScore: 2,
        ),
        GloMatch(
          id: 11,
          leagueId: 1,
          homeTeamId: 3,
          awayTeamId: 1,
          status: 'completed',
          roundNumber: 2,
          homeScore: 1,
          awayScore: 1,
        ),
      ],
    );

    expect(rows.first.team.id, 1);
    expect(rows.first.played, 2);
    expect(rows.first.points, 4);
    expect(rows.first.goalsFor, 5);
    expect(rows.first.goalsAgainst, 3);
    expect(rows.first.goalDifference, 2);
  });

  test('pomija mecze niezakończone i pucharowe', () {
    final rows = StandingsCalculator.calculate(
      const [feniksy, rywale],
      const [
        GloMatch(
          id: 20,
          leagueId: 1,
          homeTeamId: 1,
          awayTeamId: 2,
          status: 'live',
          roundNumber: 1,
          homeScore: 8,
          awayScore: 0,
        ),
        GloMatch(
          id: 21,
          leagueId: 1,
          homeTeamId: 1,
          awayTeamId: 2,
          status: 'completed',
          matchType: 'cup',
          roundNumber: 1,
          homeScore: 5,
          awayScore: 0,
        ),
      ],
    );

    expect(rows.every((row) => row.played == 0 && row.points == 0), isTrue);
  });
}

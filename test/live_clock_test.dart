import 'package:flutter_test/flutter_test.dart';
import '../lib/data/models/glo_match.dart';
import '../lib/data/repositories/match_repository.dart';

void main() {
  const baseMatch = GloMatch(
    id: 1,
    leagueId: 1,
    homeTeamId: 10,
    awayTeamId: 20,
    status: 'live',
  );

  test('pierwsza połowa liczy czas od uruchomienia zegara', () {
    final started = DateTime.utc(2026, 7, 16, 18);
    final match = GloMatch(
      id: baseMatch.id,
      leagueId: baseMatch.leagueId,
      homeTeamId: baseMatch.homeTeamId,
      awayTeamId: baseMatch.awayTeamId,
      status: baseMatch.status,
      livePeriod: 'first_half',
      liveClockStartedAt: started,
    );

    final state = LiveClockState.fromMatch(
      match,
      now: started.add(const Duration(minutes: 12, seconds: 34)),
    );

    expect(state.phase, 'I połowa');
    expect(state.display, '12:34');
    expect(state.elapsedSeconds, 754);
  });

  test('po 30 min pokazuje doliczony czas i przypisuje minutę zdarzenia', () {
    final started = DateTime.utc(2026, 7, 16, 18);
    final now = started.add(const Duration(minutes: 32, seconds: 1));
    final match = GloMatch(
      id: baseMatch.id,
      leagueId: baseMatch.leagueId,
      homeTeamId: baseMatch.homeTeamId,
      awayTeamId: baseMatch.awayTeamId,
      status: baseMatch.status,
      livePeriod: 'first_half',
      liveClockStartedAt: started,
    );

    final state = LiveClockState.fromMatch(match, now: now);
    final eventMinute = MatchRepository.currentEventMinute(match, now: now);

    expect(state.display, '30+3');
    expect(eventMinute, (30, 'first_half', 3));
  });

  test('przerwa odlicza 10 minut i może skończyć się wcześniej', () {
    final started = DateTime.utc(2026, 7, 16, 18, 30);
    final match = GloMatch(
      id: baseMatch.id,
      leagueId: baseMatch.leagueId,
      homeTeamId: baseMatch.homeTeamId,
      awayTeamId: baseMatch.awayTeamId,
      status: baseMatch.status,
      livePeriod: 'half_time',
      liveElapsedSeconds: 1800,
      liveBreakStartedAt: started,
      liveBreakSeconds: 600,
    );

    final state = LiveClockState.fromMatch(
      match,
      now: started.add(const Duration(minutes: 4, seconds: 15)),
    );

    expect(state.phase, 'Przerwa');
    expect(state.display, '05:45');
  });

  test('druga połowa kontynuuje od 30 minuty', () {
    final started = DateTime.utc(2026, 7, 16, 19);
    final match = GloMatch(
      id: baseMatch.id,
      leagueId: baseMatch.leagueId,
      homeTeamId: baseMatch.homeTeamId,
      awayTeamId: baseMatch.awayTeamId,
      status: baseMatch.status,
      livePeriod: 'second_half',
      liveElapsedSeconds: 1800,
      liveClockStartedAt: started,
    );

    final state = LiveClockState.fromMatch(
      match,
      now: started.add(const Duration(minutes: 8, seconds: 9)),
    );
    final eventMinute = MatchRepository.currentEventMinute(
      match,
      now: started.add(const Duration(minutes: 8, seconds: 9)),
    );

    expect(state.display, '38:09');
    expect(eventMinute, (39, 'second_half', null));
  });
}

import 'package:flutter/material.dart';

import '../../core/widgets/common.dart';
import '../../core/widgets/match_card.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/team.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';
import 'match_details_screen.dart';

enum _MatchFilter { all, live, upcoming, completed }

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  Future<Map<int, Team>>? _teamsFuture;
  Stream<List<GloMatch>>? _matchesStream;
  String? _selectionKey;
  var _filter = _MatchFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    final key = '${controller.selectedLeagueId}:${controller.selectedSeasonId}';
    if (_selectionKey == key) return;
    _selectionKey = key;
    final services = RepositoryScope.of(context);
    _teamsFuture = services.teamRepository.fetchTeamMap(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
    _matchesStream = services.matchRepository.watchMatches(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, Team>>(
      future: _teamsFuture,
      builder: (context, teamsSnapshot) {
        if (teamsSnapshot.connectionState != ConnectionState.done) return const GloLoading();
        if (teamsSnapshot.hasError) {
          return GloError(message: '${teamsSnapshot.error}', onRetry: _restart);
        }
        final teams = teamsSnapshot.data ?? const <int, Team>{};
        return StreamBuilder<List<GloMatch>>(
          stream: _matchesStream,
          builder: (context, matchesSnapshot) {
            if (!matchesSnapshot.hasData && !matchesSnapshot.hasError) return const GloLoading();
            if (matchesSnapshot.hasError) {
              return GloError(message: '${matchesSnapshot.error}', onRetry: _restart);
            }
            final matches = _applyFilter(matchesSnapshot.data ?? const []);
            final grouped = _groupByRound(matches);

            return Column(
              children: [
                SizedBox(
                  height: 58,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(label: 'Wszystkie', selected: _filter == _MatchFilter.all, onTap: () => _setFilter(_MatchFilter.all)),
                      _FilterChip(label: 'LIVE', selected: _filter == _MatchFilter.live, onTap: () => _setFilter(_MatchFilter.live)),
                      _FilterChip(label: 'Nadchodzące', selected: _filter == _MatchFilter.upcoming, onTap: () => _setFilter(_MatchFilter.upcoming)),
                      _FilterChip(label: 'Zakończone', selected: _filter == _MatchFilter.completed, onTap: () => _setFilter(_MatchFilter.completed)),
                    ],
                  ),
                ),
                Expanded(
                  child: matches.isEmpty
                      ? const _EmptyMatches()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final entry = grouped.entries.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 10),
                                  ...entry.value.map(
                                    (match) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: MatchCard(
                                        match: match,
                                        teams: teams,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => MatchDetailsScreen(
                                              initialMatch: match,
                                              homeTeam: teams[match.homeTeamId],
                                              awayTeam: teams[match.awayTeamId],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _restart() {
    _selectionKey = null;
    didChangeDependencies();
    setState(() {});
  }

  void _setFilter(_MatchFilter value) => setState(() => _filter = value);

  List<GloMatch> _applyFilter(List<GloMatch> matches) {
    final filtered = switch (_filter) {
      _MatchFilter.live => matches.where((match) => match.isLive),
      _MatchFilter.upcoming => matches.where((match) => match.isScheduled),
      _MatchFilter.completed => matches.where((match) => match.isCompleted),
      _MatchFilter.all => matches,
    }.toList(growable: false);

    filtered.sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      final roundA = a.roundNumber ?? 9999;
      final roundB = b.roundNumber ?? 9999;
      final byRound = roundA.compareTo(roundB);
      if (byRound != 0) return byRound;
      return _dateTime(a).compareTo(_dateTime(b));
    });
    return filtered;
  }

  Map<String, List<GloMatch>> _groupByRound(List<GloMatch> matches) {
    final grouped = <String, List<GloMatch>>{};
    for (final match in matches) {
      final label = match.roundNumber == null
          ? switch (match.matchType?.toLowerCase()) {
              'cup' || 'cup_final' => 'Puchar',
              'friendly' => 'Mecze towarzyskie',
              _ => 'Pozostałe mecze',
            }
          : 'Kolejka ${match.roundNumber}';
      grouped.putIfAbsent(label, () => <GloMatch>[]).add(match);
    }
    return grouped;
  }

  static DateTime _dateTime(GloMatch match) {
    final date = match.date ?? DateTime(2100);
    final parts = (match.time ?? '').split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyMatches extends StatelessWidget {
  const _EmptyMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 48),
            const SizedBox(height: 12),
            Text('Brak meczów dla tego filtra', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

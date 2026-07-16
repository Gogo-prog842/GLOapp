import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/glo_match.dart';
import '../../data/models/team.dart';
import '../../data/repositories/match_repository.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'live_clock_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.match,
    required this.teams,
    required this.onTap,
    super.key,
  });

  final GloMatch match;
  final Map<int, Team> teams;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final home = teams[match.homeTeamId];
    final away = teams[match.awayTeamId];
    final hasScore = match.homeScore != null && match.awayScore != null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.roundNumber == null ? _competitionLabel(match) : 'Kolejka ${match.roundNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (match.isLive)
                    LiveClockBadge(match: match)
                  else
                    Text(_dateLabel(match), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _TeamSide(team: home)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          hasScore ? '${match.homeScore} : ${match.awayScore}' : _timeLabel(match),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: match.isLive ? GloColors.danger : GloColors.text,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(_statusLabel(match), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(child: _TeamSide(team: away, alignEnd: true)),
                ],
              ),
              if ((match.venue ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: GloColors.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.venue!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _competitionLabel(GloMatch match) {
    return switch (match.matchType?.toLowerCase()) {
      'cup' || 'cup_final' => 'Puchar',
      'friendly' => 'Mecz towarzyski',
      _ => 'Liga',
    };
  }

  static String _dateLabel(GloMatch match) {
    if (match.date == null) return 'Termin nieustalony';
    return DateFormat('dd.MM.yyyy').format(match.date!);
  }

  static String _timeLabel(GloMatch match) {
    final time = match.time?.trim();
    return time == null || time.isEmpty
        ? 'VS'
        : time.substring(0, time.length < 5 ? time.length : 5);
  }

  static String _statusLabel(GloMatch match) {
    if (match.isLive) return LiveClockState.fromMatch(match).phase;
    if (match.isCompleted) return 'Zakończony';
    if (match.status == 'cancelled' || match.status == 'canceled') return 'Odwołany';
    return _dateLabel(match);
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.team, this.alignEnd = false});

  final Team? team;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        TeamLogo(team: team, size: 42),
        const SizedBox(height: 8),
        Text(
          team?.name ?? 'Nieznana drużyna',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}

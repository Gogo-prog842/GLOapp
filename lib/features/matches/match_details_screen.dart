import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/live_clock_badge.dart';
import '../../data/models/glo_match.dart';
import '../../data/models/match_event.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/app_services.dart';
import '../../data/repositories/match_repository.dart';
import '../../state/app_scope.dart';

class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({
    required this.initialMatch,
    required this.homeTeam,
    required this.awayTeam,
    super.key,
  });

  final GloMatch initialMatch;
  final Team? homeTeam;
  final Team? awayTeam;

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  GloMatch? _match;
  List<MatchEvent> _goals = const [];
  List<MatchEvent> _cards = const [];
  Map<int, Player> _players = const {};
  StreamSubscription<GloMatch?>? _matchSubscription;
  StreamSubscription<List<MatchEvent>>? _goalSubscription;
  StreamSubscription<List<MatchEvent>>? _cardSubscription;
  bool _initialized = false;
  bool _busy = false;
  String? _streamError;

  @override
  void initState() {
    super.initState();
    _match = widget.initialMatch;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _subscribe();
  }

  Future<void> _subscribe() async {
    final services = RepositoryScope.of(context);
    try {
      final players = await services.playerRepository.fetchPlayersForTeams([
        widget.initialMatch.homeTeamId,
        widget.initialMatch.awayTeamId,
      ]);
      if (mounted) setState(() => _players = players);

      _matchSubscription = services.matchRepository
          .watchMatch(widget.initialMatch.id)
          .listen(
            (match) {
              if (match != null && mounted) setState(() => _match = match);
            },
            onError: _onStreamError,
          );
      _goalSubscription = services.matchRepository
          .watchGoals(widget.initialMatch.id)
          .listen(
            (goals) {
              if (mounted) setState(() => _goals = goals);
            },
            onError: _onStreamError,
          );
      _cardSubscription = services.matchRepository
          .watchCards(widget.initialMatch.id)
          .listen(
            (cards) {
              if (mounted) setState(() => _cards = cards);
            },
            onError: _onStreamError,
          );
    } catch (error) {
      _onStreamError(error);
    }
  }

  void _onStreamError(Object error) {
    if (mounted) setState(() => _streamError = error.toString());
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _goalSubscription?.cancel();
    _cardSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = _match ?? widget.initialMatch;
    final role = AppScope.of(context).role;
    final canManage = _canManage(match, role);
    final events = [..._goals, ..._cards]..sort(_compareEvents);

    return Scaffold(
      appBar: AppBar(title: const Text('Centrum meczu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ScoreHeader(
            match: match,
            homeTeam: widget.homeTeam,
            awayTeam: widget.awayTeam,
          ),
          if (_streamError != null) ...[
            const SizedBox(height: 12),
            MaterialBanner(
              content: Text('Realtime: $_streamError'),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _streamError = null),
                  child: const Text('Ukryj'),
                ),
              ],
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: 16),
            _LiveControls(
              match: match,
              busy: _busy,
              onStart: () => _runAction(() => _repository.startLiveMatch(match)),
              onBreak: () => _runAction(() => _repository.startBreak(match)),
              onSecondHalf: () => _runAction(() => _repository.startSecondHalf(match)),
              onAddTime: () => _runAction(() => _repository.addAddedMinute(match)),
              onFinish: () => _confirmFinish(match),
              onAddEvent: match.isLive ? () => _showAddEventSheet(match) : null,
              onSetMvp: () => _showMvpSheet(match),
            ),
            if (match.isLive) ...[
              const SizedBox(height: 12),
              _TeamQuickActions(
                homeTeam: widget.homeTeam,
                awayTeam: widget.awayTeam,
                onHomeGoal: () => _showAddEventSheet(match, initialTeamId: match.homeTeamId, initialKind: _DraftKind.goal),
                onAwayGoal: () => _showAddEventSheet(match, initialTeamId: match.awayTeamId, initialKind: _DraftKind.goal),
                onHomeYellow: () => _showAddEventSheet(match, initialTeamId: match.homeTeamId, initialKind: _DraftKind.yellowCard),
                onAwayYellow: () => _showAddEventSheet(match, initialTeamId: match.awayTeamId, initialKind: _DraftKind.yellowCard),
                onHomeRed: () => _showAddEventSheet(match, initialTeamId: match.homeTeamId, initialKind: _DraftKind.redCard),
                onAwayRed: () => _showAddEventSheet(match, initialTeamId: match.awayTeamId, initialKind: _DraftKind.redCard),
              ),
            ],
          ],
          const SizedBox(height: 22),
          const SectionHeader(title: 'Składy'),
          const SizedBox(height: 12),
          _LineupsCard(
            match: match,
            homeTeam: widget.homeTeam,
            awayTeam: widget.awayTeam,
            players: _players.values.toList(growable: false),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Wydarzenia'),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: Text('Brak goli i kartek w protokole.')),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var index = 0; index < events.length; index++) ...[
                    _EventTile(
                      event: events[index],
                      player: _players[events[index].playerId],
                      assistPlayer: _players[events[index].assistPlayerId],
                      homeTeamId: match.homeTeamId,
                      canDelete: canManage,
                      onDelete: () => _deleteEvent(match, events[index]),
                    ),
                    if (index != events.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
          if (match.mvpPlayerId != null || match.mvpAwayPlayerId != null) ...[
            const SizedBox(height: 22),
            const SectionHeader(title: 'MVP meczu'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  if (match.mvpPlayerId != null)
                    _MvpTile(
                      label: widget.homeTeam?.name ?? 'Gospodarze',
                      player: _players[match.mvpPlayerId],
                    ),
                  if (match.mvpPlayerId != null && match.mvpAwayPlayerId != null)
                    const Divider(height: 1),
                  if (match.mvpAwayPlayerId != null)
                    _MvpTile(
                      label: widget.awayTeam?.name ?? 'Goście',
                      player: _players[match.mvpAwayPlayerId],
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          _MatchInfo(match: match),
        ],
      ),
    );
  }

  MatchRepository get _repository => RepositoryScope.of(context).matchRepository;

  bool _canManage(GloMatch match, UserRole role) {
    if (role.type == UserRoleType.admin) return true;
    if (role.type != UserRoleType.referee) return false;
    final assigned = (match.refereeEmail ?? '').trim().toLowerCase();
    final current = (role.email ?? '').trim().toLowerCase();
    return assigned.isNotEmpty && assigned == current;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString()), backgroundColor: GloColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmFinish(GloMatch match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zakończyć mecz?'),
        content: const Text('Wynik zostanie przeliczony na podstawie zapisanych goli.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Zakończ')),
        ],
      ),
    );
    if (confirmed == true) await _runAction(() => _repository.finishLiveMatch(match));
  }

  Future<void> _showAddEventSheet(
    GloMatch match, {
    int? initialTeamId,
    _DraftKind initialKind = _DraftKind.goal,
  }) async {
    final players = _players.values
        .where((player) => player.teamId == match.homeTeamId || player.teamId == match.awayTeamId)
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono zawodników obu drużyn.')),
      );
      return;
    }

    final draft = await showModalBottomSheet<_EventDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AddEventSheet(
        match: match,
        homeTeam: widget.homeTeam,
        awayTeam: widget.awayTeam,
        players: players,
        initialTeamId: initialTeamId,
        initialKind: initialKind,
      ),
    );
    if (draft == null) return;

    await _runAction(() async {
      if (draft.kind == _DraftKind.goal) {
        await _repository.addGoal(
          match: match,
          playerId: draft.playerId,
          playerTeamId: draft.teamId,
          assistPlayerId: draft.assistPlayerId,
          type: draft.goalType,
        );
      } else {
        await _repository.addCard(
          match: match,
          playerId: draft.playerId,
          playerTeamId: draft.teamId,
          type: draft.kind == _DraftKind.redCard ? 'red' : 'yellow',
        );
      }
    });
  }

  Future<void> _deleteEvent(GloMatch match, MatchEvent event) async {
    await _runAction(() async {
      if (event.kind == MatchEventKind.goal) {
        await _repository.deleteGoal(match, event.id);
      } else {
        await _repository.deleteCard(event.id);
      }
    });
  }

  Future<void> _showMvpSheet(GloMatch match) async {
    final players = _players.values
        .where((player) => player.teamId == match.homeTeamId || player.teamId == match.awayTeamId)
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono zawodników obu drużyn.')),
      );
      return;
    }

    final draft = await showModalBottomSheet<_MvpDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _MvpSheet(
        match: match,
        homeTeam: widget.homeTeam,
        awayTeam: widget.awayTeam,
        players: players,
      ),
    );
    if (draft == null) return;

    await _runAction(() => _repository.setMvp(
          match: match,
          homePlayerId: draft.homePlayerId,
          awayPlayerId: draft.awayPlayerId,
        ));
  }

  static int _compareEvents(MatchEvent a, MatchEvent b) {
    final minute = (a.minute ?? 999).compareTo(b.minute ?? 999);
    if (minute != 0) return minute;
    final extra = (a.extraMinute ?? 0).compareTo(b.extraMinute ?? 0);
    if (extra != 0) return extra;
    return a.id.compareTo(b.id);
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
  });

  final GloMatch match;
  final Team? homeTeam;
  final Team? awayTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF111E38), Color(0xFF0A0F1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: GloColors.border),
      ),
      child: Column(
        children: [
          if (match.isLive) LiveClockBadge(match: match, large: true) else Text(_status(match), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _HeaderTeam(team: homeTeam)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  match.homeScore == null || match.awayScore == null
                      ? 'VS'
                      : '${match.homeScore} : ${match.awayScore}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 32),
                ),
              ),
              Expanded(child: _HeaderTeam(team: awayTeam, alignEnd: true)),
            ],
          ),
          if (match.roundNumber != null) ...[
            const SizedBox(height: 16),
            Text('Kolejka ${match.roundNumber}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  static String _status(GloMatch match) {
    if (match.isCompleted) return 'Mecz zakończony';
    if (match.isScheduled) return 'Mecz zaplanowany';
    return match.status;
  }
}

class _HeaderTeam extends StatelessWidget {
  const _HeaderTeam({required this.team, this.alignEnd = false});

  final Team? team;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        TeamLogo(team: team, size: 58),
        const SizedBox(height: 10),
        Text(
          team?.name ?? 'Nieznana drużyna',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _LiveControls extends StatelessWidget {
  const _LiveControls({
    required this.match,
    required this.busy,
    required this.onStart,
    required this.onBreak,
    required this.onSecondHalf,
    required this.onAddTime,
    required this.onFinish,
    required this.onAddEvent,
    required this.onSetMvp,
  });

  final GloMatch match;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onBreak;
  final VoidCallback onSecondHalf;
  final VoidCallback onAddTime;
  final VoidCallback onFinish;
  final VoidCallback? onAddEvent;
  final VoidCallback onSetMvp;

  @override
  Widget build(BuildContext context) {
    final period = match.livePeriod?.toLowerCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panel sędziego LIVE', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!match.isLive && !match.isCompleted)
                  FilledButton.icon(onPressed: busy ? null : onStart, icon: const Icon(Icons.play_arrow), label: const Text('Rozpocznij')),
                if (match.isLive && period == 'first_half')
                  FilledButton.icon(onPressed: busy ? null : onBreak, icon: const Icon(Icons.pause), label: const Text('Przerwa')),
                if (match.isLive && period == 'half_time')
                  FilledButton.icon(onPressed: busy ? null : onSecondHalf, icon: const Icon(Icons.play_arrow), label: const Text('II połowa')),
                if (match.isLive && (period == 'first_half' || period == 'second_half'))
                  OutlinedButton.icon(onPressed: busy ? null : onAddTime, icon: const Icon(Icons.add_alarm), label: const Text('+1 min')),
                if (onAddEvent != null)
                  FilledButton.tonalIcon(onPressed: busy ? null : onAddEvent, icon: const Icon(Icons.add), label: const Text('Gol / kartka')),
                OutlinedButton.icon(onPressed: busy ? null : onSetMvp, icon: const Icon(Icons.star_outline), label: const Text('MVP')),
                if (match.isLive && period == 'second_half')
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: GloColors.danger),
                    onPressed: busy ? null : onFinish,
                    icon: const Icon(Icons.stop),
                    label: const Text('Zakończ'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.player,
    required this.assistPlayer,
    required this.homeTeamId,
    required this.canDelete,
    required this.onDelete,
  });

  final MatchEvent event;
  final Player? player;
  final Player? assistPlayer;
  final int homeTeamId;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isHome = event.teamId == homeTeamId;
    final icon = switch (event.kind) {
      MatchEventKind.goal => Icons.sports_soccer,
      MatchEventKind.yellowCard => Icons.style,
      MatchEventKind.redCard => Icons.style,
    };
    final color = switch (event.kind) {
      MatchEventKind.goal => GloColors.text,
      MatchEventKind.yellowCard => const Color(0xFFFACC15),
      MatchEventKind.redCard => GloColors.danger,
    };
    final subtitle = event.kind == MatchEventKind.goal && assistPlayer != null
        ? 'Asysta: ${assistPlayer!.name}${event.goalType == 'penalty' ? ' • karny' : event.goalType == 'own_goal' ? ' • samobójczy' : ''}'
        : event.kind == MatchEventKind.goal && event.goalType == 'penalty'
            ? 'Rzut karny'
            : event.kind == MatchEventKind.goal && event.goalType == 'own_goal'
                ? 'Gol samobójczy'
                : event.kind == MatchEventKind.redCard
                    ? 'Czerwona kartka'
                    : event.kind == MatchEventKind.yellowCard
                        ? 'Żółta kartka'
                        : null;

    return ListTile(
      leading: SizedBox(
        width: 54,
        child: Row(
          children: [
            Text(event.minuteLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 7),
            Icon(icon, size: 20, color: color),
          ],
        ),
      ),
      title: Text(player?.name ?? 'Zawodnik #${event.playerId}', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isHome ? Icons.arrow_back : Icons.arrow_forward, size: 17, color: GloColors.muted),
          if (canDelete)
            IconButton(
              tooltip: 'Usuń zdarzenie',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
        ],
      ),
    );
  }
}

class _MvpTile extends StatelessWidget {
  const _MvpTile({required this.label, required this.player});

  final String label;
  final Player? player;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.star)),
      title: Text(player?.name ?? 'Zawodnik', style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(label),
    );
  }
}

class _MatchInfo extends StatelessWidget {
  const _MatchInfo({required this.match});

  final GloMatch match;

  @override
  Widget build(BuildContext context) {
    final date = match.date == null ? 'Nieustalona' : DateFormat('dd.MM.yyyy').format(match.date!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informacje', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.calendar_today_outlined, label: '$date ${match.time ?? ''}'.trim()),
            _InfoRow(icon: Icons.location_on_outlined, label: match.venue ?? 'Boisko nieustalone'),
            _InfoRow(icon: Icons.sports_outlined, label: match.referee ?? match.refereeEmail ?? 'Sędzia nieprzypisany'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GloColors.muted),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}


class _TeamQuickActions extends StatelessWidget {
  const _TeamQuickActions({
    required this.homeTeam,
    required this.awayTeam,
    required this.onHomeGoal,
    required this.onAwayGoal,
    required this.onHomeYellow,
    required this.onAwayYellow,
    required this.onHomeRed,
    required this.onAwayRed,
  });

  final Team? homeTeam;
  final Team? awayTeam;
  final VoidCallback onHomeGoal;
  final VoidCallback onAwayGoal;
  final VoidCallback onHomeYellow;
  final VoidCallback onAwayYellow;
  final VoidCallback onHomeRed;
  final VoidCallback onAwayRed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _QuickTeamCard(
            title: homeTeam?.name ?? 'Gospodarze',
            alignEnd: false,
            onGoal: onHomeGoal,
            onYellow: onHomeYellow,
            onRed: onHomeRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTeamCard(
            title: awayTeam?.name ?? 'Goście',
            alignEnd: true,
            onGoal: onAwayGoal,
            onYellow: onAwayYellow,
            onRed: onAwayRed,
          ),
        ),
      ],
    );
  }
}

class _QuickTeamCard extends StatelessWidget {
  const _QuickTeamCard({
    required this.title,
    required this.alignEnd,
    required this.onGoal,
    required this.onYellow,
    required this.onRed,
  });

  final String title;
  final bool alignEnd;
  final VoidCallback onGoal;
  final VoidCallback onYellow;
  final VoidCallback onRed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGoal,
                icon: const Icon(Icons.sports_soccer),
                label: const Text('Gol'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onYellow,
                    child: const Text('Żółta'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRed,
                    child: const Text('Czerwona'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineupsCard extends StatelessWidget {
  const _LineupsCard({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.players,
  });

  final GloMatch match;
  final Team? homeTeam;
  final Team? awayTeam;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final homePlayers = players.where((player) => player.teamId == match.homeTeamId).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    final awayPlayers = players.where((player) => player.teamId == match.awayTeamId).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _TeamLineupColumn(title: homeTeam?.name ?? 'Gospodarze', players: homePlayers)),
            const SizedBox(width: 12),
            Expanded(child: _TeamLineupColumn(title: awayTeam?.name ?? 'Goście', players: awayPlayers, alignEnd: true)),
          ],
        ),
      ),
    );
  }
}

class _TeamLineupColumn extends StatelessWidget {
  const _TeamLineupColumn({required this.title, required this.players, this.alignEnd = false});

  final String title;
  final List<Player> players;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final preview = players.take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (preview.isEmpty)
          Text('Brak zawodników', style: Theme.of(context).textTheme.bodySmall)
        else
          ...preview.map(
            (player) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                player.jerseyNumber == null ? player.name : '#${player.jerseyNumber} ${player.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              ),
            ),
          ),
        if (players.length > preview.length)
          Text('+${players.length - preview.length} więcej', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MvpDraft {
  const _MvpDraft({this.homePlayerId, this.awayPlayerId});

  final int? homePlayerId;
  final int? awayPlayerId;
}

class _MvpSheet extends StatefulWidget {
  const _MvpSheet({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.players,
  });

  final GloMatch match;
  final Team? homeTeam;
  final Team? awayTeam;
  final List<Player> players;

  @override
  State<_MvpSheet> createState() => _MvpSheetState();
}

class _MvpSheetState extends State<_MvpSheet> {
  int? _homePlayerId;
  int? _awayPlayerId;

  @override
  void initState() {
    super.initState();
    _homePlayerId = widget.match.mvpPlayerId;
    _awayPlayerId = widget.match.mvpAwayPlayerId;
  }

  @override
  Widget build(BuildContext context) {
    final homePlayers = widget.players.where((player) => player.teamId == widget.match.homeTeamId).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    final awayPlayers = widget.players.where((player) => player.teamId == widget.match.awayTeamId).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    if (_homePlayerId != null && !homePlayers.any((player) => player.id == _homePlayerId)) {
      _homePlayerId = null;
    }
    if (_awayPlayerId != null && !awayPlayers.any((player) => player.id == _awayPlayerId)) {
      _awayPlayerId = null;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ustaw MVP meczu', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _homePlayerId,
            decoration: InputDecoration(labelText: 'MVP ${widget.homeTeam?.name ?? 'gospodarzy'}'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Brak MVP')),
              ...homePlayers.map((player) => DropdownMenuItem<int?>(value: player.id, child: Text(player.name))),
            ],
            onChanged: (value) => setState(() => _homePlayerId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _awayPlayerId,
            decoration: InputDecoration(labelText: 'MVP ${widget.awayTeam?.name ?? 'gości'}'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Brak MVP')),
              ...awayPlayers.map((player) => DropdownMenuItem<int?>(value: player.id, child: Text(player.name))),
            ],
            onChanged: (value) => setState(() => _awayPlayerId = value),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                _MvpDraft(homePlayerId: _homePlayerId, awayPlayerId: _awayPlayerId),
              ),
              icon: const Icon(Icons.save),
              label: const Text('Zapisz MVP'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _DraftKind { goal, yellowCard, redCard }

class _EventDraft {
  const _EventDraft({
    required this.kind,
    required this.teamId,
    required this.playerId,
    required this.goalType,
    this.assistPlayerId,
  });

  final _DraftKind kind;
  final int teamId;
  final int playerId;
  final int? assistPlayerId;
  final String goalType;
}

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.players,
    required this.initialTeamId,
    required this.initialKind,
  });

  final GloMatch match;
  final Team? homeTeam;
  final Team? awayTeam;
  final List<Player> players;
  final int? initialTeamId;
  final _DraftKind initialKind;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  _DraftKind _kind = _DraftKind.goal;
  late int _teamId;
  int? _playerId;
  int? _assistPlayerId;
  String _goalType = 'normal';

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _teamId = widget.initialTeamId ?? widget.match.homeTeamId;
  }

  List<Player> get _teamPlayers => widget.players.where((player) => player.teamId == _teamId).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final players = _teamPlayers;
    if (_playerId != null && !players.any((player) => player.id == _playerId)) {
      _playerId = null;
      _assistPlayerId = null;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dodaj wydarzenie', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<_DraftKind>(
              segments: const [
                ButtonSegment(value: _DraftKind.goal, label: Text('Gol'), icon: Icon(Icons.sports_soccer)),
                ButtonSegment(value: _DraftKind.yellowCard, label: Text('Żółta')),
                ButtonSegment(value: _DraftKind.redCard, label: Text('Czerwona')),
              ],
              selected: {_kind},
              onSelectionChanged: (value) => setState(() => _kind = value.first),
            ),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: widget.match.homeTeamId, label: Text(widget.homeTeam?.name ?? 'Gospodarze')),
                ButtonSegment(value: widget.match.awayTeamId, label: Text(widget.awayTeam?.name ?? 'Goście')),
              ],
              selected: {_teamId},
              onSelectionChanged: (value) => setState(() {
                _teamId = value.first;
                _playerId = null;
                _assistPlayerId = null;
              }),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _playerId,
              decoration: const InputDecoration(labelText: 'Zawodnik'),
              items: players
                  .map((player) => DropdownMenuItem(value: player.id, child: Text(player.name)))
                  .toList(growable: false),
              onChanged: (value) => setState(() {
                _playerId = value;
                if (_assistPlayerId == value) _assistPlayerId = null;
              }),
            ),
            if (_kind == _DraftKind.goal) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _goalType,
                decoration: const InputDecoration(labelText: 'Rodzaj gola'),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normalny')), 
                  DropdownMenuItem(value: 'penalty', child: Text('Rzut karny')),
                  DropdownMenuItem(value: 'own_goal', child: Text('Gol samobójczy')),
                ],
                onChanged: (value) => setState(() {
                  _goalType = value ?? 'normal';
                  if (_goalType == 'own_goal') _assistPlayerId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _assistPlayerId,
                decoration: const InputDecoration(labelText: 'Asysta (opcjonalnie)'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Bez asysty')),
                  ...players
                      .where((player) => player.id != _playerId)
                      .map((player) => DropdownMenuItem<int?>(value: player.id, child: Text(player.name))),
                ],
                onChanged: _goalType == 'own_goal' ? null : (value) => setState(() => _assistPlayerId = value),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _playerId == null
                    ? null
                    : () => Navigator.pop(
                          context,
                          _EventDraft(
                            kind: _kind,
                            teamId: _teamId,
                            playerId: _playerId!,
                            assistPlayerId: _assistPlayerId,
                            goalType: _goalType,
                          ),
                        ),
                icon: const Icon(Icons.save),
                label: const Text('Zapisz wydarzenie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

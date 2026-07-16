import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/transfer_record.dart';
import '../../data/repositories/app_services.dart';
import '../../state/app_scope.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  final _searchController = TextEditingController();
  late Future<List<TransferRecord>> _future;
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = Future.value(const []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<TransferRecord>> _load() {
    final controller = AppScope.of(context);
    final services = RepositoryScope.of(context);
    return services.transferRepository.fetchTransfers(
      leagueId: controller.selectedLeagueId,
      seasonId: controller.selectedSeasonId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return FutureBuilder<List<TransferRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GloLoading(label: 'Ładowanie transferów…');
        }
        if (snapshot.hasError) {
          return GloError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() => _future = _load()),
          );
        }

        final allTransfers = snapshot.data ?? const <TransferRecord>[];
        final filtered = _applyFilters(allTransfers);

        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              SectionHeader(
                title: 'Transfery',
                trailing: Chip(label: Text('${filtered.length}/${allTransfers.length}')),
              ),
              const SizedBox(height: 4),
              Text(
                '${controller.selectedLeague?.name ?? 'Liga'} · ${controller.selectedSeason?.name ?? 'wszystkie sezony'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Szukaj zawodnika lub drużyny',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _typeFilter,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Wszystkie')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfery')),
                  DropdownMenuItem(value: 'loan', child: Text('Wypożyczenia')),
                  DropdownMenuItem(value: 'loan_end', child: Text('Koniec wypożyczenia')),
                  DropdownMenuItem(value: 'free', child: Text('Wolni zawodnicy')),
                ],
                onChanged: (value) => setState(() => _typeFilter = value ?? 'all'),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Brak transferów dla wybranych filtrów.'),
                  ),
                )
              else
                ...filtered.map(_TransferCard.new),
            ],
          ),
        );
      },
    );
  }

  List<TransferRecord> _applyFilters(List<TransferRecord> transfers) {
    final query = _searchController.text.trim().toLowerCase();
    return transfers.where((transfer) {
      if (!_matchesType(transfer)) return false;
      if (query.isEmpty) return true;
      final haystack = [
        transfer.playerName,
        transfer.fromTeamName,
        transfer.toTeamName,
        transfer.notes,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  bool _matchesType(TransferRecord transfer) {
    if (_typeFilter == 'all') return true;
    final normalized = (transfer.type ?? '').trim().toLowerCase();
    final toName = (transfer.toTeamName ?? '').trim().toLowerCase();
    if (_typeFilter == 'free') return toName == 'wolni zawodnicy';
    if (_typeFilter == 'loan') return normalized == 'loan' || normalized == 'wypożyczenie';
    if (_typeFilter == 'loan_end') return normalized == 'loan_end' || normalized.contains('koniec');
    return normalized.isEmpty || normalized == 'transfer';
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard(this.transfer);

  final TransferRecord transfer;

  @override
  Widget build(BuildContext context) {
    final date = transfer.transferDate == null
        ? '—'
        : DateFormat('dd.MM.yyyy', 'pl_PL').format(transfer.transferDate!);
    final route = '${transfer.fromTeamName ?? 'Brak drużyny'} → ${transfer.toTeamName ?? '—'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transfer.playerName ?? 'Nieznany zawodnik',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _TypeBadge(transfer: transfer),
              ],
            ),
            const SizedBox(height: 8),
            Text(route, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Meta(icon: Icons.event, label: date),
                if ((transfer.seasonName ?? '').isNotEmpty)
                  _Meta(icon: Icons.emoji_events_outlined, label: transfer.seasonName!),
                if (transfer.leagueId != null)
                  _Meta(icon: Icons.leaderboard_outlined, label: transfer.leagueId == 1 ? 'L1' : 'L2'),
              ],
            ),
            if ((transfer.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(transfer.notes!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.transfer});

  final TransferRecord transfer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: GloColors.primary.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GloColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        transfer.typeLabel,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: GloColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

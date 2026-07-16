import 'package:flutter/material.dart';

import '../../data/models/team.dart';
import '../theme/app_theme.dart';

class GloLoading extends StatelessWidget {
  const GloLoading({super.key, this.label = 'Ładowanie danych…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class GloError extends StatelessWidget {
  const GloError({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: GloColors.danger),
            const SizedBox(height: 12),
            Text('Nie udało się pobrać danych', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamIdentity extends StatelessWidget {
  const TeamIdentity({
    required this.team,
    super.key,
    this.compact = false,
    this.textAlign = TextAlign.start,
  });

  final Team? team;
  final bool compact;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 28.0 : 42.0;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamLogo(team: team, size: logoSize),
        SizedBox(width: compact ? 8 : 10),
        Flexible(
          child: Text(
            team?.name ?? 'Nieznana drużyna',
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    return child;
  }
}

class TeamLogo extends StatelessWidget {
  const TeamLogo({required this.team, required this.size, super.key});

  final Team? team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = team?.logoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GloColors.surfaceStrong,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: GloColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? Center(
              child: Text(
                _initials(team?.name),
                style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w900),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(_initials(team?.name), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
    );
  }

  static String _initials(String? name) {
    final words = (name ?? 'GLO').trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word.isEmpty ? '' : word[0]).join().toUpperCase();
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

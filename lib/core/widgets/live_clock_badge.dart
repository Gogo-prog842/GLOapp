import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/glo_match.dart';
import '../../data/repositories/match_repository.dart';
import '../theme/app_theme.dart';

class LiveClockBadge extends StatefulWidget {
  const LiveClockBadge({required this.match, super.key, this.large = false});

  final GloMatch match;
  final bool large;

  @override
  State<LiveClockBadge> createState() => _LiveClockBadgeState();
}

class _LiveClockBadgeState extends State<LiveClockBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant LiveClockBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.status != widget.match.status ||
        oldWidget.match.livePeriod != widget.match.livePeriod) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    if (widget.match.isLive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock = LiveClockState.fromMatch(widget.match);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.large ? 14 : 9,
        vertical: widget.large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: GloColors.danger.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GloColors.danger.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.large ? 9 : 7,
            height: widget.large ? 9 : 7,
            decoration: const BoxDecoration(color: GloColors.danger, shape: BoxShape.circle),
          ),
          SizedBox(width: widget.large ? 8 : 6),
          Text(
            clock.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.large ? 15 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

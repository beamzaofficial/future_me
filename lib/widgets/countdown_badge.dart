import 'dart:async';

import 'package:flutter/material.dart';

String formatRemaining(Duration d) {
  if (d.isNegative || d.inSeconds == 0) return 'Unlocked';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

class CountdownBadge extends StatefulWidget {
  final DateTime unlockAt;
  final TextStyle? style;
  final bool compact;
  const CountdownBadge({
    super.key,
    required this.unlockAt,
    this.style,
    this.compact = false,
  });

  @override
  State<CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<CountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final unlocked = !now.isBefore(widget.unlockAt);
    final scheme = Theme.of(context).colorScheme;
    final bg = unlocked
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHigh;
    final fg = unlocked ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final label = unlocked
        ? 'Unlocked'
        : formatRemaining(widget.unlockAt.difference(now));
    final icon = unlocked
        ? Icons.mark_email_read_rounded
        : Icons.schedule_rounded;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 12,
        vertical: widget.compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: widget.compact ? 14 : 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: (widget.style ?? Theme.of(context).textTheme.labelMedium)
                ?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

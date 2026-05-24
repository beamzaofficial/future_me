import 'package:flutter/material.dart';

import '../models/letter.dart';

class ReactionBar extends StatelessWidget {
  final Letter letter;
  final String? currentUserId;
  final void Function(ReactionType?) onReact;

  const ReactionBar({
    super.key,
    required this.letter,
    required this.currentUserId,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mine = currentUserId == null
        ? null
        : letter.reactionOf(currentUserId!);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in ReactionType.values)
          _ReactionChip(
            type: type,
            count: letter.reactionCount(type),
            selected: mine == type,
            onTap: currentUserId == null
                ? null
                : () => onReact(mine == type ? null : type),
            scheme: scheme,
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final ReactionType type;
  final int count;
  final bool selected;
  final VoidCallback? onTap;
  final ColorScheme scheme;
  const _ReactionChip({
    required this.type,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return Tooltip(
      message: _reactionLabel(type),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${_reactionLabel(type)} reactions: $count',
        child: Material(
          key: Key('reaction-${type.key}'),
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.34)
                  : scheme.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_reactionIcon(type), size: 18, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _reactionIcon(ReactionType type) {
    switch (type) {
      case ReactionType.heart:
        return Icons.favorite_rounded;
      case ReactionType.hug:
        return Icons.volunteer_activism_rounded;
      case ReactionType.star:
        return Icons.star_rounded;
    }
  }

  String _reactionLabel(ReactionType type) {
    switch (type) {
      case ReactionType.heart:
        return 'Loved';
      case ReactionType.hug:
        return 'Encouraged';
      case ReactionType.star:
        return 'Remembered';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/letter.dart';
import 'countdown_badge.dart';

class LetterCard extends StatelessWidget {
  final Letter letter;
  final VoidCallback? onTap;
  final bool showVisibilityChip;
  const LetterCard({
    super.key,
    required this.letter,
    this.onTap,
    this.showVisibilityChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unlocked = letter.isUnlocked;
    final accent = unlocked ? scheme.secondary : scheme.primary;
    final preview = unlocked
        ? letter.content
        : 'Sealed until ${DateFormat.yMMMd().add_jm().format(letter.unlockAt)}';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: accent),
                child: const SizedBox(width: 5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          backgroundImage: letter.authorPhotoUrl != null
                              ? NetworkImage(letter.authorPhotoUrl!)
                              : null,
                          child: letter.authorPhotoUrl == null
                              ? const Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            letter.authorName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showVisibilityChip)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _VisibilityMark(isPublic: letter.isPublic),
                          ),
                        Icon(
                          unlocked
                              ? Icons.mark_email_read_outlined
                              : Icons.mark_email_unread_outlined,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        CountdownBadge(
                          unlockAt: letter.unlockAt,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      letter.title.isEmpty ? '(Untitled)' : letter.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: unlocked
                            ? FontStyle.normal
                            : FontStyle.italic,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityMark extends StatelessWidget {
  final bool isPublic;
  const _VisibilityMark({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: isPublic ? 'Public after unlock' : 'Private letter',
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(
          isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
          size: 15,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

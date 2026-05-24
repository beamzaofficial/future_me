import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_assets.dart';
import '../models/letter.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/countdown_badge.dart';
import '../widgets/reaction_bar.dart';

class DetailPage extends StatelessWidget {
  final String letterId;
  const DetailPage({super.key, required this.letterId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Letter'),
      ),
      body: StreamBuilder<Letter?>(
        stream: fs.watchLetter(letterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final letter = snapshot.data;
          if (letter == null) {
            return const Center(child: Text('Letter not found.'));
          }
          final isOwner = auth.user?.uid == letter.authorId;
          // Privacy guard: a private locked letter that isn't yours shouldn't render
          if (!letter.isPublic && !isOwner) {
            return const Center(
              child: Text('You do not have access to this letter.'),
            );
          }
          return _LetterView(letter: letter, isOwner: isOwner);
        },
      ),
    );
  }
}

class _LetterView extends StatelessWidget {
  final Letter letter;
  final bool isOwner;
  const _LetterView({required this.letter, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    if (letter.isUnlocked) {
      return _UnlockedView(letter: letter);
    }
    return _SealedView(letter: letter, isOwner: isOwner);
  }
}

// ─── Unlocked: arrival → journey → reading → reactions ────────────────────

class _UnlockedView extends StatelessWidget {
  final Letter letter;
  const _UnlockedView({required this.letter});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _ArrivalHero(letter: letter),
        const SizedBox(height: 14),
        _JourneyStrip(letter: letter),
        const SizedBox(height: 14),
        _LetterPaper(letter: letter),
        if (letter.isPublic) ...[
          const SizedBox(height: 22),
          _ReactionsSection(letter: letter),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ArrivalHero extends StatelessWidget {
  final Letter letter;
  const _ArrivalHero({required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final openedDay = DateTime(
      letter.unlockAt.year,
      letter.unlockAt.month,
      letter.unlockAt.day,
    );
    final daysAgo = today.difference(openedDay).inDays;
    final delivered = daysAgo <= 0
        ? 'Delivered today'
        : daysAgo == 1
        ? 'Delivered yesterday'
        : daysAgo < 7
        ? 'Delivered $daysAgo days ago'
        : 'Delivered ${DateFormat.yMMMd().format(letter.unlockAt)}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 152,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _ArrivalHeroImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.0),
                    scheme.surface.withValues(alpha: 0.74),
                  ],
                  stops: const [0.40, 1.0],
                ),
              ),
            ),
            // Postmark in upper-right
            Positioned(
              top: 12,
              right: 12,
              child: _PostmarkStamp(date: letter.unlockAt),
            ),
            Positioned(
              left: 16,
              right: 80,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivered.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A letter has arrived',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From ${letter.authorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  final Letter letter;
  const _JourneyStrip({required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final journey = _formatTraveled(
      letter.unlockAt.difference(letter.createdAt),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          _JourneyEnd(
            label: 'Sealed',
            value: DateFormat.yMMMd().format(letter.createdAt),
            icon: Icons.lock_clock_rounded,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.outlineVariant,
                          scheme.primary.withValues(alpha: 0.55),
                          scheme.outlineVariant,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 12,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            journey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _JourneyEnd(
            label: 'Opened',
            value: DateFormat.yMMMd().format(letter.unlockAt),
            icon: Icons.mark_email_read_rounded,
            alignEnd: true,
          ),
        ],
      ),
    );
  }
}

class _JourneyEnd extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool alignEnd;
  const _JourneyEnd({
    required this.label,
    required this.value,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignEnd) ...[
              Icon(icon, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
            if (alignEnd) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LetterPaper extends StatelessWidget {
  final Letter letter;
  const _LetterPaper({required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letterhead — small line + "A letter from …"
          Row(
            children: [
              Container(
                height: 2,
                width: 28,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A letter from ${letter.authorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            letter.title.isEmpty ? '(Untitled)' : letter.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            letter.content,
            key: const Key('letter-content'),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          // Signature block
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                backgroundImage: letter.authorPhotoUrl != null
                    ? NetworkImage(letter.authorPhotoUrl!)
                    : null,
                child: letter.authorPhotoUrl == null
                    ? const Icon(Icons.person_outline_rounded, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '— ${letter.authorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Sealed ${DateFormat.yMMMd().format(letter.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: letter.isPublic
                    ? 'On the public wall'
                    : 'Private letter',
                child: Icon(
                  letter.isPublic
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReactionsSection extends StatelessWidget {
  final Letter letter;
  const _ReactionsSection({required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.favorite_outline_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How readers received it',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Send a small note back through time.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final fs = context.read<FirestoreService>();
              final auth = context.watch<AuthProvider>();
              return ReactionBar(
                letter: letter,
                currentUserId: auth.user?.uid,
                onReact: (type) async {
                  final uid = auth.user?.uid;
                  if (uid == null) return;
                  await fs.setReaction(letter.id, uid, type);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Sealed (locked): owner sees envelope hero + meta + delete ────────────

class _SealedView extends StatelessWidget {
  final Letter letter;
  final bool isOwner;
  const _SealedView({required this.letter, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          key: const Key('letter-locked-placeholder'),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                SizedBox(
                  height: 240,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _SealedHeroImage(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.surface.withValues(alpha: 0.0),
                              scheme.surface.withValues(alpha: 0.40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sealed and waiting',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This letter is sleeping until ${DateFormat.yMMMd().add_jm().format(letter.unlockAt)}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CountdownBadge(unlockAt: letter.unlockAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SealedMetaCard(letter: letter),
        if (isOwner) ...[
          const SizedBox(height: 22),
          _DeleteButton(letter: letter),
        ],
      ],
    );
  }
}

class _SealedMetaCard extends StatelessWidget {
  final Letter letter;
  const _SealedMetaCard({required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Letter details', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          _MetaRow(
            icon: Icons.title_rounded,
            label: 'Title',
            value: letter.title.isEmpty ? '(Untitled)' : letter.title,
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.event_note_rounded,
            label: 'Sealed on',
            value: DateFormat.yMMMd().format(letter.createdAt),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: letter.isPublic
                ? Icons.public_rounded
                : Icons.lock_outline_rounded,
            label: 'Will deliver to',
            value: letter.isPublic ? 'The public wall' : 'You only',
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final Letter letter;
  const _DeleteButton({required this.letter});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('delete-button'),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this letter?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;
        final fs = context.read<FirestoreService>();
        final messenger = ScaffoldMessenger.of(context);
        context.go('/vault');
        try {
          await fs.deleteLetter(letter.id);
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete this letter'),
    );
  }
}

class _ArrivalHeroImage extends StatelessWidget {
  const _ArrivalHeroImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.letterArrivalHero,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _SealedHeroImage extends StatelessWidget {
  const _SealedHeroImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.sakuraSealedLetter,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _PostmarkStamp extends StatelessWidget {
  final DateTime date;
  const _PostmarkStamp({required this.date});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.primary;
    return SizedBox(
      width: 60,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.66),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.82), width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.48)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 3,
                  left: 4,
                  right: 4,
                  child: _PostmarkText(DateFormat.MMMd().format(date)),
                ),
                Transform.rotate(
                  angle: -0.18,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PostmarkRule(),
                      SizedBox(height: 6),
                      _PostmarkRule(),
                    ],
                  ),
                ),
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 3,
                  child: _PostmarkText(DateFormat.y().format(date)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostmarkText extends StatelessWidget {
  final String text;
  const _PostmarkText(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        style: TextStyle(
          color: scheme.primary.withValues(alpha: 0.92),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PostmarkRule extends StatelessWidget {
  const _PostmarkRule();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 36,
      height: 1.4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

String _formatTraveled(Duration dur) {
  if (dur.inDays >= 365) {
    final years = (dur.inDays / 365).floor();
    final months = ((dur.inDays % 365) / 30).floor();
    return months > 0 ? 'traveled ${years}y ${months}m' : 'traveled ${years}y';
  }
  if (dur.inDays >= 30) {
    final months = (dur.inDays / 30).floor();
    return 'traveled ${months}mo';
  }
  if (dur.inDays >= 1) return 'traveled ${dur.inDays}d';
  if (dur.inHours >= 1) return 'traveled ${dur.inHours}h';
  return 'just sealed';
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_assets.dart';
import '../models/letter.dart';
import '../services/firestore_service.dart';
import '../widgets/countdown_badge.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Public Wall'), centerTitle: false),
      body: StreamBuilder<List<Letter>>(
        stream: fs.watchPublicUnlocked(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(message: snapshot.error.toString());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const _EmptyWall();
          }
          return _WallView(letters: items);
        },
      ),
    );
  }
}

class _WallView extends StatelessWidget {
  final List<Letter> letters;
  const _WallView({required this.letters});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 7));

    // Letters are already sorted by unlockAt descending in the stream.
    final featured = letters.first;
    final featuredId = featured.id;

    final todayLetters = letters
        .where((l) => l.id != featuredId && !l.unlockAt.isBefore(today))
        .toList();
    final weekLetters = letters
        .where(
          (l) =>
              l.id != featuredId &&
              l.unlockAt.isBefore(today) &&
              !l.unlockAt.isBefore(weekStart),
        )
        .toList();
    final archive = letters
        .where((l) => l.id != featuredId && l.unlockAt.isBefore(weekStart))
        .toList();

    final allTodayCount = letters
        .where((l) => !l.unlockAt.isBefore(today))
        .length;
    final allWeekCount = letters
        .where((l) => !l.unlockAt.isBefore(weekStart))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _WallHero(
          totalCount: letters.length,
          todayCount: allTodayCount,
          weekCount: allWeekCount,
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          icon: Icons.local_florist_rounded,
          title: 'Latest arrival',
          subtitle: _featuredSubtitle(featured),
        ),
        const SizedBox(height: 12),
        _FeaturedLetterCard(
          letter: featured,
          onTap: () => context.go('/letter/${featured.id}'),
        ),
        if (todayLetters.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.wb_sunny_outlined,
            title: 'Also opened today',
            subtitle:
                '${todayLetters.length} more ${todayLetters.length == 1 ? 'letter' : 'letters'} arriving on the same day',
          ),
          const SizedBox(height: 12),
          for (final letter in todayLetters) ...[
            _WallLetterCard(
              key: ValueKey('wall-${letter.id}'),
              letter: letter,
              onTap: () => context.go('/letter/${letter.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (weekLetters.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.calendar_today_rounded,
            title: 'Earlier this week',
            subtitle: 'Letters that opened in the last few days',
          ),
          const SizedBox(height: 12),
          for (final letter in weekLetters) ...[
            _WallLetterCard(
              key: ValueKey('wall-${letter.id}'),
              letter: letter,
              onTap: () => context.go('/letter/${letter.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (archive.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.history_edu_rounded,
            title: 'From the archive',
            subtitle: 'Older letters, still here on the wall',
          ),
          const SizedBox(height: 12),
          for (final letter in archive) ...[
            _WallLetterCard(
              key: ValueKey('wall-${letter.id}'),
              letter: letter,
              onTap: () => context.go('/letter/${letter.id}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  String _featuredSubtitle(Letter letter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final openedDay = DateTime(
      letter.unlockAt.year,
      letter.unlockAt.month,
      letter.unlockAt.day,
    );
    final daysAgo = today.difference(openedDay).inDays;
    if (daysAgo <= 0) return 'Just arrived today';
    if (daysAgo == 1) return 'Arrived yesterday';
    if (daysAgo < 7) return 'Arrived $daysAgo days ago';
    return 'Most recent letter on the wall';
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────────

class _WallHero extends StatelessWidget {
  final int totalCount;
  final int todayCount;
  final int weekCount;
  const _WallHero({
    required this.totalCount,
    required this.todayCount,
    required this.weekCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _WallHeroImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.0),
                    scheme.surface.withValues(alpha: 0.78),
                  ],
                  stops: const [0.42, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Letters from across time',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Time-capsules from past selves, opening one by one for the world to read.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          label: 'Today',
                          count: todayCount,
                          icon: Icons.local_florist_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroStat(
                          label: 'This week',
                          count: weekCount,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroStat(
                          label: 'In total',
                          count: totalCount,
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),
                    ],
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

class _HeroStat extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  const _HeroStat({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Featured (latest arrival) card ────────────────────────────────────────

class _FeaturedLetterCard extends StatelessWidget {
  final Letter letter;
  final VoidCallback onTap;
  const _FeaturedLetterCard({required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final journey = _formatJourney(letter.createdAt, letter.unlockAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer.withValues(alpha: 0.42),
                scheme.tertiaryContainer.withValues(alpha: 0.30),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LATEST ARRIVAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  CountdownBadge(unlockAt: letter.unlockAt, compact: true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    backgroundImage: letter.authorPhotoUrl != null
                        ? NetworkImage(letter.authorPhotoUrl!)
                        : null,
                    child: letter.authorPhotoUrl == null
                        ? const Icon(Icons.person_outline_rounded, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          letter.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          journey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                letter.title.isEmpty ? '(Untitled)' : letter.title,
                style: theme.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Letter body preview with a leading paper-fold accent
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 56,
                    margin: const EdgeInsets.only(right: 10, top: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      letter.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.86),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Read this letter',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (letter.reactions.isNotEmpty)
                    _ReactionSummary(letter: letter),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact wall letter card ──────────────────────────────────────────────

class _WallLetterCard extends StatelessWidget {
  final Letter letter;
  final VoidCallback onTap;
  const _WallLetterCard({super.key, required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final journey = _formatJourney(letter.createdAt, letter.unlockAt);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: scheme.secondary),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              ? const Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            letter.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd().format(letter.unlockAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      letter.title.isEmpty ? '(Untitled)' : letter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      letter.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            journey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (letter.reactions.isNotEmpty)
                          _ReactionSummary(letter: letter),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reaction summary chip ─────────────────────────────────────────────────

class _ReactionSummary extends StatelessWidget {
  final Letter letter;
  const _ReactionSummary({required this.letter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = letter.reactions.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 12, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            '$total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty wall ────────────────────────────────────────────────────────────

class _EmptyWall extends StatelessWidget {
  const _EmptyWall();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _WallHeroImage(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.0),
                        scheme.surface.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Text(
                    'A quiet wall, waiting',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                'No letters have arrived yet',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "When someone's sealed letter reaches its opening day, it appears here for everyone to read.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/write'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Be the first to write'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Error view ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WallHeroImage extends StatelessWidget {
  const _WallHeroImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.wallHero,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.medium,
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

String _formatJourney(DateTime sealed, DateTime opened) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final openedDay = DateTime(opened.year, opened.month, opened.day);
  final dur = opened.difference(sealed);

  String openedLabel;
  final daysFromToday = today.difference(openedDay).inDays;
  if (daysFromToday <= 0) {
    openedLabel = 'opened today';
  } else if (daysFromToday == 1) {
    openedLabel = 'opened yesterday';
  } else if (daysFromToday < 7) {
    openedLabel = 'opened ${daysFromToday}d ago';
  } else {
    openedLabel = 'opened ${DateFormat.yMMMd().format(opened)}';
  }

  String journeyLabel;
  if (dur.inDays >= 365) {
    final years = (dur.inDays / 365).floor();
    final months = ((dur.inDays % 365) / 30).floor();
    journeyLabel = months > 0
        ? 'traveled ${years}y ${months}m'
        : 'traveled ${years}y';
  } else if (dur.inDays >= 30) {
    final months = (dur.inDays / 30).floor();
    journeyLabel = 'traveled ${months}mo';
  } else if (dur.inDays >= 1) {
    journeyLabel = 'traveled ${dur.inDays}d';
  } else if (dur.inHours >= 1) {
    journeyLabel = 'traveled ${dur.inHours}h';
  } else {
    journeyLabel = 'just sealed';
  }

  return '$journeyLabel • $openedLabel';
}

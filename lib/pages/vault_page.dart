import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_assets.dart';
import '../models/letter.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/countdown_badge.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  @override
  void initState() {
    super.initState();
    // Update last viewed timestamp so future "new since" highlighting works
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalStorageService>().setLastVaultViewedAt(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fs = context.read<FirestoreService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Vault'), centerTitle: false),
      body: user == null
          ? const Center(child: Text('Not signed in.'))
          : StreamBuilder<List<Letter>>(
              stream: fs.watchMyLetters(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return _empty(context);
                }
                final locked = items.where((l) => !l.isUnlocked).toList();
                final unlocked = items.where((l) => l.isUnlocked).toList();
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 24 : 16,
                        10,
                        wide ? 24 : 16,
                        96,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: wide ? 760 : 520,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _VaultHero(
                                  lockedCount: locked.length,
                                  unlockedCount: unlocked.length,
                                  nextUnlockAt: locked.isEmpty
                                      ? null
                                      : locked.first.unlockAt,
                                ),
                                const SizedBox(height: 14),
                                if (locked.isNotEmpty)
                                  _VaultShelf(
                                    title: 'Sleeping letters',
                                    subtitle:
                                        'These notes are folded away until their season arrives.',
                                    count: locked.length,
                                    locked: true,
                                    letters: locked,
                                  ),
                                if (locked.isNotEmpty && unlocked.isNotEmpty)
                                  const SizedBox(height: 14),
                                if (unlocked.isNotEmpty)
                                  _VaultShelf(
                                    title: 'Ready to open',
                                    subtitle:
                                        'Letters whose dates have arrived are waiting for you.',
                                    count: unlocked.length,
                                    locked: false,
                                    letters: unlocked,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return ListView(
          padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 12, wide ? 24 : 16, 96),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 760 : 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _EmptyVaultHero(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            AppAssets.navVault,
                            width: 58,
                            height: 58,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The vault is waiting',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Write a letter, choose its opening day, and this shelf will keep it quiet until then.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.go('/write'),
                            icon: Image.asset(
                              AppAssets.navWrite,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            label: const Text('Write the first letter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VaultHero extends StatelessWidget {
  final int lockedCount;
  final int unlockedCount;
  final DateTime? nextUnlockAt;

  const _VaultHero({
    required this.lockedCount,
    required this.unlockedCount,
    required this.nextUnlockAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 188,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.vaultShelf,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.08),
                    scheme.surface.withValues(alpha: 0.78),
                  ],
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
                  Image.asset(
                    AppAssets.navVault,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Your private shelf of time',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nextUnlockAt == null
                        ? 'Every sealed letter here has already found its day.'
                        : 'Next opening ${DateFormat.yMMMd().format(nextUnlockAt!)}.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _VaultStat(
                          label: 'Sleeping',
                          count: lockedCount,
                          asset: AppAssets.navVault,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _VaultStat(
                          label: 'Open',
                          count: unlockedCount,
                          asset: AppAssets.sakuraSealedLetter,
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

class _EmptyVaultHero extends StatelessWidget {
  const _EmptyVaultHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.vaultShelf,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultStat extends StatelessWidget {
  final String label;
  final int count;
  final String asset;

  const _VaultStat({
    required this.label,
    required this.count,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Image.asset(asset, width: 26, height: 26, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultShelf extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final bool locked;
  final List<Letter> letters;

  const _VaultShelf({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.locked,
    required this.letters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: locked
            ? scheme.primaryContainer.withValues(alpha: 0.28)
            : scheme.secondaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                locked ? AppAssets.navVault : AppAssets.sakuraSealedLetter,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
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
              const SizedBox(width: 8),
              _CountSeal(count: count, locked: locked),
            ],
          ),
          const SizedBox(height: 10),
          for (final letter in letters) ...[
            _VaultLetterCard(
              key: ValueKey('vault-letter-${letter.id}'),
              letter: letter,
              locked: locked,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CountSeal extends StatelessWidget {
  final int count;
  final bool locked;

  const _CountSeal({required this.count, required this.locked});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: locked ? scheme.primary : scheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            color: locked ? scheme.onPrimary : scheme.onSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _VaultLetterCard extends StatelessWidget {
  final Letter letter;
  final bool locked;

  const _VaultLetterCard({
    super.key,
    required this.letter,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = locked ? 'Sealed in the vault' : 'Ready to read';
    final detail = locked
        ? 'Opens ${DateFormat.yMMMd().add_jm().format(letter.unlockAt)}'
        : 'Opened ${DateFormat.yMMMd().format(letter.unlockAt)}';
    final preview = locked
        ? 'The words are sleeping until the seal breaks.'
        : letter.content;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/letter/${letter.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 66,
                decoration: BoxDecoration(
                  color: locked
                      ? scheme.primaryContainer.withValues(alpha: 0.46)
                      : scheme.secondaryContainer.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    locked ? AppAssets.navVault : AppAssets.sakuraSealedLetter,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: locked ? scheme.primary : scheme.secondary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _VisibilityPill(isPublic: letter.isPublic),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      letter.title.isEmpty ? '(Untitled)' : letter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                        fontStyle: locked ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CountdownBadge(
                          unlockAt: letter.unlockAt,
                          compact: true,
                        ),
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

class _VisibilityPill extends StatelessWidget {
  final bool isPublic;

  const _VisibilityPill({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        isPublic ? 'Wall' : 'Private',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

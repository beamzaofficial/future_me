import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_assets.dart';
import '../models/app_user.dart';
import '../models/letter.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/countdown_badge.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = context
        .read<LocalStorageService>()
        .getNotificationsEnabled();
  }

  Future<void> _toggleNotifications(bool v) async {
    setState(() => _notifications = v);
    await context.read<LocalStorageService>().setNotificationsEnabled(v);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final compact = constraints.maxHeight < 640;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 760 : 520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 24 : 16,
                  compact ? 6 : 8,
                  wide ? 24 : 16,
                  compact ? 8 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsHero(height: compact ? 92 : 116, compact: compact),
                    SizedBox(height: compact ? 6 : 8),
                    if (user != null) ...[
                      _LetterheadCard(user: user, compact: compact),
                      SizedBox(height: compact ? 6 : 8),
                      _VaultStoryStrip(userId: user.uid, compact: compact),
                    ],
                    SizedBox(height: compact ? 10 : 12),
                    const _ChapterLabel(
                      overline: 'Chapter I',
                      title: 'Atmosphere',
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    _AtmosphereSection(compact: compact),
                    SizedBox(height: compact ? 10 : 12),
                    const _ChapterLabel(
                      overline: 'Chapter II',
                      title: 'Desk rituals',
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Row(
                      children: [
                        Expanded(
                          child: _BellSection(
                            value: _notifications,
                            compact: compact,
                            onChanged: _toggleNotifications,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ClosingSection(auth: auth, compact: compact),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(height: compact ? 6 : 8),
                    _Footer(compact: compact),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  final double height;
  final bool compact;

  const _SettingsHero({required this.height, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.settingsRitual,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.06),
                    scheme.surface.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    AppAssets.navSettings,
                    width: compact ? 28 : 34,
                    height: compact ? 28 : 34,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  Text(
                    'Tune the writing room',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      fontSize: compact ? 20 : null,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Set the paper, the bell, and the way the desk closes.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterheadCard extends StatelessWidget {
  final AppUser user;
  final bool compact;
  const _LetterheadCard({required this.user, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: compact ? 50 : 56,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                compact ? 7 : 8,
                10,
                compact ? 7 : 8,
              ),
              child: Row(
                children: [
                  _UserAvatar(
                    photoUrl: user.photoUrl,
                    radius: compact ? 18 : 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    AppAssets.navSettings,
                    width: compact ? 24 : 28,
                    height: compact ? 24 : 28,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatefulWidget {
  final String? photoUrl;
  final double radius;
  const _UserAvatar({required this.photoUrl, required this.radius});

  @override
  State<_UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<_UserAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant _UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _failed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showImage = widget.photoUrl != null && !_failed;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: showImage ? NetworkImage(widget.photoUrl!) : null,
      onBackgroundImageError: showImage
          ? (_, __) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: showImage
          ? null
          : Icon(Icons.person_outline_rounded, size: widget.radius * 0.9),
    );
  }
}

class _VaultStoryStrip extends StatelessWidget {
  final String userId;
  final bool compact;
  const _VaultStoryStrip({required this.userId, required this.compact});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<List<Letter>>(
      stream: fs.watchMyLetters(userId),
      builder: (context, snap) {
        final items = snap.data ?? const <Letter>[];
        final now = DateTime.now();
        final locked = items.where((l) => !l.isUnlockedAt(now)).toList()
          ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
        final unlockedCount = items.length - locked.length;
        final nextLabel = locked.isEmpty
            ? '—'
            : formatRemaining(locked.first.unlockAt.difference(now));

        return _VaultPulseCard(
          sealedCount: locked.length,
          unsealedCount: unlockedCount,
          nextLabel: nextLabel,
          compact: compact,
        );
      },
    );
  }
}

class _VaultPulseCard extends StatelessWidget {
  final int sealedCount;
  final int unsealedCount;
  final String nextLabel;
  final bool compact;

  const _VaultPulseCard({
    required this.sealedCount,
    required this.unsealedCount,
    required this.nextLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: compact ? 58 : 66,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                AppAssets.navVault,
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vault pulse',
                      style: theme.textTheme.titleSmall?.copyWith(height: 1.05),
                    ),
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      nextLabel == '—'
                          ? 'No sealed letters are waiting right now.'
                          : 'The next seal softens in $nextLabel.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _VaultPulseMini(value: '$sealedCount', label: 'Sealed'),
              const SizedBox(width: 6),
              _VaultPulseMini(value: '$unsealedCount', label: 'Open'),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultPulseMini extends StatelessWidget {
  final String value;
  final String label;

  const _VaultPulseMini({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterLabel extends StatelessWidget {
  final String overline;
  final String title;
  const _ChapterLabel({required this.overline, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            overline.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: scheme.outlineVariant)),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphereSection extends StatelessWidget {
  final bool compact;
  const _AtmosphereSection({required this.compact});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final mode = themeProv.mode;

    final cards = <Widget>[
      _AtmosphereCard(
        cardKey: const Key('theme-system'),
        label: 'Follow sky',
        icon: Icons.brightness_auto_outlined,
        papers: const [Color(0xFFFFF8F1), Color(0xFF1D1716)],
        inks: const [Color(0xFF934355), Color(0xFFF1A9B7)],
        compact: compact,
        selected: mode == ThemeMode.system,
        onTap: () => themeProv.setMode(ThemeMode.system),
      ),
      _AtmosphereCard(
        cardKey: const Key('theme-light'),
        label: 'Day paper',
        icon: Icons.wb_sunny_outlined,
        papers: const [Color(0xFFFFF8F1)],
        inks: const [Color(0xFF934355)],
        compact: compact,
        selected: mode == ThemeMode.light,
        onTap: () => themeProv.setMode(ThemeMode.light),
      ),
      _AtmosphereCard(
        cardKey: const Key('theme-dark'),
        label: 'Night paper',
        icon: Icons.nightlight_outlined,
        papers: const [Color(0xFF1D1716)],
        inks: const [Color(0xFFF1A9B7)],
        compact: compact,
        selected: mode == ThemeMode.dark,
        onTap: () => themeProv.setMode(ThemeMode.dark),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _AtmosphereCard extends StatelessWidget {
  final Key cardKey;
  final String label;
  final IconData icon;
  final List<Color> papers;
  final List<Color> inks;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  const _AtmosphereCard({
    required this.cardKey,
    required this.label,
    required this.icon,
    required this.papers,
    required this.inks,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      key: cardKey,
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: compact ? 64 : 70,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: compact ? 24 : 30,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _PaperPreview(papers: papers, inks: inks),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(icon, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: scheme.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperPreview extends StatelessWidget {
  final List<Color> papers;
  final List<Color> inks;
  const _PaperPreview({required this.papers, required this.inks});

  @override
  Widget build(BuildContext context) {
    if (papers.length >= 2) {
      return Row(
        children: [
          Expanded(
            child: _OnePaper(paper: papers[0], ink: inks[0]),
          ),
          Expanded(
            child: _OnePaper(paper: papers[1], ink: inks[1]),
          ),
        ],
      );
    }
    return _OnePaper(paper: papers.first, ink: inks.first);
  }
}

class _OnePaper extends StatelessWidget {
  final Color paper;
  final Color ink;
  const _OnePaper({required this.paper, required this.ink});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: paper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 2, color: ink.withValues(alpha: 0.85)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Container(
                    height: 2,
                    color: ink.withValues(alpha: 0.55),
                  ),
                ),
                const Expanded(flex: 9, child: SizedBox.shrink()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BellSection extends StatelessWidget {
  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;
  const _BellSection({
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: compact ? 56 : 62,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              compact ? 7 : 9,
              4,
              compact ? 7 : 9,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 34 : 38,
                  height: compact ? 34 : 38,
                  decoration: BoxDecoration(
                    color: value
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        AppAssets.settingsRitual,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        color: value ? null : scheme.onSurfaceVariant,
                        colorBlendMode: value ? null : BlendMode.modulate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bell',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: 1.05,
                        ),
                      ),
                      Text(
                        value ? 'Wake letters' : 'Quiet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('notifications-switch'),
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClosingSection extends StatelessWidget {
  final AuthProvider auth;
  final bool compact;
  const _ClosingSection({required this.auth, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      height: compact ? 56 : 62,
      child: Card(
        child: InkWell(
          key: const Key('signout-tile'),
          borderRadius: BorderRadius.circular(8),
          onTap: auth.isBusy ? null : () => auth.signOut(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              compact ? 7 : 9,
              8,
              compact ? 7 : 9,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 34 : 38,
                  height: compact ? 34 : 38,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(AppAssets.navVault, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Close',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: 1.05,
                        ),
                      ),
                      Text(
                        'Sign out',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                auth.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool compact;
  const _Footer({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        if (!compact) ...[
          Container(width: 36, height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 8),
        ],
        Text(
          'FUTURE ME',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? 1.2 : 2.0,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 3),
          Text(
            'Time capsule letters · v1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

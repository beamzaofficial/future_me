import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_assets.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final String location;
  const MainScaffold({super.key, required this.child, required this.location});

  static const _items = <_NavItem>[
    _NavItem(label: 'Wall', iconAsset: AppAssets.navWall, route: '/home'),
    _NavItem(label: 'Vault', iconAsset: AppAssets.navVault, route: '/vault'),
    _NavItem(label: 'Write', iconAsset: AppAssets.navWrite, route: '/write'),
    _NavItem(
      label: 'Settings',
      iconAsset: AppAssets.navSettings,
      route: '/settings',
    ),
  ];

  int get _currentIndex {
    final i = _items.indexWhere((it) => location.startsWith(it.route));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _FutureMeNavBar(
        items: _items,
        selectedIndex: _currentIndex,
        onSelected: (i) => context.go(_items[i].route),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String iconAsset;
  final String route;
  const _NavItem({
    required this.label,
    required this.iconAsset,
    required this.route,
  });
}

class _FutureMeNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FutureMeNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.48 : 0.9),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.09),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedFill = isDark
        ? scheme.primaryContainer.withValues(alpha: 0.48)
        : scheme.primaryContainer.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? selectedFill : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1.08 : 0.92,
                    child: Opacity(
                      opacity: selected ? 1 : 0.66,
                      child: Image.asset(
                        item.iconAsset,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          height: 1,
                        ) ??
                        TextStyle(
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          height: 1,
                        ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/components/brand_icons.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../achievements/achievements_screen.dart';
import '../learning_path/learning_path_screen.dart';
import '../word_garden/word_garden_screen.dart';
import 'home_screen.dart';

/// Root after onboarding: four tabs with a custom bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenTab: _go),
          const LearningPathScreen(),
          const WordGardenScreen(),
          const AchievementsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(index: _tab, onTap: _go),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_rounded, null, 'Home'),
    (Icons.route_rounded, null, 'Path'),
    (null, BrandIconKind.leaf, 'Garden'),
    (Icons.emoji_events_rounded, null, 'Badges'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final (i, (icon, brand, label)) in _items.indexed)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: '$label tab',
                    excludeSemantics: true,
                    child: InkWell(
                      key: ValueKey('nav_$label'),
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: Motion.of(context, Motion.medium),
                            curve: Motion.emphasized,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: i == index
                                  ? AppColors.coralTint
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: brand != null
                                ? BrandIcon(brand, size: 24, muted: i != index)
                                : Icon(
                                    icon,
                                    size: 26,
                                    color: i == index
                                        ? AppColors.coralInk
                                        : AppColors.textMuted,
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: AppType.caption.copyWith(
                              color: i == index
                                  ? AppColors.coralInk
                                  : AppColors.textMuted,
                              fontWeight: i == index
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

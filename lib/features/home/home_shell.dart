import 'package:flutter/material.dart';

import '../../core/components/brand_icons.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/navigation/app_routes.dart';
import '../discover/discover_screen.dart';
import '../learning_path/learning_path_screen.dart';
import '../my_words/my_words_screen.dart';
import '../speak/speak_screen.dart';
import 'home_screen.dart';

/// Root after onboarding: five product areas (see [HomeTab]).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  void _go(int i) => setState(() => _tab = i);
  void _goTab(HomeTab t) => _go(t.index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenTab: _goTab),
          const LearningPathScreen(),
          const DiscoverScreen(),
          // Speak is built lazily so no session starts until it is opened.
          _tab == HomeTab.speak.index
              ? const SpeakScreen()
              : const SizedBox.shrink(),
          const MyWordsScreen(),
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

  static final _items = [
    for (final t in HomeTab.values)
      switch (t) {
        HomeTab.home => (Icons.home_rounded, null, t.label),
        HomeTab.learn => (Icons.route_rounded, null, t.label),
        HomeTab.discover => (Icons.smart_display_rounded, null, t.label),
        HomeTab.speak => (Icons.record_voice_over_rounded, null, t.label),
        HomeTab.myWords => (null, BrandIconKind.leaf, t.label),
      },
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
                              horizontal: 12,
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: AppType.caption.copyWith(
                                color: i == index
                                    ? AppColors.coralInk
                                    : AppColors.textMuted,
                                fontWeight: i == index
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
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

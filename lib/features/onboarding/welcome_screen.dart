import 'package:flutter/material.dart';

import '../../core/components/app_button.dart';
import '../../core/components/entrance.dart';
import '../../core/components/speech_bubble.dart';
import '../../core/components/tibeb_band.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../mascot/mascot.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: Column(
                    children: [
                      const Spacer(),
                      const _Hero(),
                      const Spacer(),
                      Entrance(
                        delay: const Duration(milliseconds: 250),
                        child: Text(
                          'Learn English through the language you already speak.',
                          textAlign: TextAlign.center,
                          style: AppType.display.copyWith(fontSize: 30),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Entrance(
                        delay: const Duration(milliseconds: 350),
                        child: Text(
                          'Bite-sized, playful lessons explained in Amharic or Afaan Oromo — and they work offline.',
                          textAlign: TextAlign.center,
                          style: AppType.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.xl),
                      Entrance(
                        delay: const Duration(milliseconds: 450),
                        child: AppButton(
                          label: 'Get started',
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.language),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Entrance(
                        delay: const Duration(milliseconds: 520),
                        child: AppButton(
                          label: 'I already have an account',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Accounts arrive in a later version. Your progress is saved on this device.',
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Layered sun / hill backdrop.
          Positioned(
            top: 30,
            child: Container(
              width: 270,
              height: 270,
              decoration: const BoxDecoration(
                color: AppColors.goldTint,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 62,
            child: Container(
              width: 206,
              height: 206,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            left: 30,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const TibebBand(height: 12),
            ),
          ),
          const Positioned(
            bottom: 30,
            child: Mascot(
              mood: MascotMood.welcome,
              size: 260,
              semanticLabel: 'Gela the mascot waving hello',
            ),
          ),
          const Positioned(
            top: 34,
            left: 0,
            child: Entrance(
              delay: Duration(milliseconds: 100),
              child: SpeechBubble(
                text: 'ሰላም!',
                color: AppColors.coral,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const Positioned(
            top: 6,
            right: 8,
            child: Entrance(
              delay: Duration(milliseconds: 220),
              child: SpeechBubble(
                text: 'Akkam!',
                color: AppColors.teal,
                tail: BubbleTail.bottomRight,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const Positioned(
            top: 150,
            right: 0,
            child: Entrance(
              delay: Duration(milliseconds: 340),
              child: SpeechBubble(
                text: 'Hello!',
                color: AppColors.periwinkle,
                tail: BubbleTail.bottomRight,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:ethio_linguo/core/navigation/app_routes.dart';
import 'package:ethio_linguo/features/lessons/lesson_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('dashboard renders every required section', (t) async {
    await pumpApp(t, progress: midJourney());
    // Personalised greeting from the fixed 09:30 clock.
    expect(find.text('ሰላም! Good morning'), findsOneWidget);
    // Stats.
    expect(find.bySemanticsLabel('3 day streak'), findsOneWidget);
    expect(find.bySemanticsLabel('58 XP'), findsOneWidget);
    expect(find.bySemanticsLabel('4 of 5 hearts'), findsOneWidget);
    expect(find.textContaining('LVL 2'), findsOneWidget);
    // Continue card shows the current lesson.
    expect(find.text('Coffee time'), findsWidgets);
    expect(find.text('CONTINUE'), findsOneWidget);
    // Featured scene + entry points to every product area.
    expect(find.byKey(const ValueKey('home_featured_media')), findsOneWidget);
    expect(find.text('Long time no see'), findsOneWidget);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('home_badges')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    for (final k in [
      'home_discover',
      'home_speak',
      'home_my_words',
      'home_badges',
    ]) {
      expect(find.byKey(ValueKey(k)), findsOneWidget);
    }
    // Word Garden entry.
    await t.scrollUntilVisible(
      find.text('Word Garden'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Word Garden'), findsOneWidget);
    expect(find.textContaining('5 words growing'), findsOneWidget);
    // Daily quests + path preview (scroll down).
    await t.scrollUntilVisible(
      find.text('Your path'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Daily quests'), findsOneWidget);
    expect(find.text('Earn 30 XP'), findsOneWidget);
    expect(find.text('Your path'), findsOneWidget);
    // Bottom navigation.
    for (final tab in ['Home', 'Learn', 'Discover', 'Speak', 'My Words']) {
      expect(find.byKey(ValueKey('nav_$tab')), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('new learner dashboard: zero states + start lesson', (t) async {
    await pumpApp(t, progress: onboarded());
    expect(find.text('START LESSON'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Nothing saved yet'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await t.scrollUntilVisible(
      find.textContaining('plant your first words'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('continue_learning')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (t) async {
    await pumpApp(t, progress: midJourney());
    await t.tap(find.byKey(const ValueKey('nav_Learn')));
    await t.pumpAndSettle();
    expect(find.text('Learning path'), findsOneWidget);
    await tapTab(t, 'Discover');
    expect(find.text('Long time no see'), findsWidgets);
    await tapTab(t, 'Speak');
    expect(find.text('Talk with the Professor'), findsOneWidget);
    await tapTab(t, 'My Words');
    expect(find.text('No saved expressions yet'), findsOneWidget);
    await tapTab(t, 'Home');
    expect(find.text('Coffee time'), findsWidgets);
    await openRoute(t, AppRoutes.garden);
    expect(find.text('WATER YOUR GARDEN'), findsOneWidget);
    await openRoute(t, AppRoutes.achievements);
    expect(find.text('Badges & progress'), findsOneWidget);
  });

  testWidgets('learning path shows completed, current and locked nodes', (
    t,
  ) async {
    await pumpApp(t, progress: midJourney());
    await t.tap(find.byKey(const ValueKey('nav_Learn')));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('Say hello, completed'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Coffee time, current lesson, tap to start'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Mix & review, locked'), findsOneWidget);
    expect(find.bySemanticsLabel('Unit 1 checkpoint, locked'), findsOneWidget);
    expect(find.text('Start here!'), findsOneWidget);
    expect(find.text('First words'), findsOneWidget);

    // Tapping a locked node explains why instead of doing nothing.
    await t.tap(find.bySemanticsLabel('Mix & review, locked'));
    await t.pump();
    expect(find.textContaining('Locked'), findsOneWidget);

    // Units further down render too.
    await t.scrollUntilVisible(
      find.text('My day'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Around town'), findsOneWidget);
  });

  testWidgets('node without content shows a friendly empty state', (t) async {
    await pumpApp(
      t,
      progress: midJourney().copyWith(
        completedNodeIds: {
          'n_greetings',
          'n_coffee',
          'n_u1_practice',
          'n_u1_check',
        },
      ),
    );
    await t.tap(find.byKey(const ValueKey('continue_learning')));
    await t.pumpAndSettle();
    expect(find.textContaining('still being written'), findsOneWidget);
  });

  testWidgets('word garden empty state', (t) async {
    await pumpApp(t, progress: onboarded());
    await openRoute(t, AppRoutes.garden);
    expect(find.text('Your garden is waiting'), findsOneWidget);
  });
}

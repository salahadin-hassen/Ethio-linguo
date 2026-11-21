import 'package:flutter/foundation.dart';

import '../../app/app_controller.dart';
import '../../app/app_services.dart';
import '../../data/models/activity.dart';
import '../../data/models/vocabulary.dart';
import '../../services/analytics/analytics.dart';

/// Flashcard review of due My Words entries. Fixed-interval scheduling lives
/// in [VocabularyEntry.reviewed]; XP goes through the progress service.
class RevisionController extends ChangeNotifier {
  RevisionController({
    required AppServices services,
    required AppController progress,
    int maxCards = 10,
  }) : _services = services,
       _progress = progress {
    final now = progress.now;
    final due = services.vocabulary.due(now);
    // Fall back to the whole list so learners can always practise.
    queue = (due.isEmpty ? services.vocabulary.all : due)
        .take(maxCards)
        .toList();
  }

  final AppServices _services;
  final AppController _progress;
  late final List<VocabularyEntry> queue;

  int index = 0;
  bool revealed = false;
  int remembered = 0;
  ActivityReward? reward;

  bool get isEmpty => queue.isEmpty;
  bool get finished => index >= queue.length;
  VocabularyEntry? get card => finished ? null : queue[index];

  void reveal() {
    revealed = true;
    notifyListeners();
  }

  Future<void> grade({required bool knewIt}) async {
    final c = card;
    if (c == null || !revealed) return;
    await _services.vocabulary.save(
      c.reviewed(remembered: knewIt, now: _progress.now),
    );
    if (knewIt) remembered++;
    index++;
    revealed = false;
    if (finished) await _complete();
    notifyListeners();
  }

  Future<void> _complete() async {
    reward = await _progress.completeActivity(
      LearningActivity(
        id: 'revision:${_progress.today}',
        type: ActivityType.revision,
        native: _progress.native,
      ),
      units: queue.length,
    );
    _services.analytics.log(AnalyticsEvent.revisionCompleted, {
      'cards': queue.length,
      'remembered': remembered,
    });
  }
}

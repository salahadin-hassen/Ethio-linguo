/// What to play when opening the lesson screen.
sealed class LessonLaunch {
  const LessonLaunch();
}

/// A node on the learning path (authored lesson, practice or checkpoint).
class NodeLaunch extends LessonLaunch {
  const NodeLaunch(this.nodeId);
  final String nodeId;
}

/// A Word Garden watering session over specific words.
class GardenReviewLaunch extends LessonLaunch {
  const GardenReviewLaunch(this.termIds);
  final List<String> termIds;

  static const nodeId = 'garden_review';
}

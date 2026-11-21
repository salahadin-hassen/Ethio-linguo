import 'package:flutter/foundation.dart';

import '../models/conversation.dart';

/// Conversation summaries for post-conversation review.
/// MVP: in memory only — transcripts and audio are never persisted
/// (privacy default, docs/AI_PROVIDER_INTEGRATION.md §Privacy).
abstract class ConversationRepository extends ChangeNotifier {
  List<ConversationSession> get recent;
  Future<void> save(ConversationSession session);
}

class InMemoryConversationRepository extends ConversationRepository {
  final _items = <ConversationSession>[];

  @override
  List<ConversationSession> get recent => List.unmodifiable(_items.reversed);

  @override
  Future<void> save(ConversationSession session) async {
    _items.add(session);
    if (_items.length > 20) _items.removeAt(0);
    notifyListeners();
  }
}

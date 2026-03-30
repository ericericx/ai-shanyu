// lib/features/chat/providers/chat_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';

part 'chat_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// ChatRepository 單例。
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ChatRepository();

// ── 訊息串流 Provider ─────────────────────────────────────────────────────────

/// 監聽指定使用者的所有訊息（即時更新）。
@riverpod
Stream<List<ChatMessage>> chatMessages(Ref ref, String userId) {
  return ref.watch(chatRepositoryProvider).watchMessages(userId);
}

// ── 未讀計數 Provider ─────────────────────────────────────────────────────────

/// 監聽目前登入使用者的未讀訊息數。
/// 未登入時固定回傳 0。
@riverpod
Stream<int> unreadChatCount(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(chatRepositoryProvider).watchUnreadCount(user.uid);
}

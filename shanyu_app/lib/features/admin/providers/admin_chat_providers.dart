// lib/features/admin/providers/admin_chat_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../chat/models/chat_models.dart';
import '../data/admin_chat_repository.dart';
import '../models/chat_summary_model.dart';

part 'admin_chat_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
AdminChatRepository adminChatRepository(Ref ref) => AdminChatRepository();

// ── 所有對話摘要 Provider ─────────────────────────────────────────────────────

@riverpod
Stream<List<ChatSummary>> allChats(Ref ref) {
  return ref.watch(adminChatRepositoryProvider).watchAllChats();
}

// ── 指定使用者訊息列表 Provider ───────────────────────────────────────────────

@riverpod
Stream<List<ChatMessage>> adminChatMessages(Ref ref, String userId) {
  return ref.watch(adminChatRepositoryProvider).watchMessages(userId)
      as Stream<List<ChatMessage>>;
}

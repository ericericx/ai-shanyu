// lib/features/admin/models/chat_summary_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 對話摘要，供後台 Chat 列表使用。
class ChatSummary {
  const ChatSummary({
    required this.userId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.status,
  });

  final String userId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String status;

  factory ChatSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lastMessageAtRaw = data['lastMessageAt'];
    final DateTime lastMessageAt;
    if (lastMessageAtRaw is Timestamp) {
      lastMessageAt = lastMessageAtRaw.toDate();
    } else {
      lastMessageAt = DateTime.now();
    }

    return ChatSummary(
      userId: doc.id,
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: lastMessageAt,
      unreadCount: (data['unreadCount'] as int?) ?? 0,
      status: (data['status'] as String?) ?? 'open',
    );
  }
}

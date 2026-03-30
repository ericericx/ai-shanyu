// lib/features/chat/models/chat_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 單則聊天訊息的資料模型。
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final bool isRead;

  /// 判斷訊息是否由使用者（非客服）發送。
  bool get isFromUser => senderId != 'admin';

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAtRaw = data['createdAt'];
    final DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return ChatMessage(
      id: doc.id,
      content: (data['content'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderName: (data['senderName'] as String?) ?? '',
      createdAt: createdAt,
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }
}

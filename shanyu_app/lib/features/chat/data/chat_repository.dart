// lib/features/chat/data/chat_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';

/// 客服 Chat 的 Firestore 資料存取層。
///
/// Firestore 結構：
/// ```
/// chats/{userId}
///   status: 'open' | 'closed'
///   lastMessageAt: Timestamp
///   lastMessage: string
///   unreadCount: number
///
/// chats/{userId}/messages/{messageId}
///   content: string
///   senderId: string   // userId 或 'admin'
///   senderName: string
///   createdAt: Timestamp
///   isRead: boolean
/// ```
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── 聊天室文件參考 ─────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _chatDoc(String userId) =>
      _firestore.collection('chats').doc(userId);

  CollectionReference<Map<String, dynamic>> _messagesCol(String userId) =>
      _chatDoc(userId).collection('messages');

  // ── 公開 API ───────────────────────────────────────────────────────────────

  /// 即時監聽指定使用者的聊天訊息，依 `createdAt` 升序排列（舊 → 新）。
  Stream<List<ChatMessage>> watchMessages(String userId) {
    return _messagesCol(userId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(ChatMessage.fromFirestore).toList());
  }

  /// 監聽目前未讀訊息數（整數）。
  Stream<int> watchUnreadCount(String userId) {
    return _chatDoc(userId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data();
      return (data?['unreadCount'] as int?) ?? 0;
    });
  }

  /// 發送一則訊息，並同步更新 chat 文件的 `lastMessage`。
  Future<void> sendMessage(
    String userId,
    String content,
    String senderName,
  ) async {
    final batch = _firestore.batch();
    final messageRef = _messagesCol(userId).doc();

    // 新增訊息文件
    batch.set(messageRef, {
      'content': content,
      'senderId': userId,
      'senderName': senderName,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 更新 chat 文件摘要
    batch.set(
      _chatDoc(userId),
      {
        'status': 'open',
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        // 使用者發訊，不增加 unreadCount（unreadCount 由客服端管理）
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// 將目前使用者聊天室的未讀數歸零（進入頁面時呼叫）。
  Future<void> markAsRead(String userId) async {
    await _chatDoc(userId).set(
      {'unreadCount': 0},
      SetOptions(merge: true),
    );
  }
}

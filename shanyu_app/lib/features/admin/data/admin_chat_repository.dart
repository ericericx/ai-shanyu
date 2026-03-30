// lib/features/admin/data/admin_chat_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../chat/data/chat_repository.dart';
import '../models/chat_summary_model.dart';

/// 後台客服 Chat 的資料存取層。
///
/// 監聽所有 `chats/` 文件，供管理員管理所有使用者對話。
/// 回覆訊息複用 [ChatRepository.sendMessage]，但 senderId 固定為 'admin'。
class AdminChatRepository {
  AdminChatRepository({
    FirebaseFirestore? firestore,
    ChatRepository? chatRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatRepository = chatRepository ?? ChatRepository();

  final FirebaseFirestore _firestore;
  final ChatRepository _chatRepository;

  // ── 對話摘要監聽 ──────────────────────────────────────────────────────────

  /// 監聽所有使用者對話摘要，依 `lastMessageAt` 降序排列（最新在上）。
  Stream<List<ChatSummary>> watchAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(ChatSummary.fromFirestore).toList());
  }

  // ── 客服回覆 ──────────────────────────────────────────────────────────────

  /// 以管理員身份回覆訊息。
  ///
  /// senderId 固定為 'admin'，senderName 固定為 '山裕客服'。
  /// 同時更新 chat 文件的 `lastMessage` 並將未讀計數 +1（通知使用者）。
  Future<void> sendAdminMessage(String userId, String content) async {
    final batch = _firestore.batch();
    final messagesCol =
        _firestore.collection('chats').doc(userId).collection('messages');
    final messageRef = messagesCol.doc();

    // 新增訊息文件
    batch.set(messageRef, {
      'content': content,
      'senderId': 'admin',
      'senderName': '山裕客服',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 更新 chat 文件摘要，並將未讀數 +1 通知使用者
    batch.set(
      _firestore.collection('chats').doc(userId),
      {
        'status': 'open',
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// 取得指定使用者的即時訊息串流（複用前台 ChatRepository）。
  Stream<List<dynamic>> watchMessages(String userId) {
    return _chatRepository.watchMessages(userId);
  }
}

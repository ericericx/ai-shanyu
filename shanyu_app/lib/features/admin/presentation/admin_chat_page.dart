// lib/features/admin/presentation/admin_chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../chat/models/chat_models.dart';
import '../models/chat_summary_model.dart';
import '../providers/admin_chat_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _AdminChatTokens {
  static const surface = Color(0xFFFAF8F5);
  static const brandBrown = Color(0xFFB82020);
  static const brandBrownLight = Color(0xFF9C1B1B);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);
  static const listBg = Colors.white;

  // 氣泡 — 使用者（靠左灰色）
  static const userBubbleBg = Color(0xFFF0EAE4);
  static const userBubbleText = Color(0xFF2D2118);

  // 氣泡 — 客服（靠右深棕）
  static const adminBubbleBg = Color(0xFFB82020);
  static const adminBubbleText = Colors.white;

  static const inputBarBg = Colors.white;
  static const inputBorderColor = Color(0xFFD7CFC8);
  static const badgeBg = Color(0xFFE53935);
  static const badgeText = Colors.white;

  static const sidebarWidth = 280.0;
  static const mobileBreakpoint = 640.0;
  static const bubbleMaxWidthRatio = 0.68;
  static const bubbleRadius = 16.0;
}

// ── AdminChatPage ─────────────────────────────────────────────────────────────

/// 後台客服 Chat 管理頁面（路由 `/admin/chat`）。
///
/// 桌機：左側 Chat 列表 + 右側訊息區。
/// 手機：全螢幕切換 Chat 列表 ↔ 對話。
class AdminChatPage extends ConsumerStatefulWidget {
  const AdminChatPage({super.key});

  @override
  ConsumerState<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends ConsumerState<AdminChatPage> {
  String? _selectedUserId;
  bool _showChatOnMobile = false;

  void _selectChat(String userId) {
    setState(() {
      _selectedUserId = userId;
      _showChatOnMobile = true;
    });
  }

  void _backToList() {
    setState(() => _showChatOnMobile = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _AdminChatTokens.mobileBreakpoint;

    if (isDesktop) {
      return _DesktopLayout(
        selectedUserId: _selectedUserId,
        onSelectChat: _selectChat,
      );
    }

    // 手機模式：切換列表 / 對話
    if (_showChatOnMobile && _selectedUserId != null) {
      return _MobileConversationView(
        userId: _selectedUserId!,
        onBack: _backToList,
      );
    }

    return _MobileChatListView(onSelectChat: _selectChat);
  }
}

// ── 桌機雙欄版面 ──────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.selectedUserId,
    required this.onSelectChat,
  });

  final String? selectedUserId;
  final ValueChanged<String> onSelectChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminChatTokens.surface,
      body: Row(
        children: [
          // 左側列表
          SizedBox(
            width: _AdminChatTokens.sidebarWidth,
            child: _ChatListPanel(
              selectedUserId: selectedUserId,
              onSelectChat: onSelectChat,
            ),
          ),
          const VerticalDivider(
            width: 1,
            color: _AdminChatTokens.divider,
          ),

          // 右側對話區
          Expanded(
            child: selectedUserId == null
                ? const _EmptySelectionPlaceholder()
                : _ConversationPanel(
                    userId: selectedUserId!,
                    showBackButton: false,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 手機 — Chat 列表全螢幕 ────────────────────────────────────────────────────

class _MobileChatListView extends StatelessWidget {
  const _MobileChatListView({required this.onSelectChat});

  final ValueChanged<String> onSelectChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminChatTokens.surface,
      appBar: AppBar(
        title: const Text(
          '客服管理',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _AdminChatTokens.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _AdminChatTokens.divider),
        ),
      ),
      body: _ChatListPanel(
        selectedUserId: null,
        onSelectChat: onSelectChat,
      ),
    );
  }
}

// ── 手機 — 對話全螢幕 ─────────────────────────────────────────────────────────

class _MobileConversationView extends StatelessWidget {
  const _MobileConversationView({
    required this.userId,
    required this.onBack,
  });

  final String userId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AdminChatTokens.surface,
      appBar: AppBar(
        title: Text(
          _truncateUserId(userId),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _AdminChatTokens.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _AdminChatTokens.brandBrown,
          ),
          onPressed: onBack,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _AdminChatTokens.divider),
        ),
      ),
      body: _ConversationPanel(userId: userId, showBackButton: false),
    );
  }
}

// ── Chat 列表面板 ─────────────────────────────────────────────────────────────

class _ChatListPanel extends ConsumerWidget {
  const _ChatListPanel({
    required this.selectedUserId,
    required this.onSelectChat,
  });

  final String? selectedUserId;
  final ValueChanged<String> onSelectChat;

  static final _timeFormat = DateFormat('MM/dd HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(allChatsProvider);

    return Container(
      color: _AdminChatTokens.listBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標頭
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: const Text(
              '所有對話',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _AdminChatTokens.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: _AdminChatTokens.divider),

          // 列表
          Expanded(
            child: chatsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  '載入失敗：$e',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (chats) {
                if (chats.isEmpty) {
                  return const Center(
                    child: Text(
                      '目前尚無客服對話',
                      style: TextStyle(
                        fontSize: 13,
                        color: _AdminChatTokens.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 16,
                    color: _AdminChatTokens.divider,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isSelected = chat.userId == selectedUserId;

                    return _ChatListTile(
                      chat: chat,
                      isSelected: isSelected,
                      timeFormat: _timeFormat,
                      onTap: () => onSelectChat(chat.userId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat 列表項目 ─────────────────────────────────────────────────────────────

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({
    required this.chat,
    required this.isSelected,
    required this.timeFormat,
    required this.onTap,
  });

  final ChatSummary chat;
  final bool isSelected;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shortUserId = _truncateUserId(chat.userId);

    return Material(
      color: isSelected
          ? _AdminChatTokens.brandBrown.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頭像
              CircleAvatar(
                radius: 20,
                backgroundColor: _AdminChatTokens.brandBrown
                    .withValues(alpha: 0.15),
                child: Text(
                  shortUserId.isNotEmpty ? shortUserId[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AdminChatTokens.brandBrown,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 訊息摘要
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shortUserId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _AdminChatTokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeFormat.format(chat.lastMessageAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _AdminChatTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _AdminChatTokens.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0)
                          _UnreadBadge(count: chat.unreadCount),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 未讀 Badge ────────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _AdminChatTokens.badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _AdminChatTokens.badgeText,
        ),
      ),
    );
  }
}

// ── 無選取提示 ────────────────────────────────────────────────────────────────

class _EmptySelectionPlaceholder extends StatelessWidget {
  const _EmptySelectionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 56,
            color: _AdminChatTokens.brandBrownLight,
          ),
          SizedBox(height: 12),
          Text(
            '選取左側對話以開始回覆',
            style: TextStyle(
              fontSize: 14,
              color: _AdminChatTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 對話面板 ──────────────────────────────────────────────────────────────────

class _ConversationPanel extends ConsumerStatefulWidget {
  const _ConversationPanel({
    required this.userId,
    required this.showBackButton,
  });

  final String userId;
  final bool showBackButton;

  @override
  ConsumerState<_ConversationPanel> createState() =>
      _ConversationPanelState();
}

class _ConversationPanelState extends ConsumerState<_ConversationPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputController.clear();

    try {
      await ref
          .read(adminChatRepositoryProvider)
          .sendAdminMessage(widget.userId, content);
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(adminChatMessagesProvider(widget.userId));

    return Column(
      children: [
        // 標頭
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: _AdminChatTokens.divider),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    _AdminChatTokens.brandBrown.withValues(alpha: 0.15),
                child: Text(
                  _truncateUserId(widget.userId).isNotEmpty
                      ? _truncateUserId(widget.userId)[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _AdminChatTokens.brandBrown,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _truncateUserId(widget.userId),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AdminChatTokens.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // 訊息列表
        Expanded(
          child: messagesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                '載入失敗：$e',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            data: (messages) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToBottom());

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    '尚無訊息',
                    style: TextStyle(
                      fontSize: 13,
                      color: _AdminChatTokens.textSecondary,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _AdminMessageBubble(message: messages[index]);
                },
              );
            },
          ),
        ),

        // 輸入列
        _AdminInputBar(
          controller: _inputController,
          isSending: _isSending,
          onSend: _handleSend,
        ),
      ],
    );
  }
}

// ── 訊息氣泡（管理員視角）────────────────────────────────────────────────────

class _AdminMessageBubble extends StatelessWidget {
  const _AdminMessageBubble({required this.message});

  final ChatMessage message;

  static final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    // 從管理員視角：senderId == 'admin' → 右側（客服發出）；其餘 → 左側（使用者）
    final isAdmin = !message.isFromUser;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth =
        screenWidth * _AdminChatTokens.bubbleMaxWidthRatio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment:
            isAdmin ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Column(
            crossAxisAlignment: isAdmin
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // 寄件人標籤
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                child: Text(
                  isAdmin ? '山裕客服' : '使用者',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AdminChatTokens.brandBrownLight,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // 氣泡本體
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? _AdminChatTokens.adminBubbleBg
                      : _AdminChatTokens.userBubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(
                        _AdminChatTokens.bubbleRadius),
                    topRight: const Radius.circular(
                        _AdminChatTokens.bubbleRadius),
                    bottomLeft: Radius.circular(
                      isAdmin ? _AdminChatTokens.bubbleRadius : 4,
                    ),
                    bottomRight: Radius.circular(
                      isAdmin ? 4 : _AdminChatTokens.bubbleRadius,
                    ),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isAdmin
                        ? _AdminChatTokens.adminBubbleText
                        : _AdminChatTokens.userBubbleText,
                  ),
                ),
              ),

              // 時間戳記
              Padding(
                padding:
                    const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  _timeFormat.format(message.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: _AdminChatTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 客服輸入列 ────────────────────────────────────────────────────────────────

class _AdminInputBar extends StatelessWidget {
  const _AdminInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
        decoration: const BoxDecoration(
          color: _AdminChatTokens.inputBarBg,
          border: Border(
            top: BorderSide(color: _AdminChatTokens.divider),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 14,
                  color: _AdminChatTokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '以山裕客服身份回覆…',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: _AdminChatTokens.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: _AdminChatTokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: _AdminChatTokens.inputBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: _AdminChatTokens.inputBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: _AdminChatTokens.brandBrown,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: _AdminChatTokens.brandBrown,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: isSending ? null : onSend,
                  child: Center(
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 工具函式 ──────────────────────────────────────────────────────────────────

String _truncateUserId(String userId) {
  if (userId.length <= 12) return userId;
  return '${userId.substring(0, 6)}…${userId.substring(userId.length - 6)}';
}

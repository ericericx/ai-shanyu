// lib/features/chat/presentation/chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_nav_bar.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _ChatTokens {
  static const surface = Color(0xFFFAF8F5);
  static const brandBrown = Color(0xFF5C4033);
  static const brandBrownLight = Color(0xFF8D6E63);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);

  // 氣泡顏色
  static const userBubbleBg = Color(0xFF5C4033);
  static const userBubbleText = Colors.white;
  static const adminBubbleBg = Color(0xFFF0EAE4);
  static const adminBubbleText = Color(0xFF2D2118);

  static const inputBarBg = Colors.white;
  static const inputBorderColor = Color(0xFFD7CFC8);

  static const horizontalPadding = 16.0;
  static const bubbleMaxWidthRatio = 0.72;
  static const bubbleRadius = 16.0;
  static const bubbleVerticalPad = 10.0;
  static const bubbleHorizontalPad = 14.0;
}

// ── ChatPage ──────────────────────────────────────────────────────────────────

/// 使用者端即時客服聊天頁面（路由 `/chat`）。
///
/// 佈局：AppNavBar → 訊息列表 → 底部輸入列
/// 未登入時顯示引導提示，不顯示輸入列。
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user != null) {
        // 進入頁面時將未讀歸零
        ref.read(chatRepositoryProvider).markAsRead(user.uid);
      }
    });
  }

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
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final content = _inputController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputController.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            user.uid,
            content,
            user.displayName ?? user.email ?? '使用者',
          );
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _ChatTokens.surface,
      appBar: const AppNavBar(),
      body: user == null
          ? const _UnauthenticatedPlaceholder()
          : _ChatBody(
              userId: user.uid,
              scrollController: _scrollController,
              inputController: _inputController,
              isSending: _isSending,
              onSend: _handleSend,
              onMessagesUpdated: _scrollToBottom,
            ),
    );
  }
}

// ── 未登入提示 ────────────────────────────────────────────────────────────────

class _UnauthenticatedPlaceholder extends StatelessWidget {
  const _UnauthenticatedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: _ChatTokens.brandBrownLight,
            ),
            const SizedBox(height: 16),
            const Text(
              '請先登入才能使用客服功能',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ChatTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 主體聊天區域 ──────────────────────────────────────────────────────────────

class _ChatBody extends ConsumerWidget {
  const _ChatBody({
    required this.userId,
    required this.scrollController,
    required this.inputController,
    required this.isSending,
    required this.onSend,
    required this.onMessagesUpdated,
  });

  final String userId;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onMessagesUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(userId));

    return Column(
      children: [
        // ── 頁面標題列 ──
        _ChatHeader(),

        // ── 訊息列表 ──
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                '載入失敗：$error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (messages) {
              // 每次資料更新後自動捲到底部
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => onMessagesUpdated());

              if (messages.isEmpty) {
                return const _EmptyChatPlaceholder();
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: _ChatTokens.horizontalPadding,
                  vertical: 16,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _MessageBubble(message: messages[index]);
                },
              );
            },
          ),
        ),

        // ── 底部輸入列 ──
        _InputBar(
          controller: inputController,
          isSending: isSending,
          onSend: onSend,
        ),
      ],
    );
  }
}

// ── 聊天標題列 ────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _ChatTokens.divider),
        ),
      ),
      child: const Text(
        '聯繫我們',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _ChatTokens.textPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── 空聊天提示 ────────────────────────────────────────────────────────────────

class _EmptyChatPlaceholder extends StatelessWidget {
  const _EmptyChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: _ChatTokens.brandBrownLight,
            ),
            const SizedBox(height: 12),
            const Text(
              '有任何問題，歡迎留言，\n山裕客服將盡快回覆您！',
              style: TextStyle(
                fontSize: 14,
                color: _ChatTokens.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 訊息氣泡 ──────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  static final _timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth * _ChatTokens.bubbleMaxWidthRatio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment:
            isFromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Column(
            crossAxisAlignment: isFromUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // 客服名稱（僅客服訊息顯示）
              if (!isFromUser)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    '山裕客服',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _ChatTokens.brandBrownLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

              // 氣泡本體
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _ChatTokens.bubbleHorizontalPad,
                  vertical: _ChatTokens.bubbleVerticalPad,
                ),
                decoration: BoxDecoration(
                  color: isFromUser
                      ? _ChatTokens.userBubbleBg
                      : _ChatTokens.adminBubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(_ChatTokens.bubbleRadius),
                    topRight: const Radius.circular(_ChatTokens.bubbleRadius),
                    bottomLeft: Radius.circular(
                      isFromUser ? _ChatTokens.bubbleRadius : 4,
                    ),
                    bottomRight: Radius.circular(
                      isFromUser ? 4 : _ChatTokens.bubbleRadius,
                    ),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isFromUser
                        ? _ChatTokens.userBubbleText
                        : _ChatTokens.adminBubbleText,
                  ),
                ),
              ),

              // 時間戳記
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  _timeFormat.format(message.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: _ChatTokens.textSecondary,
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

// ── 底部輸入列 ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
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
          color: _ChatTokens.inputBarBg,
          border: Border(
            top: BorderSide(color: _ChatTokens.divider),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 輸入框
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 14,
                  color: _ChatTokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '輸入訊息…',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: _ChatTokens.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: _ChatTokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: _ChatTokens.inputBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: _ChatTokens.inputBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: _ChatTokens.brandBrown,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 發送按鈕
            SizedBox(
              width: 44,
              height: 44,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: Material(
                  color: _ChatTokens.brandBrown,
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
            ),
          ],
        ),
      ),
    );
  }
}

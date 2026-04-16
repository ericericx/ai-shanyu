// lib/features/profile/presentation/profile_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_nav_bar.dart';
import '../../auth/providers/auth_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _ProfileTokens {
  static const surface = Color(0xFFFAF8F5);
  static const brandBrown = Color(0xFFB82020);
  static const brandBrownLight = Color(0xFF9C1B1B);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);
  static const cardBg = Colors.white;
  static const dangerRed = Color(0xFFD32F2F);
  static const disabledBg = Color(0xFFF5F5F5);
  static const disabledText = Color(0xFFBDBDBD);

  static const sectionPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );
  static const cardBorderRadius = 12.0;
  static const avatarRadius = 40.0;
}

// ── ProfilePage ───────────────────────────────────────────────────────────────

/// 會員中心頁面（路由 `/profile`）。
///
/// 已登入：顯示使用者資訊、訂單入口、帳號設定、登出。
/// 未登入：顯示引導提示。
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _ProfileTokens.surface,
      appBar: const AppNavBar(),
      body: user == null
          ? const _UnauthenticatedPlaceholder()
          : _ProfileBody(user: user),
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
            const Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: _ProfileTokens.brandBrownLight,
            ),
            const SizedBox(height: 16),
            const Text(
              '請先登入以查看會員資訊',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ProfileTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.login),
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileTokens.brandBrown,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '前往登入',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 已登入內容主體 ─────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 使用者資訊區
                _UserInfoSection(user: user),
                const SizedBox(height: 16),

                // 2. 訂單紀錄入口
                _OrderEntryCard(),
                const SizedBox(height: 16),

                // 3. 帳號設定
                _AccountSettingsSection(user: user),
                const SizedBox(height: 16),

                // 4. 登出
                _SignOutButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 1. 使用者資訊區 ───────────────────────────────────────────────────────────

class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : '會員';
    final email = user.email ?? user.phoneNumber ?? '';

    return Container(
      padding: _ProfileTokens.sectionPadding,
      decoration: BoxDecoration(
        color: _ProfileTokens.cardBg,
        borderRadius: BorderRadius.circular(_ProfileTokens.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 大頭照
          CircleAvatar(
            radius: _ProfileTokens.avatarRadius,
            backgroundColor: _ProfileTokens.brandBrown,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // 名稱與 Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ProfileTokens.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _ProfileTokens.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. 訂單紀錄入口 ───────────────────────────────────────────────────────────

class _OrderEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: InkWell(
        onTap: () => context.go(AppRoutes.orders),
        borderRadius: BorderRadius.circular(_ProfileTokens.cardBorderRadius),
        child: Padding(
          padding: _ProfileTokens.sectionPadding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _ProfileTokens.brandBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _ProfileTokens.brandBrown,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '訂單紀錄',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ProfileTokens.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ProfileTokens.brandBrownLight,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3. 帳號設定 ───────────────────────────────────────────────────────────────

class _AccountSettingsSection extends ConsumerStatefulWidget {
  const _AccountSettingsSection({required this.user});

  final User user;

  @override
  ConsumerState<_AccountSettingsSection> createState() =>
      _AccountSettingsSectionState();
}

class _AccountSettingsSectionState
    extends ConsumerState<_AccountSettingsSection> {
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    try {
      await widget.user.updateDisplayName(newName);
      // 強制刷新 auth state
      await FirebaseAuth.instance.currentUser?.reload();
      if (mounted) {
        setState(() => _feedbackMessage = '顯示名稱已更新');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _feedbackMessage = '更新失敗，請稍後再試');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Padding(
        padding: _ProfileTokens.sectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '帳號設定',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ProfileTokens.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),

            // 顯示名稱編輯
            _DisplayNameField(
              controller: _nameController,
              isSaving: _isSaving,
              feedbackMessage: _feedbackMessage,
              onSave: _handleSaveName,
            ),

            const SizedBox(height: 20),
            const Divider(color: _ProfileTokens.divider, height: 1),
            const SizedBox(height: 20),

            // 社群綁定（即將推出）
            const Text(
              '社群帳號綁定',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ProfileTokens.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            _SocialBindingRow(
              icon: Icons.message_outlined,
              label: 'LINE',
              iconColor: const Color(0xFF06C755),
            ),
            const SizedBox(height: 10),
            _SocialBindingRow(
              icon: Icons.facebook_outlined,
              label: 'Facebook',
              iconColor: const Color(0xFF1877F2),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 顯示名稱欄位 ──────────────────────────────────────────────────────────────

class _DisplayNameField extends StatelessWidget {
  const _DisplayNameField({
    required this.controller,
    required this.isSaving,
    required this.feedbackMessage,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isSaving;
  final String? feedbackMessage;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '顯示名稱',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _ProfileTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                maxLength: 30,
                style: const TextStyle(
                  fontSize: 14,
                  color: _ProfileTokens.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '輸入顯示名稱',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: _ProfileTokens.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: _ProfileTokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _ProfileTokens.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _ProfileTokens.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: _ProfileTokens.brandBrown,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: isSaving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: _ProfileTokens.brandBrown,
                  disabledBackgroundColor: _ProfileTokens.disabledBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '儲存',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (feedbackMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            feedbackMessage!,
            style: TextStyle(
              fontSize: 12,
              color: feedbackMessage!.contains('失敗')
                  ? _ProfileTokens.dangerRed
                  : _ProfileTokens.brandBrown,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 社群綁定列 ────────────────────────────────────────────────────────────────

class _SocialBindingRow extends StatelessWidget {
  const _SocialBindingRow({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _ProfileTokens.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _ProfileTokens.disabledBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '未綁定',
            style: TextStyle(
              fontSize: 12,
              color: _ProfileTokens.disabledText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: _ProfileTokens.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            '即將推出',
            style: TextStyle(
              fontSize: 12,
              color: _ProfileTokens.disabledText,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 4. 登出按鈕 ───────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      child: InkWell(
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                '確認登出',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ProfileTokens.textPrimary,
                ),
              ),
              content: const Text(
                '確定要登出帳號嗎？',
                style: TextStyle(
                  fontSize: 14,
                  color: _ProfileTokens.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: _ProfileTokens.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    '登出',
                    style: TextStyle(
                      color: _ProfileTokens.dangerRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) {
              context.go(AppRoutes.home);
            }
          }
        },
        borderRadius: BorderRadius.circular(_ProfileTokens.cardBorderRadius),
        child: Padding(
          padding: _ProfileTokens.sectionPadding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _ProfileTokens.dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _ProfileTokens.dangerRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '登出',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ProfileTokens.dangerRed,
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

// ── 通用卡片容器 ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileTokens.cardBg,
        borderRadius: BorderRadius.circular(_ProfileTokens.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_ProfileTokens.cardBorderRadius),
        child: child,
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

// ── 設計 Token（局部，待整合全局 UI Kit） ────────────────────────────────────

abstract final class _AuthColors {
  static const brandBrown = Color(0xFF5C4033);
  static const brandBrownLight = Color(0xFF8D6E63);
  static const surface = Color(0xFFFAF7F4);
  static const inputBorder = Color(0xFFD7CCC8);
  static const errorRed = Color(0xFFC62828);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);
}

abstract final class _AuthSpacing {
  static const pagePadding = 24.0;
  static const cardPadding = 32.0;
  static const fieldGap = 16.0;
  static const sectionGap = 24.0;
  static const buttonHeight = 52.0;
  static const cardMaxWidth = 440.0;
  static const borderRadius = 12.0;
  static const inputBorderRadius = 8.0;
}

// ── FirebaseAuthException 中文訊息對照 ───────────────────────────────────────

String _authErrorMessage(String code) {
  return switch (code) {
    'user-not-found' => '找不到此電子郵件帳號，請確認後重試。',
    'wrong-password' => '密碼錯誤，請重新輸入。',
    'invalid-credential' => '帳號或密碼錯誤，請確認後重試。',
    'email-already-in-use' => '此電子郵件已被註冊，請直接登入或使用其他信箱。',
    'weak-password' => '密碼強度不足，請使用至少 6 個字元。',
    'invalid-email' => '電子郵件格式不正確。',
    'too-many-requests' => '登入嘗試次數過多，請稍後再試。',
    'network-request-failed' => '網路連線失敗，請檢查網路後重試。',
    'user-disabled' => '此帳號已被停用，請聯絡客服。',
    'popup-closed-by-user' => 'Google 登入視窗已關閉，請重試。',
    'cancelled-popup-request' => '登入已取消。',
    _ => '登入失敗（$code），請稍後再試。',
  };
}

// ── 頁面入口 ──────────────────────────────────────────────────────────────────

/// 登入／註冊頁面。
///
/// 版面中央為白色卡片，包含：
/// - Google 一鍵登入按鈕
/// - 分隔線
/// - Email / Password 表單（含登入 / 註冊 Tab 切換）
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _errorMessage = null);
        _formKey.currentState?.reset();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── 動作處理 ────────────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _authErrorMessage(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Google 登入失敗，請稍後再試。');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleEmailAction() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isEmailLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final isLogin = _tabController.index == 0;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (isLogin) {
        await repo.signInWithEmailPassword(email, password);
      } else {
        await repo.createUserWithEmailPassword(email, password);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _authErrorMessage(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '操作失敗，請稍後再試。');
      }
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  // ── 版面建構 ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_AuthSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _AuthSpacing.cardMaxWidth,
              ),
              child: _LoginCard(
                tabController: _tabController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                formKey: _formKey,
                isGoogleLoading: _isGoogleLoading,
                isEmailLoading: _isEmailLoading,
                obscurePassword: _obscurePassword,
                obscureConfirm: _obscureConfirm,
                errorMessage: _errorMessage,
                onGoogleSignIn: _handleGoogleSignIn,
                onEmailAction: _handleEmailAction,
                onTogglePasswordVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onToggleConfirmVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 登入卡片（Layout Widget） ─────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.tabController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.isGoogleLoading,
    required this.isEmailLoading,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.errorMessage,
    required this.onGoogleSignIn,
    required this.onEmailAction,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmVisibility,
  });

  final TabController tabController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final bool isGoogleLoading;
  final bool isEmailLoading;
  final bool obscurePassword;
  final bool obscureConfirm;
  final String? errorMessage;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onEmailAction;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_AuthSpacing.borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_AuthSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 品牌標題 ──
          const _BrandHeader(),
          const SizedBox(height: _AuthSpacing.sectionGap),

          // ── Google 登入 ──
          _GoogleSignInButton(
            isLoading: isGoogleLoading,
            onPressed: isEmailLoading ? null : onGoogleSignIn,
          ),
          const SizedBox(height: _AuthSpacing.sectionGap),

          // ── 分隔線 ──
          const _OrDivider(),
          const SizedBox(height: _AuthSpacing.sectionGap),

          // ── 登入 / 註冊 Tab ──
          _AuthTabBar(controller: tabController),
          const SizedBox(height: _AuthSpacing.fieldGap),

          // ── 表單 ──
          _EmailPasswordForm(
            tabController: tabController,
            emailController: emailController,
            passwordController: passwordController,
            confirmPasswordController: confirmPasswordController,
            formKey: formKey,
            isLoading: isEmailLoading,
            obscurePassword: obscurePassword,
            obscureConfirm: obscureConfirm,
            onSubmit: isGoogleLoading ? null : onEmailAction,
            onTogglePasswordVisibility: onTogglePasswordVisibility,
            onToggleConfirmVisibility: onToggleConfirmVisibility,
          ),

          // ── 錯誤訊息 ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: errorMessage != null
                ? _ErrorBanner(key: ValueKey(errorMessage), message: errorMessage!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── 品牌標頭 ──────────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _AuthColors.brandBrown,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '山裕電商',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _AuthColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '嚴選農產品直送到府',
          style: TextStyle(
            fontSize: 13,
            color: _AuthColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Google 登入按鈕 ───────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _AuthSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _AuthColors.inputBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          ),
          foregroundColor: _AuthColors.textPrimary,
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _AuthColors.brandBrown,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" 圖示（使用 SVG 色彩近似）
                  _GoogleIcon(),
                  const SizedBox(width: 10),
                  const Text(
                    '使用 Google 帳號登入',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Google "G" 圖示的近似實作（不依賴外部圖片資源）。
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 底色圓
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // 簡化的多色弧線代表 Google 圖示
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 藍色弧
    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      -0.5,
      1.8,
      false,
      strokePaint,
    );

    // 綠色弧
    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      1.3,
      1.6,
      false,
      strokePaint,
    );

    // 黃色弧
    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      2.9,
      0.8,
      false,
      strokePaint,
    );

    // 紅色弧
    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      3.7,
      1.9,
      false,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 分隔線 ────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: _AuthColors.divider, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '或',
            style: TextStyle(
              color: _AuthColors.textSecondary.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: _AuthColors.divider, thickness: 1),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _AuthTabBar extends StatelessWidget {
  const _AuthTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AuthColors.surface,
        borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
      ),
      child: TabBar(
        controller: controller,
        tabs: const [
          Tab(text: '登入'),
          Tab(text: '註冊'),
        ],
        labelColor: Colors.white,
        unselectedLabelColor: _AuthColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: BoxDecoration(
          color: _AuthColors.brandBrown,
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(3),
      ),
    );
  }
}

// ── Email / Password 表單 ─────────────────────────────────────────────────────

class _EmailPasswordForm extends StatelessWidget {
  const _EmailPasswordForm({
    required this.tabController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmVisibility,
  });

  final TabController tabController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback? onSubmit;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmVisibility;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          final isRegister = tabController.index == 1;
          return Column(
            children: [
              // 電子郵件
              _AuthTextField(
                controller: emailController,
                label: '電子郵件',
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入電子郵件';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return '電子郵件格式不正確';
                  }
                  return null;
                },
              ),
              const SizedBox(height: _AuthSpacing.fieldGap),

              // 密碼
              _AuthTextField(
                controller: passwordController,
                label: '密碼',
                hint: isRegister ? '至少 6 個字元' : '輸入密碼',
                obscureText: obscurePassword,
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: onTogglePasswordVisibility,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: _AuthColors.textSecondary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入密碼';
                  if (isRegister && value.length < 6) return '密碼至少需要 6 個字元';
                  return null;
                },
              ),

              // 確認密碼（僅註冊時顯示）
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isRegister
                    ? Column(
                        children: [
                          const SizedBox(height: _AuthSpacing.fieldGap),
                          _AuthTextField(
                            controller: confirmPasswordController,
                            label: '確認密碼',
                            hint: '再次輸入密碼',
                            obscureText: obscureConfirm,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: onToggleConfirmVisibility,
                              icon: Icon(
                                obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: _AuthColors.textSecondary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '請確認密碼';
                              }
                              if (value != passwordController.text) {
                                return '兩次輸入的密碼不一致';
                              }
                              return null;
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: _AuthSpacing.sectionGap),

              // 提交按鈕
              _SubmitButton(
                isLoading: isLoading,
                label: isRegister ? '建立帳號' : '登入',
                onPressed: onSubmit,
              ),
              const SizedBox(height: _AuthSpacing.fieldGap),
            ],
          );
        },
      ),
    );
  }
}

// ── 通用輸入框 ────────────────────────────────────────────────────────────────

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 15,
        color: _AuthColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: _AuthColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: _AuthColors.textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: _AuthColors.brandBrownLight,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _AuthColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          borderSide: const BorderSide(color: _AuthColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          borderSide: const BorderSide(color: _AuthColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          borderSide: const BorderSide(
            color: _AuthColors.brandBrown,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          borderSide: const BorderSide(color: _AuthColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          borderSide: const BorderSide(
            color: _AuthColors.errorRed,
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(
          color: _AuthColors.errorRed,
          fontSize: 12,
        ),
      ),
      validator: validator,
    );
  }
}

// ── 提交按鈕 ──────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _AuthSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AuthColors.brandBrown,
          disabledBackgroundColor: _AuthColors.brandBrownLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

// ── 錯誤訊息橫幅 ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F3),
          border: Border.all(color: _AuthColors.errorRed.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(_AuthSpacing.inputBorderRadius),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _AuthColors.errorRed,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _AuthColors.errorRed,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

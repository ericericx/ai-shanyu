import 'package:firebase_auth/firebase_auth.dart';

/// Auth Repository — 封裝 FirebaseAuth 操作。
///
/// 所有認證邏輯集中於此，禁止在 Widget 層直接呼叫 FirebaseAuth。
class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── 狀態監聽 ──────────────────────────────────────────────────────────────

  /// 監聽登入狀態變化，每次 auth 狀態更新都會發出新事件。
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 取得目前登入的使用者（未登入為 null）。
  User? get currentUser => _auth.currentUser;

  // ── 登入方法 ──────────────────────────────────────────────────────────────

  /// Google OAuth 登入（Flutter Web 使用 signInWithPopup）。
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    await _auth.signInWithPopup(provider);
  }

  /// Email + Password 登入。
  Future<void> signInWithEmailPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Email + Password 建立新帳號。
  Future<void> createUserWithEmailPassword(
    String email,
    String password,
  ) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 登出。
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

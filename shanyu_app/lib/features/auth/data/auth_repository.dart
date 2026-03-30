import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Auth Repository — 封裝 FirebaseAuth 操作。
///
/// 所有認證邏輯集中於此，禁止在 Widget 層直接呼叫 FirebaseAuth。
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ── 狀態監聽 ──────────────────────────────────────────────────────────────

  /// 監聽登入狀態變化，每次 auth 狀態更新都會發出新事件。
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 取得目前登入的使用者（未登入為 null）。
  User? get currentUser => _auth.currentUser;

  // ── 登入方法 ──────────────────────────────────────────────────────────────

  /// Google OAuth 登入（Flutter Web 使用 signInWithPopup）。
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final credential = await _auth.signInWithPopup(provider);
    final user = credential.user;
    if (user != null) {
      await _logIdTokenClaims('signInWithGoogle', user);
      await ensureUserFirestoreProfile(user);
    }
  }

  /// Email + Password 登入。
  Future<void> signInWithEmailPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _logIdTokenClaims('signInWithEmailPassword', user);
      await ensureUserFirestoreProfile(user);
    }
  }

  /// Email + Password 建立新帳號。
  Future<void> createUserWithEmailPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _logIdTokenClaims('createUserWithEmailPassword', user);
      await ensureUserFirestoreProfile(user);
    }
  }

  /// Writes `users/{uid}` when missing (canonical profile shape for this app).
  ///
  /// Rules allow the signed-in owner to create their own document with role customer.
  Future<void> ensureUserFirestoreProfile(User user) async {
    final uid = user.uid;
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      if (kDebugMode) {
        debugPrint(
          '[ShanYu:Auth] ensureUserFirestoreProfile skip (exists) uid=$uid '
          'role=${snapshot.data()?['role']}',
        );
      }
      return;
    }
    try {
      if (kDebugMode) {
        debugPrint('[ShanYu:Auth] ensureUserFirestoreProfile creating uid=$uid');
      }
      await docRef.set({
        'uid': uid,
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lineLinked': false,
        'facebookLinked': false,
      });
    } catch (e, st) {
      debugPrint('[ShanYu:Auth] ensureUserFirestoreProfile failed: $e\n$st');
    }
  }

  Future<void> _logIdTokenClaims(String source, User user) async {
    if (!kDebugMode) {
      return;
    }
    try {
      final result = await user.getIdTokenResult(true);
      final c = result.claims;
      debugPrint(
        '[ShanYu:Auth] $source uid=${user.uid} email=${user.email} '
        'claimsKeys=${c?.keys.toList()} admin=${c?['admin']}',
      );
    } catch (e, st) {
      debugPrint('[ShanYu:Auth] $source getIdTokenResult failed: $e\n$st');
    }
  }

  /// 登出。
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

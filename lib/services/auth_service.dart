import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 監聽登入狀態
  Stream<User?> get user => _auth.authStateChanges();

  // 電子郵件與密碼登入
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("登入錯誤: ${e.code}");
      rethrow;
    }
  }

  // 電子郵件與密碼註冊
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("註冊錯誤: ${e.code}");
      rethrow;
    }
  }

  // 匿名登入 (訪客)
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      debugPrint("訪客登入錯誤: ${e.code}");
      rethrow;
    }
  }

  // 登出
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 重設密碼
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 獲取目前使用者
  User? get currentUser => _auth.currentUser;
}

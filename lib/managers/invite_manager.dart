import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class InviteManager extends ChangeNotifier {
  static final InviteManager _instance = InviteManager._internal();
  factory InviteManager() => _instance;
  InviteManager._internal();

  static const String _inviteCodeKey = 'my_invite_code';
  static const String _usedInviteCodeKey = 'used_invite_code';
  static const String _inviteCountKey = 'invite_count';

  String? _myInviteCode;
  String? _usedInviteCode;
  int _inviteCount = 0;

  String? get myInviteCode => _myInviteCode;
  String? get usedInviteCode => _usedInviteCode;
  int get inviteCount => _inviteCount;
  bool get hasUsedInviteCode => _usedInviteCode != null;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _myInviteCode = prefs.getString(_inviteCodeKey);
      _usedInviteCode = prefs.getString(_usedInviteCodeKey);
      _inviteCount = prefs.getInt(_inviteCountKey) ?? 0;

      // 招待コードがなければ生成
      if (_myInviteCode == null) {
        await _generateInviteCode();
      }

      // Firestoreから招待数を同期
      await _syncInviteCount();
    } catch (e) {
      // エラーを無視
    }
  }

  // 招待コードを生成（6桁の英数字）
  Future<void> _generateInviteCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 紛らわしい文字を除外
    final random = Random();
    String code;

    // ユニークなコードが生成されるまでループ
    do {
      code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    } while (await _isCodeExists(code));

    _myInviteCode = code;

    // ローカルに保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inviteCodeKey, code);

    // Firestoreに登録
    await _firestore.collection('invite_codes').doc(code).set({
      'createdAt': FieldValue.serverTimestamp(),
      'inviteCount': 0,
    });

    notifyListeners();
  }

  // コードが既に存在するかチェック
  Future<bool> _isCodeExists(String code) async {
    try {
      final doc = await _firestore.collection('invite_codes').doc(code).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // 招待コードを使用
  Future<bool> useInviteCode(String code) async {
    // 既に招待コードを使用している場合はエラー
    if (_usedInviteCode != null) {
      return false;
    }

    // 自分の招待コードは使えない
    if (code == _myInviteCode) {
      return false;
    }

    try {
      // Firestoreで招待コードを検証
      final docRef = _firestore.collection('invite_codes').doc(code);
      final doc = await docRef.get();

      if (!doc.exists) {
        return false; // 無効なコード
      }

      // トランザクションで招待数を増やす
      int newCount = 0;
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Code not found');
        }

        final currentCount = snapshot.data()?['inviteCount'] ?? 0;
        newCount = currentCount + 1;
        transaction.update(docRef, {'inviteCount': newCount});
      });

      // ローカルに保存
      _usedInviteCode = code;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usedInviteCodeKey, code);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Firestoreから招待数を同期
  Future<void> _syncInviteCount() async {
    if (_myInviteCode == null) return;

    try {
      final doc = await _firestore.collection('invite_codes').doc(_myInviteCode).get();
      if (doc.exists) {
        final count = doc.data()?['inviteCount'] ?? 0;
        if (count != _inviteCount) {
          _inviteCount = count;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_inviteCountKey, count);
          notifyListeners();
        }
      }
    } catch (e) {
      // エラーを無視
    }
  }

  // 招待数を手動で同期（リフレッシュ用）
  Future<void> refreshInviteCount() async {
    await _syncInviteCount();
  }

  // 招待メッセージを取得
  String getInviteMessage(String appStoreUrl, String languageCode) {
    if (languageCode == 'ja') {
      return 'MERGE TRIO - 数字を3つ揃えてマージする中毒性のあるパズルゲーム！\n\n'
          '招待コード: $_myInviteCode\n'
          'このコードを入力してネオンスキンをアンロック！\n\n'
          '$appStoreUrl';
    } else {
      return 'MERGE TRIO - Addictive puzzle game! Match 3 numbers to merge!\n\n'
          'Invite Code: $_myInviteCode\n'
          'Enter this code to unlock the Neon skin!\n\n'
          '$appStoreUrl';
    }
  }
}

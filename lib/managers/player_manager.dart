import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'score_manager.dart';

class PlayerManager {
  static final PlayerManager _instance = PlayerManager._internal();
  factory PlayerManager() => _instance;
  PlayerManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _playerName;
  static const String _playerNameKey = 'player_name';

  // 不適切な単語リスト（NGワード）
  static final List<String> _inappropriateWords = [
    // 性的な表現
    'セックス', 'sex', 'えっち', 'エッチ', 'ちんこ', 'まんこ', 'おっぱい',
    'ちんぽ', 'おめこ', 'ぱいぱい', 'ぱいずり', 'ふぇら', 'フェラ', 'シコシコ', 
    'しこしこ', 'せっくす'
    // 下品な表現
    'うんこ', 'うんち', 'くそ', 'クソ', 'しね', 'シネ', '死ね', 'ころす', '殺す',
    'きちがい', 'キチガイ', '気違い', 'かたわ', 'めくら', 'つんぼ', 'ちんば',
    // 差別用語
    '部落', 'えた', 'ひにん',
    // その他の不適切な表現
    'porn', 'fuck', 'shit', 'dick', 'pussy', 'bitch', 'ass',
  ];

  // プレイヤー名を取得
  Future<String?> getPlayerName() async {
    if (_playerName != null) return _playerName;

    final prefs = await SharedPreferences.getInstance();
    _playerName = prefs.getString(_playerNameKey);
    return _playerName;
  }

  // プレイヤー名を保存
  Future<void> setPlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, name);
    _playerName = name;
  }

  // プレイヤー名が登録済みかチェック
  Future<bool> isPlayerNameRegistered() async {
    final name = await getPlayerName();
    return name != null && name.isNotEmpty;
  }

  // 不適切な名前かどうかをチェック
  bool isInappropriateName(String name) {
    final lowerName = name.toLowerCase();

    // NGワードが含まれているかチェック
    for (final word in _inappropriateWords) {
      if (lowerName.contains(word.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  // 名前の重複チェック
  Future<bool> isNameAvailable(String name) async {
    try {
      final querySnapshot = await _firestore
          .collection('players')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      // ドキュメントが存在しない = 利用可能
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      // エラー時はログを出力してデバッグ
      print('Error checking name availability: $e');
      // エラー時は利用可能として扱う（初回登録を妨げないため）
      return true;
    }
  }

  // プレイヤーを登録
  Future<bool> registerPlayer(String name) async {
    try {
      print('Registering player: $name');

      // 現在のユーザーIDを取得
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        print('No user ID found');
        return false;
      }

      // 重複チェック
      final isAvailable = await isNameAvailable(name);
      print('Name available: $isAvailable');

      if (!isAvailable) {
        print('Name already taken - this might be from a previous installation');
        print('Deleting old data for name: $name');

        // 古いデータを削除（再インストール対応）
        await _deleteOldDataByName(name);
        print('Old data deleted');
      }

      // Firestoreに登録（userIdも保存）
      print('Adding to Firestore...');
      await _firestore.collection('players').add({
        'name': name,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Added to Firestore successfully');

      // ローカルに保存
      await setPlayerName(name);
      print('Saved locally');
      return true;
    } catch (e) {
      print('Error registering player: $e');
      return false;
    }
  }

  // 古いデータを削除（名前ベース）
  Future<void> _deleteOldDataByName(String playerName) async {
    try {
      // leaderboardから削除
      await _deleteFromLeaderboard('leaderboard', playerName);

      // leaderboard_5x5から削除
      await _deleteFromLeaderboard('leaderboard_5x5', playerName);

      // playersから削除
      final querySnapshot = await _firestore
          .collection('players')
          .where('name', isEqualTo: playerName)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Deleted old player data: ${doc.id}');
      }
    } catch (e) {
      print('Error deleting old data: $e');
    }
  }

  // 開発用: プレイヤーデータをリセット
  void clearPlayerData() {
    _playerName = null;
  }

  // leaderboardコレクションから削除（プレイヤー名で削除）
  Future<void> _deleteFromLeaderboard(String collectionName, String playerName) async {
    try {
      print('Attempting to delete from $collectionName with playerName: $playerName');

      // プレイヤー名で検索して削除
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('playerName', isEqualTo: playerName)
          .get();

      print('Found ${querySnapshot.docs.length} documents in $collectionName with playerName');
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        print('Deleted from $collectionName: ${doc.id}');
      }
    } catch (e) {
      print('Error deleting from $collectionName: $e');
    }
  }

  // アカウント削除（Firestoreとローカルデータを削除）
  Future<bool> deleteAccount() async {
    try {
      print('Deleting account...');

      // 現在のユーザーIDを取得
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

      if (userId == null) {
        print('No user ID found');
        return false;
      }

      print('User ID: $userId');

      // プレイヤー名を取得（名前での検索用）
      final playerName = await getPlayerName();
      print('Player name: $playerName');

      if (playerName == null || playerName.isEmpty) {
        print('No player name found');
        return false;
      }

      // 1. Firestoreのleaderboard（4×4）から削除（プレイヤー名で）
      await _deleteFromLeaderboard('leaderboard', playerName);

      // 2. Firestoreのleaderboard_5x5から削除（プレイヤー名で）
      await _deleteFromLeaderboard('leaderboard_5x5', playerName);

      // 3. Firestoreのplayersから削除（プレイヤー名で検索）
      try {
        print('Attempting to delete from players collection...');

        final querySnapshot = await _firestore
            .collection('players')
            .where('name', isEqualTo: playerName)
            .get();

        print('Found ${querySnapshot.docs.length} documents with playerName in players collection');
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
          print('Deleted from players: ${doc.id}');
        }

        if (querySnapshot.docs.isEmpty) {
          print('Warning: No player documents found to delete');
        }
      } catch (e, stackTrace) {
        print('Error deleting from players: $e');
        print('Stack trace: $stackTrace');
      }

      // 3. ローカルデータを削除
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _playerName = null;
      print('Cleared local data');

      // 4. Secure Storageから保存されているUIDを削除
      try {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'firebase_uid');
        print('Deleted UID from secure storage');
      } catch (e) {
        print('Error deleting from secure storage: $e');
      }

      // 5. Firebase匿名アカウントを削除
      try {
        await auth.currentUser?.delete();
        print('Deleted Firebase auth user');
      } catch (e) {
        print('Error deleting auth user: $e');
      }

      // 6. ScoreManagerもリセット
      await ScoreManager().clearAllData();
      print('Cleared score data');

      print('Account deletion completed');
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}

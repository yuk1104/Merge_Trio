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

      // 重複チェック
      final isAvailable = await isNameAvailable(name);
      print('Name available: $isAvailable');

      if (!isAvailable) {
        print('Name already taken');
        return false;
      }

      // 現在のユーザーIDを取得
      final auth = FirebaseAuth.instance;
      final userId = auth.currentUser?.uid;

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

  // 開発用: プレイヤーデータをリセット
  void clearPlayerData() {
    _playerName = null;
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

      // 1. Firestoreのleaderboardから削除
      try {
        print('Attempting to delete from leaderboard with userId: $userId');
        await _firestore.collection('leaderboard').doc(userId).delete();
        print('Successfully deleted from leaderboard');
      } catch (e, stackTrace) {
        print('Error deleting from leaderboard: $e');
        print('Stack trace: $stackTrace');
      }

      // 2. Firestoreのplayersから削除（userIdで検索、見つからなければ名前でも検索）
      try {
        print('Attempting to delete from players collection...');
        int deletedCount = 0;

        // まずuserIdで検索（新しいデータ）
        var querySnapshot = await _firestore
            .collection('players')
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          print('Found ${querySnapshot.docs.length} documents with userId');
          for (var doc in querySnapshot.docs) {
            await doc.reference.delete();
            deletedCount++;
            print('Deleted from players (by userId): ${doc.id}');
          }
        }

        // 名前でも検索（既存の古いデータ + 念のため）
        final playerName = await getPlayerName();
        if (playerName != null && playerName.isNotEmpty) {
          print('Also searching by name: $playerName');
          final nameQuerySnapshot = await _firestore
              .collection('players')
              .where('name', isEqualTo: playerName)
              .get();

          print('Found ${nameQuerySnapshot.docs.length} documents with name');
          for (var doc in nameQuerySnapshot.docs) {
            // userIdで既に削除済みでないか確認
            final docData = doc.data();
            final docUserId = docData['userId'];
            if (docUserId != userId) {
              // 別のuserIdか、userIdがないドキュメント（古いデータ）を削除
              await doc.reference.delete();
              deletedCount++;
              print('Deleted from players (by name): ${doc.id}');
            } else {
              print('Skipped ${doc.id} (already deleted by userId)');
            }
          }
        }

        if (deletedCount == 0) {
          print('Warning: No player documents found to delete');
        } else {
          print('Total deleted from players: $deletedCount documents');
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

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'score_manager.dart';

class PlayerManager {
  static final PlayerManager _instance = PlayerManager._internal();
  factory PlayerManager() => _instance;
  PlayerManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _playerName;
  static const String _playerNameKey = 'player_name';

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

      // Firestoreに登録
      print('Adding to Firestore...');
      await _firestore.collection('players').add({
        'name': name,
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

      // 2. Firestoreのplayersから削除（名前で検索）
      final playerName = await getPlayerName();
      if (playerName != null && playerName.isNotEmpty) {
        try {
          final querySnapshot = await _firestore
              .collection('players')
              .where('name', isEqualTo: playerName)
              .limit(1)
              .get();

          for (var doc in querySnapshot.docs) {
            await doc.reference.delete();
            print('Deleted from players: ${doc.id}');
          }
        } catch (e) {
          print('Error deleting from players: $e');
        }
      }

      // 3. ローカルデータを削除
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _playerName = null;
      print('Cleared local data');

      // 4. Firebase匿名アカウントを削除
      try {
        await auth.currentUser?.delete();
        print('Deleted Firebase auth user');
      } catch (e) {
        print('Error deleting auth user: $e');
      }

      // 5. ScoreManagerもリセット
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

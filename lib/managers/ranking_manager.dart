import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RankingEntry {
  final String userId;
  final String playerName;
  final int score;
  final DateTime timestamp;

  RankingEntry({
    required this.userId,
    required this.playerName,
    required this.score,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'playerName': playerName,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    return RankingEntry(
      userId: map['userId'] ?? '',
      playerName: map['playerName'] ?? 'Anonymous',
      score: map['score'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class RankingManager {
  static final RankingManager _instance = RankingManager._internal();
  factory RankingManager() => _instance;
  RankingManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 匿名認証（既存のユーザーがいればそれを使用）
  Future<String> _getUserId() async {
    try {
      // 既にログイン済みの場合はそのユーザーIDを返す
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('Using existing user: ${currentUser.uid}');
        return currentUser.uid;
      }

      // ログインしていない場合は匿名認証
      debugPrint('No current user, signing in anonymously...');

      // 少し待ってから認証を試行
      await Future.delayed(const Duration(milliseconds: 100));

      UserCredential userCredential = await _auth.signInAnonymously();
      debugPrint('Signed in with uid: ${userCredential.user?.uid}');
      return userCredential.user?.uid ?? '';
    } catch (e, stackTrace) {
      debugPrint('Error getting user ID: $e');
      debugPrint('Stack trace: $stackTrace');

      // 再度currentUserを確認（初期化完了後に使えるかもしれない）
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('Fallback: Found current user after error: ${currentUser.uid}');
        return currentUser.uid;
      }

      return '';
    }
  }

  // スコア送信（ユーザーごとに最高スコアのみを保持）
  Future<void> submitScore(String playerName, int score) async {
    try {
      debugPrint('Submitting score: $playerName - $score');
      final userId = await _getUserId();
      debugPrint('Got userId: $userId');

      // userIdが空の場合はスキップ
      if (userId.isEmpty) {
        debugPrint('UserID is empty, skipping score submission');
        debugPrint('Please enable Anonymous Authentication in Firebase Console');
        return;
      }

      // userIdをドキュメントIDとして使用し、既存のスコアを上書き
      await _firestore.collection('leaderboard').doc(userId).set({
        'userId': userId,
        'playerName': playerName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Score submitted successfully to Firestore');
    } catch (e) {
      debugPrint('Error submitting score: $e');
    }
  }

  // トップランキング取得（ユーザーごとに最高スコアのみ）
  Future<List<RankingEntry>> getTopRankings({int limit = 100}) async {
    try {
      debugPrint('Fetching rankings from Firestore (limit: $limit)...');
      final querySnapshot = await _firestore
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .limit(limit * 2) // 余裕を持って取得（重複ユーザーを考慮）
          .get(const GetOptions(source: Source.server)); // キャッシュを使わず常にサーバーから取得

      debugPrint('Found ${querySnapshot.docs.length} ranking entries from Firestore');

      // ユーザーごとに最高スコアのみを保持するマップ
      final Map<String, RankingEntry> userBestScores = {};

      for (var doc in querySnapshot.docs) {
        final entry = RankingEntry.fromMap(doc.data());
        final userId = entry.userId;

        // まだこのユーザーのスコアがないか、より高いスコアの場合のみ追加
        if (!userBestScores.containsKey(userId) ||
            entry.score > userBestScores[userId]!.score) {
          userBestScores[userId] = entry;
        }
      }

      // スコアでソートして上位を取得
      final rankings = userBestScores.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final result = rankings.take(limit).toList();
      debugPrint('Unique rankings: ${result.map((r) => '${r.playerName}: ${r.score}').join(', ')}');
      return result;
    } catch (e) {
      debugPrint('Error fetching rankings: $e');
      return [];
    }
  }

  // 自分の順位取得
  Future<int?> getMyRank(String userId) async {
    try {
      final allScores = await getTopRankings(limit: 1000);
      final index = allScores.indexWhere((entry) => entry.userId == userId);
      return index == -1 ? null : index + 1;
    } catch (e) {
      return null;
    }
  }
}

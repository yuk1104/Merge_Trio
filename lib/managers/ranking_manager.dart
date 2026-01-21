import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class RankingEntry {
  final String userId;
  final String playerName;
  final int score;
  final DateTime timestamp;
  final int boardSize;

  RankingEntry({
    required this.userId,
    required this.playerName,
    required this.score,
    required this.timestamp,
    this.boardSize = 4,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'playerName': playerName,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
      'boardSize': boardSize,
    };
  }

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    return RankingEntry(
      userId: map['userId'] ?? '',
      playerName: map['playerName'] ?? 'Anonymous',
      score: map['score'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      boardSize: map['boardSize'] ?? 4,
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

  // スコア送信（ユーザーごと・盤面サイズごとに最高スコアのみを保持）
  Future<void> submitScore(String playerName, int score, int boardSize) async {
    try {
      debugPrint('Submitting score: $playerName - $score (boardSize: $boardSize)');
      final userId = await _getUserId();
      debugPrint('Got userId: $userId');

      // userIdが空の場合はスキップ
      if (userId.isEmpty) {
        debugPrint('UserID is empty, skipping score submission');
        debugPrint('Please enable Anonymous Authentication in Firebase Console');
        return;
      }

      // ボードサイズごとに別のコレクションを使用
      // 既存のleaderboardは4×4として使用
      final collectionName = boardSize == 4 ? 'leaderboard' : 'leaderboard_5x5';

      // 既存のドキュメントを確認
      final docRef = _firestore.collection(collectionName).doc(userId);
      final existingDoc = await docRef.get();

      // 管理者が手動で変更した名前を保持するため、既存の名前を優先
      String finalPlayerName = playerName;
      if (existingDoc.exists) {
        final existingData = existingDoc.data();
        final existingName = existingData?['playerName'] as String?;
        // 既存の名前がある場合、それを使用（管理者が変更した可能性があるため）
        if (existingName != null && existingName.isNotEmpty) {
          finalPlayerName = existingName;
          debugPrint('Using existing playerName from Firestore: $existingName');
        }
      }

      // userIdをドキュメントIDとして使用し、スコアを更新
      await docRef.set({
        'userId': userId,
        'playerName': finalPlayerName,
        'score': score,
        'boardSize': boardSize,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Score submitted successfully to Firestore ($collectionName)');
    } catch (e) {
      debugPrint('Error submitting score: $e');
    }
  }

  // トップランキング取得（ユーザーごとに最高スコアのみ）
  Future<List<RankingEntry>> getTopRankings({int limit = 100, int boardSize = 4}) async {
    try {
      // 既存のleaderboardは4×4として使用
      final collectionName = boardSize == 4 ? 'leaderboard' : 'leaderboard_5x5';
      debugPrint('Fetching rankings from Firestore ($collectionName, limit: $limit)...');
      final querySnapshot = await _firestore
          .collection(collectionName)
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
  Future<int?> getMyRank(String userId, {int boardSize = 4}) async {
    try {
      final allScores = await getTopRankings(limit: 1000, boardSize: boardSize);
      final index = allScores.indexWhere((entry) => entry.userId == userId);
      return index == -1 ? null : index + 1;
    } catch (e) {
      return null;
    }
  }

  // 週の開始日（月曜日）を取得
  DateTime _getWeekStart(DateTime date) {
    // 月曜日を週の開始とする
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    final daysToSubtract = weekday - 1; // 月曜日まで戻る日数
    final weekStart = DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
    return weekStart;
  }

  // 週のIDを生成（例: "2024-W03"）
  String _getWeekId(DateTime date) {
    final weekStart = _getWeekStart(date);
    // ISO week番号を計算
    final dayOfYear = weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays;
    final weekNumber = ((dayOfYear + DateTime(weekStart.year, 1, 1).weekday) / 7).ceil();
    return '${weekStart.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  // 週間ランキングにスコアを送信
  Future<void> submitWeeklyScore(String playerName, int score, int boardSize) async {
    try {
      debugPrint('Submitting weekly score: $playerName - $score (boardSize: $boardSize)');
      final userId = await _getUserId();

      if (userId.isEmpty) {
        debugPrint('UserID is empty, skipping weekly score submission');
        return;
      }

      final weekId = _getWeekId(DateTime.now());
      debugPrint('Week ID: $weekId');

      // 週間ランキング用のコレクション
      final collectionName = boardSize == 4 ? 'weekly_leaderboard_4x4' : 'weekly_leaderboard_5x5';

      // ドキュメントID: {weekId}_{userId}
      final docId = '${weekId}_$userId';
      final docRef = _firestore.collection(collectionName).doc(docId);

      // 既存のスコアを確認
      final existingDoc = await docRef.get();

      if (existingDoc.exists) {
        final existingScore = existingDoc.data()?['score'] as int? ?? 0;
        // 既存のスコアより高い場合のみ更新
        if (score <= existingScore) {
          debugPrint('Existing weekly score is higher, skipping update');
          return;
        }
      }

      // スコアを更新
      await docRef.set({
        'userId': userId,
        'playerName': playerName,
        'score': score,
        'boardSize': boardSize,
        'weekId': weekId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Weekly score submitted successfully to $collectionName');
    } catch (e) {
      debugPrint('Error submitting weekly score: $e');
    }
  }

  // 週間ランキング取得
  Future<List<RankingEntry>> getWeeklyRankings({int limit = 100, int boardSize = 4, DateTime? targetDate}) async {
    try {
      final date = targetDate ?? DateTime.now();
      final weekId = _getWeekId(date);
      final collectionName = boardSize == 4 ? 'weekly_leaderboard_4x4' : 'weekly_leaderboard_5x5';

      debugPrint('Fetching weekly rankings for $weekId from $collectionName...');

      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('weekId', isEqualTo: weekId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));

      debugPrint('Found ${querySnapshot.docs.length} weekly ranking entries');

      final rankings = querySnapshot.docs
          .map((doc) => RankingEntry.fromMap(doc.data()))
          .toList();

      return rankings;
    } catch (e) {
      debugPrint('Error fetching weekly rankings: $e');
      return [];
    }
  }

  // 自分の週間順位取得
  Future<int?> getMyWeeklyRank(String userId, {int boardSize = 4, DateTime? targetDate}) async {
    try {
      final allScores = await getWeeklyRankings(limit: 1000, boardSize: boardSize, targetDate: targetDate);
      final index = allScores.indexWhere((entry) => entry.userId == userId);
      return index == -1 ? null : index + 1;
    } catch (e) {
      return null;
    }
  }

  // 週の期間を取得（表示用）
  Map<String, DateTime> getWeekRange(DateTime date) {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    return {
      'start': weekStart,
      'end': weekEnd,
    };
  }
}

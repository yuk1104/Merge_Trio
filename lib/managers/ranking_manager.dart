import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 匿名認証
  Future<String> _getUserId() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user!.uid;
    } catch (e) {
      return '';
    }
  }

  // スコア送信
  Future<void> submitScore(String playerName, int score) async {
    try {
      final userId = await _getUserId();

      await _firestore.collection('leaderboard').add({
        'userId': userId,
        'playerName': playerName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // エラーを無視
    }
  }

  // トップランキング取得
  Future<List<RankingEntry>> getTopRankings({int limit = 100}) async {
    try {
      print('Fetching rankings from Firestore...');
      final querySnapshot = await _firestore
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      print('Found ${querySnapshot.docs.length} ranking entries');
      final rankings = querySnapshot.docs
          .map((doc) => RankingEntry.fromMap(doc.data()))
          .toList();
      print('Rankings: ${rankings.map((r) => '${r.playerName}: ${r.score}').join(', ')}');
      return rankings;
    } catch (e) {
      print('Error fetching rankings: $e');
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

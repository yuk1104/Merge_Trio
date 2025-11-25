import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  static final ScoreManager _instance = ScoreManager._internal();
  factory ScoreManager() => _instance;
  ScoreManager._internal();

  static const String _bestScoreKey = 'best_score';
  int _bestScore = 0;
  bool _initialized = false;

  int get bestScore => _bestScore;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
      _initialized = true;
    } catch (e) {
      // エラーが発生しても続行（初期化失敗時はメモリ内のみで動作）
      _initialized = true;
    }
  }

  Future<bool> checkAndUpdateBestScore(int currentScore) async {
    if (!_initialized) {
      await initialize();
    }

    if (currentScore > _bestScore) {
      _bestScore = currentScore;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_bestScoreKey, _bestScore);
      } catch (e) {
        // 保存エラーを無視（メモリ内のみで保持）
      }

      return true; // 新記録
    }
    return false; // 新記録ではない
  }
}

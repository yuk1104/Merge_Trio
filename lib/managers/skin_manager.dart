import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'invite_manager.dart';

enum TileSkin {
  classic,
  pastel,
  neon,
}

class SkinManager extends ChangeNotifier {
  static final SkinManager _instance = SkinManager._internal();
  factory SkinManager() => _instance;
  SkinManager._internal();

  static const String _skinKey = 'tile_skin';
  static const String _playCountKey = 'play_count';
  static const String _rewardAdCountKey = 'reward_ad_count';
  static const String _pastelUnlockedKey = 'pastel_unlocked';
  static const String _neonUnlockedKey = 'neon_unlocked';
  static const String _shareCountKey = 'share_count';

  TileSkin _currentSkin = TileSkin.classic;
  int _playCount = 0;
  int _rewardAdCount = 0;
  bool _pastelUnlocked = false;
  bool _neonUnlocked = false;
  int _shareCount = 0;

  TileSkin get currentSkin => _currentSkin;
  int get playCount => _playCount;
  int get rewardAdCount => _rewardAdCount;
  bool get isPastelUnlocked => _pastelUnlocked;
  bool get isNeonUnlocked => _neonUnlocked;
  int get shareCount => _shareCount;

  // パステル解放条件
  static const int requiredPlayCount = 10;
  static const int requiredRewardAdCount = 3;

  // ネオン解放条件
  static const int requiredShareCount = 3;

  // テスト用: trueにするとパステルが常に解放される
  static const bool debugUnlockPastel = false;
  // テスト用: trueにするとネオンが常に解放される
  static const bool debugUnlockNeon = false;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skinIndex = prefs.getInt(_skinKey) ?? 0;
      _currentSkin = TileSkin.values[skinIndex];

      // 進捗状況を読み込み
      _playCount = prefs.getInt(_playCountKey) ?? 0;
      _rewardAdCount = prefs.getInt(_rewardAdCountKey) ?? 0;
      _pastelUnlocked = prefs.getBool(_pastelUnlockedKey) ?? false;
      _neonUnlocked = prefs.getBool(_neonUnlockedKey) ?? false;
      _shareCount = prefs.getInt(_shareCountKey) ?? 0;

      // テストモードの場合は常に解放
      if (debugUnlockPastel) {
        _pastelUnlocked = true;
      }
      if (debugUnlockNeon) {
        _neonUnlocked = true;
      }

      // 条件を満たしていれば自動的に解放
      _checkAndUnlockPastel();
      _checkAndUnlockNeon();
    } catch (e) {
      _currentSkin = TileSkin.classic;
    }
  }

  // パステル解放チェック
  void _checkAndUnlockPastel() {
    if (!_pastelUnlocked && _playCount >= requiredPlayCount && _rewardAdCount >= requiredRewardAdCount) {
      _pastelUnlocked = true;
      _savePastelUnlocked();
      notifyListeners();
    }
  }

  // ネオン解放チェック（InviteManagerの招待数に基づく）
  Future<void> checkAndUnlockNeon() async {
    if (_neonUnlocked) return;

    // InviteManagerから招待数を取得
    final inviteManager = InviteManager();
    await inviteManager.refreshInviteCount();

    if (inviteManager.inviteCount >= requiredShareCount) {
      _neonUnlocked = true;
      await _saveNeonUnlocked();
      notifyListeners();
    }
  }

  // 内部用のネオン解放チェック（後方互換性のため残す）
  void _checkAndUnlockNeon() {
    if (!_neonUnlocked && _shareCount >= requiredShareCount) {
      _neonUnlocked = true;
      _saveNeonUnlocked();
      notifyListeners();
    }
  }

  // プレイ回数を増やす
  Future<void> incrementPlayCount() async {
    _playCount++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_playCountKey, _playCount);
      _checkAndUnlockPastel();
      notifyListeners();
    } catch (e) {
      // エラーを無視
    }
  }

  // リワード広告視聴回数を増やす
  Future<void> incrementRewardAdCount() async {
    _rewardAdCount++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_rewardAdCountKey, _rewardAdCount);
      _checkAndUnlockPastel();
      notifyListeners();
    } catch (e) {
      // エラーを無視
    }
  }

  // 共有回数を増やす
  Future<void> incrementShareCount() async {
    _shareCount++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_shareCountKey, _shareCount);
      _checkAndUnlockNeon();
      notifyListeners();
    } catch (e) {
      // エラーを無視
    }
  }

  // パステル解放状態を保存
  Future<void> _savePastelUnlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pastelUnlockedKey, _pastelUnlocked);
    } catch (e) {
      // エラーを無視
    }
  }

  // ネオン解放状態を保存
  Future<void> _saveNeonUnlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_neonUnlockedKey, _neonUnlocked);
    } catch (e) {
      // エラーを無視
    }
  }

  Future<void> setSkin(TileSkin skin) async {
    _currentSkin = skin;
    notifyListeners(); // リスナーに通知
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_skinKey, skin.index);
    } catch (e) {
      // エラーを無視
    }
  }

  // スキン名を取得
  String getSkinName(TileSkin skin) {
    switch (skin) {
      case TileSkin.classic:
        return 'クラシック';
      case TileSkin.pastel:
        return 'パステル';
      case TileSkin.neon:
        return 'ネオン';
    }
  }

  // スキンごとのグラデーションを取得
  List<Color> getTileGradient(int number, TileSkin skin) {
    switch (skin) {
      case TileSkin.classic:
        return _getClassicGradient(number);
      case TileSkin.pastel:
        return _getPastelGradient(number);
      case TileSkin.neon:
        return _getNeonGradient(number);
    }
  }

  // クラシックスキン（デフォルト）
  List<Color> _getClassicGradient(int number) {
    switch (number) {
      case 1:
        return [const Color(0xFFFFF9C4), const Color(0xFFFFF59D)];
      case 2:
        return [const Color(0xFFFFCC80), const Color(0xFFFFB74D)];
      case 3:
        return [const Color(0xFFFF9800), const Color(0xFFFB8C00)];
      case 4:
        return [const Color(0xFFEF5350), const Color(0xFFE53935)];
      case 5:
        return [const Color(0xFFAB47BC), const Color(0xFF8E24AA)];
      case 6:
        return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      case 7:
        return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      case 8:
        return [const Color(0xFF5C6BC0), const Color(0xFF3949AB)]; // インディゴ（濃い青紫）
      case 9:
        return [const Color(0xFFEC407A), const Color(0xFFD81B60)]; // マゼンタ（濃いピンク）
      default:
        return [const Color(0xFFEEEEEE), const Color(0xFFE0E0E0)];
    }
  }

  // パステルスキン（おしゃれで区別しやすい色合い）
  List<Color> _getPastelGradient(int number) {
    switch (number) {
      case 1:
        return [const Color(0xFFFFF4E0), const Color(0xFFFFE5B4)]; // 明るいクリーム
      case 2:
        return [const Color(0xFFFFD4B2), const Color(0xFFFFB88C)]; // コーラルピーチ
      case 3:
        return [const Color(0xFFFFB5D8), const Color(0xFFFF8AC7)]; // ローズピンク
      case 4:
        return [const Color(0xFFD4A5FF), const Color(0xFFB57FFF)]; // ラベンダー
      case 5:
        return [const Color(0xFFA8D8FF), const Color(0xFF7FC7FF)]; // スカイブルー
      case 6:
        return [const Color(0xFF9FFFDB), const Color(0xFF6FFFC9)]; // ミントグリーン
      case 7:
        return [const Color(0xFFFFF99C), const Color(0xFFFFED6F)]; // レモンイエロー
      case 8:
        return [const Color(0xFFC5CAE9), const Color(0xFF9FA8DA)]; // パステルインディゴ
      case 9:
        return [const Color(0xFFF48FB1), const Color(0xFFF06292)]; // パステルマゼンタ
      default:
        return [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)];
    }
  }

  // ネオンスキン（鮮やかなネオンカラー、暗い背景に映える）
  List<Color> _getNeonGradient(int number) {
    switch (number) {
      case 1:
        return [const Color(0xFFFFFF00), const Color(0xFFFFDD00)]; // ネオンイエロー
      case 2:
        return [const Color(0xFFFF6600), const Color(0xFFFF4400)]; // ネオンオレンジ
      case 3:
        return [const Color(0xFFFF0080), const Color(0xFFFF0066)]; // ネオンピンク
      case 4:
        return [const Color(0xFFBB00FF), const Color(0xFF9900FF)]; // ネオンパープル
      case 5:
        return [const Color(0xFF00D4FF), const Color(0xFF00B8FF)]; // ネオンシアン
      case 6:
        return [const Color(0xFF00FF88), const Color(0xFF00FF66)]; // ネオングリーン
      case 7:
        return [const Color(0xFFFF3366), const Color(0xFFFF1155)]; // ネオンレッド
      case 8:
        return [const Color(0xFF4D4DFF), const Color(0xFF3333FF)]; // ネオンブルー
      case 9:
        return [const Color(0xFFFF00FF), const Color(0xFFDD00DD)]; // ネオンマゼンタ
      default:
        return [const Color(0xFF333333), const Color(0xFF222222)];
    }
  }

  // テキストカラーを取得
  Color getTileTextColor(int number, TileSkin skin) {
    // ネオンスキンは常に白文字
    if (skin == TileSkin.neon) {
      return Colors.white;
    }
    return number == 1 ? Colors.orange[800]! : Colors.white;
  }
}

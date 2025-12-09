import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal() {
    _initializePlayers();
  }

  // 定数
  static const int _maxSimultaneousSounds = 5;
  static const double _tapVolume = 0.2;
  static const double _mergeVolume = 0.3;
  static const double _comboVolume = 0.4;
  static const double _gameOverVolume = 0.4;
  static const double _buttonVolume = 0.2;

  // ローカルアセットの効果音
  static const String _tapSound = 'assets/sounds/tap.mp3';
  static const String _mergeSound = 'assets/sounds/merge.mp3';
  static const String _comboSound = 'assets/sounds/combo.mp3';
  static const String _gameOverSound = 'assets/sounds/gameover.mp3';
  static const String _buttonSound = 'assets/sounds/button.mp3';

  // 状態管理
  bool _soundEnabled = true;
  bool _initialized = false;
  int _currentTapPlayerIndex = 0;
  int _currentMergePlayerIndex = 0;
  int _currentButtonPlayerIndex = 0;

  // オーディオプレイヤー
  final List<AudioPlayer> _tapPlayers = [];
  final List<AudioPlayer> _mergePlayers = [];
  final List<AudioPlayer> _buttonPlayers = [];
  AudioPlayer? _comboPlayer;
  AudioPlayer? _gameOverPlayer;

  Future<void> _initializePlayers() async {
    if (_initialized) return;

    try {
      // AudioSessionの設定（バックグラウンド再生を有効化）
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      ));

      // タップ音用のプレイヤーを複数作成
      for (int i = 0; i < _maxSimultaneousSounds; i++) {
        final player = AudioPlayer();
        await player.setAsset(_tapSound);
        await player.setVolume(_tapVolume);
        _tapPlayers.add(player);
      }

      // マージ音用のプレイヤーを複数作成
      for (int i = 0; i < _maxSimultaneousSounds; i++) {
        final player = AudioPlayer();
        await player.setAsset(_mergeSound);
        await player.setVolume(_mergeVolume);
        _mergePlayers.add(player);
      }

      // ボタン音用のプレイヤーを複数作成
      for (int i = 0; i < _maxSimultaneousSounds; i++) {
        final player = AudioPlayer();
        await player.setAsset(_buttonSound);
        await player.setVolume(_buttonVolume);
        _buttonPlayers.add(player);
      }

      // コンボとゲームオーバーは1つずつ
      _comboPlayer = AudioPlayer();
      _gameOverPlayer = AudioPlayer();

      await _comboPlayer?.setAsset(_comboSound);
      await _gameOverPlayer?.setAsset(_gameOverSound);

      await _comboPlayer?.setVolume(_comboVolume);
      await _gameOverPlayer?.setVolume(_gameOverVolume);

      _initialized = true;
    } catch (e) {
      // 初期化エラーを無視
    }
  }

  void playTap() {
    if (!_soundEnabled || !_initialized || _tapPlayers.isEmpty) return;
    try {
      // 触覚フィードバック
      HapticFeedback.lightImpact();

      // ラウンドロビン方式で次のプレイヤーを使用
      final player = _tapPlayers[_currentTapPlayerIndex];
      _currentTapPlayerIndex = (_currentTapPlayerIndex + 1) % _tapPlayers.length;

      // 即座に再生
      player.seek(Duration.zero);
      player.play();
    } catch (e) {
      // エラーを無視
    }
  }

  void playMerge(int level) {
    if (!_soundEnabled || !_initialized || _mergePlayers.isEmpty) return;
    try {
      // ラウンドロビン方式で次のプレイヤーを使用
      final player = _mergePlayers[_currentMergePlayerIndex];
      _currentMergePlayerIndex = (_currentMergePlayerIndex + 1) % _mergePlayers.length;

      // 即座に再生
      player.seek(Duration.zero);
      player.play();
    } catch (e) {
      // エラーを無視
    }
  }

  Future<void> playCombo(int combo) async {
    if (!_soundEnabled || !_initialized || _comboPlayer == null) return;
    try {
      // 再生中なら即座に停止してリセット
      await _comboPlayer!.stop();
      await _comboPlayer!.seek(Duration.zero);
      await _comboPlayer!.play();
    } catch (e) {
      // エラーを無視
    }
  }

  Future<void> playGameOver() async {
    if (!_soundEnabled || !_initialized || _gameOverPlayer == null) return;
    try {
      // 再生中なら即座に停止してリセット
      await _gameOverPlayer!.stop();
      await _gameOverPlayer!.seek(Duration.zero);
      await _gameOverPlayer!.play();
    } catch (e) {
      // エラーを無視
    }
  }

  void playButton() {
    if (!_soundEnabled || !_initialized || _buttonPlayers.isEmpty) return;
    try {
      // 触覚フィードバック（ボタンは少し強め）
      HapticFeedback.mediumImpact();

      // ラウンドロビン方式で次のプレイヤーを使用
      final player = _buttonPlayers[_currentButtonPlayerIndex];
      _currentButtonPlayerIndex = (_currentButtonPlayerIndex + 1) % _buttonPlayers.length;

      // 即座に再生
      player.seek(Duration.zero);
      player.play();
    } catch (e) {
      // エラーを無視
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
  }

  bool get isSoundEnabled => _soundEnabled;

  void dispose() {
    for (var player in _tapPlayers) {
      player.dispose();
    }
    for (var player in _mergePlayers) {
      player.dispose();
    }
    for (var player in _buttonPlayers) {
      player.dispose();
    }
    _comboPlayer?.dispose();
    _gameOverPlayer?.dispose();
  }
}

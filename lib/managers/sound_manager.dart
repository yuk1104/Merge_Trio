import 'package:just_audio/just_audio.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal() {
    _initializePlayers();
  }

  bool _soundEnabled = true;
  final List<AudioPlayer> _tapPlayers = [];
  final List<AudioPlayer> _mergePlayers = [];
  AudioPlayer? _comboPlayer;
  AudioPlayer? _gameOverPlayer;
  bool _initialized = false;
  static const int _maxSimultaneousSounds = 5; // 同時再生可能な音の数
  int _currentTapPlayerIndex = 0; // タップ音用のインデックス
  int _currentMergePlayerIndex = 0; // マージ音用のインデックス

  // フリーの効果音URL（Mixkit - https://mixkit.co/）
  static const String _tapSound = 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3';
  static const String _mergeSound = 'https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3';
  static const String _comboSound = 'https://assets.mixkit.co/active_storage/sfx/2018/2018-preview.mp3';
  static const String _gameOverSound = 'https://assets.mixkit.co/active_storage/sfx/2001/2001-preview.mp3';

  Future<void> _initializePlayers() async {
    if (_initialized) return;

    try {
      // タップ音用のプレイヤーを複数作成
      for (int i = 0; i < _maxSimultaneousSounds; i++) {
        final player = AudioPlayer();
        await player.setUrl(_tapSound);
        await player.setVolume(0.2);
        _tapPlayers.add(player);
      }

      // マージ音用のプレイヤーを複数作成
      for (int i = 0; i < _maxSimultaneousSounds; i++) {
        final player = AudioPlayer();
        await player.setUrl(_mergeSound);
        await player.setVolume(0.3);
        _mergePlayers.add(player);
      }

      // コンボとゲームオーバーは1つずつ
      _comboPlayer = AudioPlayer();
      _gameOverPlayer = AudioPlayer();

      await _comboPlayer?.setUrl(_comboSound);
      await _gameOverPlayer?.setUrl(_gameOverSound);

      await _comboPlayer?.setVolume(0.4);
      await _gameOverPlayer?.setVolume(0.4);

      _initialized = true;
    } catch (e) {
      // 初期化エラーを無視
    }
  }

  void playTap() {
    if (!_soundEnabled || !_initialized || _tapPlayers.isEmpty) return;
    try {
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
    _comboPlayer?.dispose();
    _gameOverPlayer?.dispose();
  }
}

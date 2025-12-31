import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/game_model.dart';
import '../models/particle.dart';
import '../managers/sound_manager.dart';
import '../managers/ad_manager.dart';
import '../managers/score_manager.dart';
import '../managers/player_manager.dart';
import '../managers/skin_manager.dart';
import '../screens/ranking_screen.dart';
import '../screens/home_screen.dart';
import '../screens/rules_screen.dart';
import '../widgets/game_colors.dart';
import '../widgets/game_tile.dart';
import '../widgets/particle_painter.dart';
import '../main.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameModel game;
  int? lastMergedRow;
  int? lastMergedCol;
  int lastAddedScore = 0;
  bool showScorePopup = false;
  bool showCombo = false;
  late AnimationController _tileAnimationController;
  late AnimationController _scorePopupController;
  late AnimationController _comboController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  final SoundManager _soundManager = SoundManager();
  List<Particle> particles = [];
  Timer? _particleTimer;
  String _playerName = '';
  Set<String> _glowingTiles = {}; // 光っているタイル "row,col"

  // スコアに応じた色を取得
  Color _getScoreColor(int score) {
    if (score >= 300) {
      return const Color(0xFFFFC738); // ゴールデンイエロー
    } else if (score >= 200) {
      return const Color(0xFF9D4EDD); // ビビッドパープル
    } else if (score >= 100) {
      return const Color(0xFFFF6B9D); // コーラルピンク
    } else {
      return Colors.white; // デフォルト（白）
    }
  }

  // スコアに応じたグラデーションシャドウを取得
  List<Shadow> _getScoreShadows(int score) {
    if (score >= 300) {
      // ゴールデングロー（暖かい金色）
      return [
        const Shadow(
          color: Color(0xFFFFC738),
          blurRadius: 20,
        ),
        const Shadow(
          color: Color(0xFFFFAA00),
          blurRadius: 12,
        ),
        const Shadow(
          color: Color(0xFFFF8800),
          blurRadius: 6,
        ),
      ];
    } else if (score >= 200) {
      // パープルグロー（神秘的）
      return [
        const Shadow(
          color: Color(0xFF9D4EDD),
          blurRadius: 20,
        ),
        const Shadow(
          color: Color(0xFFC77DFF),
          blurRadius: 12,
        ),
        const Shadow(
          color: Color(0xFFE0AAFF),
          blurRadius: 6,
        ),
      ];
    } else if (score >= 100) {
      // コーラルピンクグロー（柔らかく華やか）
      return [
        const Shadow(
          color: Color(0xFFFF6B9D),
          blurRadius: 20,
        ),
        const Shadow(
          color: Color(0xFFFF8FAB),
          blurRadius: 12,
        ),
        const Shadow(
          color: Color(0xFFFFB3C6),
          blurRadius: 6,
        ),
      ];
    } else {
      // デフォルト（ピンクのグロー）
      return [
        const Shadow(
          color: GameColors.accentPink,
          blurRadius: 10,
        ),
      ];
    }
  }

  // スコアに応じた枠のグラデーション背景を取得
  Gradient? _getScoreBoxGradient(int score) {
    if (score >= 300) {
      // 金色のグラデーション
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFA500),
          Color(0xFFFF8C00),
        ],
      );
    } else if (score >= 200) {
      // 銀色のグラデーション
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF5F5F5),
          Color(0xFFC0C0C0),
          Color(0xFFA8A8A8),
        ],
      );
    } else if (score >= 100) {
      // 赤色のグラデーション
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF6B6B),
          Color(0xFFFF5252),
          Color(0xFFFF1744),
        ],
      );
    }
    return null; // デフォルトは単色
  }

  // スコアに応じた枠線の色を取得
  Color _getScoreBorderColor(int score) {
    if (score >= 300) {
      return const Color(0xFFFFD700); // 金色
    } else if (score >= 200) {
      return const Color(0xFFF0F0F0); // 銀色
    } else if (score >= 100) {
      return const Color(0xFFFF5252); // 赤色
    } else {
      return Colors.white.withValues(alpha: 0.2); // デフォルト
    }
  }

  // スコアに応じたボックスシャドウを取得
  List<BoxShadow> _getScoreBoxShadow(int score) {
    if (score >= 300) {
      // 金色の強い光
      return [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
          blurRadius: 20,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: const Color(0xFFFFA500).withValues(alpha: 0.4),
          blurRadius: 30,
          spreadRadius: 2,
        ),
      ];
    } else if (score >= 200) {
      // 銀色の光
      return [
        BoxShadow(
          color: const Color(0xFFC0C0C0).withValues(alpha: 0.6),
          blurRadius: 20,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: const Color(0xFFE8E8E8).withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 2,
        ),
      ];
    } else if (score >= 100) {
      // 赤色の光
      return [
        BoxShadow(
          color: Colors.red.withValues(alpha: 0.5),
          blurRadius: 20,
          spreadRadius: 3,
        ),
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 1,
        ),
      ];
    } else {
      // デフォルト（軽い影のみ）
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    game = GameModel();
    _loadPlayerName();

    // ゲーム開始音を再生
    _soundManager.playGameStart();

    // プレイ回数をカウント
    SkinManager().incrementPlayCount();

    // SkinManagerの変更をリッスン
    SkinManager().addListener(_onSkinChanged);

    _tileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scorePopupController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _comboController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..addListener(_updateParticles);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _particleController.forward(from: 0);
      }
    });
  }

  void _onSkinChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SkinManager().removeListener(_onSkinChanged);
    _tileAnimationController.dispose();
    _scorePopupController.dispose();
    _comboController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _particleTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPlayerName() async {
    final name = await PlayerManager().getPlayerName();
    if (mounted) {
      setState(() {
        _playerName = name ?? '';
      });
    }
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (var particle in particles) {
        particle.update();
      }
      particles.removeWhere((p) => p.isDead);
    });
  }

  void _createParticles(double x, double y, Color color) {
    final random = Random();
    for (int i = 0; i < 20; i++) {
      particles.add(Particle(
        x: x,
        y: y,
        vx: (random.nextDouble() - 0.5) * 8,
        vy: (random.nextDouble() - 0.5) * 8 - 4,
        size: random.nextDouble() * 6 + 2,
        color: color,
      ));
    }
  }

  void _placeTile(int row, int col) async {
    if (game.board[row][col] != 0) return;

    _soundManager.playTap();

    // マージが発生するかチェック
    final willMerge = game.checkWillMerge(row, col);

    if (willMerge && game.pendingMergePositions.length >= 3) {
      // 光るタイルを設定
      setState(() {
        _glowingTiles = game.pendingMergePositions
            .map((pos) => '${pos.row},${pos.col}')
            .toSet();
      });

      // 光るアニメーション
      _glowController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 200));

      // 光を消す
      setState(() {
        _glowingTiles.clear();
      });
    }

    final scoreBefore = game.score;

    setState(() {
      game.placeTile(row, col);
    });

    lastMergedRow = row;
    lastMergedCol = col;
    lastAddedScore = game.score - scoreBefore;

    if (lastAddedScore > 0) {
      _createParticles(
        (col + 0.5) * 80.0,
        (row + 0.5) * 80.0,
        GameColors.getTileGlowColor(game.board[row][col]),
      );
      _soundManager.playMerge(game.board[row][col]);
    }

    if (lastAddedScore > 0) {
      setState(() {
        showScorePopup = true;
      });
      _scorePopupController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          showScorePopup = false;
        });
      }
    }

    if (game.comboCount > 1) {
      _soundManager.playCombo(game.comboCount);
      setState(() {
        showCombo = true;
      });
      _comboController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          showCombo = false;
        });
      }
    }

    _tileAnimationController.forward(from: 0);

    if (game.isGameOver) {
      _soundManager.playGameOver();
      await Future.delayed(const Duration(milliseconds: 500));
      _showGameOverDialog();
    }
  }

  void _restartGame() {
    // 広告を表示してからゲームをリスタート
    AdManager().showInterstitialAd(
      onAdClosed: () {
        setState(() {
          game.reset();
          showScorePopup = false;
          showCombo = false;
          particles.clear();
        });
      },
    );
  }

  void _showGameOverDialog() async {
    // ベストスコアをチェックして更新
    final isNewRecord = await ScoreManager().checkAndUpdateBestScore(game.score);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => _GameOverDialog(
        score: game.score,
        isNewRecord: isNewRecord,
        onRestart: _restartGame,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: GameColors.accentPink.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: const Text(
          '設定',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(
                  'プレイヤー名: $_playerName',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // 音量調整
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        '音量',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(_soundManager.volume * 100).round()}%',
                        style: const TextStyle(
                          color: GameColors.accentPinkLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: GameColors.accentPinkLight,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                      thumbColor: GameColors.accentPinkLight,
                      overlayColor: GameColors.accentPinkLight.withValues(alpha: 0.2),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _soundManager.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setDialogState(() {
                          _soundManager.setVolume(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _soundManager.playButton();
                  Navigator.pop(context); // 設定ダイアログを閉じる
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RulesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                label: const Text(
                  'ルール説明',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _soundManager.playButton();
                  Navigator.pop(context); // ダイアログを閉じる
                  // 広告を表示してからゲームをリスタート
                  AdManager().showInterstitialAd(
                    onAdClosed: () {
                      setState(() {
                        game = GameModel(); // 新しいゲームを作成
                        lastMergedRow = null;
                        lastMergedCol = null;
                        lastAddedScore = 0;
                        showScorePopup = false;
                        showCombo = false;
                        particles.clear();
                      });
                    },
                  );
                },
                icon: const Icon(Icons.replay, color: Colors.white, size: 20),
                label: const Text(
                  'リプレイ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _soundManager.playButton();
                  Navigator.pop(context); // ダイアログを閉じる
                  // 広告を表示してからホームに戻る
                  AdManager().showInterstitialAd(
                    onAdClosed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.home, color: Colors.white, size: 20),
                label: const Text(
                  'ホームに戻る',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _soundManager.playButton();
                  _confirmDeleteAccount();
                },
                icon: const Icon(Icons.delete_forever, color: Colors.white70, size: 20),
                label: const Text(
                  'アカウントを削除',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '閉じる',
              style: TextStyle(
                color: GameColors.accentPink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    Navigator.pop(context); // 設定ダイアログを閉じる
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              '確認',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'アカウントを削除すると、すべてのデータ（スコア、ランキング）が完全に削除されます。\n\nこの操作は元に戻せません。本当に削除しますか？',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'キャンセル',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteAccount(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '削除する',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() async {
    Navigator.pop(context); // 確認ダイアログを閉じる

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: GameColors.accentPink,
        ),
      ),
    );

    // アカウント削除を実行
    final success = await PlayerManager().deleteAccount();

    if (!mounted) return;

    Navigator.pop(context); // ローディングを閉じる

    if (success) {
      // 削除成功 - アプリを再起動（名前登録画面に戻る）
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const InitialScreen()),
        (route) => false,
      );
    } else {
      // 削除失敗
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アカウントの削除に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  _buildScoreDisplay(),
                  Expanded(child: _buildGameBoard()),
                  _buildNextTiles(),
                  // バナー広告の表示
                  _buildBannerAd(),
                ],
              ),
              // パーティクルエフェクト（タップを無視）
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: ParticlePainter(particles),
                  ),
                ),
              ),
              // コンボ表示（タップを無視）
              if (showCombo)
                IgnorePointer(
                  child: _buildComboDisplay(),
                ),
              // スコアポップアップ（タップを無視）
              if (showScorePopup) _buildScorePopup(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerAd() {
    final adManager = AdManager();
    // 常にバナー広告の標準的な高さを確保（50px）
    // これにより、広告読み込み時のレイアウトシフトを防ぐ
    const double bannerHeight = 50.0;

    return SizedBox(
      height: bannerHeight,
      child: adManager.isBannerAdLoaded && adManager.bannerAd != null
          ? Container(
              alignment: Alignment.center,
              child: AdWidget(ad: adManager.bannerAd!),
            )
          : const SizedBox.shrink(), // 広告未読み込み時は空のスペースを確保
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  _soundManager.playButton();
                  _showSettingsDialog();
                },
              ),
              const Expanded(
                child: Text(
                  'MERGE TRIO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: GameColors.accentPink,
                        blurRadius: 15,
                      ),
                      Shadow(
                        color: GameColors.accentPink,
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.leaderboard,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  _soundManager.playButton();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RankingScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_playerName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Player: $_playerName',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 現在のスコア
            Column(
              children: [
                const Text(
                  'SCORE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${game.score}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _getScoreColor(game.score),
                    shadows: _getScoreShadows(game.score),
                  ),
                ),
              ],
            ),
            // ベストスコア
            Column(
              children: [
                const Text(
                  'BEST',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ScoreManager().bestScore}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.8),
                    shadows: const [
                      Shadow(
                        color: GameColors.accentPinkLight,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 利用可能なスペース全体を使って盤面サイズを計算
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // 盤面のサイズを決定（小さい方を基準にする）
        final boardSize = maxWidth < maxHeight ? maxWidth : maxHeight;

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: game.boardSize,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: game.boardSize * game.boardSize,
                itemBuilder: (context, index) {
                  final row = index ~/ game.boardSize;
                  final col = index % game.boardSize;
                  final number = game.board[row][col];
                  final isGlowing = _glowingTiles.contains('$row,$col');

                  return GameTile(
                    number: number,
                    isAnimating: row == lastMergedRow && col == lastMergedCol,
                    animationController: _tileAnimationController,
                    onTap: () => _placeTile(row, col),
                    isGlowing: isGlowing,
                    glowController: _glowController,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextTiles() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNextTile(game.currentNumber, '現在', isLarge: true),
          const SizedBox(width: 16),
          _buildNextTile(game.nextNumber, '次', isLarge: false),
          const SizedBox(width: 16),
          // 入れ替えボタン
          _buildSwapButton(),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    final isEnabled = game.swapsRemaining > 0;

    return Container(
      decoration: BoxDecoration(
        color: isEnabled
            ? GameColors.accentPink.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? GameColors.accentPink.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _swapNumbers : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: isEnabled ? GameColors.accentPinkLight : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${game.swapsRemaining}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? GameColors.accentPinkLight : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _swapNumbers() {
    if (game.swapNumbers()) {
      _soundManager.playTap();
      setState(() {});
    }
  }

  Widget _buildNextTile(int number, String label, {required bool isLarge}) {
    final size = isLarge ? 65.0 : 55.0;
    final skinManager = SkinManager();
    final gradient = skinManager.getTileGradient(number, skinManager.currentSkin);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w900,
                color: skinManager.getTileTextColor(number, skinManager.currentSkin),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: isLarge ? 0.9 : 0.6),
            fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildComboDisplay() {
    return Center(
      child: AnimatedBuilder(
        animation: _comboController,
        builder: (context, child) {
          final opacity = 1.0 - _comboController.value;
          final scale = 1.0 + _comboController.value * 0.5;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [GameColors.accentPink, GameColors.accentPinkLight],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.accentPink.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  'COMBO ×${game.comboCount}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScorePopup() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _scorePopupController,
          builder: (context, child) {
            final offset = _scorePopupController.value * 80;
            final opacity = 1.0 - _scorePopupController.value;
            return Opacity(
              opacity: opacity,
              child: Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, -offset),
                  child: Text(
                    '+$lastAddedScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: GameColors.accentPink,
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameOverDialog extends StatefulWidget {
  final int score;
  final bool isNewRecord;
  final VoidCallback onRestart;

  const _GameOverDialog({
    required this.score,
    required this.isNewRecord,
    required this.onRestart,
  });

  @override
  State<_GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<_GameOverDialog> {
  void _viewRankings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RankingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: GameColors.accentPink.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [GameColors.accentPink, GameColors.accentPinkLight],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: GameColors.accentPink.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isNewRecord ? 'NEW RECORD!' : 'GAME OVER',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: widget.isNewRecord ? GameColors.accentPinkLight : Colors.white,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'SCORE',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white60,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.score}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: GameColors.accentPink,
            shadows: [
              Shadow(
                color: GameColors.accentPink,
                blurRadius: 20,
              ),
            ],
          ),
        ),
        if (widget.isNewRecord) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GameColors.accentPinkLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GameColors.accentPinkLight.withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.celebration, color: GameColors.accentPinkLight),
                SizedBox(width: 8),
                Text(
                  '🎉 新記録達成！',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GameColors.accentPinkLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ランキングに自動送信されました',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
            ),
          ),
        ],
        if (!widget.isNewRecord && ScoreManager().bestScore > 0) ...[
          const SizedBox(height: 8),
          Text(
            'BEST: ${ScoreManager().bestScore}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _viewRankings,
          style: OutlinedButton.styleFrom(
            foregroundColor: GameColors.accentPinkLight,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: GameColors.accentPinkLight, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'ランキングを見る',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onRestart();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.accentPink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'RESTART',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ];
  }
}

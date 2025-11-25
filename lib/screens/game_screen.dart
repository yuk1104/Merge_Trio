import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/game_model.dart';
import '../models/particle.dart';
import '../managers/sound_manager.dart';
import '../managers/ad_manager.dart';
import '../managers/score_manager.dart';
import '../widgets/game_colors.dart';
import '../widgets/game_tile.dart';
import '../widgets/particle_painter.dart';

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
  final SoundManager _soundManager = SoundManager();
  List<Particle> particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    game = GameModel();
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

    _particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _particleController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _tileAnimationController.dispose();
    _scorePopupController.dispose();
    _comboController.dispose();
    _particleController.dispose();
    _particleTimer?.cancel();
    super.dispose();
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

    final scoreBefore = game.score;

    setState(() {
      game.placeTile(row, col);
    });

    lastMergedRow = row;
    lastMergedCol = col;
    lastAddedScore = game.score - scoreBefore;

    if (lastAddedScore > 0) {
      final gradient = GameColors.getTileGradient(game.board[row][col]);
      _createParticles(
        (col + 0.5) * 80.0,
        (row + 0.5) * 80.0,
        gradient.first,
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: GameColors.accentPink.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: Column(
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
              isNewRecord ? 'NEW RECORD!' : 'GAME OVER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isNewRecord ? GameColors.accentPinkLight : Colors.white,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        content: Column(
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
              '${game.score}',
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
            if (isNewRecord) ...[
              const SizedBox(height: 8),
              const Text(
                '🎉 新記録達成！',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameColors.accentPinkLight,
                ),
              ),
            ],
            if (!isNewRecord && ScoreManager().bestScore > 0) ...[
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
        ),
        actions: [
          // リスタートボタン（広告表示付き）
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
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
        ],
      ),
    );
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
    if (adManager.isBannerAdLoaded && adManager.bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: adManager.bannerAd!.size.width.toDouble(),
        height: adManager.bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: adManager.bannerAd!),
      );
    }
    return const SizedBox(height: 20);
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: const Text(
          'MERGE TRIO',
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
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
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
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: GameColors.accentPink,
                      blurRadius: 10,
                    ),
                  ],
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
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: game.boardSize,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: game.boardSize * game.boardSize,
            itemBuilder: (context, index) {
              final row = index ~/ game.boardSize;
              final col = index % game.boardSize;
              final number = game.board[row][col];

              return GameTile(
                number: number,
                isAnimating: row == lastMergedRow && col == lastMergedCol,
                animationController: _tileAnimationController,
                onTap: () => _placeTile(row, col),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNextTiles() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNextTile(game.currentNumber, '現在', isLarge: true),
              const SizedBox(width: 24),
              _buildNextTile(game.nextNumber, '次', isLarge: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextTile(int number, String label, {required bool isLarge}) {
    final size = isLarge ? 80.0 : 65.0;
    final gradient = GameColors.getTileGradient(number);

    return Column(
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w900,
                color: GameColors.getTileTextColor(number),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: isLarge ? 1.0 : 0.6),
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

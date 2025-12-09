import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';
import '../managers/sound_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final SoundManager _soundManager = SoundManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイトル
              const Spacer(flex: 2),
              const Text(
                'MERGE TRIO',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black45,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),

              // ボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // Playボタン
                    _buildMenuButton(
                      context: context,
                      label: 'PLAY',
                      icon: Icons.play_arrow_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                      ),
                      onPressed: () {
                        _soundManager.playButton();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const GameScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ランキングボタン
                    _buildMenuButton(
                      context: context,
                      label: 'ランキング',
                      icon: Icons.leaderboard_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC9ADFF), Color(0xFFD4B9FF)],
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
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

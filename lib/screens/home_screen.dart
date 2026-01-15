import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';
import 'board_size_selection_screen.dart';
import 'unlock_pastel_dialog.dart';
import '../managers/sound_manager.dart';
import '../managers/skin_manager.dart';
import '../widgets/game_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BoardSizeSelectionScreen(),
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
                    const SizedBox(height: 20),

                    // スキン変更ボタン
                    _buildMenuButton(
                      context: context,
                      label: 'スキン変更',
                      icon: Icons.palette_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FC3F7), Color(0xFF6DD5FA)],
                      ),
                      onPressed: () {
                        _soundManager.playButton();
                        _showSkinDialog();
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

  void _showSkinDialog() {
    final skinManager = SkinManager();
    final currentSkin = skinManager.currentSkin;

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
          'タイルスキン',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'お好みのスキンを選択してください',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...TileSkin.values.map((skin) {
                final isSelected = skin == currentSkin;
                final isLocked = skin == TileSkin.pastel && !skinManager.isPastelUnlocked;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      _soundManager.playButton();

                      // パステルがロックされている場合はアンロックダイアログを表示
                      if (isLocked) {
                        Navigator.pop(context); // スキン選択ダイアログを閉じる
                        showDialog(
                          context: context,
                          builder: (context) => const UnlockPastelDialog(),
                        );
                        return;
                      }

                      await skinManager.setSkin(skin);
                      if (context.mounted) {
                        Navigator.pop(context);
                        // ホーム画面を更新
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isSelected ? 0.15 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? GameColors.accentPink
                              : Colors.white.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      skinManager.getSkinName(skin),
                                      style: TextStyle(
                                        color: isSelected
                                            ? GameColors.accentPink
                                            : isLocked
                                                ? Colors.white60
                                                : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isLocked) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.lock,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [1, 2, 3].map((number) {
                                    final colors = skinManager.getTileGradient(number, skin);
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: colors,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$number',
                                          style: TextStyle(
                                            color: skinManager.getTileTextColor(number, skin),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: GameColors.accentPink,
                              size: 28,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _soundManager.playButton();
              Navigator.pop(context);
            },
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

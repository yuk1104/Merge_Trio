import 'package:flutter/material.dart';
import '../managers/skin_manager.dart';
import '../managers/score_manager.dart';
import '../managers/sound_manager.dart';
import '../managers/language_manager.dart';
import '../widgets/game_colors.dart';

class UnlockNeonDialog extends StatefulWidget {
  const UnlockNeonDialog({super.key});

  @override
  State<UnlockNeonDialog> createState() => _UnlockNeonDialogState();
}

class _UnlockNeonDialogState extends State<UnlockNeonDialog> {
  static final SoundManager _soundManager = SoundManager();
  final SkinManager _skinManager = SkinManager();
  final ScoreManager _scoreManager = ScoreManager();

  @override
  void initState() {
    super.initState();
    _skinManager.addListener(_onSkinChanged);
  }

  @override
  void dispose() {
    _skinManager.removeListener(_onSkinChanged);
    super.dispose();
  }

  void _onSkinChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bestScore4x4 = _scoreManager.getBestScore(4);
    final required = SkinManager.requiredBestScore;
    final isUnlocked = _skinManager.isNeonUnlocked;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: GameColors.accentPink.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            isUnlocked ? Icons.lock_open : Icons.lock,
            color: isUnlocked ? Colors.green : GameColors.accentPink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUnlocked
                  ? LanguageManager().translate('neon_unlocked')
                  : '${LanguageManager().translate('neon')}${LanguageManager().translate('unlock_pastel')}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUnlocked) ...[
              Text(
                LanguageManager().translate('unlock_neon_description'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // スコアの進捗
              _buildProgressItem(
                icon: Icons.star,
                title: LanguageManager().translate('your_best_score'),
                progress: bestScore4x4,
                goal: required,
                isCompleted: isUnlocked,
              ),
            ] else ...[
              Text(
                '${LanguageManager().translate('neon')}スキンが使えるようになりました!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // ネオンカラーのプレビュー
              Row(
                children: [1, 2, 3, 4, 5, 6, 7].map((number) {
                  final colors = _skinManager.getTileGradient(number, TileSkin.neon);
                  return Expanded(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: colors[0].withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _soundManager.playButton();
            Navigator.pop(context);
          },
          child: Text(
            LanguageManager().translate('close'),
            style: const TextStyle(
              color: GameColors.accentPink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String title,
    required int progress,
    required int goal,
    required bool isCompleted,
  }) {
    final percentage = (progress / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isCompleted ? Colors.green : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$progress/$goal',
                style: TextStyle(
                  color: isCompleted ? Colors.green : GameColors.accentPink,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isCompleted)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : GameColors.accentPink,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

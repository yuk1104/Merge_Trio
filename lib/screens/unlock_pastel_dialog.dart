import 'package:flutter/material.dart';
import '../managers/skin_manager.dart';
import '../managers/ad_manager.dart';
import '../managers/sound_manager.dart';
import '../widgets/game_colors.dart';

class UnlockPastelDialog extends StatefulWidget {
  const UnlockPastelDialog({super.key});

  @override
  State<UnlockPastelDialog> createState() => _UnlockPastelDialogState();
}

class _UnlockPastelDialogState extends State<UnlockPastelDialog> {
  static final SoundManager _soundManager = SoundManager();
  bool _isLoadingAd = false;

  @override
  Widget build(BuildContext context) {
    final skinManager = SkinManager();
    final playProgress = skinManager.playCount;
    final adProgress = skinManager.rewardAdCount;
    final playGoal = SkinManager.requiredPlayCount;
    final adGoal = SkinManager.requiredRewardAdCount;

    final playCompleted = playProgress >= playGoal;
    final adCompleted = adProgress >= adGoal;
    final isUnlocked = skinManager.isPastelUnlocked;

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
              isUnlocked ? 'パステルスキン 解放済み!' : 'パステルスキンを解放',
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
              const Text(
                '以下の条件を達成してパステルスキンを解放しよう!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // プレイ回数の進捗
              _buildProgressItem(
                icon: Icons.videogame_asset,
                title: 'ゲームをプレイ',
                progress: playProgress,
                goal: playGoal,
                isCompleted: playCompleted,
              ),
              const SizedBox(height: 16),

              // リワード広告の進捗
              _buildProgressItem(
                icon: Icons.play_circle_outline,
                title: '広告を視聴',
                progress: adProgress,
                goal: adGoal,
                isCompleted: adCompleted,
              ),
              const SizedBox(height: 20),

              // リワード広告視聴ボタン
              if (!adCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingAd ? null : _showRewardedAd,
                    icon: _isLoadingAd
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_circle_fill, color: Colors.white),
                    label: Text(
                      _isLoadingAd ? '広告を読み込み中...' : '広告を視聴してアンロック',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.accentPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              const Text(
                'パステルスキンが使えるようになりました!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // パステルカラーのプレビュー
              Row(
                children: [1, 2, 3, 4, 5, 6, 7].map((number) {
                  final colors = skinManager.getTileGradient(number, TileSkin.pastel);
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
          child: const Text(
            '閉じる',
            style: TextStyle(
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

  Future<void> _showRewardedAd() async {
    if (!AdManager().isRewardedAdLoaded) {
      _showMessage('広告の準備ができていません。しばらくしてからもう一度お試しください。');
      return;
    }

    setState(() {
      _isLoadingAd = true;
    });

    await AdManager().showRewardedAd(onComplete: (bool rewarded) {
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
        });

        if (rewarded) {
          SkinManager().incrementRewardAdCount();
          _showMessage('広告視聴ありがとうございます!');
        } else {
          _showMessage('広告が最後まで視聴されませんでした。');
        }
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'game_colors.dart';
import '../managers/skin_manager.dart';

class GameTile extends StatelessWidget {
  final int number;
  final bool isAnimating;
  final AnimationController animationController;
  final VoidCallback onTap;
  final bool isGlowing;
  final AnimationController glowController;
  final int boardSize;

  const GameTile({
    super.key,
    required this.number,
    required this.isAnimating,
    required this.animationController,
    required this.onTap,
    this.isGlowing = false,
    required this.glowController,
    this.boardSize = 4,
  });

  @override
  Widget build(BuildContext context) {
    final skinManager = SkinManager();
    final currentSkin = skinManager.currentSkin;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([animationController, glowController]),
        builder: (context, child) {
          final scale = isAnimating
              ? 1.0 + (animationController.value * 0.15 * (1 - animationController.value) * 4)
              : 1.0;

          final tileColors = skinManager.getTileGradient(number, currentSkin);

          // グローエフェクトの強度を計算
          final glowIntensity = isGlowing ? glowController.value : 0.0;

          // ネオンスキンかどうか
          final isNeonSkin = currentSkin == TileSkin.neon;

          // ネオンスキン用のボックスシャドウ（より強力なグロー）
          List<BoxShadow> getBoxShadows() {
            if (number == 0) return [];

            if (isNeonSkin) {
              // ネオンスキン: 複数のグローレイヤーで本物のネオンライトを再現
              final baseColor = tileColors[0];
              return [
                // 最も外側の柔らかいグロー
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.4 + (glowIntensity * 0.3)),
                  blurRadius: 40 + (glowIntensity * 30),
                  spreadRadius: 8 + (glowIntensity * 12),
                ),
                // 中間の明るいグロー
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.6 + (glowIntensity * 0.4)),
                  blurRadius: 25 + (glowIntensity * 20),
                  spreadRadius: 4 + (glowIntensity * 8),
                ),
                // 最も内側の強いグロー
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.8),
                  blurRadius: 12 + (glowIntensity * 10),
                  spreadRadius: 1 + (glowIntensity * 3),
                ),
                // 深さを出すための影
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ];
            } else {
              // クラシック・パステルスキン: 元のグロー
              return [
                BoxShadow(
                  color: (isGlowing ? Colors.white : GameColors.getTileGlowColor(number))
                      .withValues(
                    alpha: 0.6 + (glowIntensity * 0.4),
                  ),
                  blurRadius: 15 + (glowIntensity * 20),
                  spreadRadius: 2 + (glowIntensity * 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ];
            }
          }

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                gradient: number == 0
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: tileColors,
                      ),
                color: number == 0 ? Colors.white.withValues(alpha: 0.05) : null,
                borderRadius: BorderRadius.circular(16),
                border: number == 0
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      )
                    : (isNeonSkin && number != 0
                        ? Border.all(
                            color: tileColors[0].withValues(alpha: 0.6),
                            width: 2,
                          )
                        : null),
                boxShadow: getBoxShadows(),
              ),
              child: Center(
                child: number != 0
                    ? Text(
                        '$number',
                        style: TextStyle(
                          fontSize: boardSize == 4 ? 36 : 24,
                          fontWeight: FontWeight.w900,
                          color: skinManager.getTileTextColor(number, currentSkin),
                          shadows: isNeonSkin
                              ? [
                                  // ネオンスキン: テキストにもグロー効果
                                  Shadow(
                                    color: tileColors[0].withValues(alpha: 0.8),
                                    blurRadius: 15,
                                  ),
                                  Shadow(
                                    color: tileColors[0].withValues(alpha: 0.6),
                                    blurRadius: 25,
                                  ),
                                  const Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : const [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

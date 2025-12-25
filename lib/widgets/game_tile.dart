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

  const GameTile({
    super.key,
    required this.number,
    required this.isAnimating,
    required this.animationController,
    required this.onTap,
    this.isGlowing = false,
    required this.glowController,
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
                    : null,
                boxShadow: number != 0
                    ? [
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
                      ]
                    : null,
              ),
              child: Center(
                child: number != 0
                    ? Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: skinManager.getTileTextColor(number, currentSkin),
                          shadows: const [
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

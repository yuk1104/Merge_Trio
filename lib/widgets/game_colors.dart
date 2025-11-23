import 'package:flutter/material.dart';

class GameColors {
  static List<Color> getTileGradient(int number) {
    switch (number) {
      case 1:
        return [const Color(0xFFFFF9C4), const Color(0xFFFFF59D)];
      case 2:
        return [const Color(0xFFFFCC80), const Color(0xFFFFB74D)];
      case 3:
        return [const Color(0xFFFF9800), const Color(0xFFFB8C00)];
      case 4:
        return [const Color(0xFFEF5350), const Color(0xFFE53935)];
      case 5:
        return [const Color(0xFFAB47BC), const Color(0xFF8E24AA)];
      case 6:
        return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      case 7:
        return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      default:
        return [const Color(0xFFEEEEEE), const Color(0xFFE0E0E0)];
    }
  }

  static Color getTileTextColor(int number) {
    return number == 1 ? Colors.orange[800]! : Colors.white;
  }

  static Color getTileGlowColor(int number) {
    final gradient = getTileGradient(number);
    return gradient.first;
  }

  // ダークテーマの背景グラデーション
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16213E),
      Color(0xFF0F3460),
    ],
  );

  // アクセントカラー
  static const accentPink = Color(0xFFE94560);
  static const accentPinkLight = Color(0xFFFF6B9D);
}

import 'package:flutter/material.dart';
import '../models/particle.dart';

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.life)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );

      // グロー効果
      final glowPaint = Paint()
        ..color = particle.color.withValues(alpha: particle.life * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 2,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

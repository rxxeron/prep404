import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Dedicated CustomPainter for the gamified admission hiking mountain trail
class MilestonePathPainter extends CustomPainter {
  final List<Offset> points;
  final int completedIndex;
  final Color activeColorStart;
  final Color activeColorEnd;
  final Color trackColor;

  MilestonePathPainter({
    required this.points,
    required this.completedIndex,
    required this.activeColorStart,
    required this.activeColorEnd,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // 1. Draw inactive background track
    final inactivePaint = Paint()
      ..color = trackColor
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fullPath = Path();
    fullPath.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      fullPath.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
    }

    canvas.drawPath(fullPath, inactivePaint);

    // 2. Draw active completed glowing track
    if (completedIndex >= 0 && points.isNotEmpty) {
      final activeTarget = math.min(completedIndex, points.length - 1);
      if (activeTarget > 0) {
        final activePath = Path();
        activePath.moveTo(points[0].dx, points[0].dy);

        for (int i = 0; i < activeTarget; i++) {
          final p0 = points[i];
          final p1 = points[i + 1];
          final midY = (p0.dy + p1.dy) / 2;
          activePath.cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);
        }

        // Outer glow
        final glowPaint = Paint()
          ..shader = ui.Gradient.linear(
            points.first,
            points[activeTarget],
            [
              activeColorStart.withValues(alpha: 0.4),
              activeColorEnd.withValues(alpha: 0.4)
            ],
          )
          ..strokeWidth = 14.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(activePath, glowPaint);

        // Solid core active line
        final activePaint = Paint()
          ..shader = ui.Gradient.linear(
            points.first,
            points[activeTarget],
            [activeColorStart, activeColorEnd],
          )
          ..strokeWidth = 7.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(activePath, activePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MilestonePathPainter oldDelegate) {
    return oldDelegate.completedIndex != completedIndex ||
        oldDelegate.points.length != points.length;
  }
}

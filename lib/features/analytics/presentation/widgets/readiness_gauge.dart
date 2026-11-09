import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Radial animated gauge displaying candidate readiness probability for competitive exams (BCS / Medical / Varsity).
class ReadinessGauge extends StatefulWidget {
  final double score; // 0.0 to 100.0
  final double targetCutoff; // e.g. 62.0 for BCS prelim
  final String examTitle;

  const ReadinessGauge({
    super.key,
    required this.score,
    this.targetCutoff = 62.0,
    this.examTitle = '46th BCS Preliminary',
  });

  @override
  State<ReadinessGauge> createState() => _ReadinessGaugeState();
}

class _ReadinessGaugeState extends State<ReadinessGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (_controller.value < 1) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ReadinessGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation =
          Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      if (_reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (widget.score <= 0) return 'Take tests to assess admission readiness';
    if (widget.score >= 75) return 'Safe Zone (High Probability)';
    if (widget.score >= widget.targetCutoff) {
      return 'Competitive (Above Cut-off)';
    }
    return 'Action Needed (At Risk)';
  }

  Color get _statusColor {
    if (widget.score >= 75) return const Color(0xFF10B981); // Emerald
    if (widget.score >= widget.targetCutoff) {
      return const Color(0xFF542747); // Deep Plum
    }
    return const Color(0xFFF59E0B); // Amber warning
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admission Readiness Index',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: 240,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GaugePainter(
                    score: _animation.value,
                    cutoff: widget.targetCutoff,
                    accentColor: _statusColor,
                    trackColor: colors.surfaceElevated,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _animation.value.toStringAsFixed(1),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                '%',
                                style: TextStyle(
                                  color: Color(0xFFFF7A36),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Estimated Cut-off: ${widget.targetCutoff.toInt()}%',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.examTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final double cutoff;
  final Color accentColor;
  final Color trackColor;

  _GaugePainter({
    required this.score,
    required this.cutoff,
    required this.accentColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;

    const startAngle = pi * 0.85;
    const sweepTotal = pi * 1.30;

    // Track Background Arc
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Active Gradient Arc
    final activeAngle = sweepTotal * (score.clamp(0, 100) / 100.0);
    if (activeAngle > 0) {
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepTotal,
        colors: [
          const Color(0xFFFF7A36), // Indigo
          accentColor,
        ],
      );

      final activePaint = Paint()
        ..shader = gradient
            .createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeAngle,
        false,
        activePaint,
      );
    }

    // Cut-off Marker Line
    final cutoffAngle = startAngle + sweepTotal * (cutoff / 100.0);
    final innerCutoff = Offset(
      center.dx + (radius - 12) * cos(cutoffAngle),
      center.dy + (radius - 12) * sin(cutoffAngle),
    );
    final outerCutoff = Offset(
      center.dx + (radius + 12) * cos(cutoffAngle),
      center.dy + (radius + 12) * sin(cutoffAngle),
    );

    final cutoffPaint = Paint()
      ..color = const Color(0xFFEF4444) // Red indicator line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(innerCutoff, outerCutoff, cutoffPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.cutoff != cutoff ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}

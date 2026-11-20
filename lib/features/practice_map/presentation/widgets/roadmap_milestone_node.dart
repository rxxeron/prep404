import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admission_plan_service.dart';

class RoadmapMilestoneNode extends StatelessWidget {
  final int index;
  final AdmissionPlanItem item;
  final Offset nodeCenter;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final double screenWidth;
  final double tokenRadius;
  final Animation<double> pulseAnimation;
  final Color pillarColor;
  final String pillarBadgeLabel;
  final IconData pillarIcon;
  final Color colorTangerine;
  final Color colorSunshine;
  final Color colorCardPlum;
  final Color colorPlumBorder;
  final Color colorCream;
  final VoidCallback onTap;

  const RoadmapMilestoneNode({
    super.key,
    required this.index,
    required this.item,
    required this.nodeCenter,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.screenWidth,
    required this.tokenRadius,
    required this.pulseAnimation,
    required this.pillarColor,
    required this.pillarBadgeLabel,
    required this.pillarIcon,
    required this.colorTangerine,
    required this.colorSunshine,
    required this.colorCardPlum,
    required this.colorPlumBorder,
    required this.colorCream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLeftAligned = nodeCenter.dx < (screenWidth / 2);
    final cardWidth = screenWidth * 0.44;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // The Interactive Circular Milestone Token
        Positioned(
          left: nodeCenter.dx - tokenRadius,
          top: nodeCenter.dy - tokenRadius,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: _buildToken(),
          ),
        ),

        // Floating "START" Tag on Active Milestone
        if (isCurrent)
          Positioned(
            left: nodeCenter.dx - 28,
            top: nodeCenter.dy - tokenRadius - 20,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                final bounce = math.sin(pulseAnimation.value * math.pi) * 3;
                return Transform.translate(
                  offset: Offset(0, -bounce),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorTangerine,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: colorTangerine.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'START 🎯',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF542747),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Attached Milestone Information Card
        Positioned(
          top: nodeCenter.dy - 34,
          left: isLeftAligned ? nodeCenter.dx + tokenRadius + 12 : null,
          right: !isLeftAligned ? screenWidth - (nodeCenter.dx - tokenRadius - 12) : null,
          width: cardWidth,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? (isDark ? const Color(0xFF2E1026) : const Color(0xFFFFF3E6))
                    : colorCardPlum,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? colorTangerine.withValues(alpha: 0.8)
                      : (isCompleted ? colorSunshine.withValues(alpha: 0.5) : colorPlumBorder),
                  width: isCurrent ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: pillarColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pillarBadgeLabel,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: pillarColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.displayDay.isNotEmpty ? item.displayDay : 'Day ${item.dayNumber}',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorCream.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _cleanMilestoneTitle(item.title),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? colorCream.withValues(alpha: 0.6) : colorCream,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 11, color: colorSunshine),
                      const SizedBox(width: 2),
                      Text(
                        '+${item.totalQuestions * 10} XP',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: colorSunshine,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.durationMinutes}m',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: colorCream.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _cleanMilestoneTitle(String raw) {
    final cleaned = raw
        .replaceFirst(
          RegExp(r'^[A-Z]+\s+(?:ENGINEERING|BUSINESS|PHARMACY|ARCHITECTURE|LAW|ARTS|GENERAL)\s+Official Model Test\s*[-–:]\s*', caseSensitive: false),
          '',
        )
        .replaceFirst(
          RegExp(r'^[A-Z]+\s+Real Admission Test\s*[-–:]\s*', caseSensitive: false),
          '',
        )
        .trim();
    return cleaned.isNotEmpty ? cleaned : raw;
  }

  Widget _buildToken() {
    if (isCompleted) {
      return Container(
        width: tokenRadius * 2,
        height: tokenRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [const Color(0xFFFFF1A8), colorSunshine, const Color(0xFFF59E0B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colorSunshine.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Color(0xFF381432), size: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, size: 10, color: Color(0xFF381432)),
                Icon(Icons.star_rounded, size: 10, color: Color(0xFF381432)),
                Icon(Icons.star_rounded, size: 10, color: Color(0xFF381432)),
              ],
            ),
          ],
        ),
      );
    }

    if (isCurrent) {
      return AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          final scale = 1.0 + (pulseAnimation.value * 0.08);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: tokenRadius * 2,
              height: tokenRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF8E4D),
                    colorTangerine,
                    const Color(0xFFE65100),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: colorTangerine.withValues(alpha: 0.65),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  pillarIcon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          );
        },
      );
    }

    // Locked: Frosted Plum Token with Lock & Level Number
    return Container(
      width: tokenRadius * 2,
      height: tokenRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorCardPlum,
        border: Border.all(color: colorPlumBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              color: colorCream.withValues(alpha: 0.35), size: 18),
          const SizedBox(height: 1),
          Text(
            '$index',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorCream.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

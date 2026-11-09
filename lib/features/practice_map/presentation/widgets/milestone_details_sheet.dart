import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admission_plan_service.dart';

/// Modal bottom sheet showing milestone challenge details and start trigger
class MilestoneDetailsSheet extends StatelessWidget {
  final AdmissionPlanItem item;
  final int milestoneNumber;
  final bool isLocked;
  final bool isCompleted;
  final Color pillarColor;
  final String pillarBadgeLabel;
  final Color colorCardPlum;
  final Color colorPlumBorder;
  final Color colorCream;
  final Color colorTangerine;
  final Color colorSunshine;
  final VoidCallback onStart;

  const MilestoneDetailsSheet({
    super.key,
    required this.item,
    required this.milestoneNumber,
    required this.isLocked,
    required this.isCompleted,
    required this.pillarColor,
    required this.pillarBadgeLabel,
    required this.colorCardPlum,
    required this.colorPlumBorder,
    required this.colorCream,
    required this.colorTangerine,
    required this.colorSunshine,
    required this.onStart,
  });

  Widget _buildSpecBox(IconData icon, String value, String label, [Color? iconColor]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: colorCardPlum,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorPlumBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: iconColor ?? colorCream.withValues(alpha: 0.7)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colorCream,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: colorCream.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorCardPlum,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colorPlumBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorCream.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillarColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: pillarColor, width: 1.0),
                ),
                child: Text(
                  'MILESTONE #$milestoneNumber • $pillarBadgeLabel',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: pillarColor,
                  ),
                ),
              ),
              const Spacer(),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFFA7F3D0)),
                      SizedBox(width: 4),
                      Text(
                        'CLEARED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA7F3D0),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colorCream,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.subtitle,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorCream.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildSpecBox(Icons.quiz_rounded, '${item.totalQuestions}', 'Questions'),
              const SizedBox(width: 10),
              _buildSpecBox(Icons.timer_rounded, '${item.durationMinutes}m', 'Time Limit'),
              const SizedBox(width: 10),
              _buildSpecBox(Icons.bolt_rounded, '+${item.totalQuestions * 10}', 'XP Reward', colorSunshine),
              const SizedBox(width: 10),
              _buildSpecBox(Icons.warning_amber_rounded, '-${item.negativeMark}', 'Penalty', const Color(0xFFFF5722)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onStart();
              },
              icon: Icon(
                isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(
                isCompleted ? 'Replay Challenge 🔄' : 'Start Milestone Challenge 🚀',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorTangerine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

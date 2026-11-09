import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admission_plan_service.dart';

class RoadmapSummitGate extends StatelessWidget {
  final AdmissionJourneyData journey;
  final int completedCount;
  final int totalCount;
  final Color colorSunshine;
  final Color colorTangerine;
  final Color colorCream;
  final ValueChanged<AdmissionPlanItem> onConquerFinal;

  const RoadmapSummitGate({
    super.key,
    required this.journey,
    required this.completedCount,
    required this.totalCount,
    required this.colorSunshine,
    required this.colorTangerine,
    required this.colorCream,
    required this.onConquerFinal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConquered = completedCount >= totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConquered
              ? (isDark
                  ? [const Color(0xFF4A1E40), const Color(0xFF2E1026)]
                  : [const Color(0xFFFFF3E6), Colors.white])
              : (isDark
                  ? [const Color(0xFF32122B), const Color(0xFF1E0A1A)]
                  : [Colors.white, const Color(0xFFFFF3E6)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isConquered ? colorSunshine : colorTangerine.withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConquered ? colorSunshine : colorTangerine).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFFF1A8), colorSunshine, const Color(0xFFE5A820)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorSunshine.withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events_rounded, color: Color(0xFF381432), size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VARSITY ADMISSION CONQUEST',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: colorSunshine,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${journey.universityCode} Admission Exam Day',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorCream,
                      ),
                    ),
                    Text(
                      'Target: 85%+ Clearance Benchmark • ${journey.daysRemaining} Days Left',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorCream.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (journey.allPlanItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onConquerFinal(journey.allPlanItems.last),
                icon: const Icon(Icons.military_tech_rounded, size: 18),
                label: Text(
                  'Conquer Final Simulation Mock 🎯',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorTangerine,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

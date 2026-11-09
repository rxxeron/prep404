import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admission_plan_service.dart';

class HorizonPickerSheet extends StatelessWidget {
  final AdmissionJourneyData journey;
  final PlanHorizon selectedHorizon;
  final ValueChanged<PlanHorizon> onHorizonSelected;

  const HorizonPickerSheet({
    super.key,
    required this.journey,
    required this.selectedHorizon,
    required this.onHorizonSelected,
  });

  static const colorCardPlum = Color(0xFF2E1329);
  static const colorPlumBorder = Color(0xFF542747);
  static const colorTangerine = Color(0xFFFF7A36);
  static const colorSunshine = Color(0xFFFFD166);
  static const colorCream = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorCardPlum,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: colorPlumBorder, width: 1.5),
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
          const SizedBox(height: 16),
          Text(
            'Select Preparation Timeline Plan',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorCream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-selected based on ${journey.daysRemaining} days left until exam',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorCream.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          _buildHorizonOption(
            context,
            PlanHorizon.tenDays,
            '10-Day Speed Sprint (20 Milestones)',
            '🔥 High-Intensity Blitz • 2.0 Tests/Day (Crunch formula speed & error spotting)',
            journey.autoHorizonDays == 10,
          ),
          const SizedBox(height: 10),
          _buildHorizonOption(
            context,
            PlanHorizon.fifteenDays,
            '15-Day High-Yield (16 Milestones)',
            '⚡ Accelerated Push • ~1.1 Tests/Day (Daily testing with simulation mocks)',
            journey.autoHorizonDays == 15,
          ),
          const SizedBox(height: 10),
          _buildHorizonOption(
            context,
            PlanHorizon.thirtyDays,
            '30-Day Benchmark (12 Milestones)',
            '🌿 Relaxed & Balanced • 1 Test / 2-3 Days (Dedicated study rest buffers)',
            journey.autoHorizonDays == 30,
          ),
          const SizedBox(height: 10),
          _buildHorizonOption(
            context,
            PlanHorizon.twoMonths,
            '2-Month Foundation (12 Milestones)',
            '📚 Deep Foundation • 1 Test / 5 Days (Full theory reading buffers)',
            journey.autoHorizonDays == 60,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHorizonOption(
    BuildContext ctx,
    PlanHorizon horizon,
    String title,
    String desc,
    bool isAutoRecommended,
  ) {
    final isSelected = selectedHorizon == horizon;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(ctx).pop();
        onHorizonSelected(horizon);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorTangerine.withValues(alpha: 0.2)
              : const Color(0xFF1B0718),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorTangerine : colorPlumBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? colorTangerine
                  : colorCream.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorCream,
                        ),
                      ),
                      if (isAutoRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorSunshine.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: colorSunshine,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorCream.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

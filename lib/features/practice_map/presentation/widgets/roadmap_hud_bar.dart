import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/admission_plan_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/widgets/university_logo.dart';

class RoadmapTopSelectorBar extends StatelessWidget {
  final AdmissionJourneyData journey;
  final String activeUniversityKey;
  final String activeTrack;
  final String Function(String) formatTrackName;
  final VoidCallback onTapUniversity;
  final VoidCallback onTapHorizon;
  final Color colorCardPlum;
  final Color colorPlumBorder;
  final Color colorCream;
  final Color colorTangerine;
  final Color colorSunshine;

  const RoadmapTopSelectorBar({
    super.key,
    required this.journey,
    required this.activeUniversityKey,
    required this.activeTrack,
    required this.formatTrackName,
    required this.onTapUniversity,
    required this.onTapHorizon,
    required this.colorCardPlum,
    required this.colorPlumBorder,
    required this.colorCream,
    required this.colorTangerine,
    required this.colorSunshine,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Target University & Track Capsule
          Expanded(
            child: InkWell(
              onTap: onTapUniversity,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colorCardPlum,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorPlumBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    UniversityLogo(
                      universityKey: activeUniversityKey,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            journey.universityCode,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colorCream,
                            ),
                          ),
                          Text(
                            formatTrackName(activeTrack),
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorTangerine,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: colorSunshine, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Timeline Horizon Capsule
          InkWell(
            onTap: onTapHorizon,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorCardPlum,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorTangerine.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: colorSunshine, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${journey.horizonDays}D Plan',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorCream,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: colorCream, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoadmapGamifiedHudCard extends StatelessWidget {
  final AdmissionJourneyData journey;
  final List<AdmissionPlanItem> allItems;
  final int completedCount;
  final int progressPercent;
  final Color colorCardPlum;
  final Color colorPlumBorder;
  final Color colorCream;
  final Color colorTangerine;
  final Color colorSunshine;

  const RoadmapGamifiedHudCard({
    super.key,
    required this.journey,
    required this.allItems,
    required this.completedCount,
    required this.progressPercent,
    required this.colorCardPlum,
    required this.colorPlumBorder,
    required this.colorCream,
    required this.colorTangerine,
    required this.colorSunshine,
  });

  @override
  Widget build(BuildContext context) {
    final earnedXp = completedCount * 150;
    final earnedStars = completedCount * 3;
    final totalStars = allItems.length * 3;
    final streakDays = CacheService().loadProfile()?.studyStreakDays ?? 0;
    final streakLabel = streakDays > 0 ? '$streakDays-Day Streak' : '0-Day Streak';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorCardPlum,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorPlumBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBadge(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF5722),
                  label: streakLabel,
                ),
                _buildBadge(
                  icon: Icons.bolt_rounded,
                  iconColor: colorSunshine,
                  label: '$earnedXp XP',
                ),
                _buildBadge(
                  icon: Icons.star_rounded,
                  iconColor: colorSunshine,
                  label: '$earnedStars/$totalStars',
                ),
                _buildBadge(
                  icon: journey.horizonDays <= 10
                      ? Icons.local_fire_department_rounded
                      : (journey.horizonDays <= 15 ? Icons.bolt_rounded : Icons.spa_rounded),
                  iconColor: journey.horizonDays <= 10
                      ? const Color(0xFFFF5722)
                      : (journey.horizonDays <= 15 ? colorSunshine : const Color(0xFF10B981)),
                  label: journey.dailyFrequency,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: allItems.isEmpty ? 0 : completedCount / allItems.length,
                      minHeight: 6,
                      backgroundColor: colorPlumBorder.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(colorTangerine),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$completedCount/${allItems.length} Milestones ($progressPercent%)',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorCream.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colorCream,
          ),
        ),
      ],
    );
  }
}

class RoadmapPillarFilterBar extends StatelessWidget {
  final List<AdmissionPlanItem> allItems;
  final PlanPreparationPillar selectedPillar;
  final ValueChanged<PlanPreparationPillar> onSelectPillar;
  final Color colorTangerine;
  final Color colorCardPlum;
  final Color colorCream;
  final Color colorPlumBorder;

  const RoadmapPillarFilterBar({
    super.key,
    required this.allItems,
    required this.selectedPillar,
    required this.onSelectPillar,
    required this.colorTangerine,
    required this.colorCardPlum,
    required this.colorCream,
    required this.colorPlumBorder,
  });

  @override
  Widget build(BuildContext context) {
    final topicCount = allItems.where((i) => i.pillar == PlanPreparationPillar.topicWise).length;
    final subjectCount = allItems.where((i) => i.pillar == PlanPreparationPillar.subjectWise).length;
    final sectionCount = allItems.where((i) => i.pillar == PlanPreparationPillar.sectionWise).length;
    final mockCount = allItems.where((i) => i.pillar == PlanPreparationPillar.overall).length;

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPill(PlanPreparationPillar.all, 'All Quests (${allItems.length})'),
          const SizedBox(width: 8),
          _buildPill(PlanPreparationPillar.topicWise, '🔬 Topic ($topicCount)'),
          const SizedBox(width: 8),
          _buildPill(PlanPreparationPillar.subjectWise, '📚 Subject ($subjectCount)'),
          const SizedBox(width: 8),
          _buildPill(PlanPreparationPillar.sectionWise, '📑 Section ($sectionCount)'),
          const SizedBox(width: 8),
          _buildPill(PlanPreparationPillar.overall, '🎯 Mock ($mockCount)'),
        ],
      ),
    );
  }

  Widget _buildPill(PlanPreparationPillar pillar, String label) {
    final isSelected = selectedPillar == pillar;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelectPillar(pillar);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorTangerine : colorCardPlum,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorCream : colorPlumBorder,
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : colorCream.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

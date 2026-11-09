import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/widgets/university_logo.dart';

class DashboardUniversityCarousel extends StatelessWidget {
  final List<UniversityRoadmapData> universities;
  final String activeKey;
  final ValueChanged<String> onSelectUniversity;
  final VoidCallback? onEditTargets;
  final VoidCallback? onViewRoadmap;

  const DashboardUniversityCarousel({
    super.key,
    required this.universities,
    required this.activeKey,
    required this.onSelectUniversity,
    this.onEditTargets,
    this.onViewRoadmap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'YOUR TARGET UNIVERSITIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: colors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                if (onEditTargets != null)
                  InkWell(
                    onTap: onEditTargets,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Edit Targets',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.tangerine,
                        ),
                      ),
                    ),
                  ),
                if (onEditTargets != null) const SizedBox(width: 8),
                if (onViewRoadmap != null)
                  InkWell(
                    onTap: onViewRoadmap,
                    child: Text(
                      'View Roadmap →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.tangerine,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: universities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final uni = universities[idx];
              final isSelected = uni.key == activeKey;

              return InkWell(
                onTap: () => onSelectUniversity(uni.key),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 190),
                  curve: Curves.easeOutCubic,
                  width: MediaQuery.of(context).size.width * 0.76,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.deepPlum : colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? colors.tangerine : colors.border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : colors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                UniversityLogo(
                                  universityKey: uni.key,
                                  logoUrl: uni.logoUrl,
                                  size: 34,
                                  isCircle: false,
                                  showShadow: !isSelected,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        uni.fullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected ? Colors.white : colors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${uni.sections.length} Section Patterns',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected
                                              ? const Color(0xFFFFF3E6)
                                              : colors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '✓',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Admission Readiness',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? const Color(0xFFFFF3E6)
                                      : colors.textSecondary,
                                ),
                              ),
                              Text(
                                '${uni.summitScore}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? colors.accentSunshine : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: uni.summitScore / 100.0,
                              minHeight: 5,
                              backgroundColor: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : colors.borderSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSelected ? colors.accentSunshine : colors.tangerine,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : colors.borderSubtle,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${uni.totalMarksInfo} • ${uni.durationInfo}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? const Color(0xFFE2E8F0) : colors.textSecondary,
                              ),
                            ),
                            Text(
                              'Details →',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : colors.tangerine,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/utils/app_sorter.dart';
import '../../../../core/widgets/university_logo.dart';
import '../../../../core/theme/app_theme.dart';

class DailyExamUniversityFilter extends StatelessWidget {
  final List<UniversityRoadmapData> roadmaps;
  final String activeKey;
  final ValueChanged<String> onSelectUniversity;

  const DailyExamUniversityFilter({
    super.key,
    required this.roadmaps,
    required this.activeKey,
    required this.onSelectUniversity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sorted = List<UniversityRoadmapData>.from(roadmaps)
      ..sort((a, b) {
        if (a.key == activeKey) return -1;
        if (b.key == activeKey) return 1;
        return AppSorter.compareAZ09(a.shortCode, b.shortCode);
      });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sorted.map((r) {
          final isSelected = r.key == activeKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelectUniversity(r.key),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF7A36) : colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF7A36) : colors.border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7A36).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    UniversityLogo(
                      universityKey: r.key,
                      logoUrl: r.logoUrl,
                      size: 20,
                      isCircle: true,
                      showShadow: false,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      r.shortCode,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.bold,
                        color: isSelected ? Colors.white : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

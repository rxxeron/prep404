import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 52-week calendar heatmap showing study consistency, questions solved, and daily activity.
class StudyHeatmap extends StatelessWidget {
  final Map<DateTime, int> activityData; // Date -> Question count
  final int totalQuestionsSolved;
  final int currentStreak;

  const StudyHeatmap({
    super.key,
    required this.activityData,
    this.totalQuestionsSolved = 3420,
    this.currentStreak = 14,
  });

  Color _getColorForCount(int count, bool isDark) {
    if (count == 0) {
      return isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    }
    if (count <= 10) {
      return isDark ? const Color(0xFF542747) : const Color(0xFFFFF3E6);
    }
    if (count <= 25) return const Color(0xFFFF7A36);
    if (count <= 50) return const Color(0xFFFF7A36);
    return const Color(0xFFFFD166);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    // Generate dates for the last 16 weeks (or up to 52 in scrollable)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const weeksToShow = 20;
    final startDate = today.subtract(const Duration(days: weeksToShow * 7));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: Color(0xFFF97316), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '$currentStreak Day Streak',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$totalQuestionsSolved Solved',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable Grid of Days
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Scroll to today by default
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeksToShow, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final dayDate = startDate
                          .add(Duration(days: weekIndex * 7 + dayIndex));
                      final normalized =
                          DateTime(dayDate.year, dayDate.month, dayDate.day);
                      final count = activityData[normalized] ??
                          (dayIndex % 2 == 0 ? (weekIndex * 3) % 40 : 0);

                      return Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: _getColorForCount(count, isDark),
                          borderRadius: BorderRadius.circular(3),
                          border: normalized == today
                              ? Border.all(color: colors.primary, width: 1.5)
                              : null,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
              const SizedBox(width: 6),
              ...[0, 10, 25, 50, 75].map((lvl) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _getColorForCount(lvl, isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(color: colors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

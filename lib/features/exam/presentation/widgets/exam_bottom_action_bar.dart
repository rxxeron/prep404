import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum ExamFilterType {
  all,
  answered,
  unanswered,
}

class ExamFilterBar extends StatelessWidget {
  final int totalCount;
  final int answeredCount;
  final ExamFilterType currentFilter;
  final ValueChanged<ExamFilterType> onFilterChanged;

  const ExamFilterBar({
    super.key,
    required this.totalCount,
    required this.answeredCount,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unAnsweredCount = totalCount - answeredCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildChip(
            colors: colors,
            label: 'All ($totalCount)',
            isSelected: currentFilter == ExamFilterType.all,
            activeColor: colors.primary,
            onTap: () => onFilterChanged(ExamFilterType.all),
          ),
          _buildChip(
            colors: colors,
            label: 'Answered ($answeredCount)',
            isSelected: currentFilter == ExamFilterType.answered,
            activeColor: colors.accentEmerald,
            onTap: () => onFilterChanged(ExamFilterType.answered),
          ),
          _buildChip(
            colors: colors,
            label: 'Unanswered ($unAnsweredCount)',
            isSelected: currentFilter == ExamFilterType.unanswered,
            activeColor: colors.dangerRed,
            onTap: () => onFilterChanged(ExamFilterType.unanswered),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required AppColors colors,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : colors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? activeColor : colors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExamBottomActionBar extends StatelessWidget {
  final int totalCount;
  final int answeredCount;
  final VoidCallback onSubmit;

  const ExamBottomActionBar({
    super.key,
    required this.totalCount,
    required this.answeredCount,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = totalCount - answeredCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: colors.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Answered: $answeredCount/$totalCount',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Remaining: $remaining',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Submit Exam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentEmerald,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

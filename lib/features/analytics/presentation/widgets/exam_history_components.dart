import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MistakeVaultBanner extends StatelessWidget {
  final int mistakeCount;
  final int skippedCount;
  final VoidCallback? onPracticeMistakes;

  const MistakeVaultBanner({
    super.key,
    required this.mistakeCount,
    this.skippedCount = 0,
    this.onPracticeMistakes,
  });

  @override
  Widget build(BuildContext context) {
    final totalDeficit = mistakeCount + skippedCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('📕', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mistake & Skipped Vault',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9F1239),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalDeficit == 0
                      ? 'No active mistakes or skips. Keep taking exams to track weak points.'
                      : '$mistakeCount mistakes • $skippedCount skipped • Tap to optimize weak topics',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBE123C),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: totalDeficit > 0 ? onPracticeMistakes : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFDA4AF),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              totalDeficit > 0 ? 'Open Vault' : 'Empty (0)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsMetricCard extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const AnalyticsMetricCard({
    super.key,
    required this.colors,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class AnalyticsLegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final AppColors colors;

  const AnalyticsLegendItem({
    super.key,
    required this.label,
    required this.value,
    required this.dotColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

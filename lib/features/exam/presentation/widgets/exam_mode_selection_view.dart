import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum ExamRunnerMode {
  inApp,
  omrBubble,
}

class ExamModeSelectionView extends StatelessWidget {
  final String examTitle;
  final int questionCount;
  final double negativeMark;
  final int durationMinutes;
  final VoidCallback onExit;
  final ValueChanged<ExamRunnerMode> onSelectMode;

  const ExamModeSelectionView({
    super.key,
    required this.examTitle,
    required this.questionCount,
    required this.negativeMark,
    required this.durationMinutes,
    required this.onExit,
    required this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        title: Text(
          'Select Exam Mode',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: onExit,
        ),
        actions: const [
          ThemeToggleIconButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                boxShadow: colors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.accentEmerald),
                        ),
                        child: Text(
                          'LIVE EXAM',
                          style: TextStyle(
                            color: colors.accentEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$questionCount Questions • -$negativeMark Neg',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    examTitle,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Standard syllabus: Higher Math, Quant Math, English, Physics & Analytical Reasoning.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose how you want to take this test:',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Mode Option 1: In-App Digital Mode
            _ModeCard(
              colors: colors,
              icon: Icons.touch_app_rounded,
              iconColor: colors.primary,
              title: 'In-App Digital Exam',
              timeBadge: '$durationMinutes Mins',
              description:
                  'Continuous vertical scroll. Tap options to select answers instantly. Ideal for quick mobile practice.',
              onTap: () => onSelectMode(ExamRunnerMode.inApp),
            ),
            const SizedBox(height: 16),

            // Mode Option 2: OMR Bubble Sheet Simulation
            _ModeCard(
              colors: colors,
              icon: Icons.radio_button_checked_rounded,
              iconColor: colors.accentAmber,
              title: 'OMR Bubble Sheet Simulation',
              timeBadge: '${durationMinutes + 15} Mins (+15m)',
              description:
                  'Authentic pencil bubble sheet simulator. Extra 15 mins buffer time granted to simulate offline private university test halls.',
              highlightBadge: 'RECOMMENDED FOR BRACU & NSU',
              onTap: () => onSelectMode(ExamRunnerMode.omrBubble),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeBadge;
  final String description;
  final String? highlightBadge;
  final VoidCallback onTap;

  const _ModeCard({
    required this.colors,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeBadge,
    required this.description,
    this.highlightBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: colors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlightBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.accentAmber),
                ),
                child: Text(
                  highlightBadge!,
                  style: TextStyle(
                    color: colors.accentAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Official Duration: $timeBadge',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

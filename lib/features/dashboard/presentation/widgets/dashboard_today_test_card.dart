import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/widgets/university_logo.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../../core/animations/sensor_parallax_card.dart';
import '../../../../core/widgets/prep_bounce_tap.dart';

class DashboardTodayTestCard extends StatelessWidget {
  final UniversityRoadmapData currentUni;
  final Future<Map<String, dynamic>?>? dailyTestFuture;
  final String remainingTimeLeft;
  final void Function({
    required String title,
    required String slug,
    required int durationMinutes,
    required double negativeMark,
  }) onLaunchExam;

  const DashboardTodayTestCard({
    super.key,
    required this.currentUni,
    required this.dailyTestFuture,
    required this.remainingTimeLeft,
    required this.onLaunchExam,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FutureBuilder<Map<String, dynamic>?>(
      future: dailyTestFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PrepSkeleton(
            width: double.infinity,
            height: 140,
            radius: 20,
          );
        }
        final isLoaded = snapshot.hasData && snapshot.data != null;
        if (!isLoaded) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy_rounded,
                    color: colors.textMuted, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Live Test Scheduled for ${currentUni.shortCode}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Check Daily Test Arena for past drills and practice tests.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final testData = snapshot.data!;
        final examTitle =
            testData['title']?.toString() ?? currentUni.dailyExamTitle;
        final totalQuestions =
            (testData['totalQuestions'] as num?)?.toInt() ?? 0;
        final durationMins =
            (testData['durationMinutes'] as num?)?.toInt() ?? 0;
        final totalMarks =
            (testData['totalMarks'] as num?)?.toDouble() ?? 0.0;
        final negativeMark =
            (testData['negativeMark'] as num?)?.toDouble() ?? 0.0;
        final enrolledCount =
            (testData['enrolledCount'] as num?)?.toInt() ?? 0;
        final examId =
            testData['examId']?.toString() ?? 'daily-${currentUni.key}-live';

        final negText = negativeMark == 0
            ? 'No Negative Marking'
            : 'Penalty: -${negativeMark.toStringAsFixed(2)}';

        final nowHour = DateTime.now().hour;
        final isLiveWindow = nowHour >= 10 && nowHour < 22;
        final enrolledText = !isLiveWindow
            ? (nowHour < 10
                ? '⏳ Opens Today at 10:00 AM for ${currentUni.shortCode}'
                : '🔒 Today\'s Live Slot Closed for ${currentUni.shortCode}')
            : (enrolledCount > 0
                ? '🔥 $enrolledCount ${currentUni.shortCode} Candidates Submitted'
                : '🔥 Today\'s Live Slot Open for ${currentUni.shortCode}');

        return SensorParallaxCard(
          maxTiltAngle: 0.10,
          depthTranslation: 6.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.cream, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: colors.deepPlum.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          UniversityLogo(
                            universityKey: currentUni.key,
                            logoUrl: currentUni.logoUrl,
                            size: 20,
                            isCircle: false,
                            showShadow: false,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              "${currentUni.shortCode} Today's Test (10 AM - 10 PM)",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⏱️ $remainingTimeLeft',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  examTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalQuestions Questions • $durationMins Mins • ${totalMarks.toStringAsFixed(0)} Marks • $negText',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        enrolledText,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrepBounceTap(
                      onTap: () => onLaunchExam(
                        title: examTitle,
                        slug: examId,
                        durationMinutes: durationMins,
                        negativeMark: negativeMark,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => onLaunchExam(
                          title: examTitle,
                          slug: examId,
                          durationMinutes: durationMins,
                          negativeMark: negativeMark,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text(
                          'Start Exam',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.tangerine,
                          foregroundColor: colors.deepPlum,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

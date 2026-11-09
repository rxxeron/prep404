import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/widgets/university_logo.dart';
import '../../../../core/widgets/prep_skeleton.dart';

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
        final testData = snapshot.data;

        final examTitle = isLoaded
            ? (testData!['title']?.toString() ?? currentUni.dailyExamTitle)
            : currentUni.dailyExamTitle;
        final totalQuestions =
            isLoaded ? (testData!['totalQuestions'] as num?)?.toInt() ?? 25 : 25;
        final durationMins =
            isLoaded ? (testData!['durationMinutes'] as num?)?.toInt() ?? 30 : 30;
        final totalMarks =
            isLoaded ? (testData!['totalMarks'] as num?)?.toDouble() ?? 50.0 : 50.0;
        final negativeMark =
            isLoaded ? (testData!['negativeMark'] as num?)?.toDouble() ?? 0.25 : 0.25;
        final enrolledCount =
            isLoaded ? (testData!['enrolledCount'] as num?)?.toInt() ?? 0 : 0;
        final examId = isLoaded
            ? (testData!['examId']?.toString() ?? 'daily-${currentUni.key}-live')
            : 'daily-${currentUni.key}-live';

        final negText = negativeMark == 0
            ? 'No Negative Marking'
            : 'Penalty: -${negativeMark.toStringAsFixed(2)}';

        final enrolledText = enrolledCount > 0
            ? '🔥 $enrolledCount ${currentUni.shortCode} Candidates Submitted'
            : '🔥 Today\'s Live Slot Open for ${currentUni.shortCode}';

        return Container(
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
                  ElevatedButton.icon(
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

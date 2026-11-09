import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/university_roadmap_service.dart';

class PastExamsView extends StatelessWidget {
  final Future<List<Map<String, dynamic>>>? pastExamsFuture;
  final UniversityRoadmapData activeUni;
  final AppColors colors;
  final void Function({
    required String title,
    required String slug,
    required int durationMinutes,
    required double negativeMark,
    bool isPracticeMode,
  }) onLaunchLiveTest;

  const PastExamsView({
    super.key,
    required this.pastExamsFuture,
    required this.activeUni,
    required this.colors,
    required this.onLaunchLiveTest,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: pastExamsFuture,
      builder: (context, snapshot) {
        final pastExams = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Past Daily Drills & Missed Exams',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Missed a test? Practice anytime to sharpen skills (unranked).',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Practice Vault',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colors.accentAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else if (pastExams.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No past model tests archived yet for ${activeUni.shortCode}.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pastExams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final exam = pastExams[index];
                  final id = exam['id']?.toString() ?? '';
                  final title = exam['title']?.toString() ?? 'Daily Drill';
                  final date = exam['date']?.toString() ?? '';
                  final totalQ = exam['totalQuestions'] ?? 25;
                  final duration = exam['durationMinutes'] ?? 30;
                  final marks = exam['totalMarks'] ?? 50;
                  final negMark =
                      (exam['negativeMark'] as num?)?.toDouble() ?? 0.25;
                  final hasAttempted = exam['hasAttempted'] == true;
                  final userScore = exam['userScore'];

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (hasAttempted)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.accentEmerald
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Completed • ${userScore ?? 0}/$marks',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: colors.accentEmerald,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.accentAmber
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Missed Test',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: colors.accentAmber,
                                        ),
                                      ),
                                    ),
                                  if (date.isNotEmpty)
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalQ Questions • $duration Mins • $marks Marks',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            onLaunchLiveTest(
                              title: title,
                              slug: id,
                              durationMinutes: duration,
                              negativeMark: negMark,
                              isPracticeMode: true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.surface,
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.primary),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Practice',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

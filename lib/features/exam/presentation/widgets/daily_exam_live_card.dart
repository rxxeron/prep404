import 'package:flutter/material.dart';
import '../../../../core/models/question.dart';
import '../../../../core/services/university_roadmap_service.dart';

enum DailySlotState {
  upcoming,
  live,
  closed,
}

class DailyExamLiveCard extends StatelessWidget {
  final UniversityRoadmapData activeUni;
  final Future<Map<String, dynamic>?>? dailyTestFuture;
  final DailySlotState slotState;
  final String slotBadgeText;
  final String remainingTime;
  final VoidCallback onRetry;
  final void Function({
    required String title,
    required String slug,
    required int durationMinutes,
    required double negativeMark,
    List<Question>? initialQuestions,
    bool isPracticeMode,
  }) onLaunchExam;

  const DailyExamLiveCard({
    super.key,
    required this.activeUni,
    required this.dailyTestFuture,
    required this.slotState,
    required this.slotBadgeText,
    required this.remainingTime,
    required this.onRetry,
    required this.onLaunchExam,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: dailyTestFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final isLoaded = snapshot.hasData && snapshot.data != null;
        final testData = snapshot.data;

        final examTitle = isLoaded
            ? (testData!['title']?.toString() ?? activeUni.dailyExamTitle)
            : activeUni.dailyExamTitle;
        final totalQuestions =
            isLoaded ? (testData!['totalQuestions'] as num?)?.toInt() ?? 0 : 0;
        final durationMins = isLoaded
            ? (testData!['durationMinutes'] as num?)?.toInt() ?? 30
            : 30;
        final totalMarks = isLoaded
            ? (testData!['totalMarks'] as num?)?.toDouble() ?? 50.0
            : 50.0;
        final negativeMark = isLoaded
            ? (testData!['negativeMark'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        final enrolledCount =
            isLoaded ? (testData!['enrolledCount'] as num?)?.toInt() ?? 0 : 0;
        final examId = isLoaded
            ? (testData!['examId']?.toString() ?? 'daily-${activeUni.key}-live')
            : 'daily-${activeUni.key}-live';
        final hasAttempted = isLoaded && testData!['hasAttempted'] == true;
        final userSubmission = isLoaded
            ? testData!['userSubmission'] as Map<String, dynamic>?
            : null;

        final negText = negativeMark == 0
            ? 'No Negative Marking'
            : 'Penalty: -${negativeMark.toStringAsFixed(2)}';

        final enrolledText = !isLoaded
            ? '⚠️ Backend Server Offline — No exam synced'
            : (slotState == DailySlotState.upcoming
                ? '⏳ Opens Today at 10:00 AM for ${activeUni.shortCode}'
                : (slotState == DailySlotState.closed
                    ? '🔒 Today\'s Live Window Closed for ${activeUni.shortCode}'
                    : (enrolledCount > 0
                        ? '🔥 $enrolledCount ${activeUni.shortCode} Candidates Submitted'
                        : '🔥 Today\'s Live Slot Open for ${activeUni.shortCode}')));

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: activeUni.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      '10:00 AM - 10:00 PM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: !isLoaded
                              ? const Color(0xFFD1D5DB)
                              : (slotState == DailySlotState.live
                                  ? const Color(0xFF34D399)
                                  : (slotState == DailySlotState.upcoming
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF9CA3AF))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        !isLoaded ? 'SERVER OFFLINE' : slotBadgeText,
                        style: TextStyle(
                          color: !isLoaded
                              ? const Color(0xFFE5E7EB)
                              : (slotState == DailySlotState.live
                                  ? const Color(0xFF6EE7B7)
                                  : (slotState == DailySlotState.upcoming
                                      ? const Color(0xFFFDE68A)
                                      : const Color(0xFFD1D5DB))),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                examTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLoaded
                    ? '$totalQuestions Questions • $durationMins Mins • ${totalMarks.toStringAsFixed(0)} Marks • $negText'
                    : 'Start your backend server (port 4040) to load today\'s scheduled test questions',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFFF3E6),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // If candidate already attempted today's exam:
              if (hasAttempted && userSubmission != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF34D399), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Completed Today: Score ${userSubmission['score']}/$totalMarks (Rank #${userSubmission['rank'] ?? 1})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      enrolledText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFF3E6),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⏱️ $remainingTime',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : (!isLoaded
                        ? ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Server Offline — Tap to Retry',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          )
                        : (slotState != DailySlotState.live
                            ? ElevatedButton.icon(
                                onPressed: null,
                                icon: Icon(
                                  slotState == DailySlotState.upcoming
                                      ? Icons.hourglass_top_rounded
                                      : Icons.lock_clock_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  slotState == DailySlotState.upcoming
                                      ? 'Exam Opens at 10:00 AM'
                                      : 'Today\'s Slot Closed (10 AM - 10 PM)',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.25),
                                  disabledBackgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  disabledForegroundColor: Colors.white70,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                              )
                            : (hasAttempted
                                ? ElevatedButton.icon(
                                    onPressed: () {
                                      final qListRaw =
                                          testData['questions'] as List? ?? [];
                                      final parsed = qListRaw
                                          .map((q) => Question.fromJson(
                                              q as Map<String, dynamic>))
                                          .toList();
                                      onLaunchExam(
                                        title: examTitle,
                                        slug: examId,
                                        durationMinutes: durationMins,
                                        negativeMark: negativeMark,
                                        initialQuestions:
                                            parsed.isNotEmpty ? parsed : null,
                                        isPracticeMode: true,
                                      );
                                    },
                                    icon: const Icon(Icons.replay_rounded,
                                        size: 18),
                                    label: const Text(
                                        'Completed Today • Practice Again (Unranked)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.95),
                                      foregroundColor: const Color(0xFF542747),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () {
                                      final qListRaw =
                                          testData?['questions'] as List? ?? [];
                                      final parsed = qListRaw
                                          .map((q) => Question.fromJson(
                                              q as Map<String, dynamic>))
                                          .toList();
                                      onLaunchExam(
                                        title: examTitle,
                                        slug: examId,
                                        durationMinutes: durationMins,
                                        negativeMark: negativeMark,
                                        initialQuestions:
                                            parsed.isNotEmpty ? parsed : null,
                                        isPracticeMode: false,
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18),
                                    label: const Text('Start Exam',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF542747),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      elevation: 3,
                                    ),
                                  )))),
              ),
            ],
          ),
        );
      },
    );
  }
}

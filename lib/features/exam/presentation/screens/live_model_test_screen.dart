import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/question.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/services/admission_plan_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../widgets/katex_question_view.dart';
import '../widgets/exam_timer_pill.dart';
import '../widgets/exam_score_card.dart';
import '../widgets/software_omr_sheet_view.dart';
import '../widgets/exam_mode_selection_view.dart';
import '../widgets/exam_dialogs.dart';
import '../widgets/exam_bottom_action_bar.dart';

/// Premier Dual-Mode (In-App vs OMR) Continuous Scroll Exam Runner
class LiveModelTestScreen extends StatefulWidget {
  final String slug;
  final String? title;
  final int? durationMinutes;
  final double? negativeMark;
  final List<Question>? initialQuestions;
  final String? userId;
  final String candidateName;
  final String candidateCollege;
  final bool isPracticeMode;
  final VoidCallback onExit;

  const LiveModelTestScreen({
    super.key,
    required this.slug,
    this.title,
    this.durationMinutes,
    this.negativeMark,
    this.initialQuestions,
    this.userId,
    this.candidateName = 'Private Uni Candidate',
    this.candidateCollege = 'Notre Dame College',
    this.isPracticeMode = false,
    required this.onExit,
  });

  @override
  State<LiveModelTestScreen> createState() => _LiveModelTestScreenState();
}

class _LiveModelTestScreenState extends State<LiveModelTestScreen> {
  final ExamRepository _repository = ExamRepository();
  final String _submissionIdempotencyKey = const Uuid().v4();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  String? _submissionError;
  String? _examSessionId;
  late String _examTitle;
  late int _durationMinutes;
  late double _negativeMark;
  List<Question> _questions = [];

  ExamRunnerMode? _runnerMode;
  ExamFilterType _filterType = ExamFilterType.all;
  bool _showOmrSheet = false;
  late bool _isPractice;

  final Map<String, String> _userAnswers = {}; // questionId -> optionId
  final ValueNotifier<int> _remainingSeconds = ValueNotifier<int>(0);
  Timer? _timer;
  bool _isSubmitted = false;
  int _timeTakenSeconds = 0;

  // Calculated Results
  int _correctCount = 0;
  int _wrongCount = 0;
  double _finalScore = 0.0;
  int _simulatedRank = 1;
  int _totalCandidates = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isPractice = widget.isPracticeMode;
    _examTitle = widget.title ?? 'Daily Model Test';
    _durationMinutes = widget.durationMinutes ?? 30;
    _negativeMark = widget.negativeMark ?? 0.25;

    if (SupabaseService().currentUser != null && !widget.isPracticeMode) {
      _loadDynamicExam();
    } else if (widget.initialQuestions != null &&
        widget.initialQuestions!.isNotEmpty) {
      _questions = widget.initialQuestions!
          .map((q) => q.withShuffledOptions())
          .toList();
      _remainingSeconds.value = _durationMinutes * 60;
      _isLoading = false;
    } else {
      _loadDynamicExam();
    }
  }

  Future<void> _loadDynamicExam() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated =
          SupabaseService().currentUser != null && !widget.isPracticeMode;
      final startedSession = authenticated
          ? await _repository.startDynamicExamSession(widget.slug)
          : null;
      final exam = startedSession?.exam ??
          await _repository.fetchExamBySlug(widget.slug);
      if (mounted && exam != null) {
        // Authoritative questions loaded directly from exam blueprint (scrambling is handled server-side per session)
        final readyQuestions = exam.questions;

        setState(() {
          _examSessionId = startedSession?.sessionId;
          _questions = readyQuestions;
          _examTitle = exam.title;
          _durationMinutes = exam.durationMinutes;
          _negativeMark = exam.negativeMark;
          _remainingSeconds.value = _durationMinutes * 60;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load examination questions.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is StateError
              ? e.message.toString()
              : 'Network error: Unable to load exam.';
          _isLoading = false;
        });
      }
    }
  }

  void _selectRunnerMode(ExamRunnerMode mode) {
    setState(() {
      _runnerMode = mode;
      // In OMR simulation mode, grant extra 15 minutes buffer
      if (mode == ExamRunnerMode.omrBubble) {
        _durationMinutes += 15;
        _remainingSeconds.value = _durationMinutes * 60;
        _showOmrSheet = true;
      }
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds.value > 0) {
        _remainingSeconds.value--;
      } else {
        _timer?.cancel();
        _submitExam();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingSeconds.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectOption(String questionId, String optionId) {
    if (_isSubmitted) return;
    setState(() {
      if (_userAnswers[questionId] == optionId) {
        _userAnswers.remove(questionId); // Unselect if tapped again
      } else {
        _userAnswers[questionId] = optionId;
      }
    });
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (ctx) => ExamSubmitConfirmDialog(
        totalQuestions: _questions.length,
        answeredCount: _userAnswers.length,
        onConfirmSubmit: _submitExam,
      ),
    );
  }

  void _openQuestionPalette() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question Navigator',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    tooltip: 'Close question navigator',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPaletteLegend(colors.accentEmerald,
                      'Answered (${_userAnswers.length})', colors),
                  const SizedBox(width: 16),
                  _buildPaletteLegend(
                      colors.surfaceElevated,
                      'Unanswered (${_questions.length - _userAnswers.length})',
                      colors),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_questions.length, (index) {
                      final q = _questions[index];
                      final isAnswered = _userAnswers.containsKey(q.id);
                      void openQuestion() {
                        Navigator.pop(ctx);
                        setState(() => _filterType = ExamFilterType.all);
                        // Smooth scroll jump
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            index * 320.0,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      }

                      return Semantics(
                        container: true,
                        button: true,
                        label: 'Question ${index + 1}',
                        value: isAnswered ? 'Answered' : 'Not answered',
                        onTap: openQuestion,
                        child: ExcludeSemantics(
                          child: InkWell(
                            onTap: openQuestion,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isAnswered
                                    ? colors.accentEmerald
                                    : colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isAnswered
                                      ? colors.accentEmerald
                                      : colors.border,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isAnswered
                                      ? Colors.white
                                      : colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaletteLegend(Color color, String label, AppColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Future<void> _submitExam() async {
    if (_isSubmitting || _isSubmitted) return;
    _timer?.cancel();
    final timeTaken = (_durationMinutes * 60) - _remainingSeconds.value;

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
      _timeTakenSeconds = timeTaken;
    });

    try {
      final result = await _repository.submitExam(
        slug: widget.slug,
        candidateName: widget.candidateName,
        candidateInstitution: widget.candidateCollege,
        sessionId: _examSessionId,
        userId: widget.userId,
        isPractice: widget.isPracticeMode,
        answers: _userAnswers,
        timeTakenSeconds: timeTaken,
        idempotencyKey: _submissionIdempotencyKey,
        questionsSnapshot: _questions,
      );

      if (mounted) {
        AdmissionPlanService().markItemCompleted(widget.slug);

        // Enrich questions with authoritative correct answers and predefined explanations from feedback
        final feedbackMap = {for (final f in result.feedback) f.questionId: f};
        final enrichedQuestions = _questions.map((q) {
          final fb = feedbackMap[q.id];
          if (fb == null) return q;
          return q.copyWith(
            correctOptionId: fb.correctOption.isNotEmpty
                ? fb.correctOption
                : q.correctOptionId,
            explanation:
                fb.explanation.isNotEmpty ? fb.explanation : q.explanation,
          );
        }).toList();

        CacheService().saveExamScript({
          'id': result.submissionId ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
          'examId': widget.slug,
          'examSlug': widget.slug,
          'examTitle': _examTitle,
          'date': DateTime.now().toIso8601String(),
          'score': result.score,
          'totalMarks': result.totalMarks,
          'totalQuestions': enrichedQuestions.length,
          'correctCount': result.correctCount,
          'wrongCount': result.wrongCount,
          'skippedCount': result.unansweredCount,
          'negativeMark': (result.wrongCount * _negativeMark),
          'timeTakenSeconds': result.timeTakenSeconds,
          'rank': result.rank,
          'totalCandidates': result.totalParticipants,
          'isPassed': result.score >= (result.totalMarks * 0.40),
          'isPractice': widget.isPracticeMode || result.isPractice,
          'submissionPersisted': result.submissionPersisted,
          'userAnswers': _userAnswers,
          'questions': enrichedQuestions.map((q) => q.toJson()).toList(),
        });
        setState(() {
          _questions = enrichedQuestions;
          _isPractice = widget.isPracticeMode || result.isPractice;
          _timeTakenSeconds = result.timeTakenSeconds;
          _correctCount = result.correctCount;
          _wrongCount = result.wrongCount;
          _finalScore = result.score;
          _simulatedRank = result.rank;
          _totalCandidates = result.totalParticipants;
          _isSubmitted = true;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (_examSessionId != null || SupabaseService().currentUser != null) {
        if (mounted) {
          setState(() {
            _submissionError =
                'Submission was not confirmed. Retry to safely check the same exam attempt.';
            _isSubmitting = false;
          });
        }
        return;
      }

      // Fallback local scoring
      List<Question> readyQuestions = _questions;
      if (readyQuestions.any((q) => q.correctOptionId.isEmpty)) {
        try {
          final reviewQs = await _repository.fetchSubmissionReview(
            widget.slug,
            examId: widget.slug,
          );
          if (reviewQs.isNotEmpty) {
            final revMap = {for (final r in reviewQs) r.id: r};
            readyQuestions = readyQuestions.map((q) {
              final r = revMap[q.id];
              if (r == null) return q;
              return q.copyWith(
                correctOptionId: r.correctOptionId.isNotEmpty
                    ? r.correctOptionId
                    : q.correctOptionId,
                explanation:
                    r.explanation.isNotEmpty ? r.explanation : q.explanation,
              );
            }).toList();
          }
        } catch (_) {}
      }

      int correct = 0;
      int wrong = 0;
      for (final q in readyQuestions) {
        final chosen = _userAnswers[q.id];
        if (chosen != null) {
          if (chosen == q.correctOptionId) {
            correct++;
          } else {
            wrong++;
          }
        }
      }
      final rawScore = correct - (wrong * _negativeMark);
      final calcScore = rawScore < 0 ? 0.0 : rawScore;
      final totalMarks = readyQuestions.length.toDouble();
      final skipped = readyQuestions.length - (correct + wrong);

      if (mounted) {
        AdmissionPlanService().markItemCompleted(widget.slug);
        CacheService().saveExamScript({
          'id': 'sub_${DateTime.now().millisecondsSinceEpoch}',
          'examSlug': widget.slug,
          'examTitle': _examTitle,
          'date': DateTime.now().toIso8601String(),
          'score': calcScore,
          'totalMarks': totalMarks,
          'totalQuestions': readyQuestions.length,
          'correctCount': correct,
          'wrongCount': wrong,
          'skippedCount': skipped,
          'negativeMark': (wrong * _negativeMark),
          'timeTakenSeconds': timeTaken,
          'rank': 1,
          'totalCandidates': 1,
          'isPassed': calcScore >= (totalMarks * 0.40),
          'isPractice': true,
          'submissionPersisted': false,
          'userAnswers': _userAnswers,
          'questions': readyQuestions.map((q) => q.toJson()).toList(),
        });
        setState(() {
          _questions = readyQuestions;
          _isPractice = true;
          _correctCount = correct;
          _wrongCount = wrong;
          _finalScore = calcScore;
          _simulatedRank = 1;
          _totalCandidates = 1;
          _isSubmitted = true;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Text(_examTitle,
              style: TextStyle(color: colors.textPrimary, fontSize: 16)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: widget.onExit),
        ),
        body: const PrepPageSkeleton(cardCount: 2),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Text(_examTitle, style: TextStyle(color: colors.textPrimary)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: widget.onExit),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 64, color: colors.dangerRed),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'No questions found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textPrimary, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDynamicExam,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Step 1: Pre-Exam Mode Selection View (Digital vs OMR Bubble)
    if (_runnerMode == null) {
      return ExamModeSelectionView(
        examTitle: _examTitle,
        questionCount: _questions.length,
        negativeMark: _negativeMark,
        durationMinutes: _durationMinutes,
        onExit: widget.onExit,
        onSelectMode: _selectRunnerMode,
      );
    }

    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colors.accentEmerald),
              const SizedBox(height: 20),
              Text(
                'Calculating score and rank...',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSubmitted) {
      return ExamScoreCard(
        title: _examTitle,
        slug: widget.slug,
        score: _finalScore,
        totalQuestions: _questions.length,
        correctCount: _correctCount,
        wrongCount: _wrongCount,
        timeTakenSeconds: _timeTakenSeconds,
        nationalRank: _simulatedRank,
        totalCandidates: _totalCandidates,
        questions: _questions,
        userAnswers: _userAnswers,
        isPractice: _isPractice,
        onExit: widget.onExit,
      );
    }

    // Filter questions based on candidate selection
    final displayQuestions = _filterType == ExamFilterType.all
        ? _questions
        : (_filterType == ExamFilterType.answered
            ? _questions.where((q) => _userAnswers.containsKey(q.id)).toList()
            : _questions
                .where((q) => !_userAnswers.containsKey(q.id))
                .toList());

    final isOmr = _runnerMode == ExamRunnerMode.omrBubble;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _examTitle,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary),
            ),
            Text(
              widget.isPracticeMode
                  ? '🎯 Practice Mode • Unranked'
                  : (isOmr
                      ? 'OMR Simulation Mode • +15m Buffer'
                      : 'In-App Digital Mode'),
              style: TextStyle(
                fontSize: 12,
                color: widget.isPracticeMode
                    ? colors.accentAmber
                    : (isOmr ? colors.accentAmber : colors.primary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Mode / View Switcher (Question Scroll <-> Software OMR Bubble Sheet)
          IconButton(
            icon: Icon(
              _showOmrSheet
                  ? Icons.format_list_bulleted_rounded
                  : Icons.radio_button_checked_rounded,
              color: _showOmrSheet ? colors.primary : colors.accentAmber,
            ),
            tooltip: _showOmrSheet
                ? 'Switch to Question List'
                : 'Switch to OMR Sheet',
            onPressed: () => setState(() => _showOmrSheet = !_showOmrSheet),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _remainingSeconds,
            builder: (context, remainingSeconds, child) =>
                ExamTimerPill(remainingSeconds: remainingSeconds),
          ),
          // Central Theme Toggle Pill
          const ThemeToggleIconButton(),
          if (!_showOmrSheet)
            IconButton(
              icon: Icon(Icons.grid_view_rounded, color: colors.primary),
              onPressed: _openQuestionPalette,
              tooltip: 'Question Navigator Grid',
            ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary),
            tooltip: 'Exit exam',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ExamQuitConfirmDialog(onQuit: widget.onExit),
              );
            },
          ),
        ],
        bottom: _submissionError == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: colors.dangerRed.withValues(alpha: 0.12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.dangerRed),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _submissionError!,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: _isSubmitting ? null : _submitExam,
                          child: Text('Retry',
                              style: TextStyle(color: colors.dangerRed)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      body: _showOmrSheet
          ? SoftwareOmrSheetView(
              title: _examTitle,
              candidateName: widget.candidateName,
              candidateCollege: widget.candidateCollege,
              questions: _questions,
              userAnswers: _userAnswers,
              onOptionSelected: _selectOption,
              onSubmit: _confirmSubmit,
              onQuestionTap: (index) {
                setState(() {
                  _showOmrSheet = false;
                  _filterType = ExamFilterType.all;
                });
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    index * 320.0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                }
              },
            )
          : Column(
              children: [
                // Filter Chips Row (All, Answered, Unanswered)
                ExamFilterBar(
                  totalCount: _questions.length,
                  answeredCount: _userAnswers.length,
                  currentFilter: _filterType,
                  onFilterChanged: (filter) =>
                      setState(() => _filterType = filter),
                ),

                // Continuous Scroll Question List
                Expanded(
                  child: displayQuestions.isEmpty
                      ? Center(
                          child: Text(
                            _filterType == ExamFilterType.unanswered
                                ? 'All questions have been answered! 🎉'
                                : 'No questions found.',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 15),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: displayQuestions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final q = displayQuestions[index];
                            final realQuestionNumber =
                                _questions.indexOf(q) + 1;

                            return KaTeXQuestionView(
                              question: q,
                              questionNumber: realQuestionNumber,
                              isOmrMode: isOmr,
                              selectedOptionId: _userAnswers[q.id],
                              onOptionSelected: (optId) =>
                                  _selectOption(q.id, optId),
                            );
                          },
                        ),
                ),

                // Floating Sticky Submit Bar
                ExamBottomActionBar(
                  totalCount: _questions.length,
                  answeredCount: _userAnswers.length,
                  onSubmit: _confirmSubmit,
                ),
              ],
            ),
    );
  }
}

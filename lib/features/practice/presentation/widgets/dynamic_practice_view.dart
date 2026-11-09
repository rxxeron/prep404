import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/question.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/algorithms/fsrs.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../ai_tutor/services/ai_socratic_tutor.dart';
import '../../../exam/presentation/widgets/katex_question_view.dart';

/// Dynamic practice view with the question bank, FSRS, and authored study hints.
class DynamicPracticeView extends StatefulWidget {
  final SocraticStudyHintService studyHintService;
  final ApiClient? apiClient;
  final String? initialSubjectId;
  final String? initialTopicId;

  const DynamicPracticeView({
    super.key,
    required this.studyHintService,
    this.apiClient,
    this.initialSubjectId,
    this.initialTopicId,
  });

  @override
  State<DynamicPracticeView> createState() => _DynamicPracticeViewState();
}

class _DynamicPracticeViewState extends State<DynamicPracticeView> {
  final ExamRepository _repository = ExamRepository();
  late final ApiClient _api;
  final FSRSAlgorithm _fsrs = const FSRSAlgorithm();

  List<Question> _questions = [];
  int _currentIndex = 0;
  String? _selectedOption;
  bool _showExplanation = false;
  bool _isScoringAnswer = false;
  String? _pendingAttemptId;
  String? _pendingAttemptQuestionId;
  String? _pendingAttemptOptionId;
  bool _isLoading = true;
  late String _activeSubject;

  List<Map<String, String>> _subjectFilters = [
    {'id': 'all', 'label': 'All Topics'},
    {'id': 'bookmarked', 'label': 'Bookmarked ★'},
  ];

  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _activeSubject = widget.initialSubjectId ?? 'all';
    _loadSubjectFilters();
    _loadQuestions();
  }

  Future<void> _loadSubjectFilters() async {
    try {
      final filters = await _repository.fetchSubjectFilters();
      if (mounted && filters.isNotEmpty) {
        setState(() {
          _subjectFilters = filters;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    List<Question> list;
    if (_activeSubject == 'bookmarked') {
      final bookmarks = List<String>.from(
          CacheService().read<List<dynamic>>('bookmarked_questions') ?? []);
      final all = await _repository.fetchQuestions(limit: 50);
      list = all.where((q) => bookmarks.contains(q.id)).toList();
    } else {
      final subject = _activeSubject == 'all' ? null : _activeSubject;
      list = await _repository.fetchQuestions(
          subjectId: subject, topicId: widget.initialTopicId, limit: 20);
      if (list.isEmpty) {
        list = await _repository.fetchQuestions(limit: 20);
      }
    }
    if (mounted) {
      setState(() {
        _questions = list.map((q) => q.withShuffledOptions()).toList();
        _currentIndex = 0;
        _selectedOption = null;
        _showExplanation = false;
        _isLoading = false;
      });
    }
  }

  bool _isCurrentBookmarked() {
    if (_questions.isEmpty) return false;
    final bookmarks =
        CacheService().read<List<dynamic>>('bookmarked_questions') ?? [];
    return bookmarks.contains(_questions[_currentIndex].id);
  }

  void _toggleBookmark() {
    if (_questions.isEmpty) return;
    final id = _questions[_currentIndex].id;
    final bookmarks = List<String>.from(
        CacheService().read<List<dynamic>>('bookmarked_questions') ?? []);
    if (bookmarks.contains(id)) {
      bookmarks.remove(id);
    } else {
      bookmarks.add(id);
    }
    CacheService().write('bookmarked_questions', bookmarks);
    if (_activeSubject == 'bookmarked') {
      final updatedQuestions = _questions
          .where((question) => bookmarks.contains(question.id))
          .toList();
      setState(() {
        _questions = updatedQuestions;
        _currentIndex = updatedQuestions.isEmpty
            ? 0
            : _currentIndex.clamp(0, updatedQuestions.length - 1);
        _selectedOption = null;
        _showExplanation = false;
      });
    } else {
      setState(() {});
    }
  }

  void _recordFsrsRating(FSRSRating rating) {
    final colors = context.colors;
    final cardState = FSRSCardState.initial();
    final updated = _fsrs.review(cardState, rating);
    final nextInterval = _fsrs.calculateNextInterval(updated.stability);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'FSRS: Review scheduled in $nextInterval ${nextInterval == 1 ? "day" : "days"}!'),
        backgroundColor: colors.accentEmerald,
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-advance if not at the end
    _advanceTimer?.cancel();
    if (_currentIndex < _questions.length - 1) {
      _advanceTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _currentIndex++;
            _selectedOption = null;
            _showExplanation = false;
          });
        }
      });
    }
  }

  Future<void> _submitPracticeAnswer(Question question, String optionId) async {
    if (_isScoringAnswer || _showExplanation) return;
    if (_pendingAttemptQuestionId != question.id || _pendingAttemptOptionId != optionId) {
      _pendingAttemptId = const Uuid().v4();
      _pendingAttemptQuestionId = question.id;
      _pendingAttemptOptionId = optionId;
    }
    final attemptId = _pendingAttemptId!;
    setState(() => _isScoringAnswer = true);
    try {
      final result = await _api.submitPracticeAttempt(
        questionId: question.id,
        selectedOptionId: optionId,
        attemptId: attemptId,
      );
      if (!mounted) return;
      final scored = question.copyWith(
        correctOptionId: result['correctOptionId']?.toString() ?? '',
        explanation: result['explanation']?.toString() ?? '',
      );
      setState(() {
        _questions[_currentIndex] = scored;
        _selectedOption = optionId;
        _showExplanation = true;
        _isScoringAnswer = false;
        _pendingAttemptId = null;
        _pendingAttemptQuestionId = null;
        _pendingAttemptOptionId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isScoringAnswer = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is StateError
            ? error.message.toString()
            : 'Could not score this answer. Check your connection and try again.'),
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _showSocraticHint(BuildContext context, Question question) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SocraticHintModal(
          question: question,
          studentChosenOptionId: _selectedOption,
          studyHintService: widget.studyHintService,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) return const PrepPageSkeleton(cardCount: 2);

    return Material(
      color: colors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _subjectFilters.map((filter) {
                  final isSelected = _activeSubject == filter['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        filter['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected ? Colors.white : colors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _activeSubject = filter['id']!;
                        });
                        _loadQuestions();
                      },
                      backgroundColor: colors.surface,
                      selectedColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? colors.primary : colors.border,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            if (_questions.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _activeSubject == 'bookmarked'
                          ? Icons.bookmark_border
                          : Icons.search_off,
                      size: 48,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _activeSubject == 'bookmarked'
                          ? 'No bookmarked questions yet.\nBookmark tricky questions to review them here anytime!'
                          : 'No questions found in this category.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: colors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              )
            else ...[
              // Question Header & Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of ${_questions.length}',
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: MediaQuery.of(context).disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                                opacity: animation, child: child),
                          ),
                          child: Icon(
                            _isCurrentBookmarked()
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            key: ValueKey(_isCurrentBookmarked()),
                            color: _isCurrentBookmarked()
                                ? colors.accentSunshine
                                : colors.textMuted,
                            size: 20,
                          ),
                        ),
                        onPressed: _toggleBookmark,
                        tooltip: 'Bookmark Question',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.chevron_left, color: colors.textPrimary),
                        onPressed: _currentIndex > 0
                            ? () => setState(() {
                                  _currentIndex--;
                                  _selectedOption = null;
                                  _showExplanation = false;
                                })
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right,
                            color: colors.textPrimary),
                        onPressed: _currentIndex < _questions.length - 1
                            ? () => setState(() {
                                  _currentIndex++;
                                  _selectedOption = null;
                                  _showExplanation = false;
                                })
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Question View
              KaTeXQuestionView(
                question: _questions[_currentIndex],
                selectedOptionId: _selectedOption,
                onOptionSelected: (optId) {
                  _submitPracticeAnswer(_questions[_currentIndex], optId);
                },
                showExplanation: _showExplanation || _isScoringAnswer,
              ),
              if (_isScoringAnswer) const LinearProgressIndicator(minHeight: 2),

              // FSRS Difficulty Rating Bar (Only visible when explanation is shown)
              if (_showExplanation) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology,
                              color: colors.accentPurple, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Rate Difficulty (FSRS Memory Spaced Repetition):',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildFsrsButton('Again', '< 1d', colors.dangerRed,
                              () => _recordFsrsRating(FSRSRating.again)),
                          const SizedBox(width: 8),
                          _buildFsrsButton('Hard', '2d', colors.accentAmber,
                              () => _recordFsrsRating(FSRSRating.hard)),
                          const SizedBox(width: 8),
                          _buildFsrsButton('Good', '5d', colors.primary,
                              () => _recordFsrsRating(FSRSRating.good)),
                          const SizedBox(width: 8),
                          _buildFsrsButton('Easy', '12d', colors.accentEmerald,
                              () => _recordFsrsRating(FSRSRating.easy)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    _showSocraticHint(context, _questions[_currentIndex]),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Show Socratic hint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFsrsButton(
      String title, String interval, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                interval,
                style: TextStyle(
                    color: color.withValues(alpha: 0.7), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocraticHintModal extends StatefulWidget {
  final Question question;
  final String? studentChosenOptionId;
  final SocraticStudyHintService studyHintService;

  const _SocraticHintModal({
    required this.question,
    this.studentChosenOptionId,
    required this.studyHintService,
  });

  @override
  State<_SocraticHintModal> createState() => _SocraticHintModalState();
}

class _SocraticHintModalState extends State<_SocraticHintModal> {
  final ApiClient _api = ApiClient();
  String _streamedHint = '';
  bool _isStreaming = true;
  bool _isReporting = false;
  bool _reported = false;
  String? _reportError;
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  void _startStreaming() {
    final stream = widget.studyHintService.streamAuthoredHint(
      question: widget.question,
      studentChosenOptionId: widget.studentChosenOptionId ?? 'A',
    );
    _sub = stream.listen(
      (token) {
        if (mounted) {
          setState(() {
            _streamedHint += token;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isStreaming = false;
          });
        }
      },
    );
  }

  Future<void> _reportResponse() async {
    final category = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report this hint'),
        content: const Text(
            'Choose the main issue. We send the displayed hint and, when available, its question ID so moderators can review it. Your selected answer is not sent.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'incorrect'),
              child: const Text('Incorrect')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'unsafe'),
              child: const Text('Unsafe')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'irrelevant'),
              child: const Text('Irrelevant')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'other'),
              child: const Text('Other')),
        ],
      ),
    );
    if (category == null || !mounted) return;
    setState(() {
      _isReporting = true;
      _reportError = null;
    });
    try {
      await _api.reportTutorResponse(
        category: category,
        responseText: _streamedHint,
        questionId: widget.question.id,
      );
      if (mounted) setState(() => _reported = true);
    } catch (error) {
      if (mounted) {
        setState(() =>
            _reportError = error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: colors.accentPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Socratic Study Hint',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_isStreaming)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: colors.accentPurple),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
              'Question-authored guidance · AI-generated tutoring is not available in this build.',
              style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          const SizedBox(height: 16),
          Text(
            _streamedHint.isNotEmpty
                ? _streamedHint
                : _isStreaming
                    ? 'Checking for an authored study hint…'
                    : 'No guided hint has been authored for this question yet.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.textPrimary,
            ),
          ),
          if (_reportError != null) ...[
            const SizedBox(height: 8),
            Text(_reportError!,
                style: TextStyle(color: colors.dangerRed, fontSize: 12)),
          ],
          if (_streamedHint.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isReporting || _reported ? null : _reportResponse,
                icon: Icon(
                    _reported
                        ? Icons.check_circle_outline
                        : Icons.flag_outlined,
                    size: 18),
                label: Text(_reported
                    ? 'Report received'
                    : _isReporting
                        ? 'Sending report…'
                        : 'Report this hint'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: colors.accentPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

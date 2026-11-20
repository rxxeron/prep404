import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/university_logo.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../ai_tutor/services/ai_socratic_tutor.dart';
import '../../../exam/presentation/screens/live_model_test_screen.dart';
import '../../../practice/presentation/widgets/dynamic_practice_view.dart';

/// Comprehensive, well-organized Question Bank Hub for a specific Private University
class UniversityDetailQuestionBankScreen extends StatefulWidget {
  final String universityKey; // 'nsu', 'brac', 'iub', 'aust', 'uiu', etc.
  final String universityName;
  final String shortCode;
  final String location;
  final String? logoUrl;
  final String candidateName;
  final String candidateCollege;
  final int initialTabIndex;

  const UniversityDetailQuestionBankScreen({
    super.key,
    required this.universityKey,
    required this.universityName,
    required this.shortCode,
    this.location = 'Dhaka, Bangladesh',
    this.logoUrl,
    this.candidateName = 'Private Uni Candidate',
    this.candidateCollege = 'Notre Dame College',
    this.initialTabIndex = 0,
  });

  @override
  State<UniversityDetailQuestionBankScreen> createState() =>
      _UniversityDetailQuestionBankScreenState();
}

class _UniversityDetailQuestionBankScreenState
    extends State<UniversityDetailQuestionBankScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFacultyIndex = 0;
  final ExamRepository _repository = ExamRepository();
  bool _isLoading = true;
  Map<String, dynamic>? _uniData;
  List<Map<String, dynamic>> _academicUnits = [];
  List<Map<String, dynamic>> _modelTests = [];
  List<Map<String, dynamic>> _pastPapers = [];
  List<Map<String, dynamic>> _sectionExams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final supaClient = SupabaseService().client;
    final cleanCode = widget.shortCode.isNotEmpty
        ? widget.shortCode.toUpperCase()
        : widget.universityKey.toUpperCase();

    try {
      final uniRows = await supaClient
          .from('universities')
          .select(
              'id, code, full_name, short_name, logo_url, campus_location, exam_pattern_summary')
          .or('code.ilike.$cleanCode,slug.ilike.${cleanCode.toLowerCase()}')
          .limit(1);

      if (uniRows.isNotEmpty) {
        _uniData = uniRows.first;
        final uniId = _uniData!['id'] as String;

        final unitRows = await supaClient
            .from('academic_units')
            .select('name, short_code, slug')
            .eq('university_id', uniId)
            .order('name', ascending: true);
        _academicUnits = (unitRows as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    if (_uniData == null) {
      final meta = await _repository.fetchDirectoryMetadata();
      final unis = meta['universities'] as List? ?? [];
      for (final u in unis) {
        final code = (u['code'] as String? ?? '').toUpperCase();
        if (code == cleanCode) {
          _uniData = u as Map<String, dynamic>;
          break;
        }
      }
      if (_uniData != null) {
        final uniId = _uniData!['id'];
        final allUnits = meta['academic_units'] as List? ?? [];
        _academicUnits = allUnits
            .where((un) => un['university_id'] == uniId)
            .cast<Map<String, dynamic>>()
            .toList();
      }
    }

    final breakdown = await _repository.fetchUniversityExamBreakdown(cleanCode);

    if (mounted) {
      setState(() {
        _modelTests = (breakdown['modelTests'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _pastPapers = (breakdown['pastPapers'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _sectionExams = (breakdown['sectionExams'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  void _launchExam(Map<String, dynamic> exam) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        AppRoutes.liveModelTest,
        extra: {
          'title': exam['title'] as String? ?? 'Admission Test',
          'slug': exam['id'] as String? ?? exam['slug'] as String? ?? 'exam',
          'durationMinutes': (exam['durationMinutes'] as num?)?.toInt() ?? 60,
          'negativeMark': (exam['negativeMarking'] as num?)?.toDouble() ??
              (widget.universityKey.toLowerCase().contains('nsu') ? 0.0 : 0.25),
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveModelTestScreen(
            title: exam['title'] as String? ?? 'Admission Test',
            slug: exam['id'] as String? ?? exam['slug'] as String? ?? 'exam',
            durationMinutes: (exam['durationMinutes'] as num?)?.toInt() ?? 60,
            negativeMark: (exam['negativeMarking'] as num?)?.toDouble() ?? 0.0,
            isPracticeMode: true,
            candidateName: widget.candidateName,
            candidateCollege: widget.candidateCollege,
            onExit: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }

  void _startSectionPractice(String sectionTitle) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        AppRoutes.practice,
        extra: {
          'title': sectionTitle,
          'subjectId': widget.universityKey,
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(sectionTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            body: DynamicPracticeView(
              studyHintService: SocraticStudyHintService(),
              initialSubjectId: widget.universityKey,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final uniName = _uniData?['full_name'] as String? ?? widget.universityName;
    final uniLocation =
        _uniData?['campus_location'] as String? ?? widget.location;
    final uniPattern = _uniData?['exam_pattern_summary'] as String? ??
        'Official Admission Exams & Model Tests';
    final uniLogo = _uniData?['logo_url'] as String? ?? widget.logoUrl;

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              backgroundColor: const Color(0xFF542747),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF542747),
                        Color(0xFF7A3667),
                        Color(0xFFFF7A36)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 54),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UniversityLogo(
                            universityKey: widget.universityKey,
                            logoUrl: uniLogo,
                            size: 44,
                            isCircle: false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  uniName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  uniLocation,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          uniPattern,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E8F0),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF7A36),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF94A3B8),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Sections & Subjects'),
                  Tab(text: 'Past Year Papers'),
                  Tab(text: 'Model Tests'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const PrepPageSkeleton(cardCount: 3)
            : TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: SECTIONS & CHAPTERS (Section-Specific Exams from DB)
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Real Academic Units from database
                      if (_academicUnits.isNotEmpty) ...[
                        Text(
                          'Faculties / Departments:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                _academicUnits.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final fac = entry.value;
                              final isSelected = _selectedFacultyIndex == idx;
                              final label = fac['short_code'] != null &&
                                      (fac['short_code'] as String).isNotEmpty
                                  ? '${fac['short_code']} - ${fac['name']}'
                                  : fac['name'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (_) => setState(
                                      () => _selectedFacultyIndex = idx),
                                  selectedColor: const Color(0xFFFF7A36),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : colors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  backgroundColor: colors.surface,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text(
                        _sectionExams.isNotEmpty
                            ? 'Section-specific Exams (${_sectionExams.length} Sections):'
                            : 'No section-specific exams found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_sectionExams.isNotEmpty)
                        ..._sectionExams.map((sec) {
                          final marks =
                              (sec['totalMarks'] as num?)?.round() ?? 25;
                          final duration =
                              (sec['durationMinutes'] as num?)?.toInt() ?? 20;
                          final neg =
                              (sec['negativeMarking'] as num?)?.toDouble() ??
                                  0.25;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                              boxShadow: colors.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF7A36),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              sec['title'] as String? ??
                                                  'Section Exam',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: colors.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF7A36)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$marks Marks',
                                        style: const TextStyle(
                                          color: Color(0xFFFF7A36),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '⏱️ Time: $duration mins • Negative: ${neg > 0 ? "-$neg" : "None (0.0)"}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _startSectionPractice(
                                          sec['title'] as String),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colors.textSecondary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Practice',
                                          style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _launchExam(sec),
                                      icon: const Icon(Icons.play_arrow_rounded,
                                          size: 16),
                                      label: const Text('Take Test',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF7A36),
                                        foregroundColor:
                                            const Color(0xFF542747),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No section exams available for this university in database',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // TAB 2: PAST YEAR QUESTION PAPERS (Real University Exams from DB)
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _pastPapers.isNotEmpty
                            ? 'Past Year Questions & Solutions (${_pastPapers.length} Official Exams):'
                            : 'No past year exams found in database',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_pastPapers.isNotEmpty)
                        ..._pastPapers.map((paper) {
                          final duration =
                              (paper['durationMinutes'] as num?)?.toInt() ?? 60;
                          final marks =
                              (paper['totalMarks'] as num?)?.round() ?? 50;
                          final neg =
                              (paper['negativeMarking'] as num?)?.toDouble() ??
                                  0.25;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.border),
                              boxShadow: colors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.history_edu_rounded,
                                      color: Color(0xFFFF7A36)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        paper['title'] as String? ??
                                            'Past Exam',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$marks Total Marks • $duration mins • Negative: ${neg > 0 ? "-$neg" : "0.0"}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _launchExam(paper),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7A36),
                                    foregroundColor: const Color(0xFF542747),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Take Test',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No past year exams found in database for this university',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // TAB 3: FULL GRAND MODEL TESTS (Every Model Test Set from DB)
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _modelTests.isNotEmpty
                            ? 'Full-Length Official Grand Model Tests (${_modelTests.length} Model Tests):'
                            : 'No model tests found in database',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_modelTests.isNotEmpty)
                        ..._modelTests.map((mock) {
                          final duration =
                              (mock['durationMinutes'] as num?)?.toInt() ?? 60;
                          final marks =
                              (mock['totalMarks'] as num?)?.round() ?? 50;
                          final neg =
                              (mock['negativeMarking'] as num?)?.toDouble() ??
                                  0.25;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: const Color(0xFFFFF3E6)),
                              boxShadow: colors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.quiz_rounded,
                                      color: Color(0xFF542747)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mock['title'] as String? ??
                                            'Model Test',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$marks Total Marks • $duration mins • Negative: ${neg > 0 ? "-$neg" : "0.0"} • 100% Simulation',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _launchExam(mock),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7A36),
                                    foregroundColor: const Color(0xFF542747),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Start Test',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No model tests found in database for this university',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

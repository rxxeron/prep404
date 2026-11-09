import 'package:flutter/material.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import 'live_model_test_screen.dart';

/// Catalog of Live & Scheduled Model Tests with Vibrant 3D Subject Cards (Chorcha-Level Polish)
class ModelTestCatalogScreen extends StatefulWidget {
  final String candidateName;
  final String candidateCollege;

  const ModelTestCatalogScreen({
    super.key,
    this.candidateName = 'Private Uni Candidate',
    this.candidateCollege = 'Notre Dame College',
  });

  @override
  State<ModelTestCatalogScreen> createState() => _ModelTestCatalogScreenState();
}

class _ModelTestCatalogScreenState extends State<ModelTestCatalogScreen> {
  final ExamRepository _repository = ExamRepository();
  List<Map<String, dynamic>> _exams = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedTypeFilter =
      'all'; // 'all', 'model_test', 'uni_exam', 'section_exam'

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.fetchLiveExams(limit: 200);
      if (mounted) {
        setState(() {
          _exams = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _launchExam(Map<String, dynamic> exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveModelTestScreen(
          title: exam['title'] as String? ?? 'Model Test',
          slug: exam['slug'] as String? ?? 'daily-nsu-test-24',
          durationMinutes: (exam['durationMinutes'] as num?)?.toInt() ?? 30,
          negativeMark: (exam['negativeMarking'] as num?)?.toDouble() ?? 0.25,
          candidateName: widget.candidateName,
          candidateCollege: widget.candidateCollege,
          onExit: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _exams.where((e) {
      final matchesUni = _selectedFilter == 'All' ||
          (e['track'] ?? '').toString().toUpperCase() ==
              _selectedFilter.toUpperCase();
      final matchesType = _selectedTypeFilter == 'all' ||
          (e['examType'] ?? 'model_test').toString() == _selectedTypeFilter;
      return matchesUni && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        title: Text(
          'Private University Model Tests',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontSize: 16),
        ),
        actions: [
          const ThemeToggleIconButton(),
          IconButton(
            icon: Icon(Icons.refresh, color: colors.primary),
            onPressed: _loadExams,
          ),
        ],
      ),
      body: _isLoading
          ? const PrepPageSkeleton(cardCount: 3)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Vibrant 3D Track Cards Grid (Inspired by Chorcha's Question Bank Grid)
                  Text(
                    'Private University Tracks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTrackCardsGrid(context),
                  const SizedBox(height: 20),

                  // 2. Filter Tabs: All, BRACU, NSU, IUB
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live & Scheduled Exams',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.dangerRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filtered.length} Exams Available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Exam Type Filter Pills (Model Tests, Past Papers, Section Drills)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        {'label': 'All Exams', 'key': 'all'},
                        {'label': 'Model Tests', 'key': 'model_test'},
                        {'label': 'Past Papers', 'key': 'uni_exam'},
                        {'label': 'Section Drills', 'key': 'section_exam'},
                      ].map((t) {
                        final isSelected = _selectedTypeFilter == t['key'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t['label']!),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedTypeFilter = t['key']!),
                            selectedColor: colors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 11,
                            ),
                            backgroundColor: colors.surfaceElevated,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // University Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'BRACU',
                        'NSU',
                        'IUB',
                        'AUST',
                        'EWU',
                        'AIUB',
                        'UAP',
                        'UIU'
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary
                                    : colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.border,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : colors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Exam Cards List
                  ...filtered.map((exam) {
                    final isLive = exam['isLiveNow'] == true;
                    final track = exam['track'] ?? 'General';
                    final title = exam['title'] ?? 'Model Test';
                    final totalQuestions = exam['totalQuestions'] ?? 100;
                    final durationMinutes = exam['durationMinutes'] ?? 60;
                    final negMark = exam['negativeMarking'] ?? 0.25;
                    final activeCandidates = exam['activeCandidates'] ?? 1200;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLive
                                ? colors.primary.withValues(alpha: 0.4)
                                : colors.border,
                          ),
                          boxShadow: colors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.accentPurple
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: colors.accentPurple
                                            .withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    '$track Track',
                                    style: TextStyle(
                                      color: colors.accentPurple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (isLive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.dangerRed
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: colors.dangerRed),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                            radius: 3,
                                            backgroundColor: colors.dangerRed),
                                        const SizedBox(width: 6),
                                        Text(
                                          'LIVE NOW',
                                          style: TextStyle(
                                            color: colors.dangerRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    '${(activeCandidates as num).toInt().toString()} Registered',
                                    style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 11),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalQuestions Questions • $durationMinutes Mins • -$negMark Neg Mark',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLive
                                      ? colors.primary
                                      : colors.surfaceElevated,
                                  foregroundColor: isLive
                                      ? Colors.white
                                      : colors.textPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: isLive
                                        ? BorderSide.none
                                        : BorderSide(color: colors.border),
                                  ),
                                  elevation: isLive ? 2 : 0,
                                ),
                                onPressed: () => _launchExam(exam),
                                icon: Icon(
                                    isLive ? Icons.play_arrow : Icons.lock_open,
                                    size: 18),
                                label: Text(
                                  isLive
                                      ? 'Start Live Model Test'
                                      : 'Practice Past Exam',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildTrackCardsGrid(BuildContext context) {
    final tracks = [
      {
        'title': 'Engineering & CSE',
        'sub': 'NSU, BRACU, AUST',
        'count': '48',
        'gradient': [
          const Color(0xFF542747),
          const Color(0xFF7A3667)
        ], // Deep Plum
        'icon': Icons.computer_rounded,
      },
      {
        'title': 'Business & BBA',
        'sub': 'IBA, NSU, IUB',
        'count': '36',
        'gradient': [
          const Color(0xFFEA580C),
          const Color(0xFFFF7A36)
        ], // Vibrant Tangerine
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Pharmacy & Bio Sciences',
        'sub': 'NSU, BRAC, UIU',
        'count': '28',
        'gradient': [
          const Color(0xFF542747),
          const Color(0xFF7A3667)
        ], // Deep Plum
        'icon': Icons.local_pharmacy_rounded,
      },
      {
        'title': 'Architecture & Design',
        'sub': 'BRACU, AUST, AIUB',
        'count': '22',
        'gradient': [
          const Color(0xFFB45309),
          const Color(0xFFFFD166)
        ], // Sunshine Gold
        'icon': Icons.architecture_rounded,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final t = tracks[index];
        final gradient = t['gradient'] as List<Color>;

        return InkWell(
          onTap: () {
            if (_exams.isNotEmpty) {
              _launchExam(_exams.first);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sensors, color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Icon(t['icon'] as IconData,
                        color: Colors.white.withValues(alpha: 0.8), size: 20),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['title'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t['sub'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            '${t['count']} Tests',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
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

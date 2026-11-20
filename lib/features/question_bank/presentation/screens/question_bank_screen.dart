import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/university_logo.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../../core/widgets/prep_staggered_list.dart';
import '../../../exam/presentation/screens/model_test_catalog_screen.dart';
import '../../../printable_omr/services/printable_omr_launcher.dart';
import 'university_detail_question_bank_screen.dart';
import 'subject_chapter_directory_screen.dart';

/// Private University Question Bank & Model Test Directory (Prep404 UI Pattern)
class QuestionBankScreen extends StatefulWidget {
  final UserProfile? profile;
  final void Function(String filter)? onSelectTrack;
  final bool isEnglish;

  const QuestionBankScreen({
    super.key,
    this.profile,
    this.onSelectTrack,
    this.isEnglish = true,
  });

  @override
  State<QuestionBankScreen> createState() =>
      _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  int _selectedFilterPill =
      0; // 0: University-wise, 1: Subject-wise, 2: Model Tests
  String _searchQuery = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _institutionCards = [];
  List<Map<String, dynamic>> _subjectCards = [];
  List<Map<String, dynamic>> _modelTestCards = [];

  @override
  void initState() {
    super.initState();
    _loadDirectoryFromDb();
  }

  Future<void> _loadDirectoryFromDb() async {
    setState(() => _isLoading = true);
    try {
      final meta = await ExamRepository().fetchDirectoryMetadata();
      final unis = meta['universities'] as List? ?? [];
      final examRows = meta['exams'] as List? ?? [];
      final subjects = meta['academic_subjects'] as List? ?? [];

      final trackToExamCount = <String, int>{};
      final trackToModelCount = <String, int>{};

      for (final row in examRows) {
        final t = (row['track'] as String? ?? '').toUpperCase();
        trackToExamCount[t] = (trackToExamCount[t] ?? 0) + 1;
        if (row['exam_type'] == 'model_test' ||
            row['exam_type'] == 'daily_live') {
          trackToModelCount[t] = (trackToModelCount[t] ?? 0) + 1;
        }
      }

      List rawUnis = unis;
      if (rawUnis.isEmpty) {
        rawUnis = UniversityCatalog.universities
            .map((u) => {
                  'code': u.code,
                  'short_name': u.code,
                  'full_name': u.fullName,
                  'campus_location': u.location,
                  'logo_url': u.logoUrl ??
                      UniversityLogo.officialLogos[u.code.toLowerCase()],
                })
            .toList();
      }

      // Build Institution Cards
      final instList = <Map<String, dynamic>>[];
      final gradients = [
        [const Color(0xFF542747), const Color(0xFFFF7A36)],
        [const Color(0xFF7A3667), const Color(0xFFFFD166)],
        [const Color(0xFFFF7A36), const Color(0xFF542747)],
        [const Color(0xFFFFD166), const Color(0xFF542747)],
        [const Color(0xFF542747), const Color(0xFF7A3667)],
        [const Color(0xFFFF7A36), const Color(0xFFFFD166)],
        [const Color(0xFF7A3667), const Color(0xFFFF7A36)],
        [const Color(0xFF542747), const Color(0xFFFFD166)],
      ];

      for (int i = 0; i < rawUnis.length; i++) {
        final u = rawUnis[i];
        final code = (u['code'] as String? ?? 'UNI').toUpperCase();
        final count = trackToExamCount[code] ?? 0;
        final grad = gradients[i % gradients.length];

        instList.add({
          'title': u['short_name'] ?? u['full_name'] ?? code,
          'badge': code,
          'subtitle': u['full_name'] ?? 'Admission Tests & Question Bank',
          'hasLive': count > 0,
          'calendarText': u['campus_location'] ?? 'Dhaka, Bangladesh',
          'count': '$count ${count == 1 ? "Exam" : "Exams"}',
          'filterKey': code,
          'logoUrl':
              u['logo_url'] ?? UniversityLogo.officialLogos[code.toLowerCase()],
          'gradient': grad,
          'watermarkIcon': Icons.school_rounded,
        });
      }

      // Build Model Test Cards
      final modelList = <Map<String, dynamic>>[];
      for (int i = 0; i < rawUnis.length; i++) {
        final u = rawUnis[i];
        final code = (u['code'] as String? ?? 'UNI').toUpperCase();
        final count = trackToModelCount[code] ?? 0;
        final grad = gradients[(i + 2) % gradients.length];

        modelList.add({
          'title': code,
          'badge': 'MOCK',
          'subtitle': '${u['short_name'] ?? code} Official Model Tests',
          'hasLive': count > 0,
          'calendarText': 'Real Timing & OMR Simulation',
          'count': '$count ${count == 1 ? "Set" : "Sets"}',
          'filterKey': code,
          'logoUrl':
              u['logo_url'] ?? UniversityLogo.officialLogos[code.toLowerCase()],
          'gradient': grad,
          'watermarkIcon': Icons.quiz_rounded,
        });
      }

      // Build Subject Cards
      final subList = <Map<String, dynamic>>[];
      final subjectIcons = {
        'english': Icons.spellcheck_rounded,
        'general_mathematics': Icons.calculate_rounded,
        'higher_mathematics': Icons.functions_rounded,
        'physics': Icons.bolt_rounded,
        'chemistry': Icons.science_rounded,
        'biology': Icons.biotech_rounded,
        'drawing': Icons.architecture_rounded,
      };

      for (int i = 0; i < subjects.length; i++) {
        final s = subjects[i];
        final slug = (s['slug'] as String? ?? '').toLowerCase();
        final grad = gradients[(i + 4) % gradients.length];
        final icon = subjectIcons[slug] ?? Icons.menu_book_rounded;

        subList.add({
          'title': s['name'] ?? 'Subject',
          'badge': slug.toUpperCase(),
          'slug': slug,
          'subtitle': 'Admission Prep Questions & Solutions',
          'hasLive': true,
          'calendarText': 'Topic-wise Practice Drills',
          'count': 'Chapter-wise',
          'subjectId': s['id'],
          'gradient': grad,
          'watermarkIcon': icon,
        });
      }

      if (mounted) {
        setState(() {
          _institutionCards = instList;
          _modelTestCards = modelList;
          _subjectCards = subList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_institutionCards.isEmpty) {
            _institutionCards = UniversityCatalog.universities
                .map((u) => {
                      'title': u.code,
                      'badge': u.code,
                      'subtitle': u.fullName,
                      'hasLive': true,
                      'calendarText': u.location,
                      'count': '10+ Exams',
                      'filterKey': u.code,
                      'logoUrl': u.logoUrl ??
                          UniversityLogo.officialLogos[u.code.toLowerCase()],
                      'gradient': const [Color(0xFF542747), Color(0xFF542747)],
                      'watermarkIcon': Icons.school_rounded,
                    })
                .toList();
          }
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getActiveCards() {
    switch (_selectedFilterPill) {
      case 0:
        return _institutionCards;
      case 1:
        return _subjectCards;
      case 2:
      default:
        return _modelTestCards;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final activeCards = _getActiveCards();
    final filteredCards = _searchQuery.isEmpty
        ? activeCards
        : activeCards.where((c) {
            final title = (c['title'] as String).toLowerCase();
            final subtitle = (c['subtitle'] as String).toLowerCase();
            final q = _searchQuery.toLowerCase();
            return title.contains(q) || subtitle.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar + Scan OMR QR Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    color: Color(0xFF9CA3AF), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    onChanged: (val) =>
                                        setState(() => _searchQuery = val),
                                    decoration: InputDecoration(
                                      hintText: _selectedFilterPill == 1
                                          ? 'Search subjects (Physics, Math, English...)'
                                          : (_selectedFilterPill == 2
                                              ? 'Search full model tests...'
                                              : 'Search private universities (NSU, BRACU, AUST...)'),
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: InkWell(
                                      onTap: () => setState(() => _searchQuery = ''),
                                      child: const Center(
                                        child: Icon(Icons.close_rounded,
                                            color: Color(0xFF9CA3AF), size: 18),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'Scan Printable OMR QR Code',
                          child: InkWell(
                            onTap: () => PrintableOmrLauncher.openQrScanner(context),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: colors.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded,
                                      size: 20, color: colors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Scan QR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 2. Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedFilterPill == 1
                              ? 'Subject-Wise Practice & Chapters'
                              : (_selectedFilterPill == 2
                                  ? 'Full Admission Model Tests'
                                  : 'Private University Question Banks'),
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
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            '${filteredCards.length} Available',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Banner to All 60+ Database Model Tests
                    if (_selectedFilterPill == 2)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF542747), Color(0xFFFF7A36)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A36)
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.auto_stories_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Full Model Test Catalog',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '61+ live university model tests',
                                    style: TextStyle(
                                        fontSize: 10, color: Color(0xFFFFF3E6)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (GoRouter.maybeOf(context) != null) {
                                  context.push(AppRoutes.modelTestCatalog);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ModelTestCatalogScreen(
                                        candidateName:
                                            widget.profile?.name ?? 'Candidate',
                                        candidateCollege:
                                            widget.profile?.institutionName ??
                                                'Scholar',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF542747),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Browse',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. 2-Column Grid of 3D Glossy Cards (Dynamically Loaded from Database)
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: PrepInlineSkeleton(count: 3),
                      )
                    else if (filteredCards.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'No matching items found',
                            style: TextStyle(
                                fontSize: 13, color: colors.textSecondary),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCards.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.12,
                        ),
                        itemBuilder: (context, index) {
                          final card = filteredCards[index];
                          return PrepStaggeredItem(
                            index: index,
                            slideOffset: 16,
                            child: _buildGlossyTrackCard(context, card),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 4. Filter Pills at Bottom (Model Tests, University-wise, Subject-wise)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                border: const Border(
                    top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
              ),
              child: Row(
                children: [
                  _buildFilterPill(0, 'University-wise'),
                  const SizedBox(width: 8),
                  _buildFilterPill(1, 'Subject-wise'),
                  const SizedBox(width: 8),
                  _buildFilterPill(2, 'Model Tests'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilterPill == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedFilterPill = index);
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF542747) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF7A36)
                  : const Color(0xFFE5E7EB),
              width: isSelected ? 1.5 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF542747).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFFFFF3E6)
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlossyTrackCard(
      BuildContext context, Map<String, dynamic> card) {
    final gradient = card['gradient'] as List<Color>;
    final title = card['title'] as String;
    final subtitle = card['subtitle'] as String;
    final calendarText = card['calendarText'] as String;
    final count = card['count'] as String;
    final watermarkIcon = card['watermarkIcon'] as IconData;
    final badge = card['badge'] as String?;

    return InkWell(
      onTap: () {
        if (_selectedFilterPill == 0) {
          final uniKey = (card['badge'] ?? card['filterKey'] ?? title)
              .toString()
              .toLowerCase();
          if (GoRouter.maybeOf(context) != null) {
            context.push(
              AppRoutes.universityDetail,
              extra: {
                'universityKey': uniKey,
                'universityName': title,
                'shortCode':
                    (card['badge'] ?? card['filterKey'] ?? title).toString(),
              },
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UniversityDetailQuestionBankScreen(
                  universityKey: uniKey,
                  universityName: title,
                  shortCode:
                      (card['badge'] ?? card['filterKey'] ?? title).toString(),
                  location: calendarText,
                  candidateName: widget.profile?.name ?? 'Candidate',
                  candidateCollege:
                      widget.profile?.institutionName ?? 'Prep404 Scholar',
                ),
              ),
            );
          }
        } else if (_selectedFilterPill == 1) {
          final subSlug = (card['slug'] ?? card['badge'] ?? title)
              .toString()
              .toLowerCase();
          if (GoRouter.maybeOf(context) != null) {
            context.push(
              AppRoutes.subjectChapters,
              extra: {
                'title': title,
                'slug': subSlug,
                'icon': watermarkIcon,
                'color': gradient.first,
              },
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SubjectChapterDirectoryScreen(
                  subjectTitle: title,
                  subjectSlug: subSlug,
                  icon: watermarkIcon,
                  themeColor: gradient.first,
                ),
              ),
            );
          }
        } else {
          final uniKey = (card['badge'] ?? card['filterKey'] ?? title)
              .toString()
              .toLowerCase();
          if (GoRouter.maybeOf(context) != null) {
            context.push(
              AppRoutes.universityDetail,
              extra: {
                'universityKey': uniKey,
                'universityName': '${card['title']} Model Tests',
                'shortCode':
                    (card['filterKey'] ?? card['badge'] ?? title).toString(),
              },
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UniversityDetailQuestionBankScreen(
                  universityKey: uniKey,
                  universityName: '${card['title']} Model Tests',
                  shortCode:
                      (card['filterKey'] ?? card['badge'] ?? title).toString(),
                  location: calendarText,
                  candidateName: widget.profile?.name ?? 'Candidate',
                  candidateCollege:
                      widget.profile?.institutionName ?? 'Prep404 Scholar',
                  initialTabIndex: 2,
                ),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top Gloss Glass Shine Reflection Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Background Watermark Icon
            Positioned(
              right: -10,
              bottom: 10,
              child: Icon(
                watermarkIcon,
                size: 90,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Logo/Icon on left, clean count badge on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_selectedFilterPill == 0 ||
                          (_selectedFilterPill == 2 &&
                              card['filterKey'] != null))
                        UniversityLogo(
                          universityKey:
                              (badge ?? card['filterKey'] ?? title).toString(),
                          logoUrl: card['logoUrl'] as String?,
                          size: 32,
                          isCircle: true,
                          showShadow: true,
                        )
                      else
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(watermarkIcon,
                              color: Colors.white, size: 18),
                        ),
                      if (badge != null &&
                          _selectedFilterPill != 1 &&
                          badge.toLowerCase() != title.toLowerCase())
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Big White Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location / Topic row
                  Row(
                    children: [
                      Icon(
                          _selectedFilterPill == 1
                              ? Icons.menu_book_outlined
                              : Icons.location_on_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          calendarText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bottom Left Count Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 11, color: Color(0xFF542747)),
                        const SizedBox(width: 4),
                        Text(
                          count,
                          style: const TextStyle(
                            color: Color(0xFF542747),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

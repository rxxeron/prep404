import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_state_views.dart';
import '../../../ai_tutor/services/ai_socratic_tutor.dart';
import '../../../practice/presentation/widgets/dynamic_practice_view.dart';

/// Clean, categorized chapter and topic directory for subject-wise practice
class SubjectChapterDirectoryScreen extends StatefulWidget {
  final String subjectTitle;
  final String subjectSlug;
  final IconData icon;
  final Color themeColor;

  const SubjectChapterDirectoryScreen({
    super.key,
    required this.subjectTitle,
    required this.subjectSlug,
    required this.icon,
    required this.themeColor,
  });

  @override
  State<SubjectChapterDirectoryScreen> createState() =>
      _SubjectChapterDirectoryScreenState();
}

class _SubjectChapterDirectoryScreenState
    extends State<SubjectChapterDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getChapters() {
    final slug = widget.subjectSlug.toLowerCase();
    final title = widget.subjectTitle.toLowerCase();
    if (slug.contains('higher') || title.contains('higher')) {
      return [
        {
          'title': 'Differential & Integral Calculus',
          'questionCount': 180,
          'topics': [
            'Limits & Continuity',
            'Differentiation & Tangents',
            'Definite & Indefinite Integrals',
            'Applications & Area Under Curves',
          ],
        },
        {
          'title': 'Vectors & Coordinate Geometry',
          'questionCount': 160,
          'topics': [
            'Vectors: Dot & Cross Product',
            'Straight Lines & Slope Form',
            'Circle Equations & Tangents',
            'Conics: Parabola, Ellipse, Hyperbola',
          ],
        },
        {
          'title': 'Algebra, Matrices & Trigonometry',
          'questionCount': 150,
          'topics': [
            'Matrices & Determinants (Cramer\'s Rule)',
            'Quadratic Equations & Roots',
            'Trigonometric Functions & Identities',
            'Complex Numbers & Polar Form',
          ],
        },
      ];
    } else if (slug.contains('math') || title.contains('math')) {
      return [
        {
          'title': 'Algebra & Quantitative Reasoning',
          'questionCount': 220,
          'topics': [
            'Linear & Quadratic Equations',
            'Exponents & Logarithms',
            'Arithmetic & Geometric Progressions',
            'Permutation & Combination',
          ],
        },
        {
          'title': 'Geometry & Mensuration',
          'questionCount': 150,
          'topics': [
            'Triangles & Polygons',
            'Circles, Chords & Tangents',
            '3D Shapes & Solid Mensuration',
          ],
        },
        {
          'title': 'Commercial Arithmetic & Statistics',
          'questionCount': 140,
          'topics': [
            'Ratio, Proportion & Percentages',
            'Profit, Loss & Simple Interest',
            'Data Interpretation & Probability',
          ],
        },
      ];
    } else if (slug.contains('phy') || title.contains('phy')) {
      return [
        {
          'title': 'Mechanics & Dynamics',
          'questionCount': 190,
          'topics': [
            'Kinematics & Projectile Motion',
            'Newton\'s Laws & Momentum',
            'Work, Power & Energy',
            'Gravitation & Circular Motion',
          ],
        },
        {
          'title': 'Waves, Optics & Modern Physics',
          'questionCount': 160,
          'topics': [
            'Simple Harmonic Motion (SHM)',
            'Wave Motion & Sound Waves',
            'Geometrical & Physical Optics',
            'Atomic Structure & Photoelectric Effect',
          ],
        },
        {
          'title': 'Electricity & Magnetism',
          'questionCount': 175,
          'topics': [
            'Electrostatics & Capacitance',
            'Current Electricity & Ohm\'s Law',
            'Magnetic Field & Biot-Savart Law',
            'Electromagnetic Induction & AC',
          ],
        },
      ];
    } else if (slug.contains('chem') || title.contains('chem')) {
      return [
        {
          'title': 'Physical Chemistry & Gas Laws',
          'questionCount': 160,
          'topics': [
            'Ideal & Real Gas Laws (Van der Waals)',
            'Chemical Equilibrium & Le Chatelier',
            'Thermochemistry & Enthalpy',
            'Electrochemistry & Nernst Equation',
          ],
        },
        {
          'title': 'Inorganic Chemistry & Periodic Table',
          'questionCount': 140,
          'topics': [
            'Periodic Trends & Ionization Energy',
            'Chemical Bonding & Hybridization',
            'Coordination Compounds & Ligands',
            's, p, d, f Block Elements',
          ],
        },
        {
          'title': 'Organic Chemistry & Reaction Mechanisms',
          'questionCount': 210,
          'topics': [
            'IUPAC Nomenclature & Isomerism',
            'Hydrocarbons (Alkanes, Alkenes, Alkynes)',
            'Alcohols, Phenols & Carbonyls',
            'Carboxylic Acids & Biomolecules',
          ],
        },
      ];
    } else if (slug.contains('bio') || title.contains('bio')) {
      return [
        {
          'title': 'Cell Biology & Genetics',
          'questionCount': 180,
          'topics': [
            'Cell Structure & Organelles',
            'Cell Division (Mitosis & Meiosis)',
            'DNA Replication & Protein Synthesis',
            'Mendelian Inheritance & Mutations',
          ],
        },
        {
          'title': 'Plant & Human Physiology',
          'questionCount': 190,
          'topics': [
            'Photosynthesis & Plant Respiration',
            'Digestive & Circulatory Systems',
            'Respiratory & Excretory Systems',
            'Nervous System & Endocrine Hormones',
          ],
        },
      ];
    } else if (slug.contains('draw') ||
        slug.contains('arch') ||
        title.contains('draw') ||
        title.contains('arch')) {
      return [
        {
          'title': 'Freehand Sketching & Perspective',
          'questionCount': 40,
          'topics': [
            '1-Point & 2-Point Perspective Guidelines',
            'Light, Shadow & Texture Shading',
            'Object Drawing & Still Life Proportions',
            'Human Figure Scaling & Silhouette',
          ],
        },
        {
          'title': 'Architectural Composition & Space',
          'questionCount': 38,
          'topics': [
            'Conceptual Memory & Environmental Scenes',
            'Spatial Balance & Grid Layouts',
            '2D to 3D Projection & Visual Logic',
          ],
        },
      ];
    } else {
      return [
        {
          'title': 'Grammar & Sentence Syntax',
          'questionCount': 240,
          'topics': [
            'Subject-Verb Agreement',
            'Tenses & Conditionals',
            'Prepositions & Phrasal Verbs',
            'Sentence Correction (SAT Style)',
          ],
        },
        {
          'title': 'Vocabulary & Analogies',
          'questionCount': 210,
          'topics': [
            'Contextual Vocabulary & Usage',
            'Synonyms & Antonyms',
            'Word Analogy & Logical Relationship',
          ],
        },
        {
          'title': 'Reading Comprehension',
          'questionCount': 150,
          'topics': [
            'Critical Passage Reading',
            'Main Idea & Inferences',
            'Tone & Author Attitude',
          ],
        },
      ];
    }
  }

  void _startPractice(BuildContext context, String topicTitle) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        AppRoutes.practice,
        extra: {
          'title': '${widget.subjectTitle} • $topicTitle',
          'subjectId': widget.subjectSlug,
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(
                '${widget.subjectTitle} • $topicTitle',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: DynamicPracticeView(
              studyHintService: SocraticStudyHintService(),
              initialSubjectId: widget.subjectSlug,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allChapters = _getChapters();

    final query = _searchQuery.trim().toLowerCase();
    final filteredChapters = query.isEmpty
        ? allChapters
        : allChapters.where((ch) {
            final chTitle = (ch['title'] as String).toLowerCase();
            final topics = (ch['topics'] as List).cast<String>();
            final hasMatchingTopic = topics.any((t) => t.toLowerCase().contains(query));
            return chTitle.contains(query) || hasMatchingTopic;
          }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.themeColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              widget.subjectTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search chapters or topics (e.g. Calculus, Optics)...',
                hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.inputFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.tangerine, width: 1.5),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colors.borderSubtle),

          // Content Area
          Expanded(
            child: filteredChapters.isEmpty
                ? PrepNoSearchResultsView(
                    query: _searchQuery,
                    onClearSearch: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredChapters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final ch = filteredChapters[index];
                      final topics = (ch['topics'] as List).cast<String>();

                      return Container(
                        padding: const EdgeInsets.all(16),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ch['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.themeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${ch['questionCount']} Questions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.themeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: topics.map((t) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _startPractice(context, t),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: colors.background,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: colors.borderSubtle),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded,
                                              size: 16, color: widget.themeColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.arrow_forward_ios_rounded,
                                              size: 12, color: colors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

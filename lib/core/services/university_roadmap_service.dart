import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/university_target.dart';
import '../network/resilient_api_client.dart';
import 'cache_service.dart';
import 'supabase_service.dart';

/// Section pattern for a specific university examination
class UniversitySectionPattern {
  final String name;
  final String marks;
  final int progress; // 0..100
  final int weight; // % contribution to overall admission chance
  final Color color;
  final String chapters;

  const UniversitySectionPattern({
    required this.name,
    required this.marks,
    required this.progress,
    required this.weight,
    required this.color,
    required this.chapters,
  });

  factory UniversitySectionPattern.fromJson(
    Map<String, dynamic> json, [
    Color defaultColor = const Color(0xFFFF7A36),
  ]) {
    Color parsedColor = defaultColor;
    try {
      final hex = json['color']?.toString().replaceAll('#', '');
      if (hex != null && hex.isNotEmpty) {
        parsedColor = Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {
      parsedColor = defaultColor;
    }
    final marksVal = json['marks']?.toString() ??
        (json['questions'] != null ? '${json['questions']} Marks' : '25 Marks');
    final formattedMarks =
        marksVal.contains('Mark') ? marksVal : '$marksVal Marks';

    return UniversitySectionPattern(
      name: json['name']?.toString() ?? 'Section',
      marks: formattedMarks,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt() ?? 25,
      color: parsedColor,
      chapters: (json['topics'] is List)
          ? (json['topics'] as List).join(', ')
          : (json['chapters']?.toString() ?? ''),
    );
  }

  /// Mathematical contribution to the admission summit
  double get calculatedContribution => (weight * progress) / 100.0;
}

/// A node on the Admission Hiking Mountain
enum HikingNodeType { completed, active, locked, summit }

class HikingTrailNode {
  final String id;
  final String label;
  final String subtitle;
  final HikingNodeType type;
  final double xPercent; // 0..100
  final double yPercent; // 0..100
  final String? unlockCondition;
  final List<String> coveredTopics;

  const HikingTrailNode({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.type,
    required this.xPercent,
    required this.yPercent,
    this.unlockCondition,
    this.coveredTopics = const [],
  });
}

/// Leaderboard candidate entry
class UniversityLeaderboardEntry {
  final String rank;
  final String name;
  final String score;
  final String badge;

  const UniversityLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    required this.badge,
  });
}

/// Complete University Admission Blueprint & State
class UniversityRoadmapData {
  final String key;
  final String shortCode;
  final String fullName;
  final String department;
  final String? logoUrl;
  final int summitScore; // % ready (e.g. 0 for new student)
  final String totalMarksInfo;
  final String durationInfo;
  final LinearGradient gradient;
  final String dailyExamTitle;
  final String dailyExamDesc;
  final String dailyExamParticipants;
  final String userRank;
  final List<UniversitySectionPattern> sections;
  final List<HikingTrailNode> hikingNodes;
  final List<UniversityLeaderboardEntry> leaderboard;

  const UniversityRoadmapData({
    required this.key,
    required this.shortCode,
    required this.fullName,
    required this.department,
    this.logoUrl,
    required this.summitScore,
    required this.totalMarksInfo,
    required this.durationInfo,
    required this.gradient,
    required this.dailyExamTitle,
    required this.dailyExamDesc,
    required this.dailyExamParticipants,
    required this.userRank,
    required this.sections,
    required this.hikingNodes,
    required this.leaderboard,
  });
}

/// University branding configuration for UI rendering
class _UniversityBrandConfig {
  final String key;
  final String shortCode;
  final String fullName;
  final String department;
  final String? logoUrl;
  final LinearGradient gradient;
  final String dailyExamTitle;
  final String dailyExamDesc;
  final String dailyExamParticipants;

  const _UniversityBrandConfig({
    required this.key,
    required this.shortCode,
    required this.fullName,
    required this.department,
    this.logoUrl,
    required this.gradient,
    required this.dailyExamTitle,
    required this.dailyExamDesc,
    required this.dailyExamParticipants,
  });
}

/// Central Service providing University Roadmaps, Sections, and Hiking Trails
/// Completely database & API-driven via /api/v1/admission-plan/patterns
class UniversityRoadmapService {
  static final UniversityRoadmapService _instance =
      UniversityRoadmapService._internal();
  factory UniversityRoadmapService() => _instance;
  UniversityRoadmapService._internal() {
    _initializeCatalog();
  }

  static const List<Color> _sectionPalette = [
    Color(0xFFFF7A36), // Tangerine
    Color(0xFFFFD166), // Sunshine
    Color(0xFF542747), // Deep Plum
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Azure
  ];

  static const Map<String, _UniversityBrandConfig> _brands = {
    'brac': _UniversityBrandConfig(
      key: 'brac',
      shortCode: 'BRAC',
      fullName: 'BRAC University',
      department: 'CSE & Data Science (SECS)',
      logoUrl:
          'https://thumb.wikimedia.org/wikipedia/en/thumb/4/40/BRAC_University_monogram.svg/250px-BRAC_University_monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF542747), Color(0xFF7A3667), Color(0xFFFF7A36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'BRAC Special Daily Drill - 08',
      dailyExamDesc: 'BRAC Speed & Accuracy Test • 25 Questions • 25 Mins',
      dailyExamParticipants: '🔥 340 BRAC Candidates Enrolled',
    ),
    'nsu': _UniversityBrandConfig(
      key: 'nsu',
      shortCode: 'NSU',
      fullName: 'North South University',
      department: 'Electrical & Computer Eng (SEPS)',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/e/e0/North_South_University_Monogram.svg/250px-North_South_University_Monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF1B365D), Color(0xFF2C5E9E), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'NSU Speed & Aptitude Drill',
      dailyExamDesc: 'NSU Standard SAT Pattern • 30 Questions • 30 Mins',
      dailyExamParticipants: '🔥 520 NSU Candidates Enrolled',
    ),
    'aiub': _UniversityBrandConfig(
      key: 'aiub',
      shortCode: 'AIUB',
      fullName: 'American International University-Bangladesh',
      department: 'Science & Technology (FST)',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/b/b2/American_International_University-Bangladesh_monogram.svg/250px-American_International_University-Bangladesh_monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF003865), Color(0xFF1A5F7A), Color(0xFFFF7A36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'AIUB Engineering Math & Physics Drill',
      dailyExamDesc: 'AIUB Admission Standard • 25 Questions • 25 Mins',
      dailyExamParticipants: '🔥 210 AIUB Candidates Enrolled',
    ),
    'aust': _UniversityBrandConfig(
      key: 'aust',
      shortCode: 'AUST',
      fullName: 'Ahsanullah University of Science and Technology',
      department: 'Faculty of Engineering (FE)',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/5/53/Ahsanullah_University_of_Science_and_Technology_monogram.svg/250px-Ahsanullah_University_of_Science_and_Technology_monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF0D3B2E), Color(0xFF1B6B52), Color(0xFFFFD166)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'AUST HSC Depth Challenge',
      dailyExamDesc: 'AUST Rigorous Engineering Standard • 25 Questions',
      dailyExamParticipants: '🔥 430 AUST Candidates Enrolled',
    ),
    'ewu': _UniversityBrandConfig(
      key: 'ewu',
      shortCode: 'EWU',
      fullName: 'East West University',
      department: 'Faculty of Sciences & Engineering',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/3/3d/East_West_University_monogram.svg/250px-East_West_University_monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF6B1D2F), Color(0xFF9E2A2B), Color(0xFFFF7A36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'EWU Speed & Analytical Sprint',
      dailyExamDesc: 'EWU Admission Format • 25 Questions • 25 Mins',
      dailyExamParticipants: '🔥 180 EWU Candidates Enrolled',
    ),
    'uiu': _UniversityBrandConfig(
      key: 'uiu',
      shortCode: 'UIU',
      fullName: 'United International University',
      department: 'School of Science & Engineering',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/d/d4/United_International_University_Monogram.svg/250px-United_International_University_Monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF993300), Color(0xFFCC5500), Color(0xFFFFD166)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'UIU Engineering Aptitude Drill',
      dailyExamDesc: 'UIU Admission Standard • 20 Questions • 20 Mins',
      dailyExamParticipants: '🔥 195 UIU Candidates Enrolled',
    ),
    'diu': _UniversityBrandConfig(
      key: 'diu',
      shortCode: 'DIU',
      fullName: 'Daffodil International University',
      department: 'Faculty of Science & Information Technology',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/6/6f/Daffodil_International_University_monogram.svg/250px-Daffodil_International_University_monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF0F4C5C), Color(0xFF1A7589), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'DIU Foundation Skills Drill',
      dailyExamDesc: 'DIU Assessment Standard • 25 Questions • 25 Mins',
      dailyExamParticipants: '🔥 290 DIU Candidates Enrolled',
    ),
    'uap': _UniversityBrandConfig(
      key: 'uap',
      shortCode: 'UAP',
      fullName: 'University of Asia Pacific',
      department: 'School of Engineering & Architecture',
      logoUrl:
          'https://upload.wikimedia.org/wikipedia/en/thumb/a/ab/University_of_Asia_Pacific_monogram.svg/250px-University_of_Asia_Pacific_monogram.svg.png',
      gradient: LinearGradient(
        colors: [Color(0xFF3C2050), Color(0xFF5E3A7D), Color(0xFFFF7A36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      dailyExamTitle: 'UAP Written & MCQ Assessment Sprint',
      dailyExamDesc: 'UAP Admission Pattern • 20 Questions • 25 Mins',
      dailyExamParticipants: '🔥 140 UAP Candidates Enrolled',
    ),
  };

  final ValueNotifier<String> activeUniversityKey =
      ValueNotifier<String>('brac');

  final Map<String, UniversityRoadmapData> _catalog = {};
  final Map<String, List<Map<String, dynamic>>> _rawPatternsByUni = {};

  void setActiveUniversity(String key) {
    if (_catalog.containsKey(key)) {
      activeUniversityKey.value = key;
    }
  }

  UniversityRoadmapData get currentRoadmap =>
      getRoadmap(activeUniversityKey.value);

  UniversityRoadmapData getRoadmap(String key) {
    return _catalog[key] ?? _catalog.values.first;
  }

  List<UniversityRoadmapData> get allRoadmaps => _catalog.values.toList();

  /// Retrieve academic section patterns dynamically tailored to university and program track
  List<UniversitySectionPattern> getSectionsForProgram(
    String uniKey,
    DisciplineCategory category,
  ) {
    final lowerUni = uniKey.toLowerCase().trim();
    final patterns = _rawPatternsByUni[lowerUni] ?? [];

    if (patterns.isNotEmpty) {
      final matchedPattern = patterns.firstWhere((p) {
        final slug = (p['patternSlug'] ?? p['slug'] ?? '').toString().toLowerCase();
        final name = (p['patternName'] ?? '').toString().toLowerCase();
        switch (category) {
          case DisciplineCategory.business:
            return slug.contains('bba') || slug.contains('bus') || name.contains('bus');
          case DisciplineCategory.pharmacy:
            return slug.contains('pharm') || slug.contains('bio') || name.contains('pharm');
          case DisciplineCategory.architecture:
            return slug.contains('arch') || name.contains('arch');
          case DisciplineCategory.lawAndArts:
            return slug.contains('law') || slug.contains('hum') || name.contains('law');
          case DisciplineCategory.engineering:
            return slug.contains('eng') || slug.contains('cse') || name.contains('eng');
        }
      }, orElse: () => patterns.first);

      final rawSections = matchedPattern['sections'] as List? ?? [];
      if (rawSections.isNotEmpty) {
        final result = <UniversitySectionPattern>[];
        for (var i = 0; i < rawSections.length; i++) {
          final s = rawSections[i];
          if (s is Map<String, dynamic>) {
            final color = _sectionPalette[i % _sectionPalette.length];
            result.add(UniversitySectionPattern.fromJson(s, color));
          }
        }
        if (result.isNotEmpty) return result;
      }
    }

    // Default academic template when offline or awaiting network sync
    return _defaultSectionsForDiscipline(category);
  }

  /// Filters roadmaps to only those universities chosen by the user in onboarding
  List<UniversityRoadmapData> getRoadmapsForTargets(List<String> targetKeys) {
    if (targetKeys.isEmpty) return allRoadmaps;
    final lowerKeys = targetKeys.map((k) => k.toLowerCase().trim()).toSet();
    final filtered = _catalog.values.where((r) {
      return lowerKeys.contains(r.key.toLowerCase()) ||
          lowerKeys.contains(r.shortCode.toLowerCase()) ||
          lowerKeys.any((tk) => r.key.contains(tk) || tk.contains(r.key));
    }).toList();
    return filtered.isNotEmpty ? filtered : allRoadmaps;
  }

  /// Automatically aligns the active university with the candidate's selected targets
  void ensureActiveTarget(List<String> targetKeys) {
    if (targetKeys.isEmpty) return;
    final lowerKeys = targetKeys.map((k) => k.toLowerCase().trim()).toList();
    final current = activeUniversityKey.value.toLowerCase();

    final isAlreadyTarget = lowerKeys.contains(current) ||
        lowerKeys.any((tk) => current.contains(tk) || tk.contains(current));
    if (!isAlreadyTarget) {
      final match = _catalog.keys.firstWhere(
        (k) =>
            lowerKeys.contains(k) ||
            lowerKeys.any((tk) => k.contains(tk) || tk.contains(k)),
        orElse: () => _catalog.keys.first,
      );
      activeUniversityKey.value = match;
    }
  }

  /// Initialize baseline catalog with clean branding configuration
  void _initializeCatalog() {
    for (final entry in _brands.entries) {
      final key = entry.key;
      final brand = entry.value;
      final defaultSections =
          _defaultSectionsForDiscipline(DisciplineCategory.engineering);

      _catalog[key] = UniversityRoadmapData(
        key: key,
        shortCode: brand.shortCode,
        fullName: brand.fullName,
        department: brand.department,
        logoUrl: brand.logoUrl,
        summitScore: 0,
        totalMarksInfo: '100 Marks',
        durationInfo: '120 Mins',
        gradient: brand.gradient,
        dailyExamTitle: brand.dailyExamTitle,
        dailyExamDesc: brand.dailyExamDesc,
        dailyExamParticipants: brand.dailyExamParticipants,
        userRank: 'Unranked (Take 1 test)',
        sections: defaultSections,
        hikingNodes: _generateHikingNodes(key, brand.shortCode),
        leaderboard: _generateDefaultLeaderboard(),
      );
    }
  }

  List<HikingTrailNode> _generateHikingNodes(String key, String shortCode) {
    return [
      HikingTrailNode(
        id: '${key}_1',
        label: 'Basecamp',
        subtitle: 'English Comprehension & Grammar',
        type: HikingNodeType.active,
        xPercent: 15,
        yPercent: 82,
        unlockCondition: 'Active — Take your first foundation test',
        coveredTopics: const [
          'Reading Comprehension',
          'Sentence Correction',
          'Vocabulary & Syntax',
        ],
      ),
      HikingTrailNode(
        id: '${key}_2',
        label: 'Camp 02',
        subtitle: 'Core Mathematics & Functions',
        type: HikingNodeType.locked,
        xPercent: 62,
        yPercent: 55,
        unlockCondition: 'Unlocks with passing score on Basecamp test',
        coveredTopics: const [
          'Calculus & Coordinate Geometry',
          'Matrices & Determinants',
          'Algebra',
        ],
      ),
      HikingTrailNode(
        id: '${key}_3',
        label: 'Camp 03',
        subtitle: '$shortCode Specialized Sciences Drill',
        type: HikingNodeType.locked,
        xPercent: 22,
        yPercent: 32,
        unlockCondition: 'Unlocks with passing score on Camp 02 test',
        coveredTopics: const [
          'Physics Fundamentals',
          'Analytical Reasoning',
          'Specialized HSC Topics',
        ],
      ),
      HikingTrailNode(
        id: '${key}_4',
        label: 'Camp 04',
        subtitle: 'Time Pressure & Section Conquest',
        type: HikingNodeType.locked,
        xPercent: 70,
        yPercent: 18,
        unlockCondition: 'Unlocks with 80%+ on Camp 03',
        coveredTopics: const [
          'Negative Marking Management',
          'Rapid Speed Techniques',
        ],
      ),
      HikingTrailNode(
        id: '${key}_summit',
        label: 'The Summit',
        subtitle: '$shortCode Full Model Test Mastery',
        type: HikingNodeType.summit,
        xPercent: 50,
        yPercent: 5,
        unlockCondition: 'Unlocks after mastering all checkpoint camps',
        coveredTopics: const [
          'Full-Length Exam Hall Simulation',
          'Merit List Rank Qualification',
        ],
      ),
    ];
  }

  List<UniversityLeaderboardEntry> _generateDefaultLeaderboard() {
    return const [
      UniversityLeaderboardEntry(
        rank: '#1',
        name: 'Tanvir Hossain',
        score: '96.5%',
        badge: '👑 Summit Master',
      ),
      UniversityLeaderboardEntry(
        rank: '#2',
        name: 'Nusrat Jahan',
        score: '94.0%',
        badge: '⚡ Speed Demon',
      ),
      UniversityLeaderboardEntry(
        rank: '#3',
        name: 'Ahsanul Kabir',
        score: '91.5%',
        badge: '🎯 Precision Pro',
      ),
      UniversityLeaderboardEntry(
        rank: '#4',
        name: 'Fariha Anjum',
        score: '88.5%',
        badge: '🚀 Top 5%',
      ),
      UniversityLeaderboardEntry(
        rank: '#5',
        name: 'Saadman Rahman',
        score: '85.0%',
        badge: '🔥 Streak Champ',
      ),
    ];
  }

  List<UniversitySectionPattern> _defaultSectionsForDiscipline(
    DisciplineCategory category,
  ) {
    switch (category) {
      case DisciplineCategory.business:
        return const [
          UniversitySectionPattern(
            name: 'English Language & Reading',
            marks: '40 Marks',
            progress: 0,
            weight: 40,
            color: Color(0xFFFF7A36),
            chapters: 'Sentence Correction, Comprehension, Vocabulary',
          ),
          UniversitySectionPattern(
            name: 'Quantitative Mathematics',
            marks: '40 Marks',
            progress: 0,
            weight: 40,
            color: Color(0xFFFFD166),
            chapters: 'Arithmetic, Algebra, Word Problems',
          ),
          UniversitySectionPattern(
            name: 'Analytical & General Knowledge',
            marks: '20 Marks',
            progress: 0,
            weight: 20,
            color: Color(0xFF542747),
            chapters: 'Analytical Aptitude, Current Affairs & Heritage',
          ),
        ];
      case DisciplineCategory.pharmacy:
        return const [
          UniversitySectionPattern(
            name: 'English Proficiency',
            marks: '25 Marks',
            progress: 0,
            weight: 25,
            color: Color(0xFFFF7A36),
            chapters: 'Vocabulary, Syntax, Comprehension',
          ),
          UniversitySectionPattern(
            name: 'Chemistry',
            marks: '40 Marks',
            progress: 0,
            weight: 40,
            color: Color(0xFF10B981),
            chapters: 'Organic Chemistry, Chemical Bonding, Stoichiometry',
          ),
          UniversitySectionPattern(
            name: 'Biology',
            marks: '35 Marks',
            progress: 0,
            weight: 35,
            color: Color(0xFF3B82F6),
            chapters: 'Cell Biology, Genetics, Botany & Zoology',
          ),
        ];
      case DisciplineCategory.architecture:
        return const [
          UniversitySectionPattern(
            name: 'English & Basic Mathematics',
            marks: '25 Marks',
            progress: 0,
            weight: 25,
            color: Color(0xFFFF7A36),
            chapters: 'Grammar, Geometry, Basic Algebra',
          ),
          UniversitySectionPattern(
            name: 'Freehand Drawing & Visual Arts',
            marks: '50 Marks',
            progress: 0,
            weight: 50,
            color: Color(0xFF542747),
            chapters: 'Perspective Drawing, Light & Shade, Spatial Composition',
          ),
          UniversitySectionPattern(
            name: 'Analytical Aptitude',
            marks: '25 Marks',
            progress: 0,
            weight: 25,
            color: Color(0xFFFFD166),
            chapters: 'Spatial Reasoning, Pattern Recognition',
          ),
        ];
      case DisciplineCategory.lawAndArts:
        return const [
          UniversitySectionPattern(
            name: 'Advanced English',
            marks: '50 Marks',
            progress: 0,
            weight: 50,
            color: Color(0xFFFF7A36),
            chapters: 'Critical Reading, Legal Vocabulary, Grammar',
          ),
          UniversitySectionPattern(
            name: 'General Knowledge & Logic',
            marks: '30 Marks',
            progress: 0,
            weight: 30,
            color: Color(0xFF542747),
            chapters: 'Bangladesh Affairs, Constitution, Current Affairs',
          ),
          UniversitySectionPattern(
            name: 'Analytical Writing',
            marks: '20 Marks',
            progress: 0,
            weight: 20,
            color: Color(0xFF3B82F6),
            chapters: 'Argumentation, Composition, Ethical Reasoning',
          ),
        ];
      case DisciplineCategory.engineering:
        return const [
          UniversitySectionPattern(
            name: 'English Proficiency',
            marks: '30 Marks',
            progress: 0,
            weight: 30,
            color: Color(0xFFFF7A36),
            chapters: 'Syntax, Grammar, Reading Comprehension',
          ),
          UniversitySectionPattern(
            name: 'Higher Mathematics',
            marks: '50 Marks',
            progress: 0,
            weight: 50,
            color: Color(0xFF542747),
            chapters: 'Calculus, Coordinate Geometry, Vectors, Algebra',
          ),
          UniversitySectionPattern(
            name: 'Physics Fundamentals',
            marks: '20 Marks',
            progress: 0,
            weight: 20,
            color: Color(0xFF10B981),
            chapters: 'Mechanics, Waves, Electricity, Modern Physics',
          ),
        ];
    }
  }

  /// Synchronize university roadmaps and blueprints directly from live API & Supabase
  Future<void> syncFromDatabase() async {
    await syncFromApi();

    if (!SupabaseService().isInitialized) return;
    try {
      final supaClient = SupabaseService().client;
      final res = await supaClient
          .from('universities')
          .select(
              'id, code, short_name, full_name, logo_url, admission_test_patterns(id, pattern_name, slug, sections, total_marks, duration_seconds)')
          .eq('is_active', true);

      if (res.isNotEmpty) {
        for (final row in res) {
          final code = (row['code'] ?? '').toString().toLowerCase();
          final uniKey = code.replaceAll('u', ''); // 'bracu' -> 'brac'
          final targetKey = _catalog.containsKey(code)
              ? code
              : (_catalog.containsKey(uniKey) ? uniKey : code);

          final patterns = row['admission_test_patterns'] as List? ?? [];
          final sections = <UniversitySectionPattern>[];
          if (patterns.isNotEmpty) {
            final rawSections = patterns.first['sections'] as List? ?? [];
            for (var i = 0; i < rawSections.length; i++) {
              final s = rawSections[i];
              if (s is Map<String, dynamic>) {
                final color = _sectionPalette[i % _sectionPalette.length];
                sections.add(UniversitySectionPattern.fromJson(s, color));
              }
            }
          }
          if (sections.isNotEmpty) {
            final existing = _catalog[targetKey];
            if (existing != null) {
              _catalog[targetKey] = UniversityRoadmapData(
                key: existing.key,
                shortCode: (row['short_name'] ?? existing.shortCode).toString(),
                fullName: (row['full_name'] ?? existing.fullName).toString(),
                department: existing.department,
                logoUrl: row['logo_url']?.toString() ?? existing.logoUrl,
                summitScore: existing.summitScore,
                totalMarksInfo: existing.totalMarksInfo,
                durationInfo: existing.durationInfo,
                gradient: existing.gradient,
                dailyExamTitle: existing.dailyExamTitle,
                dailyExamDesc: existing.dailyExamDesc,
                dailyExamParticipants: existing.dailyExamParticipants,
                userRank: existing.userRank,
                sections: sections,
                hikingNodes: existing.hikingNodes,
                leaderboard: existing.leaderboard,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Synchronize university admission patterns directly from the Fastify Core API
  Future<void> syncFromApi() async {
    try {
      final res = await ResilientApiClient()
          .getWithFallback('/api/v1/admission-plan/patterns');
      if (res != null && res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic> && body['patterns'] is List) {
          CacheService().write('cached_admission_patterns', res.body);
          _applyPatternsJson(body['patterns'] as List);
          return;
        }
      }
    } catch (_) {}

    // Load from cache when offline
    final cached = CacheService().read<String>('cached_admission_patterns');
    if (cached != null) {
      try {
        final body = jsonDecode(cached);
        if (body is Map<String, dynamic> && body['patterns'] is List) {
          _applyPatternsJson(body['patterns'] as List);
        }
      } catch (_) {}
    }
  }

  void _applyPatternsJson(List patterns) {
    _rawPatternsByUni.clear();

    for (final p in patterns) {
      if (p is! Map<String, dynamic>) continue;
      final uniCode = (p['universityCode'] ?? '').toString().toLowerCase();
      final uniSlug = (p['universitySlug'] ?? '').toString().toLowerCase();
      final key = uniSlug.isNotEmpty
          ? uniSlug
          : (uniCode.endsWith('u') && uniCode.length > 3
              ? uniCode.substring(0, uniCode.length - 1)
              : uniCode);

      _rawPatternsByUni.putIfAbsent(key, () => []).add(p);
      if (uniCode != key) {
        _rawPatternsByUni.putIfAbsent(uniCode, () => []).add(p);
      }

      final existing = _catalog[key];
      if (existing != null) {
        final rawSections = p['sections'] as List? ?? [];
        if (rawSections.isNotEmpty) {
          final sections = <UniversitySectionPattern>[];
          for (var i = 0; i < rawSections.length; i++) {
            final s = rawSections[i];
            if (s is Map<String, dynamic>) {
              final color = _sectionPalette[i % _sectionPalette.length];
              sections.add(UniversitySectionPattern.fromJson(s, color));
            }
          }
          final totalMarks = p['totalMarks'] ?? 100;
          final durationMinutes = p['durationMinutes'] ?? 120;

          _catalog[key] = UniversityRoadmapData(
            key: existing.key,
            shortCode: (p['shortName'] ?? existing.shortCode).toString(),
            fullName: (p['fullName'] ?? existing.fullName).toString(),
            department: existing.department,
            logoUrl: p['logoUrl']?.toString() ?? existing.logoUrl,
            summitScore: existing.summitScore,
            totalMarksInfo: '$totalMarks Marks',
            durationInfo: '$durationMinutes Mins',
            gradient: existing.gradient,
            dailyExamTitle: existing.dailyExamTitle,
            dailyExamDesc: existing.dailyExamDesc,
            dailyExamParticipants: existing.dailyExamParticipants,
            userRank: existing.userRank,
            sections: sections,
            hikingNodes: existing.hikingNodes,
            leaderboard: existing.leaderboard,
          );
        }
      }
    }
  }
}

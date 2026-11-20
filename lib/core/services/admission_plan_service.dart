import 'dart:convert';
import '../models/university_target.dart';
import '../services/cache_service.dart';
import '../network/resilient_api_client.dart';
import 'university_roadmap_service.dart';

/// Preparation horizon options anchored to upcoming admission dates
enum PlanHorizon {
  tenDays(10, '10-Day Speed Sprint', 'High-Intensity Blitz • 2.0 Tests/Day'),
  fifteenDays(15, '15-Day High-Yield', 'Accelerated Push • ~1.1 Tests/Day'),
  thirtyDays(30, '30-Day Benchmark', 'Relaxed & Balanced • 1 Test / 2-3 Days'),
  twoMonths(60, '2-Month Foundation', 'Deep Foundation • 1 Test / 5 Days');

  final int days;
  final String title;
  final String subtitle;
  const PlanHorizon(this.days, this.title, this.subtitle);
}

/// The 4 distinct MCQ testing preparation pillars
enum PlanPreparationPillar {
  all('All Plan Tests', 'Comprehensive Drill List'),
  overall('Overall Preparation', 'Full Simulation Admission Mocks'),
  sectionWise('Section-wise', 'Faculty Mark Weightage Pattern'),
  subjectWise('Subject-wise', 'Math, English & Science Tests'),
  topicWise('Topic-wise', 'High-Yield Chapter Speed Drills');

  final String title;
  final String subtitle;
  const PlanPreparationPillar(this.title, this.subtitle);
}

/// Individual actionable MCQ exam item in the student's plan
class AdmissionPlanItem {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final PlanPreparationPillar pillar;
  final int dayNumber;
  final String? sessionSlot;
  final String displayDay;
  final int totalQuestions;
  final int durationMinutes;
  final double totalMarks;
  final double negativeMark;
  final String difficulty;
  final bool isCompleted;

  const AdmissionPlanItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.pillar,
    required this.dayNumber,
    this.sessionSlot,
    this.displayDay = '',
    required this.totalQuestions,
    required this.durationMinutes,
    required this.totalMarks,
    this.negativeMark = 0.25,
    this.difficulty = 'Standard',
    this.isCompleted = false,
  });

  factory AdmissionPlanItem.fromJson(Map<String, dynamic> json) {
    PlanPreparationPillar pillar = PlanPreparationPillar.topicWise;
    final pillarStr = json['pillar']?.toString().toLowerCase() ?? '';
    if (pillarStr.contains('subject')) {
      pillar = PlanPreparationPillar.subjectWise;
    } else if (pillarStr.contains('section')) {
      pillar = PlanPreparationPillar.sectionWise;
    } else if (pillarStr.contains('overall')) {
      pillar = PlanPreparationPillar.overall;
    }

    final dayNum = (json['dayNumber'] as num?)?.toInt() ?? 1;
    final rawDisplay = json['displayDay']?.toString();

    return AdmissionPlanItem(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'MCQ Test',
      subtitle: json['subtitle']?.toString() ?? 'Drill Test',
      pillar: pillar,
      dayNumber: dayNum,
      sessionSlot: json['sessionSlot']?.toString(),
      displayDay: (rawDisplay != null && rawDisplay.isNotEmpty)
          ? rawDisplay
          : 'Day $dayNum',
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 25,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 25,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 25.0,
      negativeMark: (json['negativeMark'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty']?.toString() ?? 'Standard',
      isCompleted: json['isCompleted'] == true,
    );
  }

  AdmissionPlanItem copyWith({bool? isCompleted}) {
    return AdmissionPlanItem(
      id: id,
      slug: slug,
      title: title,
      subtitle: subtitle,
      pillar: pillar,
      dayNumber: dayNumber,
      sessionSlot: sessionSlot,
      displayDay: displayDay,
      totalQuestions: totalQuestions,
      durationMinutes: durationMinutes,
      totalMarks: totalMarks,
      negativeMark: negativeMark,
      difficulty: difficulty,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// A sequential academic milestone stage in the candidate's journey
class AdmissionJourneyStage {
  final int stageNumber;
  final String title;
  final String subtitle;
  final int testCount;
  final List<AdmissionPlanItem> tests;

  const AdmissionJourneyStage({
    required this.stageNumber,
    required this.title,
    required this.subtitle,
    required this.testCount,
    required this.tests,
  });

  factory AdmissionJourneyStage.fromJson(Map<String, dynamic> json) {
    final rawTests = (json['tests'] as List? ?? []);
    final tests = rawTests
        .map((t) => AdmissionPlanItem.fromJson(t as Map<String, dynamic>))
        .toList();
    return AdmissionJourneyStage(
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? 'Stage',
      subtitle: json['subtitle']?.toString() ?? '',
      testCount: (json['testCount'] as num?)?.toInt() ?? tests.length,
      tests: tests,
    );
  }
}

/// Dynamic Admission Test Journey Data (100% Database-Driven)
class AdmissionJourneyData {
  final String universityCode;
  final String universityName;
  final String? logoUrl;
  final String? campusLocation;
  final List<String> availableTracks;
  final String activeTrack;
  final DateTime examDate;
  final int daysRemaining;
  final String season;
  final int academicYear;
  final String venue;
  final int horizonDays;
  final int autoHorizonDays;
  final String pacingLabel;
  final String dailyFrequency;
  final String cadenceDescription;
  final List<UniversitySectionPattern> sections;
  final List<AdmissionJourneyStage> stages;
  final List<AdmissionPlanItem> allPlanItems;

  const AdmissionJourneyData({
    required this.universityCode,
    required this.universityName,
    this.logoUrl,
    this.campusLocation,
    required this.availableTracks,
    required this.activeTrack,
    required this.examDate,
    required this.daysRemaining,
    required this.season,
    required this.academicYear,
    required this.venue,
    required this.horizonDays,
    required this.autoHorizonDays,
    this.pacingLabel = 'Relaxed & Balanced',
    this.dailyFrequency = '1 Test / 2-3 Days',
    this.cadenceDescription = '',
    required this.sections,
    required this.stages,
    required this.allPlanItems,
  });

  factory AdmissionJourneyData.fromJson(Map<String, dynamic> json) {
    final uni = json['university'] as Map<String, dynamic>? ?? {};
    final cycle = json['upcomingCycle'] as Map<String, dynamic>? ?? {};
    final horizon = json['horizon'] as Map<String, dynamic>? ?? {};
    final rawSections = json['sections'] as List? ?? [];
    final rawStages = json['stages'] as List? ?? [];
    final rawItems = json['allPlanItems'] as List? ?? [];
    final rawTracks = json['availableTracks'] as List? ?? [];

    DateTime examDt;
    try {
      examDt = DateTime.parse(cycle['examDate']?.toString() ?? '');
    } catch (_) {
      examDt = DateTime.now().add(const Duration(days: 35));
    }

    return AdmissionJourneyData(
      universityCode: uni['code']?.toString() ?? 'UNI',
      universityName: uni['fullName']?.toString() ?? 'University',
      logoUrl: uni['logoUrl']?.toString(),
      campusLocation: uni['campusLocation']?.toString(),
      availableTracks: rawTracks.map((t) => t.toString()).toList(),
      activeTrack: json['activeTrack']?.toString() ?? 'engineering',
      examDate: examDt,
      daysRemaining: (cycle['daysRemaining'] as num?)?.toInt() ?? 30,
      season: cycle['season']?.toString() ?? 'Spring',
      academicYear: (cycle['academicYear'] as num?)?.toInt() ?? 2026,
      venue: cycle['venue']?.toString() ?? '',
      horizonDays: (horizon['days'] as num?)?.toInt() ?? 30,
      autoHorizonDays: (horizon['autoDays'] as num?)?.toInt() ?? 30,
      pacingLabel: horizon['pacingLabel']?.toString() ?? 'Relaxed & Balanced',
      dailyFrequency:
          horizon['dailyFrequency']?.toString() ?? '1 Test / 2-3 Days',
      cadenceDescription: horizon['cadenceDescription']?.toString() ?? '',
      sections: rawSections
          .map((s) =>
              UniversitySectionPattern.fromJson(s as Map<String, dynamic>))
          .toList(),
      stages: rawStages
          .map((st) =>
              AdmissionJourneyStage.fromJson(st as Map<String, dynamic>))
          .toList(),
      allPlanItems: rawItems
          .map((item) =>
              AdmissionPlanItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  AdmissionJourneyData copyWith({
    List<AdmissionPlanItem>? allPlanItems,
    List<AdmissionJourneyStage>? stages,
  }) {
    return AdmissionJourneyData(
      universityCode: universityCode,
      universityName: universityName,
      logoUrl: logoUrl,
      campusLocation: campusLocation,
      availableTracks: availableTracks,
      activeTrack: activeTrack,
      examDate: examDate,
      daysRemaining: daysRemaining,
      season: season,
      academicYear: academicYear,
      venue: venue,
      horizonDays: horizonDays,
      autoHorizonDays: autoHorizonDays,
      pacingLabel: pacingLabel,
      dailyFrequency: dailyFrequency,
      cadenceDescription: cadenceDescription,
      sections: sections,
      stages: stages ?? this.stages,
      allPlanItems: allPlanItems ?? this.allPlanItems,
    );
  }
}

/// Service that dynamically constructs time-horizon MCQ testing plans
/// anchored to upcoming university admission dates.
class AdmissionPlanService {
  static final AdmissionPlanService _instance =
      AdmissionPlanService._internal();
  factory AdmissionPlanService() => _instance;
  AdmissionPlanService._internal();

  final CacheService _cache = CacheService();

  /// Remove mismatched faculty/track exams (e.g. Pharmacy tests inside Engineering/CSE)
  /// and raw oversized ingestion dumps from the student's roadmap.
  AdmissionJourneyData _filterTrackMismatches(
    AdmissionJourneyData journey,
    String activeTrack,
  ) {
    final track = activeTrack.toLowerCase();
    bool isAllowed(AdmissionPlanItem item) {
      final t = item.title.toUpperCase();
      if (t.contains('HEALER PYQ') || item.totalQuestions > 150) return false;
      if (track.contains('eng') || track.contains('cse')) {
        if (t.contains('PHARMACY') || t.contains('B.PHARM') || t.contains('BBA')) {
          return false;
        }
      } else if (track.contains('bus') || track.contains('bba')) {
        if (t.contains('PHARMACY') || t.contains('ENGINEERING')) return false;
      } else if (track.contains('pharm') || track.contains('bio')) {
        if (t.contains('BUSINESS') || t.contains('BBA') || t.contains('ENGINEERING')) {
          return false;
        }
      }
      return true;
    }

    final filteredStages = journey.stages.map((stage) {
      final kept = stage.tests.where(isAllowed).toList();
      return AdmissionJourneyStage(
        stageNumber: stage.stageNumber,
        title: stage.title,
        subtitle: stage.subtitle,
        testCount: kept.length,
        tests: kept,
      );
    }).toList();

    final filteredAll = journey.allPlanItems.where(isAllowed).toList();

    return AdmissionJourneyData(
      universityCode: journey.universityCode,
      universityName: journey.universityName,
      logoUrl: journey.logoUrl,
      campusLocation: journey.campusLocation,
      availableTracks: journey.availableTracks,
      activeTrack: journey.activeTrack,
      examDate: journey.examDate,
      daysRemaining: journey.daysRemaining,
      season: journey.season,
      academicYear: journey.academicYear,
      venue: journey.venue,
      horizonDays: journey.horizonDays,
      autoHorizonDays: journey.autoHorizonDays,
      pacingLabel: journey.pacingLabel,
      dailyFrequency: journey.dailyFrequency,
      cadenceDescription: journey.cadenceDescription,
      sections: journey.sections,
      stages: filteredStages,
      allPlanItems: filteredAll,
    );
  }

  /// Fetch complete dynamic journey from PostgreSQL Database / Fastify / Supabase
  Future<AdmissionJourneyData> fetchAdmissionJourney({
    required String universityKey,
    String? category,
    int? horizonDays,
  }) async {
    final code = _resolveUniCode(universityKey);
    final track = (category ?? 'engineering').toLowerCase();
    final days = horizonDays ?? 30;
    final cacheKey = 'journey_${code}_${track}_$days';

    // 1. Try backend with resilient candidate hosts
    try {
      final endpoint =
          '/api/v1/admission-plan/journey?universityCode=$code&category=$track&horizon=$days';
      final response = await ResilientApiClient().getWithFallback(endpoint,
          timeout: const Duration(milliseconds: 2500));
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          _cache.write(cacheKey, response.body);
          final journey = _filterTrackMismatches(
            AdmissionJourneyData.fromJson(data),
            track,
          );
          return _enrichWithCompletion(journey);
        }
      }
    } catch (_) {}

    // 2. Check local disk cache
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final journey = _filterTrackMismatches(
          AdmissionJourneyData.fromJson(data),
          track,
        );
        return _enrichWithCompletion(journey);
      } catch (_) {}
    }

    // 3. Fallback: generate from current catalog & service
    final horizonEnum = horizonDays == 10
        ? PlanHorizon.tenDays
        : (horizonDays == 15
            ? PlanHorizon.fifteenDays
            : (horizonDays == 60
                ? PlanHorizon.twoMonths
                : PlanHorizon.thirtyDays));

    DisciplineCategory discCat = DisciplineCategory.engineering;
    if (track.contains('business') || track.contains('bba')) {
      discCat = DisciplineCategory.business;
    } else if (track.contains('pharm') || track.contains('bio')) {
      discCat = DisciplineCategory.pharmacy;
    } else if (track.contains('arch')) {
      discCat = DisciplineCategory.architecture;
    }

    final fallbackItems = getPlanItems(
      universityKey: universityKey,
      horizon: horizonEnum,
      programCategory: discCat,
      pillarFilter: PlanPreparationPillar.all,
    );

    final sections =
        UniversityRoadmapService().getSectionsForProgram(code, discCat);
    final examDt = getEstimatedExamDate(universityKey);
    final daysLeft = getDaysRemaining(universityKey);

    final stage1 = fallbackItems
        .where((i) => i.pillar == PlanPreparationPillar.topicWise)
        .toList();
    final stage2 = fallbackItems
        .where((i) => i.pillar == PlanPreparationPillar.subjectWise)
        .toList();
    final stage3 = fallbackItems
        .where((i) => i.pillar == PlanPreparationPillar.sectionWise)
        .toList();
    final stage4 = fallbackItems
        .where((i) => i.pillar == PlanPreparationPillar.overall)
        .toList();

    final journey = AdmissionJourneyData(
      universityCode: code,
      universityName: '$code Admission',
      logoUrl: null,
      availableTracks: const [
        'engineering',
        'business',
        'pharmacy',
        'architecture'
      ],
      activeTrack: track,
      examDate: examDt,
      daysRemaining: daysLeft,
      season: 'Spring',
      academicYear: 2026,
      venue: 'Main Campus Exam Hall',
      horizonDays: horizonEnum.days,
      autoHorizonDays: getAutoHorizonForUniversity(universityKey).days,
      sections: sections,
      stages: [
        AdmissionJourneyStage(
          stageNumber: 1,
          title: 'Stage 1: High-Yield Topic Speed Drills',
          subtitle: 'Formula Accuracy & Rapid Error Spotting',
          testCount: stage1.length,
          tests: stage1,
        ),
        AdmissionJourneyStage(
          stageNumber: 2,
          title: 'Stage 2: Subject Mastery Testing',
          subtitle: 'Comprehensive Core Subject Syllabus Integration',
          testCount: stage2.length,
          tests: stage2,
        ),
        AdmissionJourneyStage(
          stageNumber: 3,
          title: 'Stage 3: Faculty Section Pattern Tests',
          subtitle: 'Exact University Mark Weightage Distribution',
          testCount: stage3.length,
          tests: stage3,
        ),
        AdmissionJourneyStage(
          stageNumber: 4,
          title: 'Stage 4: Full Simulation Mocks & Past Papers',
          subtitle: 'Timed Exam Hall Pressure with Negative Marking Penalty',
          testCount: stage4.length,
          tests: stage4,
        ),
      ],
      allPlanItems: fallbackItems,
    );

    return _enrichWithCompletion(journey);
  }

  AdmissionJourneyData _enrichWithCompletion(AdmissionJourneyData journey) {
    final completedIds = _getCompletedIds().toSet();
    final enrichedItems = journey.allPlanItems.map((item) {
      final isDone =
          completedIds.contains(item.id) || completedIds.contains(item.slug);
      return item.copyWith(isCompleted: isDone);
    }).toList();

    final enrichedStages = journey.stages.map((stage) {
      final stageTests = stage.tests.map((item) {
        final isDone =
            completedIds.contains(item.id) || completedIds.contains(item.slug);
        return item.copyWith(isCompleted: isDone);
      }).toList();
      return AdmissionJourneyStage(
        stageNumber: stage.stageNumber,
        title: stage.title,
        subtitle: stage.subtitle,
        testCount: stageTests.length,
        tests: stageTests,
      );
    }).toList();

    return journey.copyWith(
      allPlanItems: enrichedItems,
      stages: enrichedStages,
    );
  }

  /// Retrieve the upcoming exam date for a university
  DateTime getEstimatedExamDate(String rawKey) {
    final lower = rawKey.toLowerCase().trim();
    for (final u in UniversityCatalog.universities) {
      if (u.id.toLowerCase() == lower ||
          u.code.toLowerCase() == lower ||
          lower.contains(u.id)) {
        return u.estimatedExamDate;
      }
    }
    // Default fallback: ~35 days from now
    return DateTime.now().add(const Duration(days: 35));
  }

  /// Calculates days remaining until the target university exam
  int getDaysRemaining(String rawKey) {
    final examDate = getEstimatedExamDate(rawKey);
    final diff = examDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 10;
  }

  /// Automatically select the most relevant plan horizon based on admission date
  PlanHorizon getAutoHorizonForUniversity(String rawKey) {
    final days = getDaysRemaining(rawKey);
    if (days <= 12) return PlanHorizon.tenDays;
    if (days <= 20) return PlanHorizon.fifteenDays;
    if (days <= 45) return PlanHorizon.thirtyDays;
    return PlanHorizon.twoMonths;
  }

  /// Check whether an exam item has been completed by the student
  bool isItemCompleted(String itemId) {
    final completedList = _getCompletedIds();
    return completedList.contains(itemId);
  }

  /// Mark an exam item as completed and update local cache
  void markItemCompleted(String itemId) {
    final completedList = _getCompletedIds().toSet();
    completedList.add(itemId);
    _cache.write('completed_plan_items', completedList.toList());
  }

  List<String> _getCompletedIds() {
    final raw = _cache.read<dynamic>('completed_plan_items');
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Generate a structured MCQ testing roadmap based on university, horizon, and program category
  List<AdmissionPlanItem> getPlanItems({
    required String universityKey,
    required PlanHorizon horizon,
    DisciplineCategory programCategory = DisciplineCategory.engineering,
    PlanPreparationPillar pillarFilter = PlanPreparationPillar.all,
  }) {
    final code = _resolveUniCode(universityKey);
    final completedIds = _getCompletedIds().toSet();

    final allItems = <AdmissionPlanItem>[];

    // 1. Topic-wise Speed Drills (High yield, rapid MCQ tests)
    final topicDrills = _generateTopicDrills(code, horizon, programCategory);
    allItems.addAll(topicDrills);

    // 2. Subject-wise Drills (Math, English, Science)
    final subjectDrills =
        _generateSubjectDrills(code, horizon, programCategory);
    allItems.addAll(subjectDrills);

    // 3. Section-wise Faculty Pattern Tests (e.g. English 40%, Math 40%, Physics 20%)
    final sectionTests = _generateSectionTests(code, horizon, programCategory);
    allItems.addAll(sectionTests);

    // 4. Overall Full Simulations (Complete timed admission mock exams)
    final overallMocks = _generateOverallMocks(code, horizon, programCategory);
    allItems.addAll(overallMocks);

    // Distribute day numbers sequentially to fit within totalDays
    allItems.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    // Map completion state
    final mapped = allItems.map((item) {
      return item.copyWith(
        isCompleted:
            completedIds.contains(item.id) || completedIds.contains(item.slug),
      );
    }).toList();

    if (pillarFilter == PlanPreparationPillar.all) {
      return mapped;
    }
    return mapped.where((i) => i.pillar == pillarFilter).toList();
  }

  String _resolveUniCode(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('brac')) return 'BRACU';
    if (lower.contains('nsu') || lower.contains('north south')) return 'NSU';
    if (lower.contains('aust') || lower.contains('ahsanullah')) return 'AUST';
    if (lower.contains('aiub') || lower.contains('american international')) {
      return 'AIUB';
    }
    if (lower.contains('ewu') || lower.contains('east west')) return 'EWU';
    if (lower.contains('iub') || lower.contains('independent')) return 'IUB';
    if (lower.contains('uiu') || lower.contains('united international')) {
      return 'UIU';
    }
    if (lower.contains('uap') || lower.contains('asia pacific')) return 'UAP';
    return raw.toUpperCase();
  }

  List<AdmissionPlanItem> _generateTopicDrills(
      String code, PlanHorizon horizon, DisciplineCategory category) {
    final list = <AdmissionPlanItem>[];

    List<Map<String, dynamic>> topics;

    if (category == DisciplineCategory.business) {
      topics = [
        {
          'title': '$code Sentence Correction & Error Spotting',
          'sub': 'Cliffs TOEFL Reading & Grammar Speed Drill',
          'day': 1,
          'q': 25,
          'dur': 20,
          'slug': '${code.toLowerCase()}_topic_grammar'
        },
        {
          'title': '$code Arithmetic & Word Problems Speed Drill',
          'sub': 'Percentages, Profit-Loss & Ratios',
          'day': 2,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_arithmetic'
        },
        {
          'title': '$code Quantitative Problem Solving Drill',
          'sub': 'Linear Equations & Quadratic Functions',
          'day': 3,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_quant'
        },
        {
          'title': '$code Critical Reading & Analytical Logic',
          'sub': 'Inference Passages & Pattern Reasoning',
          'day': 4,
          'q': 25,
          'dur': 20,
          'slug': '${code.toLowerCase()}_topic_analytical'
        },
        {
          'title': '$code Vocabulary & Sentence Completion',
          'sub': 'High-Frequency Admission Vocab Drills',
          'day': 5,
          'q': 25,
          'dur': 18,
          'slug': '${code.toLowerCase()}_topic_vocab'
        },
      ];
      if (horizon.days >= 30) {
        topics.addAll([
          {
            'title': '$code Data Interpretation & Tables Drill',
            'sub': 'Charts, Graphs & Numerical Logic',
            'day': 7,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_data_interp'
          },
          {
            'title': '$code Algebraic Reasoning & Sequences Drill',
            'sub': 'Series, Progression & Exponent Rules',
            'day': 9,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_algebra'
          },
          {
            'title': '$code Advanced Modifier & Parallelism Drill',
            'sub': 'Grammar Syntax & Clause Spotting',
            'day': 11,
            'q': 25,
            'dur': 20,
            'slug': '${code.toLowerCase()}_topic_verbal'
          },
          {
            'title': '$code Speed Mental Math Shortcuts',
            'sub': 'Quick Estimation & Calculation Drills',
            'day': 13,
            'q': 25,
            'dur': 20,
            'slug': '${code.toLowerCase()}_topic_speed_math'
          },
        ]);
      }
      if (horizon.days >= 60) {
        topics.addAll([
          {
            'title': '$code Logical Deductions & Syllogisms Drill',
            'sub': 'Critical Thinking & Assertion Sets',
            'day': 18,
            'q': 30,
            'dur': 30,
            'slug': '${code.toLowerCase()}_topic_adv_analytical'
          },
          {
            'title': '$code Advanced Reading Comprehension',
            'sub': 'Complex Passages & Tone Analysis',
            'day': 22,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_adv_reading'
          },
          {
            'title': '$code Business Aptitude Comprehensive Sprint',
            'sub': 'Multi-Section Rapid Speed Drill',
            'day': 26,
            'q': 25,
            'dur': 20,
            'slug': '${code.toLowerCase()}_topic_aptitude_sprint'
          },
        ]);
      }
    } else if (category == DisciplineCategory.pharmacy) {
      topics = [
        {
          'title': '$code Cell Biology & Genetics Speed Drill',
          'sub': 'Mitosis, DNA Replication & Heredity',
          'day': 1,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_genetics'
        },
        {
          'title': '$code Organic Chemistry Fundamentals Drill',
          'sub': 'Hydrocarbons, Isomerism & Functional Groups',
          'day': 2,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_organic_chem'
        },
        {
          'title': '$code Human Physiology & Organ Systems',
          'sub': 'Circulation, Digestion & Neuro-Endocrine',
          'day': 3,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_physiology'
        },
        {
          'title': '$code Chemical Energetics & Buffer Solutions',
          'sub': 'pH, Molarity, Titration & Thermochemistry',
          'day': 4,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_solutions'
        },
        {
          'title': '$code Scientific English Vocabulary & Syntax',
          'sub': 'High-Frequency Medical Cloze & Grammar',
          'day': 5,
          'q': 25,
          'dur': 20,
          'slug': '${code.toLowerCase()}_topic_sci_english'
        },
      ];
      if (horizon.days >= 30) {
        topics.addAll([
          {
            'title': '$code Plant Physiology & Botany Drill',
            'sub': 'Photosynthesis, Respiration & Plant Anatomy',
            'day': 7,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_botany'
          },
          {
            'title': '$code Periodic Trends & Chemical Bonding',
            'sub': 'Hybridization, Molecular Orbitals & Metals',
            'day': 9,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_inorganic_chem'
          },
          {
            'title': '$code Microorganisms & Immunology Drill',
            'sub': 'Bacteria, Viruses, Vaccines & Defense',
            'day': 11,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_immunology'
          },
          {
            'title': '$code Quantitative Chemistry & Stoichiometry',
            'sub': 'Mole Concept & Chemical Equilibrium',
            'day': 13,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_stoichiometry'
          },
        ]);
      }
      if (horizon.days >= 60) {
        topics.addAll([
          {
            'title': '$code Biochemistry & Molecular Biology',
            'sub': 'Enzymes, Lipids, Proteins & Metabolic Cycles',
            'day': 18,
            'q': 30,
            'dur': 30,
            'slug': '${code.toLowerCase()}_topic_biochem'
          },
          {
            'title': '$code Environmental Chemistry & Gas Laws',
            'sub': 'Atmospheric Reactions & Ideal Gases',
            'day': 22,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_env_chem'
          },
          {
            'title': '$code High-Yield Biological Diagrams & MCQs',
            'sub': 'Histology & Reproduction Benchmark',
            'day': 26,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_adv_biology'
          },
        ]);
      }
    } else if (category == DisciplineCategory.architecture) {
      topics = [
        {
          'title': '$code Spatial Reasoning & 3D Projections',
          'sub': 'Isometric Views & Orthographic Logic',
          'day': 1,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_spatial'
        },
        {
          'title': '$code Coordinate Geometry & Trigonometry Drill',
          'sub': 'Lines, Angles, Triangles & Surfaces',
          'day': 2,
          'q': 25,
          'dur': 30,
          'slug': '${code.toLowerCase()}_topic_geom_arch'
        },
        {
          'title': '$code Freehand Drawing & Perspective Concepts',
          'sub': 'One-Point & Two-Point Perspective Rules',
          'day': 3,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_perspective'
        },
        {
          'title': '$code English Visual Vocabulary & Error Spotting',
          'sub': 'Aesthetic Theory & Sentence Correction',
          'day': 4,
          'q': 25,
          'dur': 20,
          'slug': '${code.toLowerCase()}_topic_arch_english'
        },
        {
          'title': '$code Patterns, Symmetry & Tessellations',
          'sub': 'Geometric Solids & Scale Calculations',
          'day': 5,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_symmetry'
        },
      ];
      if (horizon.days >= 30) {
        topics.addAll([
          {
            'title': '$code Conic Sections & Curve Analysis',
            'sub': 'Parabolas, Ellipses & Architectural Curves',
            'day': 7,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_conics'
          },
          {
            'title': '$code Mental Rotation & Spatial Unfolding',
            'sub': 'Cube Unfolding & Surface Pattern Matching',
            'day': 9,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_unfolding'
          },
          {
            'title': '$code Shadows, Lighting & Shade Analysis',
            'sub': 'Sun Path & Light Angle Geometry',
            'day': 11,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_shadows'
          },
          {
            'title': '$code Structural Mechanics Basics Drill',
            'sub': 'Trusses, Beams, Tension & Compression',
            'day': 13,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_structures'
          },
        ]);
      }
      if (horizon.days >= 60) {
        topics.addAll([
          {
            'title': '$code Golden Ratio & Proportion Geometry',
            'sub': 'Fibonacci & Classic Architectural Scaling',
            'day': 18,
            'q': 30,
            'dur': 30,
            'slug': '${code.toLowerCase()}_topic_proportion'
          },
          {
            'title': '$code Architectural History & Landmark Styles',
            'sub': 'Global & Bengali Architectural Heritage',
            'day': 22,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_history'
          },
          {
            'title': '$code Rapid Visual Thinking Sprint',
            'sub': 'Combined Speed Spatial Test',
            'day': 26,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_spatial_sprint'
          },
        ]);
      }
    } else {
      // Default: Engineering & CSE
      topics = [
        {
          'title': '$code English Sentence Correction & Cloze',
          'sub': 'Reading & Grammar Speed Drill',
          'day': 1,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_grammar'
        },
        {
          'title': '$code Calculus & Derivatives Speed Drill',
          'sub': 'Limits, Continuity & Differentiation',
          'day': 2,
          'q': 25,
          'dur': 30,
          'slug': '${code.toLowerCase()}_topic_calculus'
        },
        {
          'title': '$code Vectors & Coordinate Geometry Drill',
          'sub': 'Straight Lines, Circles & Vector Algebra',
          'day': 3,
          'q': 25,
          'dur': 30,
          'slug': '${code.toLowerCase()}_topic_geometry'
        },
        {
          'title': '$code Dynamics & Mechanics Formulas Drill',
          'sub': 'Newtonian Laws, Momentum & Friction',
          'day': 4,
          'q': 25,
          'dur': 25,
          'slug': '${code.toLowerCase()}_topic_dynamics'
        },
        {
          'title': '$code English Vocabulary & Error Hunting',
          'sub': 'High-Frequency Admission Vocab Drills',
          'day': 5,
          'q': 25,
          'dur': 20,
          'slug': '${code.toLowerCase()}_topic_vocab'
        },
      ];

      if (horizon.days >= 30) {
        topics.addAll([
          {
            'title': '$code Trigonometry & Complex Numbers Drill',
            'sub': 'Trig Equations & Complex Plane',
            'day': 7,
            'q': 25,
            'dur': 30,
            'slug': '${code.toLowerCase()}_topic_trig'
          },
          {
            'title': '$code Electrostatics & Current Electricity',
            'sub': 'Circuit Calculations & Field Lines',
            'day': 9,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_circuits'
          },
          {
            'title': '$code Matrices & Determinants Drill',
            'sub': 'Cramer Rule, Matrix Inversion & Rank',
            'day': 11,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_matrices'
          },
          {
            'title': '$code Modern Physics & Semiconductor Devices',
            'sub': 'Photon Energy & Logic Gates',
            'day': 13,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_modern_phys'
          },
        ]);
      }

      if (horizon.days >= 60) {
        topics.addAll([
          {
            'title': '$code Integration & Definite Integrals Drill',
            'sub': 'Areas under Curves & Substitution',
            'day': 18,
            'q': 30,
            'dur': 35,
            'slug': '${code.toLowerCase()}_topic_integrals'
          },
          {
            'title': '$code Waves, Optics & Thermodynamics',
            'sub': 'Sound Waves, Interference & Gas Laws',
            'day': 22,
            'q': 25,
            'dur': 30,
            'slug': '${code.toLowerCase()}_topic_optics'
          },
          {
            'title': '$code Critical Reading & Analytical Logic',
            'sub': 'Inference Passages & Pattern Reasoning',
            'day': 26,
            'q': 25,
            'dur': 25,
            'slug': '${code.toLowerCase()}_topic_analytical'
          },
        ]);
      }
    }

    for (final t in topics) {
      list.add(AdmissionPlanItem(
        id: '${code.toLowerCase()}_topic_${t['day']}',
        slug: t['slug'] as String,
        title: t['title'] as String,
        subtitle: t['sub'] as String,
        pillar: PlanPreparationPillar.topicWise,
        dayNumber: t['day'] as int,
        totalQuestions: t['q'] as int,
        durationMinutes: t['dur'] as int,
        totalMarks: (t['q'] as int).toDouble(),
        negativeMark: 0.25,
        difficulty: 'High-Yield Speed Drill',
      ));
    }
    return list;
  }

  List<AdmissionPlanItem> _generateSubjectDrills(
      String code, PlanHorizon horizon, DisciplineCategory category) {
    final list = <AdmissionPlanItem>[];

    List<Map<String, dynamic>> subjects;

    if (category == DisciplineCategory.business) {
      subjects = [
        {
          'title': '$code Quantitative Mathematics Subject Test',
          'sub': 'Full Secondary Arithmetic & Algebra Syllabus',
          'day': (horizon.days * 0.35).round(),
          'q': 35,
          'dur': 45,
          'slug': '${code.toLowerCase()}_subject_quant'
        },
        {
          'title': '$code English Language & Verbal Ability Test',
          'sub': 'Syntax, Sentence Correction & Critical Reading',
          'day': (horizon.days * 0.45).round(),
          'q': 35,
          'dur': 40,
          'slug': '${code.toLowerCase()}_subject_verbal'
        },
      ];
      if (horizon.days >= 30) {
        subjects.add({
          'title': '$code Analytical Aptitude & Problem Solving',
          'sub': 'Decision Making, Charts & Syllogism Drills',
          'day': (horizon.days * 0.65).round(),
          'q': 30,
          'dur': 35,
          'slug': '${code.toLowerCase()}_subject_analytical'
        });
      }
    } else if (category == DisciplineCategory.pharmacy) {
      subjects = [
        {
          'title': '$code Biology Core Subject Mastery Test',
          'sub': 'HSC 1st & 2nd Paper (Botany & Zoology)',
          'day': (horizon.days * 0.35).round(),
          'q': 35,
          'dur': 45,
          'slug': '${code.toLowerCase()}_subject_biology'
        },
        {
          'title': '$code Chemistry Comprehensive Mastery Test',
          'sub': 'Organic, Physical & Inorganic Chemistry Integration',
          'day': (horizon.days * 0.45).round(),
          'q': 35,
          'dur': 40,
          'slug': '${code.toLowerCase()}_subject_chemistry'
        },
      ];
      if (horizon.days >= 30) {
        subjects.add({
          'title': '$code English Language & Scientific Reading',
          'sub': 'Medical Nomenclature & Syntax Error Spotting',
          'day': (horizon.days * 0.65).round(),
          'q': 30,
          'dur': 35,
          'slug': '${code.toLowerCase()}_subject_english'
        });
      }
    } else if (category == DisciplineCategory.architecture) {
      subjects = [
        {
          'title': '$code Spatial Visualization & Aptitude Test',
          'sub': '3D Rotation, Plan Views & Perspective Thinking',
          'day': (horizon.days * 0.35).round(),
          'q': 35,
          'dur': 45,
          'slug': '${code.toLowerCase()}_subject_spatial'
        },
        {
          'title': '$code Mathematics for Architecture Test',
          'sub': 'Geometry, Mensuration & Trigonometric Scales',
          'day': (horizon.days * 0.45).round(),
          'q': 35,
          'dur': 40,
          'slug': '${code.toLowerCase()}_subject_arch_math'
        },
      ];
      if (horizon.days >= 30) {
        subjects.add({
          'title': '$code English Language & Aesthetic Logic',
          'sub': 'Design Comprehension & Vocabulary Drills',
          'day': (horizon.days * 0.65).round(),
          'q': 30,
          'dur': 35,
          'slug': '${code.toLowerCase()}_subject_english'
        });
      }
    } else {
      // Default: Engineering
      subjects = [
        {
          'title': '$code Higher Mathematics Core Subject Test',
          'sub': 'Full HSC Syllabus Science Integration',
          'day': (horizon.days * 0.35).round(),
          'q': 35,
          'dur': 45,
          'slug': '${code.toLowerCase()}_subject_math'
        },
        {
          'title': '$code English Language Subject Mastery Test',
          'sub': 'Syntax, Comprehension & Error Hunting',
          'day': (horizon.days * 0.45).round(),
          'q': 35,
          'dur': 40,
          'slug': '${code.toLowerCase()}_subject_english'
        },
        {
          'title': '$code Physics Fundamentals Subject Test',
          'sub': 'Mechanics, Electricity & Modern Physics',
          'day': (horizon.days * 0.55).round(),
          'q': 30,
          'dur': 40,
          'slug': '${code.toLowerCase()}_subject_physics'
        },
      ];
      if (horizon.days >= 30) {
        subjects.add({
          'title': '$code Analytical & Chemistry Aptitude Test',
          'sub': 'Logical Reasoning & Formula Speed Drill',
          'day': (horizon.days * 0.65).round(),
          'q': 30,
          'dur': 35,
          'slug': '${code.toLowerCase()}_subject_analytical'
        });
      }
    }

    for (final s in subjects) {
      list.add(AdmissionPlanItem(
        id: '${code.toLowerCase()}_subject_${s['day']}',
        slug: s['slug'] as String,
        title: s['title'] as String,
        subtitle: s['sub'] as String,
        pillar: PlanPreparationPillar.subjectWise,
        dayNumber: s['day'] as int,
        totalQuestions: s['q'] as int,
        durationMinutes: s['dur'] as int,
        totalMarks: (s['q'] as int).toDouble(),
        negativeMark: 0.25,
        difficulty: 'Subject Mastery',
      ));
    }
    return list;
  }

  List<AdmissionPlanItem> _generateSectionTests(
      String code, PlanHorizon horizon, DisciplineCategory category) {
    final list = <AdmissionPlanItem>[];
    final u = code.toLowerCase();

    List<Map<String, dynamic>> sections;

    if (category == DisciplineCategory.business) {
      if (u == 'nsu') {
        sections = [
          {
            'title': 'NSU SBE Section 1: English Grammar & Vocab',
            'sub': 'Cliffs TOEFL Pattern (50% Mark Weightage)',
            'day': (horizon.days * 0.5).round(),
            'q': 30,
            'dur': 30,
            'marks': 30.0,
            'slug':
                'nsu-admission-test-summer-2025-section-1-english-grammar-and-vocabulary'
          },
          {
            'title': 'NSU SBE Section 2: Quantitative Aptitude',
            'sub': 'Algebra & Problem Solving (50% Mark Weightage)',
            'day': (horizon.days * 0.6).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug':
                'nsu-admission-test-summer-2025-section-2-quantitative-aptitude'
          },
          {
            'title': 'NSU Cliffs TOEFL Grammar Mini-Test',
            'sub': 'High-Yield Speed OMR Section Drill',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'nsu-admission-special-cliffs-toefl-grammar-mini-test-01'
          },
        ];
      } else if (u == 'aiub') {
        sections = [
          {
            'title': 'AIUB BBA Section: Quantitative Section',
            'sub': 'BBA CIS Quantitative Section Pattern',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug':
                'aiub-bba-cis-official-model-test-sample-quantitative-section'
          },
          {
            'title': 'AIUB BBA Section: Verbal & English',
            'sub': 'Official Model Test Sample Verbal Section',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'aiub-bba-cis-official-model-test-sample-verbal-section'
          },
          {
            'title': 'AIUB FASS Section: General Knowledge',
            'sub': 'Faculty General Knowledge Test',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 20,
            'marks': 25.0,
            'slug': 'aiub-fass-official-model-test-section-b-general-knowledge'
          },
        ];
      } else if (u == 'ewu') {
        sections = [
          {
            'title': 'EWU FBS Section I: English Language',
            'sub': 'FBS Admission English Paper (Summer 2025)',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'ewu-admission-test-summer-2025-fbs-section-i-english'
          },
          {
            'title': 'EWU FBS Section II: General Mathematics',
            'sub': 'Arithmetic & Secondary Math Problem Solving',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'ewu-admission-test-summer-2025-fbs-section-ii-general-math'
          },
        ];
      } else if (u == 'uap') {
        sections = [
          {
            'title': 'UAP BBA Section: English Language',
            'sub': 'BBA Admission Grammar & Reading Section',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'uap-bba-admission-model-test-english'
          },
          {
            'title': 'UAP BBA Section: Mathematics',
            'sub': 'General Quantitative Problem Solving',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'uap-bba-admission-model-test-mathematics'
          },
          {
            'title': 'UAP BBA Section: Descriptive & Aptitude',
            'sub': 'Analytical Tasks & Verbal Reasoning',
            'day': (horizon.days * 0.7).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'uap-bba-admission-model-test-descriptive-aptitude-tasks'
          },
        ];
      } else {
        sections = [
          {
            'title': '$code BBA Section 1: English Language',
            'sub': 'Grammar, Comprehension & Sentence Completion',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'bracu-admission-model-test-02-section-a'
          },
          {
            'title': '$code BBA Section 2: Quantitative Aptitude',
            'sub': 'Percentages, Algebra & Secondary Math',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'bracu-admission-model-test-02-section-b'
          },
          {
            'title': '$code BBA Section 3: Critical Reasoning',
            'sub': 'Analytical Thinking & Logic Deductions',
            'day': (horizon.days * 0.7).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'bracu-admission-model-test-02-section-c'
          },
        ];
      }
    } else if (category == DisciplineCategory.pharmacy) {
      if (u == 'uap') {
        sections = [
          {
            'title': 'UAP Pharmacy Section: Biology',
            'sub': 'Botany & Zoology High-Yield Faculty Section',
            'day': (horizon.days * 0.5).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug': 'uap-pharmacy-admission-model-test-biology'
          },
          {
            'title': 'UAP Pharmacy Section: Chemistry',
            'sub': 'Organic & Inorganic Reactions Faculty Paper',
            'day': (horizon.days * 0.6).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug': 'uap-pharmacy-admission-model-test-chemistry'
          },
          {
            'title': 'UAP Pharmacy Section: English',
            'sub': 'Grammar, Syntax & Scientific Cloze',
            'day': (horizon.days * 0.7).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'uap-bba-admission-model-test-english'
          },
        ];
      } else if (u == 'uiu') {
        sections = [
          {
            'title': 'UIU Pharmacy Section: Biology',
            'sub': 'School of Life Sciences Biology Mark Weightage',
            'day': (horizon.days * 0.5).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug': 'uiu-pharmacy-official-model-test-biology-section'
          },
          {
            'title': 'UIU Pharmacy Section: Chemistry',
            'sub': 'School of Life Sciences Chemistry Mark Weightage',
            'day': (horizon.days * 0.6).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug': 'uiu-pharmacy-official-model-test-chemistry-section'
          },
          {
            'title': 'UIU Pharmacy Section: English',
            'sub': 'Sentence Correction & Medical Vocabulary',
            'day': (horizon.days * 0.7).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'uiu-pharmacy-official-model-test-english-section'
          },
        ];
      } else if (u == 'iub') {
        sections = [
          {
            'title': 'IUB Pharmacy Section: Biology & Science',
            'sub': 'Summer 2025 Slot 2 Pharmacy Faculty Paper',
            'day': (horizon.days * 0.5).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug': 'iub-admission-test-summer-2025-slot-2-pharmacy-test'
          },
          {
            'title': 'IUB Pharmacy Section: General Science',
            'sub': 'Chemistry & Scientific Principles',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'iub-admission-test-summer-2025-slot-2-general-science'
          },
          {
            'title': 'IUB Pharmacy Section: English',
            'sub': 'Section One Grammar & Syntax',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug':
                'iub-admission-test-summer-2025-slot-2-basic-test-english-section-one-grammar'
          },
        ];
      } else {
        sections = [
          {
            'title': '$code Pharmacy Section: Biology',
            'sub': 'Botany & Zoology Admission Mark Weightage',
            'day': (horizon.days * 0.5).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug': 'bracu-admission-model-test-04-section-f'
          },
          {
            'title': '$code Pharmacy Section: Chemistry',
            'sub': 'Organic & Physical Chemistry Faculty Pattern',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'bracu-admission-model-test-01-section-c'
          },
          {
            'title': '$code Pharmacy Section: English',
            'sub': 'Reading Comprehension & Scientific Vocabulary',
            'day': (horizon.days * 0.7).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'bracu-admission-model-test-01-section-a'
          },
        ];
      }
    } else if (category == DisciplineCategory.architecture) {
      sections = [
        {
          'title': '$code Architecture Section: Spatial Drawing',
          'sub': 'OMR Format Spatial Reasoning & 3D Projections',
          'day': (horizon.days * 0.5).round(),
          'q': 25,
          'dur': 30,
          'marks': 25.0,
          'slug': 'bracu-architecture-omr-guidelines-test'
        },
        {
          'title': '$code Architecture Section: Mathematics',
          'sub': 'Coordinate Geometry, Mensuration & Vectors',
          'day': (horizon.days * 0.6).round(),
          'q': 25,
          'dur': 35,
          'marks': 25.0,
          'slug': 'bracu-admission-model-test-01-section-b'
        },
        {
          'title': '$code Architecture Section: English',
          'sub': 'Reading Comprehension & Language Mechanics',
          'day': (horizon.days * 0.7).round(),
          'q': 20,
          'dur': 25,
          'marks': 20.0,
          'slug': 'bracu-admission-model-test-01-section-a'
        },
      ];
    } else {
      // Default: Engineering & CSE
      if (u == 'nsu') {
        sections = [
          {
            'title': 'NSU Section 1: English Grammar & Vocabulary',
            'sub': 'Official Cliffs TOEFL Pattern (Summer 2025)',
            'day': (horizon.days * 0.5).round(),
            'q': 30,
            'dur': 30,
            'marks': 30.0,
            'slug':
                'nsu-admission-test-summer-2025-section-1-english-grammar-and-vocabulary'
          },
          {
            'title': 'NSU Section 2: Quantitative Aptitude',
            'sub': 'Math & Problem Solving (Summer 2025)',
            'day': (horizon.days * 0.6).round(),
            'q': 30,
            'dur': 35,
            'marks': 30.0,
            'slug':
                'nsu-admission-test-summer-2025-section-2-quantitative-aptitude'
          },
          {
            'title': 'NSU Cliffs TOEFL Grammar Mini-Test',
            'sub': 'High-Yield Speed OMR Section Drill',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'nsu-admission-special-cliffs-toefl-grammar-mini-test-01'
          },
        ];
      } else if (u == 'aust') {
        sections = [
          {
            'title': 'AUST Section: Higher Mathematics',
            'sub': 'Rigorous Engineering HSC Model Section',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'aust-admission-test-fall-2022-higher-math'
          },
          {
            'title': 'AUST Section: Physics Fundamentals',
            'sub': 'Formula & Calculation Accuracy Test',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'aust-admission-test-fall-2022-physics'
          },
          {
            'title': 'AUST Section: Chemistry & General Science',
            'sub': 'HSC 1st & 2nd Paper High-Yield Drill',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'aust-admission-test-fall-2022-chemistry'
          },
        ];
      } else if (u == 'iub') {
        sections = [
          {
            'title': 'IUB Section: English Grammar & Syntax',
            'sub': 'Summer 2025 Slot 2 Section One',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug':
                'iub-admission-test-summer-2025-slot-2-basic-test-english-section-one-grammar'
          },
          {
            'title': 'IUB Section: Higher Mathematics',
            'sub': 'School of Engineering & Technology Section',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug':
                'iub-admission-test-summer-2025-slot-2-engineering-test-higher-math'
          },
          {
            'title': 'IUB Section: Physics Fundamentals',
            'sub': 'Engineering Physics Section Test',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug':
                'iub-admission-test-summer-2025-slot-2-engineering-test-physics'
          },
        ];
      } else if (u == 'ewu') {
        sections = [
          {
            'title': 'EWU Section: English Grammar & Vocab',
            'sub': 'FBS Admission English Paper (Summer 2025)',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'ewu-admission-test-summer-2025-fbs-section-i-english'
          },
          {
            'title': 'EWU Section: Physics Fundamentals',
            'sub': 'FSE Engineering Physics Paper',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'ewu-fse-official-model-test-section-i-physics'
          },
          {
            'title': 'EWU Section: Mathematics Section',
            'sub': 'FSE Engineering Mathematics Paper',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'ewu-fse-official-model-test-section-iii-mathematics'
          },
        ];
      } else if (u == 'uiu') {
        sections = [
          {
            'title': 'UIU Section: Mathematics Section',
            'sub': 'School of Science & Engineering Test',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'uiu-engineering-official-model-test-mathematics-section'
          },
          {
            'title': 'UIU Section: Physics Section',
            'sub': 'Engineering Physics Mark Weightage',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug': 'uiu-engineering-official-model-test-physics-section'
          },
          {
            'title': 'UIU Section: English Section',
            'sub': 'Sentence Correction & Reading Comprehension',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'uiu-engineering-official-model-test-english-section'
          },
        ];
      } else if (u == 'aiub') {
        sections = [
          {
            'title': 'AIUB Section: Quantitative Section',
            'sub': 'BBA CIS Quantitative Section Pattern',
            'day': (horizon.days * 0.5).round(),
            'q': 25,
            'dur': 30,
            'marks': 25.0,
            'slug':
                'aiub-bba-cis-official-model-test-sample-quantitative-section'
          },
          {
            'title': 'AIUB Section: Verbal & English',
            'sub': 'Official Model Test Sample Verbal Section',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 25,
            'marks': 25.0,
            'slug': 'aiub-bba-cis-official-model-test-sample-verbal-section'
          },
          {
            'title': 'AIUB Section: General Knowledge',
            'sub': 'FASS Faculty General Knowledge Test',
            'day': (horizon.days * 0.7).round(),
            'q': 25,
            'dur': 20,
            'marks': 25.0,
            'slug': 'aiub-fass-official-model-test-section-b-general-knowledge'
          },
        ];
      } else {
        sections = [
          {
            'title': '$code Section A: English Language',
            'sub': 'Official Model Test 01 Section A',
            'day': (horizon.days * 0.5).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'bracu-admission-model-test-01-section-a'
          },
          {
            'title': '$code Section B: Mathematics Core',
            'sub': 'Official Model Test 01 Section B',
            'day': (horizon.days * 0.6).round(),
            'q': 25,
            'dur': 35,
            'marks': 25.0,
            'slug': 'bracu-admission-model-test-01-section-b'
          },
          {
            'title': '$code Section C: Physics & Science',
            'sub': 'Official Model Test 01 Section C',
            'day': (horizon.days * 0.7).round(),
            'q': 20,
            'dur': 25,
            'marks': 20.0,
            'slug': 'bracu-admission-model-test-01-section-c'
          },
        ];
      }
    }

    for (final s in sections) {
      list.add(AdmissionPlanItem(
        id: '${code.toLowerCase()}_section_${s['day']}',
        slug: s['slug'] as String,
        title: s['title'] as String,
        subtitle: s['sub'] as String,
        pillar: PlanPreparationPillar.sectionWise,
        dayNumber: s['day'] as int,
        totalQuestions: s['q'] as int,
        durationMinutes: s['dur'] as int,
        totalMarks: s['marks'] as double,
        negativeMark: 0.25,
        difficulty: 'Faculty Pattern',
      ));
    }
    return list;
  }

  List<AdmissionPlanItem> _generateOverallMocks(
      String code, PlanHorizon horizon, DisciplineCategory category) {
    final list = <AdmissionPlanItem>[];
    final u = code.toLowerCase();

    List<Map<String, dynamic>> mocks;

    if (category == DisciplineCategory.business) {
      if (u == 'nsu') {
        mocks = [
          {
            'title': 'NSU SBE Business & Economics Mock',
            'sub': 'Official Full Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-sbe-business-economics-admission-test'
          },
          {
            'title': 'NSU Admission Past Paper Spring 2024',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-admission-test-spring-2024'
          },
          {
            'title': 'NSU SBE Grand Summit Final Mock',
            'sub': 'SBE Composite Benchmark Exam (85%+ Target)',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-admission-test-fall-2023'
          },
        ];
      } else if (u == 'aiub') {
        mocks = [
          {
            'title': 'AIUB BBA CIS Official Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aiub-bba-cis-official-model-test'
          },
          {
            'title': 'AIUB FASS Official Model Test',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aiub-fass-official-model-test'
          },
          {
            'title': 'AIUB Grand Summit Business Mock',
            'sub': 'Comprehensive BBA Final Simulation',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aiub-bba-cis-official-model-test'
          },
        ];
      } else if (u == 'ewu') {
        mocks = [
          {
            'title': 'EWU Summer 2025 FBS Business Mock',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'ewu-admission-test-summer-2025-fbs'
          },
          {
            'title': 'EWU FBS Grand Summit Model Test',
            'sub': 'Faculty of Business Final Mock Simulation',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'ewu-admission-test-summer-2025-fbs'
          },
        ];
      } else if (u == 'uap') {
        mocks = [
          {
            'title': 'UAP BBA Official Admission Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uap-bba-admission-model-test'
          },
          {
            'title': 'UAP BBA Grand Summit Final Mock',
            'sub': 'Comprehensive Business Aptitude Simulation',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uap-bba-admission-model-test'
          },
        ];
      } else {
        mocks = [
          {
            'title': '$code BBA Official Model Test 01',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-model-test-02'
          },
          {
            'title': '$code BBA Grand Summit Final Mock',
            'sub': 'Final Rehearsal Before Exam Day (85%+ Target)',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-model-test-03'
          },
        ];
      }
    } else if (category == DisciplineCategory.pharmacy) {
      if (u == 'uap') {
        mocks = [
          {
            'title': 'UAP Pharmacy Admission Model Test (Biology)',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uap-pharmacy-admission-model-test-biology'
          },
          {
            'title': 'UAP Pharmacy Admission Model Test (Chemistry)',
            'sub': 'Chemical Sciences Full Simulation',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uap-pharmacy-admission-model-test-chemistry'
          },
          {
            'title': 'UAP Pharmacy Grand Summit Final Mock',
            'sub': 'Composite Health Sciences Entrance Mock',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uap-pharmacy-admission-model-test-biology'
          },
        ];
      } else if (u == 'uiu') {
        mocks = [
          {
            'title': 'UIU Pharmacy Official Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uiu-pharmacy-official-model-test'
          },
          {
            'title': 'UIU Pharmacy Grand Summit Final Mock',
            'sub': 'School of Life Sciences Composite Benchmark',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uiu-pharmacy-official-model-test'
          },
        ];
      } else if (u == 'iub') {
        mocks = [
          {
            'title': 'IUB Pharmacy Slot 2 Full Simulation Test',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'iub-admission-test-summer-2025-slot-2-pharmacy-test'
          },
          {
            'title': 'IUB Pharmacy Grand Summit Final Mock',
            'sub': 'School of Pharmacy Composite Benchmark',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'iub-admission-test-summer-2025-slot-2'
          },
        ];
      } else {
        mocks = [
          {
            'title': '$code Pharmacy Official Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-model-test-04-section-f'
          },
          {
            'title': '$code Pharmacy Grand Summit Final Mock',
            'sub': 'Composite Health Sciences Benchmark',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-model-test-01'
          },
        ];
      }
    } else if (category == DisciplineCategory.architecture) {
      mocks = [
        {
          'title': '$code Architecture & Spatial Model Test',
          'sub': 'Spatial Logic, Perspective & Geometry',
          'day': (horizon.days * 0.75).round(),
          'q': 50,
          'dur': 60,
          'marks': 50.0,
          'slug': 'bracu-architecture-omr-guidelines-test'
        },
        {
          'title': '$code Architecture Grand Summit Final Mock',
          'sub': 'Full Design & Spatial Aptitude Simulation',
          'day': horizon.days,
          'q': 50,
          'dur': 60,
          'marks': 50.0,
          'slug': 'bracu-cse-architecture-grand-model-test'
        },
      ];
    } else {
      // Default: Engineering & CSE
      if (u == 'nsu') {
        mocks = [
          {
            'title': 'NSU SEPS Engineering & Computing Mock',
            'sub': 'Official Full Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-seps-engineering-computing-admission-test'
          },
          {
            'title': 'NSU Admission Past Paper Spring 2024',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-admission-test-spring-2024'
          },
          {
            'title': 'NSU Grand Summit Final Mock Simulation',
            'sub': 'SEPS Engineering Composite Benchmark (85%+ Target)',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-seps-dynamic-ai-mock-99'
          },
        ];
        if (horizon.days >= 30) {
          mocks.insert(1, {
            'title': 'NSU Fall 2023 Real Admission Test',
            'sub': 'Negative Marking & Rapid OMR Practice',
            'day': (horizon.days * 0.80).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'nsu-admission-test-fall-2023'
          });
        }
      } else if (u == 'aust') {
        mocks = [
          {
            'title': 'AUST Engineering Rigorous HSC Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aust-engineering-rigorous-hsc-model-test'
          },
          {
            'title': 'AUST Real Admission Test Spring 2023',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aust-admission-test-spring-2023'
          },
          {
            'title': 'AUST Grand Summit Final Mock Simulation',
            'sub': 'Fall 2022 Verified Admission Benchmark',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aust-admission-test-fall-2022'
          },
        ];
      } else if (u == 'iub') {
        mocks = [
          {
            'title': 'IUB School of Engineering & Tech Mock',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'iub-school-of-engineering-technology-model-test'
          },
          {
            'title': 'IUB Summer 2025 Slot 2 Admission Test',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'iub-admission-test-summer-2025-slot-2'
          },
          {
            'title': 'IUB Grand Summit Official Model Test',
            'sub': 'Complete University Admission Simulation',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'iub-iub-official-model-test'
          },
        ];
      } else if (u == 'ewu') {
        mocks = [
          {
            'title': 'EWU Summer 2025 FSE Engineering Mock',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'ewu-admission-test-summer-2025-fse'
          },
          {
            'title': 'EWU Summer 2025 FBS Business Mock',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'ewu-admission-test-summer-2025-fbs'
          },
          {
            'title': 'EWU Grand Summit Official Model Test',
            'sub': 'Faculty of Sciences & Engineering Final Drill',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'ewu-fse-official-model-test'
          },
        ];
      } else if (u == 'uiu') {
        mocks = [
          {
            'title': 'UIU Engineering Official Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uiu-engineering-official-model-test'
          },
          {
            'title': 'UIU Pharmacy Official Model Test',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uiu-pharmacy-official-model-test'
          },
          {
            'title': 'UIU Grand Summit PYQ Final Test',
            'sub': 'Engineering & Science Composite Benchmark',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'uiu-real-admission-test-pyq-english-healer-pyq'
          },
        ];
      } else if (u == 'aiub') {
        mocks = [
          {
            'title': 'AIUB BBA CIS Official Model Test',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aiub-bba-cis-official-model-test'
          },
          {
            'title': 'AIUB FASS Official Model Test',
            'sub': 'Real Entrance Exam Reconstructed Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aiub-fass-official-model-test'
          },
          {
            'title': 'AIUB Grand Summit FST Engineering Test',
            'sub': 'Faculty of Science & Tech Final Simulation',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'aiub-fst-fe-official-model-test'
          },
        ];
      } else {
        mocks = [
          {
            'title': 'BRACU Admission Model Test 01',
            'sub': 'Full-Length Simulation with Negative Marking',
            'day': (horizon.days * 0.75).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-model-test-01'
          },
          {
            'title': 'BRACU Admission Model Test 02',
            'sub': 'Real Entrance Exam Pattern Mock Paper',
            'day': (horizon.days * 0.85).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-model-test-02'
          },
          {
            'title': 'BRACU CSE & Architecture Grand Model Test',
            'sub': 'Final Rehearsal Before Exam Day (85%+ Target)',
            'day': horizon.days,
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-cse-architecture-grand-model-test'
          },
        ];
        if (horizon.days >= 30) {
          mocks.insert(1, {
            'title': 'BRACU Admission Test Spring 2025',
            'sub': 'Negative Marking & Rapid OMR Practice',
            'day': (horizon.days * 0.80).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-test-spring-2025'
          });
        }
        if (horizon.days >= 60) {
          mocks.insert(2, {
            'title': 'BRACU Admission Test Summer 2025',
            'sub': 'Historical Admission Slot Benchmark',
            'day': (horizon.days * 0.90).round(),
            'q': 50,
            'dur': 60,
            'marks': 50.0,
            'slug': 'bracu-admission-test-summer-2025'
          });
        }
      }
    }

    for (final m in mocks) {
      list.add(AdmissionPlanItem(
        id: '${code.toLowerCase()}_overall_${m['day']}',
        slug: m['slug'] as String,
        title: m['title'] as String,
        subtitle: m['sub'] as String,
        pillar: PlanPreparationPillar.overall,
        dayNumber: m['day'] as int,
        totalQuestions: m['q'] as int,
        durationMinutes: m['dur'] as int,
        totalMarks: m['marks'] as double,
        negativeMark: 0.25,
        difficulty: 'Full Timed Simulation',
      ));
    }
    return list;
  }
}

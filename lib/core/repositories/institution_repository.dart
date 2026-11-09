import 'dart:convert';
import '../errors/app_logger.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';

class DivisionModel {
  final String id;
  final String nameEn;
  final String nameBn;
  final String? code;

  const DivisionModel({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    this.code,
  });

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'].toString(),
      nameEn: json['name_en'] as String? ?? json['divisionName'] as String? ?? '',
      nameBn: json['name_bn'] as String? ?? json['divisionNameBn'] as String? ?? '',
      code: json['code']?.toString() ?? json['divisionCode']?.toString(),
    );
  }
}

class DistrictModel {
  final String id;
  final String divisionId;
  final String nameEn;
  final String nameBn;

  const DistrictModel({
    required this.id,
    required this.divisionId,
    required this.nameEn,
    required this.nameBn,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'].toString(),
      divisionId: json['division_id']?.toString() ?? json['divisionId']?.toString() ?? '',
      nameEn: json['name_en'] as String? ?? json['districtName'] as String? ?? '',
      nameBn: json['name_bn'] as String? ?? json['districtNameBn'] as String? ?? '',
    );
  }
}

class InstitutionModel {
  final String id;
  final String eiin;
  final String nameEn;
  final String? nameBn;
  final bool isCollege;
  final bool isSchool;
  final bool isMadrasa;
  final String? board;
  final String? area;
  final String? district;

  const InstitutionModel({
    required this.id,
    required this.eiin,
    required this.nameEn,
    this.nameBn,
    required this.isCollege,
    required this.isSchool,
    this.isMadrasa = false,
    this.board,
    this.area,
    this.district,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id']?.toString() ?? 'inst_${json['eiin']}',
      eiin: json['eiin'] as String? ?? json['board_type'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      nameBn: json['name_bn'] as String?,
      isCollege: json['is_college'] as bool? ?? false,
      isSchool: json['is_school'] as bool? ?? false,
      isMadrasa: json['is_madrasa'] as bool? ?? false,
      board: json['board_type'] as String?,
      area: json['area'] as String?,
      district: json['district'] as String?,
    );
  }
}

class EnglishMediumInstitutionModel {
  final String id;
  final String name;
  final String district;
  final String area;
  final String institutionType;
  final String boardType;
  final bool isCollege;
  final bool isSchool;
  final bool isCambridge;
  final bool isEdexcel;
  final String? website;
  final String? email;

  const EnglishMediumInstitutionModel({
    required this.id,
    required this.name,
    required this.district,
    required this.area,
    required this.institutionType,
    required this.boardType,
    required this.isCollege,
    required this.isSchool,
    required this.isCambridge,
    required this.isEdexcel,
    this.website,
    this.email,
  });

  factory EnglishMediumInstitutionModel.fromJson(Map<String, dynamic> json) {
    final bType = json['board_type'] as String? ?? json['board'] as String? ?? 'Cambridge International';
    return EnglishMediumInstitutionModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      area: json['area'] as String? ?? '',
      institutionType: json['institution_type'] as String? ?? 'School',
      boardType: bType,
      isCollege: json['is_college'] as bool? ?? false,
      isSchool: json['is_school'] as bool? ?? true,
      isCambridge: json['is_cambridge'] as bool? ?? bType.toLowerCase().contains('cambridge'),
      isEdexcel: json['is_edexcel'] as bool? ?? bType.toLowerCase().contains('edexcel'),
      website: json['website'] as String?,
      email: json['email'] as String?,
    );
  }

  InstitutionModel toInstitutionModel() {
    return InstitutionModel(
      id: id,
      eiin: boardType,
      nameEn: name,
      nameBn: '$area, $district',
      isCollege: isCollege,
      isSchool: isSchool,
      board: boardType,
      area: area,
      district: district,
    );
  }
}

/// Dynamic Institution & Administrative Geographic Repository
class InstitutionRepository {
  static final InstitutionRepository _instance = InstitutionRepository._internal();
  factory InstitutionRepository() => _instance;
  InstitutionRepository._internal();

  final SupabaseService _supabase = SupabaseService();
  final CacheService _cache = CacheService();

  /// Get all 8 Divisions from database with local cache
  Future<List<DivisionModel>> getDivisions() async {
    const cacheKey = 'geo_divisions';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) return list.map(DivisionModel.fromJson).toList();
      } catch (_) {}
    }

    try {
      final raw = await _supabase.fetchDivisions();
      if (raw.isNotEmpty) {
        _cache.write(cacheKey, jsonEncode(raw));
        return raw.map(DivisionModel.fromJson).toList();
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch divisions from database', e);
    }

    return [];
  }

  /// Get Districts by Division from database with local cache
  Future<List<DistrictModel>> getDistricts({String? divisionId}) async {
    final cacheKey = 'geo_districts_${divisionId ?? 'all'}';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
        if (list.isNotEmpty) return list.map(DistrictModel.fromJson).toList();
      } catch (e) {
        AppLogger.warn('Failed to parse cached districts for $divisionId', e);
      }
    }

    try {
      final raw = await _supabase.fetchDistricts(divisionId: divisionId);
      if (raw.isNotEmpty) {
        _cache.write(cacheKey, jsonEncode(raw));
        return raw.map(DistrictModel.fromJson).toList();
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch districts from database for $divisionId', e);
    }

    return [];
  }

  /// Search institutions dynamically from database (all 39,223 records)
  Future<List<InstitutionModel>> searchInstitutions(
    String query, {
    bool isHsc = true,
    bool? collegesOnly,
    int limit = 50,
  }) async {
    final hsc = collegesOnly ?? isHsc;
    final trimmed = query.trim();

    // Check cache for initial empty query
    final cacheKey = 'inst_preload_${hsc ? 'hsc' : 'ssc'}';
    if (trimmed.isEmpty) {
      final cached = _cache.read<String>(cacheKey);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
          if (list.isNotEmpty) return list.map(InstitutionModel.fromJson).toList();
        } catch (_) {}
      }
    }

    try {
      final raw = await _supabase.searchInstitutions(trimmed, isHsc: hsc, limit: limit);
      if (raw.isNotEmpty) {
        if (trimmed.isEmpty) {
          _cache.write(cacheKey, jsonEncode(raw));
        }
        return raw.map(InstitutionModel.fromJson).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Search English Medium institutions dynamically from database
  Future<List<EnglishMediumInstitutionModel>> searchEnglishMediumInstitutions(
    String query, {
    bool isCollege = false,
    String? board,
    int limit = 250,
  }) async {
    final trimmed = query.trim();
    final cacheKey = 'em_inst_preload_${isCollege ? 'college' : 'school'}_${board ?? 'all'}';
    if (trimmed.isEmpty) {
      final cached = _cache.read<String>(cacheKey);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List).cast<Map<String, dynamic>>();
          if (list.isNotEmpty) return list.map(EnglishMediumInstitutionModel.fromJson).toList();
        } catch (_) {}
      }
    }

    try {
      final raw = await _supabase.searchEnglishMediumInstitutions(
        trimmed,
        isCollege: isCollege,
        board: board,
        limit: limit,
      );
      if (raw.isNotEmpty) {
        if (trimmed.isEmpty) {
          _cache.write(cacheKey, jsonEncode(raw));
        }
        return raw.map(EnglishMediumInstitutionModel.fromJson).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Fetch active effective academic admission year from relational database
  Future<int> getEffectiveAdmissionYear() async {
    const cacheKey = 'relational_admission_year';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      final val = int.tryParse(cached);
      if (val != null) return val;
    }
    final year = await _supabase.fetchEffectiveAdmissionYear();
    _cache.write(cacheKey, year.toString());
    return year;
  }

  /// Fetch distinct curriculum examination boards from relational English Medium database
  Future<List<String>> getEnglishMediumBoards() async {
    const cacheKey = 'relational_em_boards';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<String>();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    final boards = await _supabase.fetchEnglishMediumBoards();
    _cache.write(cacheKey, jsonEncode(boards));
    return boards;
  }

  /// Relationally compute valid SSC passing years from database admission cycle year
  List<String> getSscPassingYears(int baseYear) {
    return List.generate(6, (i) => (baseYear - 2 - i).toString());
  }

  /// Relationally compute HSC batches linked directly to the selected SSC year
  List<String> getHscBatchesForSscYear(String? sscYear, int baseYear) {
    if (sscYear != null && sscYear.isNotEmpty) {
      final ssc = int.tryParse(sscYear);
      if (ssc != null) {
        final regularBatch = ssc + 2;
        final secondTimerBatch = ssc + 1;
        final regularShort = (regularBatch % 100).toString().padLeft(2, '0');
        final secondShort = (secondTimerBatch % 100).toString().padLeft(2, '0');

        final list = <String>[];
        if (regularBatch >= baseYear) {
          list.add("HSC '$regularShort (Appearing)");
        } else {
          list.add("HSC '$regularShort");
        }
        list.add("HSC '$secondShort (2nd Time)");
        return list;
      }
    }
    final curShort = ((baseYear - 1) % 100).toString().padLeft(2, '0');
    final nextShort = (baseYear % 100).toString().padLeft(2, '0');
    final prevShort = ((baseYear - 2) % 100).toString().padLeft(2, '0');
    return ["HSC '$curShort", "HSC '$nextShort (Appearing)", "HSC '$prevShort (2nd Time)"];
  }

  /// Relationally compute valid O-Level passing years from database admission cycle year
  List<String> getOLevelPassingYears(int baseYear) {
    return List.generate(6, (i) => (baseYear - 2 - i).toString());
  }

  /// Relationally compute A-Level batches linked directly to selected O-Level year
  List<String> getALevelBatchesForOLevelYear(String? oLevelYear, int baseYear) {
    if (oLevelYear != null && oLevelYear.isNotEmpty) {
      final oL = int.tryParse(oLevelYear);
      if (oL != null) {
        final regularBatch = oL + 2;
        final secondTimerBatch = oL + 1;
        final regularShort = (regularBatch % 100).toString().padLeft(2, '0');
        final secondShort = (secondTimerBatch % 100).toString().padLeft(2, '0');

        final list = <String>[];
        if (regularBatch >= baseYear) {
          list.add("A-Level '$regularShort (Appearing)");
        } else {
          list.add("A-Level '$regularShort");
        }
        list.add("A-Level '$secondShort (2nd Time)");
        return list;
      }
    }
    final curShort = ((baseYear - 1) % 100).toString().padLeft(2, '0');
    final nextShort = (baseYear % 100).toString().padLeft(2, '0');
    final prevShort = ((baseYear - 2) % 100).toString().padLeft(2, '0');
    return ["A-Level '$curShort", "A-Level '$nextShort (Appearing)", "A-Level '$prevShort (2nd Time)"];
  }

  /// Relational NCTB transition rules: HSC streams permitted from SSC stream
  List<String> getEligibleHscGroups(String? sscGroup) {
    if (sscGroup == 'Humanities') {
      return ['Humanities'];
    }
    if (sscGroup == 'Business Studies') {
      return ['Business Studies', 'Humanities'];
    }
    return ['Science', 'Business Studies', 'Humanities'];
  }

  /// Fetch dynamic SSC passing years from database `academic_batches` table
  Future<List<String>> getDynamicSscPassingYears(int baseYear) async {
    const cacheKey = 'db_ssc_passing_years';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<String>();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    try {
      final rows = await _supabase.fetchAcademicBatches(examLevel: 'SSC');
      if (rows.isNotEmpty) {
        final years = rows.map((r) => r['batch_name'].toString()).toList();
        _cache.write(cacheKey, jsonEncode(years));
        return years;
      }
    } catch (_) {}
    return getSscPassingYears(baseYear);
  }

  /// Fetch all dynamic active HSC batches from database `academic_batches` table
  Future<List<String>> getDynamicHscBatches(int baseYear) async {
    const cacheKey = 'db_all_hsc_batches';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<String>();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    try {
      final rows = await _supabase.fetchAcademicBatches(examLevel: 'HSC');
      if (rows.isNotEmpty) {
        final batches = rows.map((r) => r['batch_name'].toString()).toList();
        _cache.write(cacheKey, jsonEncode(batches));
        return batches;
      }
    } catch (_) {}
    return getAllHscBatches(baseYear);
  }

  /// All active HSC batches fallback based on admission base year
  List<String> getAllHscBatches(int baseYear) {
    final nextShort = (baseYear % 100).toString().padLeft(2, '0');
    final curShort = ((baseYear - 1) % 100).toString().padLeft(2, '0');
    final prevShort = ((baseYear - 2) % 100).toString().padLeft(2, '0');
    final prev2Short = ((baseYear - 3) % 100).toString().padLeft(2, '0');
    return [
      "HSC '$nextShort (Appearing)",
      "HSC '$curShort",
      "HSC '$curShort (2nd Time)",
      "HSC '$prevShort",
      "HSC '$prevShort (2nd Time)",
      "HSC '$prev2Short (2nd Time)",
    ];
  }

  /// Fetch dynamic HSC batches from database `academic_batches` table optionally filtered
  Future<List<String>> getDynamicHscBatchesForSscYear(String? sscYear, int baseYear) async {
    return getDynamicHscBatches(baseYear);
  }

  /// Fetch dynamic O-Level passing years from database `academic_batches` table
  Future<List<String>> getDynamicOLevelPassingYears(int baseYear) async {
    const cacheKey = 'db_olevel_passing_years';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<String>();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    try {
      final rows = await _supabase.fetchAcademicBatches(examLevel: 'O_LEVEL');
      if (rows.isNotEmpty) {
        final years = rows.map((r) => r['batch_name'].toString()).toList();
        _cache.write(cacheKey, jsonEncode(years));
        return years;
      }
    } catch (_) {}
    return getOLevelPassingYears(baseYear);
  }

  /// Fetch all dynamic active A-Level batches from database `academic_batches` table
  Future<List<String>> getDynamicALevelBatches(int baseYear) async {
    const cacheKey = 'db_all_alevel_batches';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<String>();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    try {
      final rows = await _supabase.fetchAcademicBatches(examLevel: 'A_LEVEL');
      if (rows.isNotEmpty) {
        final batches = rows.map((r) => r['batch_name'].toString()).toList();
        _cache.write(cacheKey, jsonEncode(batches));
        return batches;
      }
    } catch (_) {}
    return getAllALevelBatches(baseYear);
  }

  /// All active A-Level batches fallback based on admission base year
  List<String> getAllALevelBatches(int baseYear) {
    final nextShort = (baseYear % 100).toString().padLeft(2, '0');
    final curShort = ((baseYear - 1) % 100).toString().padLeft(2, '0');
    final prevShort = ((baseYear - 2) % 100).toString().padLeft(2, '0');
    final prev2Short = ((baseYear - 3) % 100).toString().padLeft(2, '0');
    return [
      "A-Level '$nextShort (Appearing)",
      "A-Level '$curShort",
      "A-Level '$curShort (2nd Time)",
      "A-Level '$prevShort",
      "A-Level '$prevShort (2nd Time)",
      "A-Level '$prev2Short (2nd Time)",
    ];
  }

  /// Fetch dynamic A-Level batches from database `academic_batches` table optionally filtered
  Future<List<String>> getDynamicALevelBatchesForOLevelYear(String? oLevelYear, int baseYear) async {
    return getDynamicALevelBatches(baseYear);
  }

  /// Fetch dynamic boards from database `academic_boards` table
  Future<List<String>> getDynamicAcademicBoards() async {
    const cacheKey = 'db_academic_boards';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = (jsonDecode(cached) as List).cast<String>();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    try {
      final boards = await _supabase.fetchAcademicBoards();
      if (boards.isNotEmpty) {
        _cache.write(cacheKey, jsonEncode(boards));
        return boards;
      }
    } catch (_) {}
    return getEnglishMediumBoards();
  }
}

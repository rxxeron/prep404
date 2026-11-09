import 'dart:convert';
import '../errors/app_failure.dart';
import '../errors/app_logger.dart';
import '../models/university_target.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';

/// Dynamic Private University & Programs Catalog Repository
/// Exclusively pulls from Supabase PostgreSQL database tables: universities, academic_units, programs.
class UniversityRepository {
  static final UniversityRepository _instance = UniversityRepository._internal();
  factory UniversityRepository() => _instance;
  UniversityRepository._internal();

  final SupabaseService _supabase = SupabaseService();
  final CacheService _cache = CacheService();

  /// Fetch universities with Result pattern returning explicit typed failures
  Future<Result<List<PrivateUniversity>>> getUniversitiesResult() async {
    const cacheKey = 'db_universities_full';

    try {
      final raw = await _supabase.fetchUniversities();
      if (raw.isNotEmpty) {
        final list = raw.map(_mapJsonToUniversity).toList();
        list.sort((a, b) => a.fullName.toLowerCase().trim().compareTo(b.fullName.toLowerCase().trim()));
        _cache.write(cacheKey, jsonEncode(raw));
        return Result.success(list);
      }
    } catch (e) {
      AppLogger.warn('Unable to fetch live universities from Supabase, attempting cache', e);
    }

    // Genuine local cache from previous network response
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        final mapped = list.map((u) => _mapJsonToUniversity(u as Map<String, dynamic>)).toList();
        mapped.sort((a, b) => a.fullName.toLowerCase().trim().compareTo(b.fullName.toLowerCase().trim()));
        return Result.success(mapped);
      } catch (e, st) {
        AppLogger.error('Failed to parse cached universities', e, st);
        return Result.failure<List<PrivateUniversity>>(CacheFailure('Cached universities catalog is corrupted', cause: e, stackTrace: st));
      }
    }

    return Result.failure<List<PrivateUniversity>>(const NetworkFailure('Universities catalog is currently unreachable and no cache is available.'));
  }

  /// Fetch universities with backward-compatible list return
  Future<List<PrivateUniversity>> getUniversities() async {
    final result = await getUniversitiesResult();
    return result.fold(
      (data) => data,
      (failure) {
        AppLogger.warn('getUniversities fallback to empty list: ${failure.message}');
        return [];
      },
    );
  }

  PrivateUniversity _mapJsonToUniversity(Map<String, dynamic> json) {
    // Build academic unit map (id -> Department Name)
    final rawUnits = (json['academic_units'] as List? ?? []);
    final Map<String, String> unitMap = {};
    for (final u in rawUnits) {
      if (u is Map<String, dynamic>) {
        final uId = u['id']?.toString() ?? '';
        final uName = u['name']?.toString() ?? '';
        final sCode = u['short_code']?.toString() ?? '';
        unitMap[uId] = sCode.isNotEmpty ? '$uName ($sCode)' : uName;
      }
    }

    final rawPrograms = (json['programs'] as List? ?? []);
    final disciplines = rawPrograms.map((p) {
      final progMap = p as Map<String, dynamic>;
      final unitId = progMap['academic_unit_id']?.toString() ?? '';
      final department = unitMap[unitId] ?? '';
      final catStr = (progMap['track_category'] as String? ?? 'engineering').toLowerCase();
      DisciplineCategory cat = DisciplineCategory.engineering;
      if (catStr.contains('business') || catStr.contains('bba') || catStr.contains('econ')) {
        cat = DisciplineCategory.business;
      } else if (catStr.contains('pharm') || catStr.contains('bio') || catStr.contains('life') || catStr.contains('health') || catStr.contains('sciences')) {
        cat = DisciplineCategory.pharmacy;
      } else if (catStr.contains('arch')) {
        cat = DisciplineCategory.architecture;
      } else if (catStr.contains('law') || catStr.contains('humanities') || catStr.contains('art')) {
        cat = DisciplineCategory.lawAndArts;
      }

      return UniversityDiscipline(
        id: '${json['code'] ?? json['id']}_${progMap['slug'] ?? progMap['id']}',
        name: progMap['name'] as String? ?? 'Undergraduate Program',
        department: department,
        category: cat,
        examSections: ['General English', 'Mathematics', 'Aptitude'],
      );
    }).toList();
    disciplines.sort((a, b) => a.name.toLowerCase().trim().compareTo(b.name.toLowerCase().trim()));

    // Map admission cycles and examination slots
    final rawCycles = (json['admission_cycles'] as List? ?? []);
    final cycles = rawCycles
        .where((c) {
          if (c is! Map<String, dynamic>) return false;
          final status = c['status']?.toString().toLowerCase();
          return status == null || status == 'upcoming' || status == 'active';
        })
        .map((c) {
      final cMap = c as Map<String, dynamic>;
      final examDate = DateTime.tryParse(cMap['exam_date']?.toString() ?? '') ?? DateTime(2026, 11, 28);
      final appDeadline = cMap['application_deadline'] != null
          ? DateTime.tryParse(cMap['application_deadline'].toString())
          : null;

      return AdmissionCycleInfo(
        id: cMap['id']?.toString() ?? '',
        season: cMap['season']?.toString() ?? 'Spring',
        academicYear: cMap['academic_year'] is int
            ? cMap['academic_year'] as int
            : int.tryParse(cMap['academic_year']?.toString() ?? '2026') ?? 2026,
        slotNumber: cMap['slot_number'] is int
            ? cMap['slot_number'] as int
            : int.tryParse(cMap['slot_number']?.toString() ?? '1') ?? 1,
        slotTitle: cMap['slot_title']?.toString() ?? '',
        applicationDeadline: appDeadline,
        examDate: examDate,
        examTime: cMap['exam_time']?.toString() ?? '',
        applicationFee: cMap['application_fee']?.toString() ?? 'BDT 1,500',
        venue: cMap['venue']?.toString() ?? '',
        notes: cMap['notes']?.toString() ?? '',
        status: cMap['status']?.toString() ?? 'upcoming',
      );
    }).toList();

    cycles.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
    final estDate = cycles.isNotEmpty ? cycles.first.examDate : DateTime(2026, 11, 28);
    final examFormat = json['exam_format_type'] as String? ?? 'faculty_wide';
    final examSummary = json['exam_pattern_summary'] as String? ?? '';

    return PrivateUniversity(
      id: json['slug'] as String? ?? json['id'] as String,
      code: json['code'] as String? ?? 'UNI',
      fullName: json['full_name'] as String? ?? 'Private University',
      location: json['campus_location'] as String? ?? 'Dhaka, Bangladesh',
      logoUrl: json['logo_url'] as String?,
      estimatedExamDate: estDate,
      disciplines: disciplines,
      examFormatType: examFormat,
      examPatternSummary: examSummary,
      admissionCycles: cycles,
    );
  }
}

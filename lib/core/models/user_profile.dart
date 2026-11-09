import 'university_target.dart';

/// Candidate Profile with targeted universities, disciplines, and academic history
class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String? gender; // 'male', 'female', 'other'
  final String? divisionId;
  final String? divisionName;
  final String? districtId;
  final String? districtName;

  // SSC credentials
  final String? sscGroup;
  final String? sscYear;
  final String? sscGpa;
  final String? sscInstitution;
  final String? sscEiin;

  // HSC credentials
  final String? hscGroup;
  final String? hscBatch;
  final String? hscGpa;
  final String? hscInstitution;
  final String? hscEiin;

  // O-Level credentials (English Medium)
  final String? oLevelBoard; // 'Cambridge International' or 'Pearson Edexcel'
  final String? oLevelYear;
  final int? oLevelSubjectsCount;
  final String? oLevelGrades; // e.g. "5 A*, 2 A"
  final String? oLevelGpaEquiv;
  final String? oLevelSchool;
  final String? oLevelInstitutionId;

  // A-Level credentials (English Medium)
  final String? aLevelBoard; // 'Cambridge International' or 'Pearson Edexcel'
  final String? aLevelBatch; // e.g. "A Level '24"
  final String? aLevelStatus; // 'completed' or 'appearing'
  final int? aLevelSubjectsCount;
  final String? aLevelGrades; // e.g. "2 A*, 1 A"
  final String? aLevelGpaEquiv;
  final String? aLevelCollege;
  final String? aLevelInstitutionId;

  final StudentMedium medium;
  final NctbVersion? nctbVersion; // null if English medium
  final EnglishCurriculum? englishCurriculum; // null if Bangla medium
  final String academicBatch; // e.g. "HSC '24" or "A-Level '24"
  final String institutionName; // College name or School name
  final int studyStreakDays;
  
  /// Selected target: Map<UniversityId, Set<DisciplineId>>
  final Map<String, List<String>> targetSelections;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.gender,
    this.divisionId,
    this.divisionName,
    this.districtId,
    this.districtName,
    this.sscGroup,
    this.sscYear,
    this.sscGpa,
    this.sscInstitution,
    this.sscEiin,
    this.hscGroup,
    this.hscBatch,
    this.hscGpa,
    this.hscInstitution,
    this.hscEiin,
    this.oLevelBoard,
    this.oLevelYear,
    this.oLevelSubjectsCount,
    this.oLevelGrades,
    this.oLevelGpaEquiv,
    this.oLevelSchool,
    this.oLevelInstitutionId,
    this.aLevelBoard,
    this.aLevelBatch,
    this.aLevelStatus,
    this.aLevelSubjectsCount,
    this.aLevelGrades,
    this.aLevelGpaEquiv,
    this.aLevelCollege,
    this.aLevelInstitutionId,
    required this.medium,
    this.nctbVersion,
    this.englishCurriculum,
    required this.academicBatch,
    required this.institutionName,
    this.studyStreakDays = 0,
    required this.targetSelections,
  });

  /// True if user completed onboarding
  bool get isOnboarded => targetSelections.isNotEmpty;

  /// Returns total targeted programs count
  int get totalTargetedPrograms {
    return targetSelections.values.fold(0, (acc, list) => acc + list.length);
  }

  /// Calculates minimum days remaining until the nearest targeted exam
  int get daysUntilEarliestExam {
    final now = DateTime.now();
    int minDays = 999;
    for (final uniId in targetSelections.keys) {
      final uni = UniversityCatalog.universities.firstWhere(
        (u) => u.id == uniId,
        orElse: () => UniversityCatalog.universities.first,
      );
      final diff = uni.estimatedExamDate.difference(now).inDays;
      if (diff >= 0 && diff < minDays) {
        minDays = diff;
      }
    }
    return minDays == 999 ? 35 : minDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'gender': gender,
    'divisionId': divisionId,
    'divisionName': divisionName,
    'districtId': districtId,
    'districtName': districtName,
    'sscGroup': sscGroup,
    'sscYear': sscYear,
    'sscGpa': sscGpa,
    'sscInstitution': sscInstitution,
    'sscEiin': sscEiin,
    'hscGroup': hscGroup,
    'hscBatch': hscBatch,
    'hscGpa': hscGpa,
    'hscInstitution': hscInstitution,
    'hscEiin': hscEiin,
    'oLevelBoard': oLevelBoard,
    'oLevelYear': oLevelYear,
    'oLevelSubjectsCount': oLevelSubjectsCount,
    'oLevelGrades': oLevelGrades,
    'oLevelGpaEquiv': oLevelGpaEquiv,
    'oLevelSchool': oLevelSchool,
    'oLevelInstitutionId': oLevelInstitutionId,
    'aLevelBoard': aLevelBoard,
    'aLevelBatch': aLevelBatch,
    'aLevelStatus': aLevelStatus,
    'aLevelSubjectsCount': aLevelSubjectsCount,
    'aLevelGrades': aLevelGrades,
    'aLevelGpaEquiv': aLevelGpaEquiv,
    'aLevelCollege': aLevelCollege,
    'aLevelInstitutionId': aLevelInstitutionId,
    'medium': medium.name,
    'nctbVersion': nctbVersion?.name,
    'englishCurriculum': englishCurriculum?.name,
    'academicBatch': academicBatch,
    'institutionName': institutionName,
    'studyStreakDays': studyStreakDays,
    'targetSelections': targetSelections,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final med = (json['medium'] == 'english') ? StudentMedium.english : StudentMedium.bangla;
    final hscBatchVal = json['hscBatch'] as String? ?? json['academicBatch'] as String? ?? '';
    final instVal = json['hscInstitution'] as String? ?? json['institutionName'] as String? ?? '';

    return UserProfile(
      id: json['id'] as String? ?? 'u_local',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      gender: json['gender'] as String?,
      divisionId: json['divisionId'] as String?,
      divisionName: json['divisionName'] as String?,
      districtId: json['districtId'] as String?,
      districtName: json['districtName'] as String?,
      sscGroup: json['sscGroup'] as String?,
      sscYear: json['sscYear'] as String?,
      sscGpa: json['sscGpa'] as String?,
      sscInstitution: json['sscInstitution'] as String?,
      sscEiin: json['sscEiin'] as String?,
      hscGroup: json['hscGroup'] as String?,
      hscBatch: hscBatchVal,
      hscGpa: json['hscGpa'] as String?,
      hscInstitution: instVal,
      hscEiin: json['hscEiin'] as String?,
      oLevelBoard: json['oLevelBoard'] as String?,
      oLevelYear: json['oLevelYear'] as String?,
      oLevelSubjectsCount: json['oLevelSubjectsCount'] as int?,
      oLevelGrades: json['oLevelGrades'] as String?,
      oLevelGpaEquiv: json['oLevelGpaEquiv'] as String?,
      oLevelSchool: json['oLevelSchool'] as String?,
      oLevelInstitutionId: json['oLevelInstitutionId'] as String?,
      aLevelBoard: json['aLevelBoard'] as String?,
      aLevelBatch: json['aLevelBatch'] as String?,
      aLevelStatus: json['aLevelStatus'] as String?,
      aLevelSubjectsCount: json['aLevelSubjectsCount'] as int?,
      aLevelGrades: json['aLevelGrades'] as String?,
      aLevelGpaEquiv: json['aLevelGpaEquiv'] as String?,
      aLevelCollege: json['aLevelCollege'] as String?,
      aLevelInstitutionId: json['aLevelInstitutionId'] as String?,
      medium: med,
      nctbVersion: med == StudentMedium.bangla
          ? (json['nctbVersion'] == 'english' ? NctbVersion.english : NctbVersion.bangla)
          : null,
      englishCurriculum: json['englishCurriculum'] != null
          ? (json['englishCurriculum'] == 'edexcel' ? EnglishCurriculum.edexcel : EnglishCurriculum.cambridge)
          : null,
      academicBatch: hscBatchVal,
      institutionName: instVal,
      studyStreakDays: json['studyStreakDays'] as int? ?? 0,
      targetSelections: (json['targetSelections'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          ) ??
          {},
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? gender,
    String? divisionId,
    String? divisionName,
    String? districtId,
    String? districtName,
    String? sscGroup,
    String? sscYear,
    String? sscGpa,
    String? sscInstitution,
    String? sscEiin,
    String? hscGroup,
    String? hscBatch,
    String? hscGpa,
    String? hscInstitution,
    String? hscEiin,
    String? oLevelBoard,
    String? oLevelYear,
    int? oLevelSubjectsCount,
    String? oLevelGrades,
    String? oLevelGpaEquiv,
    String? oLevelSchool,
    String? oLevelInstitutionId,
    String? aLevelBoard,
    String? aLevelBatch,
    String? aLevelStatus,
    int? aLevelSubjectsCount,
    String? aLevelGrades,
    String? aLevelGpaEquiv,
    String? aLevelCollege,
    String? aLevelInstitutionId,
    StudentMedium? medium,
    NctbVersion? nctbVersion,
    EnglishCurriculum? englishCurriculum,
    String? academicBatch,
    String? institutionName,
    int? studyStreakDays,
    Map<String, List<String>>? targetSelections,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      divisionId: divisionId ?? this.divisionId,
      divisionName: divisionName ?? this.divisionName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      sscGroup: sscGroup ?? this.sscGroup,
      sscYear: sscYear ?? this.sscYear,
      sscGpa: sscGpa ?? this.sscGpa,
      sscInstitution: sscInstitution ?? this.sscInstitution,
      sscEiin: sscEiin ?? this.sscEiin,
      hscGroup: hscGroup ?? this.hscGroup,
      hscBatch: hscBatch ?? this.hscBatch,
      hscGpa: hscGpa ?? this.hscGpa,
      hscInstitution: hscInstitution ?? this.hscInstitution,
      hscEiin: hscEiin ?? this.hscEiin,
      oLevelBoard: oLevelBoard ?? this.oLevelBoard,
      oLevelYear: oLevelYear ?? this.oLevelYear,
      oLevelSubjectsCount: oLevelSubjectsCount ?? this.oLevelSubjectsCount,
      oLevelGrades: oLevelGrades ?? this.oLevelGrades,
      oLevelGpaEquiv: oLevelGpaEquiv ?? this.oLevelGpaEquiv,
      oLevelSchool: oLevelSchool ?? this.oLevelSchool,
      oLevelInstitutionId: oLevelInstitutionId ?? this.oLevelInstitutionId,
      aLevelBoard: aLevelBoard ?? this.aLevelBoard,
      aLevelBatch: aLevelBatch ?? this.aLevelBatch,
      aLevelStatus: aLevelStatus ?? this.aLevelStatus,
      aLevelSubjectsCount: aLevelSubjectsCount ?? this.aLevelSubjectsCount,
      aLevelGrades: aLevelGrades ?? this.aLevelGrades,
      aLevelGpaEquiv: aLevelGpaEquiv ?? this.aLevelGpaEquiv,
      aLevelCollege: aLevelCollege ?? this.aLevelCollege,
      aLevelInstitutionId: aLevelInstitutionId ?? this.aLevelInstitutionId,
      medium: medium ?? this.medium,
      nctbVersion: nctbVersion ?? this.nctbVersion,
      englishCurriculum: englishCurriculum ?? this.englishCurriculum,
      academicBatch: academicBatch ?? this.academicBatch,
      institutionName: institutionName ?? this.institutionName,
      studyStreakDays: studyStreakDays ?? this.studyStreakDays,
      targetSelections: targetSelections ?? this.targetSelections,
    );
  }

  Map<String, dynamic> toDbMap() => {
    'id': id,
    'full_name': name,
    'phone': phone.isEmpty ? null : phone,
    'gender': gender,
    'division_id': divisionId,
    'division_name': divisionName,
    'district_id': districtId,
    'district_name': districtName,
    'medium': medium.name,
    'nctb_version': nctbVersion?.name,
    'english_curriculum': englishCurriculum?.name,
    'academic_batch': academicBatch,
    'institution_name': institutionName,
    'institution_eiin': hscEiin ?? sscEiin,
    'ssc_group': sscGroup,
    'ssc_year': sscYear,
    'ssc_gpa': sscGpa,
    'ssc_institution': sscInstitution,
    'ssc_eiin': sscEiin,
    'hsc_group': hscGroup,
    'hsc_batch': hscBatch,
    'hsc_gpa': hscGpa,
    'hsc_institution': hscInstitution,
    'hsc_eiin': hscEiin,
    'o_level_board': oLevelBoard,
    'o_level_year': oLevelYear,
    'o_level_subjects_count': oLevelSubjectsCount,
    'o_level_grades': oLevelGrades,
    'o_level_gpa_equiv': oLevelGpaEquiv,
    'o_level_school': oLevelSchool,
    'o_level_institution_id': oLevelInstitutionId,
    'a_level_board': aLevelBoard,
    'a_level_batch': aLevelBatch,
    'a_level_status': aLevelStatus,
    'a_level_subjects_count': aLevelSubjectsCount,
    'a_level_grades': aLevelGrades,
    'a_level_gpa_equiv': aLevelGpaEquiv,
    'a_level_college': aLevelCollege,
    'a_level_institution_id': aLevelInstitutionId,
    'target_universities': targetSelections.keys.toList(),
    'target_disciplines': targetSelections,
    'updated_at': DateTime.now().toIso8601String(),
  };

  factory UserProfile.fromDbMap(Map<String, dynamic> map) {
    final med = (map['medium'] == 'english') ? StudentMedium.english : StudentMedium.bangla;
    final hscBatchVal = map['hsc_batch'] as String? ?? map['academic_batch'] as String? ?? '';
    final instVal = map['hsc_institution'] as String? ?? map['institution_name'] as String? ?? '';

    Map<String, List<String>> targets = {};
    final rawDisciplines = map['target_disciplines'];
    if (rawDisciplines is Map) {
      targets = rawDisciplines.map(
        (k, v) => MapEntry(k.toString(), v is List ? List<String>.from(v) : <String>[]),
      );
    } else {
      final rawUnis = map['target_universities'];
      if (rawUnis is List) {
        for (final u in rawUnis) {
          targets[u.toString()] = [u.toString()];
        }
      }
    }

    return UserProfile(
      id: map['id'] as String? ?? 'u_local',
      name: map['full_name'] as String? ?? map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      gender: map['gender'] as String?,
      divisionId: map['division_id'] as String?,
      divisionName: map['division_name'] as String?,
      districtId: map['district_id'] as String?,
      districtName: map['district_name'] as String?,
      sscGroup: map['ssc_group'] as String?,
      sscYear: map['ssc_year'] as String?,
      sscGpa: map['ssc_gpa'] as String?,
      sscInstitution: map['ssc_institution'] as String?,
      sscEiin: map['ssc_eiin'] as String?,
      hscGroup: map['hsc_group'] as String?,
      hscBatch: hscBatchVal,
      hscGpa: map['hsc_gpa'] as String?,
      hscInstitution: instVal,
      hscEiin: map['hsc_eiin'] as String?,
      oLevelBoard: map['o_level_board'] as String?,
      oLevelYear: map['o_level_year'] as String?,
      oLevelSubjectsCount: map['o_level_subjects_count'] as int?,
      oLevelGrades: map['o_level_grades'] as String?,
      oLevelGpaEquiv: map['o_level_gpa_equiv'] as String?,
      oLevelSchool: map['o_level_school'] as String?,
      oLevelInstitutionId: map['o_level_institution_id'] as String?,
      aLevelBoard: map['a_level_board'] as String?,
      aLevelBatch: map['a_level_batch'] as String?,
      aLevelStatus: map['a_level_status'] as String?,
      aLevelSubjectsCount: map['a_level_subjects_count'] as int?,
      aLevelGrades: map['a_level_grades'] as String?,
      aLevelGpaEquiv: map['a_level_gpa_equiv'] as String?,
      aLevelCollege: map['a_level_college'] as String?,
      aLevelInstitutionId: map['a_level_institution_id'] as String?,
      medium: med,
      nctbVersion: med == StudentMedium.bangla
          ? (map['nctb_version'] == 'english' ? NctbVersion.english : NctbVersion.bangla)
          : null,
      englishCurriculum: map['english_curriculum'] != null
          ? (map['english_curriculum'] == 'edexcel' ? EnglishCurriculum.edexcel : EnglishCurriculum.cambridge)
          : null,
      academicBatch: hscBatchVal,
      institutionName: instVal,
      studyStreakDays: map['streak_days'] as int? ?? 0,
      targetSelections: targets,
    );
  }
}

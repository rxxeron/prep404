import 'package:flutter/material.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/supabase_service.dart';

/// State Controller managing Onboarding navigation, academic history and target selections
class OnboardingController extends ChangeNotifier {
  final ApiClient _apiClient;

  int _currentStep = 0;
  StudentMedium _medium = StudentMedium.bangla;
  NctbVersion _nctbVersion = NctbVersion.bangla;
  EnglishCurriculum _curriculum = EnglishCurriculum.cambridge;
  String _academicBatch = "HSC '25";
  String _institutionName = 'General Education Board';
  String _studentName = '';
  String _phone = '';

  // Demographic & Location Fields (Division and District on top)
  String _gender = 'male'; // 'male', 'female', 'other'
  String? _divisionId;
  String? _divisionName;
  String? _districtId;
  String? _districtName;

  // SSC History Details
  String _sscGroup = 'Science';
  String _sscYear = '';
  String _sscGpa = '';
  String _sscInstitution = '';
  String _sscEiin = '';

  // HSC History Details
  String _hscGroup = 'Science';
  String _hscBatch = '';
  String _hscGpa = '';
  String _hscInstitution = '';
  String _hscEiin = '';

  // O-Level History Details (English Medium)
  String _oLevelBoard = 'Cambridge International'; // 'Cambridge International' or 'Pearson Edexcel'
  String _oLevelYear = '2023';
  int _oLevelSubjectsCount = 7;
  String _oLevelGrades = '5 A*, 2 A';
  String _oLevelGpaEquiv = '5.00';
  String _oLevelSchool = '';
  String _oLevelInstitutionId = '';

  // A-Level History Details (English Medium)
  String _aLevelBoard = 'Cambridge International'; // 'Cambridge International' or 'Pearson Edexcel'
  String _aLevelBatch = "A Level '24";
  String _aLevelStatus = 'Completed'; // 'Completed' or 'Appearing'
  int _aLevelSubjectsCount = 3;
  String _aLevelGrades = '2 A*, 1 A';
  String _aLevelGpaEquiv = '5.00';
  String _aLevelCollege = '';
  String _aLevelInstitutionId = '';
  
  // Map of University ID -> Set of Discipline IDs
  final Map<String, Set<String>> _targetSelections = {};
  bool _isSubmitting = false;

  String? _existingUserId;
  int _existingStudyStreak = 0;

  OnboardingController({
    ApiClient? apiClient,
    String initialName = '',
    String initialPhone = '',
    UserProfile? initialProfile,
    int initialStep = 0,
  })  : _apiClient = apiClient ?? ApiClient(),
        _currentStep = initialStep,
        _studentName = initialProfile?.name ?? initialName,
        _phone = initialProfile?.phone ?? initialPhone {
    if (initialProfile != null) {
      _existingUserId = initialProfile.id;
      _existingStudyStreak = initialProfile.studyStreakDays;
      _gender = initialProfile.gender ?? 'male';
      _divisionId = initialProfile.divisionId;
      _divisionName = initialProfile.divisionName;
      _districtId = initialProfile.districtId;
      _districtName = initialProfile.districtName;
      _medium = initialProfile.medium;
      _nctbVersion = initialProfile.nctbVersion ?? NctbVersion.bangla;
      _curriculum = initialProfile.englishCurriculum ?? EnglishCurriculum.cambridge;
      _academicBatch = initialProfile.academicBatch;
      _institutionName = initialProfile.institutionName;

      _sscGroup = initialProfile.sscGroup ?? 'Science';
      _sscYear = initialProfile.sscYear ?? '';
      _sscGpa = initialProfile.sscGpa ?? '';
      _sscInstitution = initialProfile.sscInstitution ?? '';
      _sscEiin = initialProfile.sscEiin ?? '';

      _hscGroup = initialProfile.hscGroup ?? 'Science';
      _hscBatch = initialProfile.hscBatch ?? initialProfile.academicBatch;
      _hscGpa = initialProfile.hscGpa ?? '';
      _hscInstitution = initialProfile.hscInstitution ?? initialProfile.institutionName;
      _hscEiin = initialProfile.hscEiin ?? '';

      _oLevelBoard = initialProfile.oLevelBoard ?? 'Cambridge International';
      _oLevelYear = initialProfile.oLevelYear ?? '2023';
      _oLevelSubjectsCount = initialProfile.oLevelSubjectsCount ?? 7;
      _oLevelGrades = initialProfile.oLevelGrades ?? '5 A*, 2 A';
      _oLevelGpaEquiv = initialProfile.oLevelGpaEquiv ?? '5.00';
      _oLevelSchool = initialProfile.oLevelSchool ?? '';
      _oLevelInstitutionId = initialProfile.oLevelInstitutionId ?? '';

      _aLevelBoard = initialProfile.aLevelBoard ?? 'Cambridge International';
      _aLevelBatch = initialProfile.aLevelBatch ?? "A Level '24";
      _aLevelStatus = initialProfile.aLevelStatus ?? 'Completed';
      _aLevelSubjectsCount = initialProfile.aLevelSubjectsCount ?? 3;
      _aLevelGrades = initialProfile.aLevelGrades ?? '2 A*, 1 A';
      _aLevelGpaEquiv = initialProfile.aLevelGpaEquiv ?? '5.00';
      _aLevelCollege = initialProfile.aLevelCollege ?? initialProfile.institutionName;
      _aLevelInstitutionId = initialProfile.aLevelInstitutionId ?? '';

      for (final entry in initialProfile.targetSelections.entries) {
        _targetSelections[entry.key] = Set<String>.from(entry.value);
      }
    }
  }

  // Getters
  int get currentStep => _currentStep;
  StudentMedium get medium => _medium;
  NctbVersion get nctbVersion => _nctbVersion;
  EnglishCurriculum get curriculum => _curriculum;
  String get academicBatch => _academicBatch;
  String get institutionName => _institutionName.isNotEmpty ? _institutionName : _hscInstitution;
  String get studentName => _studentName;
  String get phone => _phone;

  String get gender => _gender;
  String? get divisionId => _divisionId;
  String? get divisionName => _divisionName;
  String? get districtId => _districtId;
  String? get districtName => _districtName;

  String get sscGroup => _sscGroup;
  String get sscYear => _sscYear;
  String get sscGpa => _sscGpa;
  String get sscInstitution => _sscInstitution;
  String get sscEiin => _sscEiin;

  String get hscGroup => _hscGroup;
  String get hscBatch => _hscBatch;
  String get hscGpa => _hscGpa;
  String get hscInstitution => _hscInstitution;
  String get hscEiin => _hscEiin;

  // O-Level Getters
  String get oLevelBoard => _oLevelBoard;
  String get oLevelYear => _oLevelYear;
  int get oLevelSubjectsCount => _oLevelSubjectsCount;
  String get oLevelGrades => _oLevelGrades;
  String get oLevelGpaEquiv => _oLevelGpaEquiv;
  String get oLevelSchool => _oLevelSchool;
  String get oLevelInstitutionId => _oLevelInstitutionId;

  // A-Level Getters
  String get aLevelBoard => _aLevelBoard;
  String get aLevelBatch => _aLevelBatch;
  String get aLevelStatus => _aLevelStatus;
  int get aLevelSubjectsCount => _aLevelSubjectsCount;
  String get aLevelGrades => _aLevelGrades;
  String get aLevelGpaEquiv => _aLevelGpaEquiv;
  String get aLevelCollege => _aLevelCollege;
  String get aLevelInstitutionId => _aLevelInstitutionId;

  Map<String, Set<String>> get targetSelections => _targetSelections;
  bool get isSubmitting => _isSubmitting;

  // Setters & Actions
  void setMedium(StudentMedium val) {
    _medium = val;
    _academicBatch = val == StudentMedium.bangla ? "HSC '25" : "A-Level '25";
    _hscBatch = _academicBatch;
    _aLevelBatch = _academicBatch;
    notifyListeners();
  }

  void setNctbVersion(NctbVersion val) {
    _nctbVersion = val;
    notifyListeners();
  }

  void setEnglishCurriculum(EnglishCurriculum val) {
    _curriculum = val;
    final boardName = val == EnglishCurriculum.cambridge ? 'Cambridge International' : 'Pearson Edexcel';
    _oLevelBoard = boardName;
    _aLevelBoard = boardName;
    notifyListeners();
  }

  void setGender(String val) {
    _gender = val;
    notifyListeners();
  }

  void setDivision({required String? id, required String? name}) {
    _divisionId = id;
    _divisionName = name;
    _districtId = null;
    _districtName = null;
    notifyListeners();
  }

  void setDistrict({required String? id, required String? name}) {
    _districtId = id;
    _districtName = name;
    notifyListeners();
  }

  void setSscDetails({
    String? group,
    String? year,
    String? gpa,
    String? institution,
    String? eiin,
  }) {
    if (group != null) _sscGroup = group;
    if (year != null) _sscYear = year;
    if (gpa != null) _sscGpa = gpa;
    if (institution != null) _sscInstitution = institution;
    if (eiin != null) _sscEiin = eiin;
    notifyListeners();
  }

  void setHscDetails({
    String? group,
    String? batch,
    String? gpa,
    String? institution,
    String? eiin,
  }) {
    if (group != null) _hscGroup = group;
    if (batch != null) {
      _hscBatch = batch;
      _academicBatch = batch;
    }
    if (gpa != null) _hscGpa = gpa;
    if (institution != null) {
      _hscInstitution = institution;
      _institutionName = institution;
    }
    if (eiin != null) _hscEiin = eiin;
    notifyListeners();
  }

  void setAcademicBatch(String batch) {
    _academicBatch = batch;
    _hscBatch = batch;
    _aLevelBatch = batch;
    notifyListeners();
  }

  void setOLevelDetails({
    String? board,
    String? year,
    int? subjectsCount,
    String? grades,
    String? gpaEquiv,
    String? school,
    String? institutionId,
  }) {
    if (board != null) _oLevelBoard = board;
    if (year != null) _oLevelYear = year;
    if (subjectsCount != null) _oLevelSubjectsCount = subjectsCount;
    if (grades != null) _oLevelGrades = grades;
    if (gpaEquiv != null) _oLevelGpaEquiv = gpaEquiv;
    if (school != null) _oLevelSchool = school;
    if (institutionId != null) _oLevelInstitutionId = institutionId;
    notifyListeners();
  }

  void setALevelDetails({
    String? board,
    String? batch,
    String? status,
    int? subjectsCount,
    String? grades,
    String? gpaEquiv,
    String? college,
    String? institutionId,
  }) {
    if (board != null) _aLevelBoard = board;
    if (batch != null) {
      _aLevelBatch = batch;
      _academicBatch = batch;
    }
    if (status != null) _aLevelStatus = status;
    if (subjectsCount != null) _aLevelSubjectsCount = subjectsCount;
    if (grades != null) _aLevelGrades = grades;
    if (gpaEquiv != null) _aLevelGpaEquiv = gpaEquiv;
    if (college != null) {
      _aLevelCollege = college;
      _institutionName = college;
    }
    if (institutionId != null) _aLevelInstitutionId = institutionId;
    notifyListeners();
  }

  void setInstitutionName(String name) {
    _institutionName = name;
    _hscInstitution = name;
    notifyListeners();
  }

  void setStudentDetails({required String name, required String phone}) {
    _studentName = name;
    _phone = phone;
    notifyListeners();
  }

  /// Toggle university selection. If toggled on, automatically selects first discipline as default.
  void toggleUniversity(PrivateUniversity uni) {
    if (_targetSelections.containsKey(uni.id)) {
      _targetSelections.remove(uni.id);
    } else {
      _targetSelections[uni.id] = {uni.disciplines.first.id};
    }
    notifyListeners();
  }

  /// Toggle discipline under a selected university
  void toggleDiscipline(String uniId, String disciplineId) {
    if (!_targetSelections.containsKey(uniId)) {
      _targetSelections[uniId] = {};
    }
    final set = _targetSelections[uniId]!;
    if (set.contains(disciplineId)) {
      if (set.length > 1) {
        set.remove(disciplineId);
      }
    } else {
      set.add(disciplineId);
    }
    notifyListeners();
  }

  bool isUniversitySelected(String uniId) => _targetSelections.containsKey(uniId);
  bool isDisciplineSelected(String uniId, String disciplineId) =>
      _targetSelections[uniId]?.contains(disciplineId) ?? false;

  bool get canProceedToStep2 {
    if (_studentName.trim().isEmpty) {
      _studentName = 'Candidate';
    }
    return true;
  }

  bool get canComplete => _targetSelections.isNotEmpty;

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void jumpToStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  /// Finalizes Onboarding and submits to server/cache
  Future<UserProfile?> completeOnboarding() async {
    _isSubmitting = true;
    notifyListeners();

    final profile = UserProfile(
      id: SupabaseService().currentUser?.id ?? _existingUserId ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: _studentName.isEmpty ? 'Candidate' : _studentName,
      phone: _phone,
      gender: _gender,
      divisionId: _divisionId,
      divisionName: _divisionName,
      districtId: _districtId,
      districtName: _districtName,
      sscGroup: _sscGroup,
      sscYear: _sscYear,
      sscGpa: _sscGpa,
      sscInstitution: _sscInstitution,
      sscEiin: _sscEiin,
      hscGroup: _hscGroup,
      hscBatch: _hscBatch,
      hscGpa: _hscGpa,
      hscInstitution: _hscInstitution.isNotEmpty ? _hscInstitution : _institutionName,
      hscEiin: _hscEiin,
      oLevelBoard: _medium == StudentMedium.english ? _oLevelBoard : null,
      oLevelYear: _medium == StudentMedium.english ? _oLevelYear : null,
      oLevelSubjectsCount: _medium == StudentMedium.english ? _oLevelSubjectsCount : null,
      oLevelGrades: _medium == StudentMedium.english ? _oLevelGrades : null,
      oLevelGpaEquiv: _medium == StudentMedium.english ? _oLevelGpaEquiv : null,
      oLevelSchool: _medium == StudentMedium.english ? _oLevelSchool : null,
      oLevelInstitutionId: _medium == StudentMedium.english ? _oLevelInstitutionId : null,
      aLevelBoard: _medium == StudentMedium.english ? _aLevelBoard : null,
      aLevelBatch: _medium == StudentMedium.english ? _aLevelBatch : null,
      aLevelStatus: _medium == StudentMedium.english ? _aLevelStatus : null,
      aLevelSubjectsCount: _medium == StudentMedium.english ? _aLevelSubjectsCount : null,
      aLevelGrades: _medium == StudentMedium.english ? _aLevelGrades : null,
      aLevelGpaEquiv: _medium == StudentMedium.english ? _aLevelGpaEquiv : null,
      aLevelCollege: _medium == StudentMedium.english ? (_aLevelCollege.isNotEmpty ? _aLevelCollege : _institutionName) : null,
      aLevelInstitutionId: _medium == StudentMedium.english ? _aLevelInstitutionId : null,
      medium: _medium,
      nctbVersion: _medium == StudentMedium.bangla ? _nctbVersion : null,
      englishCurriculum: _medium == StudentMedium.english ? _curriculum : null,
      academicBatch: _academicBatch.trim().isNotEmpty
          ? _academicBatch.trim()
          : (_medium == StudentMedium.bangla ? "HSC '25" : "A-Level '25"),
      institutionName: _hscInstitution.trim().isNotEmpty
          ? _hscInstitution.trim()
          : (_institutionName.trim().isNotEmpty ? _institutionName.trim() : 'General Education Board'),
      studyStreakDays: _existingStudyStreak,
      targetSelections: _targetSelections.map((k, v) => MapEntry(k, v.toList())),
    );

    final saved = await _apiClient.submitOnboarding(profile);
    _isSubmitting = false;
    notifyListeners();
    return saved ? profile : null;
  }
}

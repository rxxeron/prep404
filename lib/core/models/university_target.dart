import '../widgets/university_logo.dart';

/// Academic Medium for Bangladeshi Students
enum StudentMedium {
  bangla,
  english;

  String get displayName => this == StudentMedium.bangla ? 'Bangla Medium (NCTB)' : 'English Medium';
}

/// Version stream for Bangla Medium (NCTB)
enum NctbVersion {
  bangla,
  english;

  String get displayName => this == NctbVersion.bangla
      ? 'NCTB Bangla Version'
      : 'NCTB English Version';
}

/// Curriculum stream for English Medium
enum EnglishCurriculum {
  cambridge,
  edexcel;

  String get displayName => this == EnglishCurriculum.cambridge ? 'Cambridge (CAIE)' : 'Pearson Edexcel';
}

/// Discipline / Major category in Private Universities
enum DisciplineCategory {
  engineering, // CSE, EEE, ECE, Civil
  business,    // BBA, Economics, Accounting
  pharmacy,    // Pharmacy, Bio-sciences
  architecture, // Architecture, Design
  lawAndArts   // Law, English, Media
}

/// University Discipline definition
class UniversityDiscipline {
  final String id;
  final String name;
  final String department;
  final DisciplineCategory category;
  final List<String> examSections; // e.g. ['Math', 'English', 'Physics']

  const UniversityDiscipline({
    required this.id,
    required this.name,
    this.department = '',
    required this.category,
    required this.examSections,
  });
}

/// Information about an upcoming semester admission cycle and examination slots
class AdmissionCycleInfo {
  final String id;
  final String season;
  final int academicYear;
  final int slotNumber;
  final String slotTitle;
  final DateTime? applicationDeadline;
  final DateTime examDate;
  final String examTime;
  final String applicationFee;
  final String venue;
  final String notes;
  final String status;

  const AdmissionCycleInfo({
    required this.id,
    required this.season,
    required this.academicYear,
    this.slotNumber = 1,
    this.slotTitle = '',
    this.applicationDeadline,
    required this.examDate,
    this.examTime = '',
    this.applicationFee = 'BDT 1,500',
    this.venue = '',
    this.notes = '',
    this.status = 'upcoming',
  });
}

/// Top Private University Model
class PrivateUniversity {
  final String id;
  final String code;
  final String fullName;
  final String location;
  final String? _logoUrl;
  final DateTime estimatedExamDate;
  final List<UniversityDiscipline> disciplines;
  final String examFormatType; // 'centralized', 'faculty_wide', 'department_wise'
  final String examPatternSummary;
  final List<AdmissionCycleInfo> admissionCycles;

  const PrivateUniversity({
    required this.id,
    required this.code,
    required this.fullName,
    required this.location,
    String? logoUrl,
    required this.estimatedExamDate,
    required this.disciplines,
    this.examFormatType = 'faculty_wide',
    this.examPatternSummary = '',
    this.admissionCycles = const [],
  }) : _logoUrl = logoUrl;

  String? get logoUrl =>
      _logoUrl ??
      UniversityLogo.officialLogos[code.toLowerCase()] ??
      UniversityLogo.officialLogos[id.toLowerCase()];
}

/// Baseline fallback university definitions for offline test suites.
/// In production, all universities, academic departments, degree programs,
/// and admission test slot schedules are loaded dynamically from Supabase database.
class UniversityCatalog {
  static final List<PrivateUniversity> universities = [
    PrivateUniversity(
      id: 'aust',
      code: 'AUST',
      fullName: 'Ahsanullah University of Science & Technology',
      location: 'Tejgaon, Dhaka',
      estimatedExamDate: DateTime(2026, 11, 29),
      examFormatType: 'faculty_wide',
      disciplines: const [
        UniversityDiscipline(
          id: 'aust_eng',
          name: 'Engineering Units (CSE/EEE/CE/ME)',
          category: DisciplineCategory.engineering,
          examSections: ['Higher Math', 'Physics', 'Chemistry', 'English'],
        ),
        UniversityDiscipline(
          id: 'aust_bba',
          name: 'Bachelor of Business Administration (BBA)',
          category: DisciplineCategory.business,
          examSections: ['General English', 'Quantitative Math'],
        ),
        UniversityDiscipline(
          id: 'aust_arch',
          name: 'Bachelor of Architecture (B.Arch)',
          category: DisciplineCategory.architecture,
          examSections: ['Spatial Logic', 'Math', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'aiub',
      code: 'AIUB',
      fullName: 'American International University-Bangladesh',
      location: 'Kuratoli, Khilkhet, Dhaka',
      estimatedExamDate: DateTime(2026, 11, 26),
      examFormatType: 'faculty_wide',
      disciplines: const [
        UniversityDiscipline(
          id: 'aiub_cse',
          name: 'Computer Science & Engineering (FST)',
          category: DisciplineCategory.engineering,
          examSections: ['English', 'Mathematics', 'Physics'],
        ),
        UniversityDiscipline(
          id: 'aiub_bba',
          name: 'Faculty of Business Administration (BBA)',
          category: DisciplineCategory.business,
          examSections: ['English', 'Quantitative Math', 'General Knowledge'],
        ),
        UniversityDiscipline(
          id: 'aiub_pharm',
          name: 'Bachelor of Pharmacy (B.Pharm)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Biology', 'Chemistry', 'English'],
        ),
        UniversityDiscipline(
          id: 'aiub_arch',
          name: 'Bachelor of Architecture (B.Arch)',
          category: DisciplineCategory.architecture,
          examSections: ['Drawing', 'Math', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'brac',
      code: 'BRACU',
      fullName: 'BRAC University',
      location: 'Merul Badda, Dhaka',
      estimatedExamDate: DateTime(2026, 12, 5),
      examFormatType: 'centralized',
      disciplines: const [
        UniversityDiscipline(
          id: 'brac_cse',
          name: 'School of Engineering & Computing (CSE)',
          category: DisciplineCategory.engineering,
          examSections: ['English', 'Higher Math', 'Physics'],
        ),
        UniversityDiscipline(
          id: 'brac_bba',
          name: 'BRAC Business School (BBS BBA)',
          category: DisciplineCategory.business,
          examSections: ['General English', 'Quantitative Math'],
        ),
        UniversityDiscipline(
          id: 'brac_pharm',
          name: 'Department of Pharmacy (B.Pharm)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Biology', 'Chemistry', 'English'],
        ),
        UniversityDiscipline(
          id: 'brac_arch',
          name: 'Department of Architecture (B.Arch)',
          category: DisciplineCategory.architecture,
          examSections: ['Spatial Logic', 'Math', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'ewu',
      code: 'EWU',
      fullName: 'East West University',
      location: 'Aftabnagar, Dhaka',
      estimatedExamDate: DateTime(2026, 12, 8),
      examFormatType: 'faculty_wide',
      disciplines: const [
        UniversityDiscipline(
          id: 'ewu_cse',
          name: 'Faculty of Sciences & Engineering (FSE)',
          category: DisciplineCategory.engineering,
          examSections: ['English', 'Mathematics', 'Physics', 'Chemistry'],
        ),
        UniversityDiscipline(
          id: 'ewu_bba',
          name: 'Faculty of Business & Economics (FBS)',
          category: DisciplineCategory.business,
          examSections: ['General English', 'General Mathematics'],
        ),
        UniversityDiscipline(
          id: 'ewu_pharm',
          name: 'Department of Pharmacy (B.Pharm)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Biology', 'Chemistry', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'iub',
      code: 'IUB',
      fullName: 'Independent University, Bangladesh',
      location: 'Bashundhara R/A, Dhaka',
      estimatedExamDate: DateTime(2026, 12, 1),
      examFormatType: 'centralized',
      disciplines: const [
        UniversityDiscipline(
          id: 'iub_cse',
          name: 'School of Engineering, Tech & Sciences (SETS)',
          category: DisciplineCategory.engineering,
          examSections: ['English', 'Higher Math', 'Physics'],
        ),
        UniversityDiscipline(
          id: 'iub_bba',
          name: 'School of Business & Entrepreneurship (SBE)',
          category: DisciplineCategory.business,
          examSections: ['English', 'Quantitative Aptitude'],
        ),
        UniversityDiscipline(
          id: 'iub_pharm',
          name: 'School of Pharmacy & Public Health (SPPH)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Chemistry', 'Biology', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'nsu',
      code: 'NSU',
      fullName: 'North South University',
      location: 'Bashundhara R/A, Dhaka',
      estimatedExamDate: DateTime(2026, 11, 28),
      examFormatType: 'centralized',
      disciplines: const [
        UniversityDiscipline(
          id: 'nsu_cse',
          name: 'School of Engineering & Physical Sciences (SEPS)',
          category: DisciplineCategory.engineering,
          examSections: ['General English', 'Quantitative Math', 'Higher Math'],
        ),
        UniversityDiscipline(
          id: 'nsu_bba',
          name: 'School of Business & Economics (SBE)',
          category: DisciplineCategory.business,
          examSections: ['General English', 'Quantitative Math'],
        ),
        UniversityDiscipline(
          id: 'nsu_pharm',
          name: 'School of Health & Life Sciences (SHLS)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Biology', 'Chemistry', 'English'],
        ),
        UniversityDiscipline(
          id: 'nsu_arch',
          name: 'Department of Architecture (B.Arch)',
          category: DisciplineCategory.architecture,
          examSections: ['Spatial Logic', 'Math', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'uiu',
      code: 'UIU',
      fullName: 'United International University',
      location: 'Madani Avenue, Dhaka',
      estimatedExamDate: DateTime(2026, 12, 4),
      examFormatType: 'faculty_wide',
      disciplines: const [
        UniversityDiscipline(
          id: 'uiu_cse',
          name: 'School of Science & Engineering (SOSE)',
          category: DisciplineCategory.engineering,
          examSections: ['Mathematics', 'Physics', 'English'],
        ),
        UniversityDiscipline(
          id: 'uiu_bba',
          name: 'School of Business & Economics (SOBE)',
          category: DisciplineCategory.business,
          examSections: ['English', 'Quantitative Math'],
        ),
        UniversityDiscipline(
          id: 'uiu_pharm',
          name: 'Department of Pharmacy (B.Pharm)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Biology', 'Chemistry', 'English'],
        ),
      ],
    ),
    PrivateUniversity(
      id: 'uap',
      code: 'UAP',
      fullName: 'University of Asia Pacific',
      location: 'Green Road, Farmgate, Dhaka',
      estimatedExamDate: DateTime(2026, 11, 25),
      examFormatType: 'department_wise',
      disciplines: const [
        UniversityDiscipline(
          id: 'uap_cse',
          name: 'School of Engineering (Civil & CSE)',
          category: DisciplineCategory.engineering,
          examSections: ['Mathematics', 'Physics', 'English'],
        ),
        UniversityDiscipline(
          id: 'uap_bba',
          name: 'Department of Business Administration (BBA)',
          category: DisciplineCategory.business,
          examSections: ['English', 'Quantitative Math', 'Aptitude'],
        ),
        UniversityDiscipline(
          id: 'uap_pharm',
          name: 'Department of Pharmacy (B.Pharm)',
          category: DisciplineCategory.pharmacy,
          examSections: ['Biology', 'Chemistry', 'English'],
        ),
        UniversityDiscipline(
          id: 'uap_arch',
          name: 'Department of Architecture (B.Arch)',
          category: DisciplineCategory.architecture,
          examSections: ['Drawing & Logic', 'Math', 'English'],
        ),
      ],
    ),
  ];
}

import {
  CommunityLink,
  DisciplineCategory,
  PrivateUniversity,
  UniversityBlueprint,
} from '../types';

export interface DivisionItem {
  id: string;
  nameEn: string;
  nameBn: string;
}

export interface DistrictItem {
  id: string;
  divisionId: string;
  nameEn: string;
  nameBn: string;
}

export interface InstitutionItem {
  id: string;
  eiin: string;
  nameEn: string;
  nameBn?: string;
  isCollege: boolean;
  isSchool: boolean;
  board?: string;
  area?: string;
  district?: string;
}

export interface LeagueTier {
  id: string;
  name: string;
  greekSymbol: string;
  minRank: number;
  maxRank: number;
  colorHex: string;
  description: string;
}

export const LEAGUE_TIERS: LeagueTier[] = [
  {
    id: 'alpha',
    name: 'Alpha League',
    greekSymbol: 'Α',
    minRank: 1,
    maxRank: 1000,
    colorHex: '#FFD700',
    description: 'Elite Top 1,000 Private University Admission Contenders',
  },
  {
    id: 'beta',
    name: 'Beta League',
    greekSymbol: 'Β',
    minRank: 1001,
    maxRank: 2000,
    colorHex: '#E5E7EB',
    description: 'High-performing STEM & Business Scholars',
  },
  {
    id: 'gamma',
    name: 'Gamma League',
    greekSymbol: 'Γ',
    minRank: 2001,
    maxRank: 3000,
    colorHex: '#CD7F32',
    description: 'Consistent Merit Track Contenders',
  },
  {
    id: 'theta',
    name: 'Theta League',
    greekSymbol: 'Θ',
    minRank: 3001,
    maxRank: 4000,
    colorHex: '#10B981',
    description: 'Rising Problem Solvers',
  },
  {
    id: 'lambda',
    name: 'Lambda League',
    greekSymbol: 'Λ',
    minRank: 4001,
    maxRank: 5000,
    colorHex: '#3B82F6',
    description: 'Focused Admission Candidates',
  },
  {
    id: 'sigma',
    name: 'Sigma League',
    greekSymbol: 'Σ',
    minRank: 5001,
    maxRank: 8000,
    colorHex: '#8B5CF6',
    description: 'Dedicated Practice Builders',
  },
  {
    id: 'omega',
    name: 'Omega League',
    greekSymbol: 'Ω',
    minRank: 8001,
    maxRank: 13000,
    colorHex: '#6B7280',
    description: 'Foundational Admission Aspirants',
  },
];

export const UNIVERSITY_MONOGRAMS: Record<
  string,
  { abbr: string; bg: string; fg: string }
> = {
  bracu: { abbr: 'BRACU', bg: '#005A9C', fg: '#FFFFFF' },
  brac: { abbr: 'BRACU', bg: '#005A9C', fg: '#FFFFFF' },
  nsu: { abbr: 'NSU', bg: '#1E3A8A', fg: '#FBBF24' },
  aiub: { abbr: 'AIUB', bg: '#0D47A1', fg: '#FFFFFF' },
  aust: { abbr: 'AUST', bg: '#065F46', fg: '#FFFFFF' },
  ewu: { abbr: 'EWU', bg: '#1D4ED8', fg: '#FFFFFF' },
  iub: { abbr: 'IUB', bg: '#0F766E', fg: '#FFFFFF' },
  uiu: { abbr: 'UIU', bg: '#EA580C', fg: '#FFFFFF' },
  uap: { abbr: 'UAP', bg: '#542747', fg: '#FFD166' },
};

export const UNIVERSITY_CATALOG: PrivateUniversity[] = [
  {
    id: 'aust',
    code: 'AUST',
    fullName: 'Ahsanullah University of Science & Technology',
    location: 'Tejgaon, Dhaka',
    estimatedExamDate: '2026-11-29T09:00:00Z',
    examFormatType: 'faculty_wide',
    examPatternSummary: '100 MCQs • Higher Math, Physics, Chemistry & English • Zero Negative',
    disciplines: [
      {
        id: 'aust_eng',
        name: 'Engineering Units (CSE/EEE/CE/ME)',
        department: 'Faculty of Engineering',
        category: 'engineering',
        examSections: ['Higher Math', 'Physics', 'Chemistry', 'English'],
      },
      {
        id: 'aust_bba',
        name: 'Bachelor of Business Administration (BBA)',
        department: 'School of Business',
        category: 'business',
        examSections: ['General English', 'Quantitative Math'],
      },
      {
        id: 'aust_arch',
        name: 'Bachelor of Architecture (B.Arch)',
        department: 'Department of Architecture',
        category: 'architecture',
        examSections: ['Spatial Logic', 'Math', 'English'],
      },
    ],
    admissionCycles: [
      {
        id: 'aust_fall_26',
        season: 'Fall',
        academicYear: 2026,
        slotNumber: 1,
        slotTitle: 'Written & MCQ Engineering Slot',
        applicationDeadline: '2026-11-18',
        examDate: '2026-11-29',
        examTime: '10:00 AM',
        applicationFee: 'BDT 1,500',
        venue: 'AUST Main Campus, Tejgaon I/A',
        status: 'upcoming',
      },
    ],
  },
  {
    id: 'aiub',
    code: 'AIUB',
    fullName: 'American International University-Bangladesh',
    location: 'Kuratoli, Khilkhet, Dhaka',
    estimatedExamDate: '2026-11-26T09:00:00Z',
    examFormatType: 'faculty_wide',
    examPatternSummary: '75 MCQs + Short Essay • Zero Negative Marking • 90 Mins',
    disciplines: [
      {
        id: 'aiub_cse',
        name: 'Computer Science & Engineering (FST)',
        department: 'Faculty of Science & Technology',
        category: 'engineering',
        examSections: ['English', 'Mathematics', 'Physics'],
      },
      {
        id: 'aiub_bba',
        name: 'Faculty of Business Administration (BBA)',
        department: 'FBA',
        category: 'business',
        examSections: ['English', 'Quantitative Math', 'General Knowledge'],
      },
      {
        id: 'aiub_pharm',
        name: 'Bachelor of Pharmacy (B.Pharm)',
        department: 'Faculty of Health',
        category: 'pharmacy',
        examSections: ['Biology', 'Chemistry', 'English'],
      },
      {
        id: 'aiub_arch',
        name: 'Bachelor of Architecture (B.Arch)',
        department: 'Architecture',
        category: 'architecture',
        examSections: ['Drawing', 'Math', 'English'],
      },
    ],
    admissionCycles: [
      {
        id: 'aiub_slot_1',
        season: 'Spring',
        academicYear: 2026,
        slotNumber: 1,
        slotTitle: 'Admission Test Slot 1',
        applicationDeadline: '2026-11-20',
        examDate: '2026-11-26',
        examTime: '09:30 AM',
        applicationFee: 'BDT 1,500',
        venue: 'AIUB Permanent Campus, Kuratoli',
        status: 'upcoming',
      },
    ],
  },
  {
    id: 'brac',
    code: 'BRACU',
    fullName: 'BRAC University',
    location: 'Merul Badda, Dhaka',
    estimatedExamDate: '2026-12-05T09:00:00Z',
    examFormatType: 'centralized',
    examPatternSummary: 'MCQ + Essay • English Composition, Higher Math & Physics • Zero Neg',
    disciplines: [
      {
        id: 'brac_cse',
        name: 'School of Engineering & Computing (CSE)',
        department: 'BSRM School of Engineering',
        category: 'engineering',
        examSections: ['English', 'Higher Math', 'Physics'],
      },
      {
        id: 'brac_bba',
        name: 'BRAC Business School (BBS BBA)',
        department: 'BRAC Business School',
        category: 'business',
        examSections: ['General English', 'Quantitative Math'],
      },
      {
        id: 'brac_pharm',
        name: 'Department of Pharmacy (B.Pharm)',
        department: 'School of Pharmacy',
        category: 'pharmacy',
        examSections: ['Biology', 'Chemistry', 'English'],
      },
      {
        id: 'brac_arch',
        name: 'Department of Architecture (B.Arch)',
        department: 'School of Architecture & Design',
        category: 'architecture',
        examSections: ['Spatial Logic', 'Math', 'English'],
      },
    ],
    admissionCycles: [
      {
        id: 'brac_spring_27',
        season: 'Spring',
        academicYear: 2027,
        slotNumber: 1,
        slotTitle: 'Centralized Admission Test',
        applicationDeadline: '2026-11-28',
        examDate: '2026-12-05',
        examTime: '09:00 AM',
        applicationFee: 'BDT 1,500',
        venue: 'BRACU Campus, Merul Badda',
        status: 'open',
      },
    ],
  },
  {
    id: 'ewu',
    code: 'EWU',
    fullName: 'East West University',
    location: 'Aftabnagar, Dhaka',
    estimatedExamDate: '2026-12-08T09:00:00Z',
    examFormatType: 'faculty_wide',
    examPatternSummary: '100 MCQs • English, Math, Physics/Chem • 90 Mins • Zero Negative',
    disciplines: [
      {
        id: 'ewu_cse',
        name: 'Faculty of Sciences & Engineering (FSE)',
        department: 'FSE',
        category: 'engineering',
        examSections: ['English', 'Mathematics', 'Physics', 'Chemistry'],
      },
      {
        id: 'ewu_bba',
        name: 'Faculty of Business & Economics (FBS)',
        department: 'FBS',
        category: 'business',
        examSections: ['General English', 'General Mathematics'],
      },
      {
        id: 'ewu_pharm',
        name: 'Department of Pharmacy (B.Pharm)',
        department: 'Department of Pharmacy',
        category: 'pharmacy',
        examSections: ['Biology', 'Chemistry', 'English'],
      },
    ],
  },
  {
    id: 'iub',
    code: 'IUB',
    fullName: 'Independent University, Bangladesh',
    location: 'Bashundhara R/A, Dhaka',
    estimatedExamDate: '2026-12-01T09:00:00Z',
    examFormatType: 'centralized',
    examPatternSummary: 'SAT-Aligned Quantitative & Verbal + Essay • 90 Mins',
    disciplines: [
      {
        id: 'iub_cse',
        name: 'School of Engineering, Tech & Sciences (SETS)',
        department: 'SETS',
        category: 'engineering',
        examSections: ['English', 'Higher Math', 'Physics'],
      },
      {
        id: 'iub_bba',
        name: 'School of Business & Entrepreneurship (SBE)',
        department: 'SBE',
        category: 'business',
        examSections: ['English', 'Quantitative Aptitude'],
      },
      {
        id: 'iub_pharm',
        name: 'School of Pharmacy & Public Health (SPPH)',
        department: 'SPPH',
        category: 'pharmacy',
        examSections: ['Chemistry', 'Biology', 'English'],
      },
    ],
  },
  {
    id: 'nsu',
    code: 'NSU',
    fullName: 'North South University',
    location: 'Bashundhara R/A, Dhaka',
    estimatedExamDate: '2026-11-28T09:00:00Z',
    examFormatType: 'centralized',
    examPatternSummary: 'General English + Quantitative + Higher Math + Essay • 120 Mins • 0 Negative',
    disciplines: [
      {
        id: 'nsu_cse',
        name: 'School of Engineering & Physical Sciences (SEPS)',
        department: 'SEPS',
        category: 'engineering',
        examSections: ['General English', 'Quantitative Math', 'Higher Math'],
      },
      {
        id: 'nsu_bba',
        name: 'School of Business & Economics (SBE)',
        department: 'SBE',
        category: 'business',
        examSections: ['General English', 'Quantitative Math'],
      },
      {
        id: 'nsu_pharm',
        name: 'School of Health & Life Sciences (SHLS)',
        department: 'SHLS',
        category: 'pharmacy',
        examSections: ['Biology', 'Chemistry', 'English'],
      },
      {
        id: 'nsu_arch',
        name: 'Department of Architecture (B.Arch)',
        department: 'Architecture',
        category: 'architecture',
        examSections: ['Spatial Logic', 'Math', 'English'],
      },
    ],
    admissionCycles: [
      {
        id: 'nsu_spring_27',
        season: 'Spring',
        academicYear: 2027,
        slotNumber: 1,
        slotTitle: 'Centralized Admission Exam',
        applicationDeadline: '2026-11-22',
        examDate: '2026-11-28',
        examTime: '10:00 AM',
        applicationFee: 'BDT 1,500',
        venue: 'NSU Campus, Bashundhara R/A',
        status: 'open',
      },
    ],
  },
  {
    id: 'uiu',
    code: 'UIU',
    fullName: 'United International University',
    location: 'Madani Avenue, Dhaka',
    estimatedExamDate: '2026-12-04T09:00:00Z',
    examFormatType: 'faculty_wide',
    examPatternSummary: '70 MCQs • Mathematics, Physics & English • Zero Negative',
    disciplines: [
      {
        id: 'uiu_cse',
        name: 'School of Science & Engineering (SOSE)',
        department: 'SOSE',
        category: 'engineering',
        examSections: ['Mathematics', 'Physics', 'English'],
      },
      {
        id: 'uiu_bba',
        name: 'School of Business & Economics (SOBE)',
        department: 'SOBE',
        category: 'business',
        examSections: ['English', 'Quantitative Math'],
      },
      {
        id: 'uiu_pharm',
        name: 'Department of Pharmacy (B.Pharm)',
        department: 'Pharmacy',
        category: 'pharmacy',
        examSections: ['Biology', 'Chemistry', 'English'],
      },
    ],
  },
  {
    id: 'uap',
    code: 'UAP',
    fullName: 'University of Asia Pacific',
    location: 'Green Road, Farmgate, Dhaka',
    estimatedExamDate: '2026-11-25T09:00:00Z',
    examFormatType: 'department_wise',
    examPatternSummary: 'Department-specific MCQ + Written • 60 Mins',
    disciplines: [
      {
        id: 'uap_cse',
        name: 'School of Engineering (Civil & CSE)',
        department: 'Engineering',
        category: 'engineering',
        examSections: ['Mathematics', 'Physics', 'English'],
      },
      {
        id: 'uap_bba',
        name: 'Department of Business Administration (BBA)',
        department: 'BBA',
        category: 'business',
        examSections: ['English', 'Quantitative Math', 'Aptitude'],
      },
      {
        id: 'uap_pharm',
        name: 'Department of Pharmacy (B.Pharm)',
        department: 'Pharmacy',
        category: 'pharmacy',
        examSections: ['Biology', 'Chemistry', 'English'],
      },
      {
        id: 'uap_arch',
        name: 'Department of Architecture (B.Arch)',
        department: 'Architecture',
        category: 'architecture',
        examSections: ['Drawing & Logic', 'Math', 'English'],
      },
    ],
  },
];

export const PHASE_1_UNIVERSITY_CODES = [
  'NSU',
  'BRACU',
  'EWU',
  'UIU',
  'AIUB',
  'AUST',
  'UAP',
] as const;

export function getUniversityBlueprint(
  universityCode: string,
  category: DisciplineCategory = 'engineering'
): UniversityBlueprint {
  const code = universityCode.toUpperCase() === 'BRAC' ? 'BRACU' : universityCode.toUpperCase();
  const uni =
    UNIVERSITY_CATALOG.find(
      (u) => u.code.toUpperCase() === code || u.id.toUpperCase() === code
    ) || UNIVERSITY_CATALOG[5]; // NSU fallback

  const disc =
    uni.disciplines.find((d) => d.category === category) || uni.disciplines[0];

  const sectionColors = ['#F28C28', '#45204F', '#059669', '#2563EB', '#7C3AED'];

  if (code === 'NSU') {
    const isEng = disc.category === 'engineering';
    return {
      universityCode: 'NSU',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: isEng ? 110 : 85,
      durationMinutes: 120,
      negativeMarking: 0.0,
      cutOffPercent: 72,
      sections: isEng
        ? [
            { name: 'English Comprehension & Reading', questionCount: 25, marks: 25, weightPercent: 23, color: sectionColors[0] },
            { name: 'Grammar & Vocabulary', questionCount: 25, marks: 25, weightPercent: 23, color: sectionColors[1] },
            { name: 'Quantitative Aptitude (SAT Math)', questionCount: 30, marks: 30, weightPercent: 27, color: sectionColors[2] },
            { name: 'Higher Mathematics & Calculus', questionCount: 30, marks: 30, weightPercent: 27, color: sectionColors[3] },
          ]
        : [
            { name: 'English Comprehension & Reading', questionCount: 25, marks: 25, weightPercent: 29, color: sectionColors[0] },
            { name: 'Grammar & Vocabulary', questionCount: 25, marks: 25, weightPercent: 29, color: sectionColors[1] },
            { name: 'Quantitative Aptitude (SAT Math)', questionCount: 35, marks: 35, weightPercent: 42, color: sectionColors[2] },
          ],
      patternNotes: [
        'No negative marking on MCQs — attempt every question strategically.',
        'English Essay (20 marks) evaluated alongside MCQ score.',
        'OMR Bubble Sheet simulation adds +15 min buffer for realistic practice.',
      ],
    };
  }

  if (code === 'BRACU') {
    const isEng = disc.category === 'engineering';
    return {
      universityCode: 'BRACU',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: isEng ? 75 : 60,
      durationMinutes: 90,
      negativeMarking: 0.0,
      cutOffPercent: 75,
      sections: isEng
        ? [
            { name: 'English Grammar & Composition', questionCount: 25, marks: 25, weightPercent: 33, color: sectionColors[0] },
            { name: 'Higher Mathematics & Calculus', questionCount: 25, marks: 25, weightPercent: 33, color: sectionColors[1] },
            { name: 'Physics & Applied Mechanics', questionCount: 25, marks: 25, weightPercent: 34, color: sectionColors[2] },
          ]
        : [
            { name: 'English Grammar & Composition', questionCount: 30, marks: 30, weightPercent: 50, color: sectionColors[0] },
            { name: 'Quantitative Mathematics', questionCount: 30, marks: 30, weightPercent: 50, color: sectionColors[2] },
          ],
      patternNotes: [
        'Zero negative marking per MCQ — every selected answer locks permanently on first tap.',
        'Qualifying threshold required individually in English & Math.',
        'Includes structured English essay in final merit evaluation.',
      ],
    };
  }

  if (code === 'AUST') {
    return {
      universityCode: 'AUST',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: 100,
      durationMinutes: 90,
      negativeMarking: 0.0,
      cutOffPercent: 78,
      sections: [
        { name: 'Higher Mathematics & Conics', questionCount: 35, marks: 35, weightPercent: 35, color: sectionColors[0] },
        { name: 'Physics (Mechanics & Electricity)', questionCount: 35, marks: 35, weightPercent: 35, color: sectionColors[1] },
        { name: 'Chemistry (Organic & Physical)', questionCount: 20, marks: 20, weightPercent: 20, color: sectionColors[2] },
        { name: 'Technical & Functional English', questionCount: 10, marks: 10, weightPercent: 10, color: sectionColors[3] },
      ],
      patternNotes: [
        'Heavy STEM weighting (90% Math, Physics, Chemistry).',
        'Zero negative marking — avoid <2.5s impulse taps since locked answers cannot be changed.',
        'HSC GPA contributes alongside admission test score.',
      ],
    };
  }

  if (code === 'EWU') {
    return {
      universityCode: 'EWU',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: 100,
      durationMinutes: 90,
      negativeMarking: 0.0,
      cutOffPercent: 68,
      sections: [
        { name: 'English Language & Reading', questionCount: 25, marks: 25, weightPercent: 25, color: sectionColors[0] },
        { name: 'Higher Mathematics', questionCount: 35, marks: 35, weightPercent: 35, color: sectionColors[1] },
        { name: 'Physics', questionCount: 25, marks: 25, weightPercent: 25, color: sectionColors[2] },
        { name: 'Chemistry', questionCount: 15, marks: 15, weightPercent: 15, color: sectionColors[3] },
      ],
      patternNotes: [
        'Faculty of Sciences & Engineering (FSE) tests core HSC Math and Physics.',
        'Zero negative marking applies; target 75+ marks for merit scholarship consideration.',
      ],
    };
  }

  if (code === 'UIU') {
    return {
      universityCode: 'UIU',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: 70,
      durationMinutes: 75,
      negativeMarking: 0.0,
      cutOffPercent: 66,
      sections: [
        { name: 'Higher Mathematics & Quantitative', questionCount: 30, marks: 30, weightPercent: 43, color: sectionColors[0] },
        { name: 'Physics & Analytical Logic', questionCount: 20, marks: 20, weightPercent: 29, color: sectionColors[1] },
        { name: 'English Grammar & Reading', questionCount: 20, marks: 20, weightPercent: 28, color: sectionColors[2] },
      ],
      patternNotes: [
        'High-speed 70 MCQ paper in 75 minutes (~64 seconds per question) with 0 negative marking.',
        'Top 10% scorers qualify for 50%–100% UIU tuition fee waiver.',
      ],
    };
  }

  if (code === 'AIUB') {
    return {
      universityCode: 'AIUB',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: 75,
      durationMinutes: 90,
      negativeMarking: 0.0,
      cutOffPercent: 65,
      sections: [
        { name: 'Mathematics (Algebra & Calculus)', questionCount: 30, marks: 30, weightPercent: 40, color: sectionColors[0] },
        { name: 'English Usage & Comprehension', questionCount: 25, marks: 25, weightPercent: 33, color: sectionColors[1] },
        { name: 'Physics Fundamentals', questionCount: 20, marks: 20, weightPercent: 27, color: sectionColors[2] },
      ],
      patternNotes: [
        'Zero negative marking policy — complete all 75 MCQs within 90 minutes.',
        'Followed by viva/interview and short written paragraph verification.',
      ],
    };
  }

  if (code === 'UAP') {
    return {
      universityCode: 'UAP',
      universityName: uni.fullName,
      programName: disc.name,
      category: disc.category,
      totalQuestions: 60,
      durationMinutes: 60,
      negativeMarking: 0.0,
      cutOffPercent: 62,
      sections: [
        { name: 'Mathematics & Quantitative', questionCount: 25, marks: 25, weightPercent: 42, color: sectionColors[0] },
        { name: 'Physics & Science Core', questionCount: 20, marks: 20, weightPercent: 33, color: sectionColors[1] },
        { name: 'English Proficiency', questionCount: 15, marks: 15, weightPercent: 25, color: sectionColors[2] },
      ],
      patternNotes: [
        '60-minute departmental sprint with zero negative marking; maintain 1-minute-per-question pacing.',
        'Strong emphasis on direct NCTB formula application.',
      ],
    };
  }

  const countPerSec = Math.round(80 / disc.examSections.length);
  return {
    universityCode: uni.code,
    universityName: uni.fullName,
    programName: disc.name,
    category: disc.category,
    totalQuestions: countPerSec * disc.examSections.length,
    durationMinutes: 75,
    negativeMarking: 0.0,
    cutOffPercent: 65,
    sections: disc.examSections.map((sec, idx) => ({
      name: sec,
      questionCount: countPerSec,
      marks: countPerSec,
      weightPercent: Math.round(100 / disc.examSections.length),
      color: sectionColors[idx % sectionColors.length],
    })),
    patternNotes: [
      `Tailored to ${uni.code} ${disc.name} admission blueprint.`,
      'Zero negative marking policy — read carefully before permanently locking each option.',
    ],
  };
}

export const BANGLADESH_DIVISIONS: DivisionItem[] = [
  { id: 'dhaka', nameEn: 'Dhaka', nameBn: 'ঢাকা' },
  { id: 'chattogram', nameEn: 'Chattogram', nameBn: 'চট্টগ্রাম' },
  { id: 'rajshahi', nameEn: 'Rajshahi', nameBn: 'রাজশাহী' },
  { id: 'khulna', nameEn: 'Khulna', nameBn: 'খুলনা' },
  { id: 'sylhet', nameEn: 'Sylhet', nameBn: 'সিলেট' },
  { id: 'barishal', nameEn: 'Barishal', nameBn: 'বরিশাল' },
  { id: 'rangpur', nameEn: 'Rangpur', nameBn: 'রংপুর' },
  { id: 'mymensingh', nameEn: 'Mymensingh', nameBn: 'ময়মনসিংহ' },
];

export const BANGLADESH_DISTRICTS: DistrictItem[] = [
  { id: 'dhaka_dist', divisionId: 'dhaka', nameEn: 'Dhaka', nameBn: 'ঢাকা' },
  { id: 'gazipur', divisionId: 'dhaka', nameEn: 'Gazipur', nameBn: 'গাজীপুর' },
  { id: 'narayanganj', divisionId: 'dhaka', nameEn: 'Narayanganj', nameBn: 'নারায়ণগঞ্জ' },
  { id: 'tangail', divisionId: 'dhaka', nameEn: 'Tangail', nameBn: 'টাঙ্গাইল' },
  { id: 'ctg_dist', divisionId: 'chattogram', nameEn: 'Chattogram', nameBn: 'চট্টগ্রাম' },
  { id: 'cumilla', divisionId: 'chattogram', nameEn: 'Cumilla', nameBn: 'কুমিল্লা' },
  { id: 'coxsbazar', divisionId: 'chattogram', nameEn: "Cox's Bazar", nameBn: 'কক্সবাজার' },
  { id: 'raj_dist', divisionId: 'rajshahi', nameEn: 'Rajshahi', nameBn: 'রাজশাহী' },
  { id: 'bogura', divisionId: 'rajshahi', nameEn: 'Bogura', nameBn: 'বগুড়া' },
  { id: 'khulna_dist', divisionId: 'khulna', nameEn: 'Khulna', nameBn: 'খুলনা' },
  { id: 'jashore', divisionId: 'khulna', nameEn: 'Jashore', nameBn: 'যশোর' },
  { id: 'sylhet_dist', divisionId: 'sylhet', nameEn: 'Sylhet', nameBn: 'সিলেট' },
  { id: 'moulvibazar', divisionId: 'sylhet', nameEn: 'Moulvibazar', nameBn: 'মৌলভীবাজার' },
  { id: 'barishal_dist', divisionId: 'barishal', nameEn: 'Barishal', nameBn: 'বরিশাল' },
  { id: 'rangpur_dist', divisionId: 'rangpur', nameEn: 'Rangpur', nameBn: 'রংপুর' },
  { id: 'mymensingh_dist', divisionId: 'mymensingh', nameEn: 'Mymensingh', nameBn: 'ময়মনসিংহ' },
];

export const NCTB_COLLEGES: InstitutionItem[] = [
  { id: 'col_ndc', eiin: '108274', nameEn: 'Notre Dame College, Dhaka', area: 'Motijheel', district: 'Dhaka', isCollege: true, isSchool: false },
  { id: 'col_dr', eiin: '108206', nameEn: 'Dhaka Residential Model College', area: 'Mohammadpur', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'col_vnsc', eiin: '108357', nameEn: 'Viqarunnisa Noon School & College', area: 'Bailey Road', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'col_hc', eiin: '108533', nameEn: 'Holy Cross College, Dhaka', area: 'Tejgaon', district: 'Dhaka', isCollege: true, isSchool: false },
  { id: 'col_dc', eiin: '107977', nameEn: 'Dhaka College', area: 'New Market', district: 'Dhaka', isCollege: true, isSchool: false },
  { id: 'col_dcc', eiin: '107975', nameEn: 'Dhaka City College', area: 'Dhanmondi', district: 'Dhaka', isCollege: true, isSchool: false },
  { id: 'col_rukc', eiin: '107855', nameEn: 'Rajuk Uttara Model College', area: 'Uttara', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'col_acc', eiin: '107841', nameEn: 'Adamjee Cantonment College', area: 'Dhaka Cantonment', district: 'Dhaka', isCollege: true, isSchool: false },
  { id: 'col_sjs', eiin: '108214', nameEn: 'St. Joseph Higher Secondary School', area: 'Mohammadpur', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'col_ctg', eiin: '104523', nameEn: 'Chattogram College', area: 'Chawkbazar', district: 'Chattogram', isCollege: true, isSchool: false },
  { id: 'col_mc', eiin: '130410', nameEn: 'MC College, Sylhet', area: 'Tilagor', district: 'Sylhet', isCollege: true, isSchool: false },
  { id: 'col_raj', eiin: '126495', nameEn: 'Rajshahi College', area: 'Boalia', district: 'Rajshahi', isCollege: true, isSchool: false },
];

export const NCTB_SCHOOLS: InstitutionItem[] = [
  { id: 'sch_sgs', eiin: '108062', nameEn: 'St. Gregory High School & College', area: 'Luxmibazar', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'sch_glab', eiin: '108210', nameEn: 'Government Laboratory High School', area: 'Dhanmondi', district: 'Dhaka', isCollege: false, isSchool: true },
  { id: 'sch_isc', eiin: '108252', nameEn: 'Ideal School & College, Motijheel', area: 'Motijheel', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'sch_mgb', eiin: '108253', nameEn: 'Motijheel Government Boys High School', area: 'Motijheel', district: 'Dhaka', isCollege: false, isSchool: true },
  { id: 'sch_vnsc', eiin: '108357', nameEn: 'Viqarunnisa Noon School & College', area: 'Bailey Road', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'sch_dr', eiin: '108206', nameEn: 'Dhaka Residential Model College', area: 'Mohammadpur', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'sch_rukc', eiin: '107855', nameEn: 'Rajuk Uttara Model College', area: 'Uttara', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'sch_cc', eiin: '104300', nameEn: 'Chattogram Collegiate School', area: 'Ice Factory Rd', district: 'Chattogram', isCollege: false, isSchool: true },
];

export const ENGLISH_MEDIUM_INSTS: InstitutionItem[] = [
  { id: 'em_scholastica', eiin: 'CAIE-BD-01', nameEn: 'Scholastica', board: 'Cambridge International', area: 'Uttara / Mirpur / Dhanmondi', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_sunbeams', eiin: 'CAIE-BD-02', nameEn: 'Sunbeams School', board: 'Cambridge International', area: 'Uttara / Dhanmondi', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_mastermind', eiin: 'EDX-BD-01', nameEn: 'Mastermind English Medium School', board: 'Pearson Edexcel', area: 'Dhanmondi / Uttara', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_mapleleaf', eiin: 'EDX-BD-02', nameEn: 'Maple Leaf International School', board: 'Pearson Edexcel', area: 'Dhanmondi', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_sunnydale', eiin: 'CAIE-BD-03', nameEn: 'Sunnydale School', board: 'Cambridge International', area: 'Bashundhara / Dhanmondi', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_bisco', eiin: 'CAIE-BD-04', nameEn: 'Bangladesh International School & College', board: 'Cambridge International', area: 'Mohakhali DOHS', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_playpen', eiin: 'CAIE-BD-05', nameEn: 'Playpen School', board: 'Cambridge International', area: 'Bashundhara R/A', district: 'Dhaka', isCollege: true, isSchool: true },
  { id: 'em_cgs', eiin: 'CAIE-BD-06', nameEn: 'Chittagong Grammar School (CGS)', board: 'Cambridge International', area: 'Nasirabad', district: 'Chattogram', isCollege: true, isSchool: true },
];

export const COMMUNITY_LINKS: CommunityLink[] = [
  {
    id: 'default-fb',
    platform: 'facebook',
    title: 'Facebook Community Group',
    description:
      'Join 40,000+ admission aspirants for live discussions, study groups, and peer problem solving.',
    url: 'https://facebook.com/groups/prep404',
  },
  {
    id: 'default-ig',
    platform: 'instagram',
    title: 'Instagram',
    description:
      'Daily exam tips, campus life updates, formula reels, and motivational stories.',
    url: 'https://instagram.com/prep404',
  },
  {
    id: 'default-in',
    platform: 'linkedin',
    title: 'LinkedIn Official',
    description:
      'Follow EdTech insights, university admission trends, career roadmaps, and announcements.',
    url: 'https://linkedin.com/company/prep404',
  },
  {
    id: 'default-tw',
    platform: 'twitter',
    title: 'X (formerly Twitter)',
    description:
      'Breaking admission circulars, exam schedule updates, and live announcements.',
    url: 'https://x.com/prep404',
  },
  {
    id: 'default-yt',
    platform: 'youtube',
    title: 'YouTube Channel',
    description:
      'Video explanations, past year question breakdowns, KaTeX math walkthroughs, and mock test tips.',
    url: 'https://youtube.com/@prep404',
  },
];

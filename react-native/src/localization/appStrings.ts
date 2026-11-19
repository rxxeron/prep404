import { AppLanguage } from '../types';

export interface AppStrings {
  language: AppLanguage;
  isBangla: boolean;
  appTitle: string;
  appTagline: string;
  selectLanguageTitle: string;
  selectLanguageSubtitle: string;
  continueBtn: string;
  appLanguageLabel: string;
  languageEnglish: string;
  languageBangla: string;
  languageUpdated: string;

  // Auth
  signUpTab: string;
  signInTab: string;
  continueWithGoogle: string;
  continueWithFacebook: string;
  orMobile: string;
  fullNameLabel: string;
  fullNameHint: string;
  phoneLabel: string;
  phoneHint: string;
  sendOtpBtn: string;
  otpInputLabel: string;
  verifyOtpBtn: string;
  demoLoginBtn: string;
  invalidPhoneMsg: string;
  invalidOtpMsg: string;
  otpSentMsg: (phone: string) => string;

  // Onboarding
  onboardingTitle: string;
  step1Title: string;
  step2Title: string;
  step3Title: string;
  chooseMediumTitle: string;
  chooseMediumSubtitle: string;
  banglaMediumTitle: string;
  banglaMediumSubtitle: string;
  nctbVersionTitle: string;
  nctbVersionSubtitle: string;
  banglaVersionTitle: string;
  banglaVersionSubtitle: string;
  englishVersionTitle: string;
  englishVersionSubtitle: string;
  englishMediumTitle: string;
  englishMediumSubtitle: string;
  boardSelection: string;

  academicInfoTitle: string;
  academicInfoSubtitle: string;
  personalGeoTitle: string;
  candidateNameLabel: string;
  candidateNameHint: string;
  confirmMobileLabel: string;
  confirmMobileHint: string;
  divisionLabel: string;
  districtLabel: string;
  selectDivisionHint: string;
  selectDistrictHint: string;
  genderLabel: string;
  maleGender: string;
  femaleGender: string;
  otherGender: string;

  sscTitle: string;
  sscGroupLabel: string;
  sscYearLabel: string;
  sscGpaLabel: string;
  sscSchoolLabel: string;
  selectSchoolHint: string;
  searchSchoolHint: string;

  oLevelTitle: string;
  oLevelBoardLabel: string;
  oLevelYearLabel: string;
  oLevelGradesLabel: string;
  oLevelSchoolLabel: string;
  selectEnglishSchoolHint: string;
  searchEnglishSchoolHint: string;

  hscTitle: string;
  hscGroupLabel: string;
  hscBatchLabel: string;
  hscGpaLabel: string;
  hscCollegeLabel: string;
  aLevelBatchLabel: string;
  selectCollegeHint: string;
  searchCollegeHint: string;
  hscStatusAppearing: string;

  aLevelTitle: string;
  aLevelBoardLabel: string;
  aLevelStatusLabel: string;
  aLevelGradesLabel: string;
  aLevelCollegeLabel: string;
  selectEnglishCollegeHint: string;
  searchEnglishCollegeHint: string;

  targetUniTitle: string;
  targetUniSubtitle: string;
  estimatedExamLabel: string;
  targetedDisciplinesLabel: string;
  undergraduateProgramsLabel: string;
  prevBtn: string;
  nextBtn: string;
  startPrepBtn: string;
  missingTargetUniMsg: string;
  editAdmissionProfile: string;
  saveChanges: string;
  back: string;
  signOut: string;
  cancel: string;

  // Nav & Dashboard
  admissionCountdownTitle: string;
  targetSummary: string;
  programsCount: string;
  daysLeft: string;
  yourUniversities: string;
  syllabusSections: string;
  launchModelTest: string;
  customModulesTitle: string;
  questionsCount: string;
  navHome: string;
  navPlan: string;
  navQuestionBank: string;
  navDailyTest: string;
  navHistory: string;
  navBattle: string;
  navMockTest: string;
  navAnalytics: string;
  profileAndAccount: string;

  // Profile & Support
  profileTitle: string;
  linkedAccounts: string;
  learningAnalytics: string;
  shareActivityAnalytics: string;
  analyticsOn: string;
  analyticsOff: string;
  analyticsConsentDescription: string;
  close: string;
  learnerSupport: string;
  supportHelpTitle: string;
  supportIntro: string;
  supportRequestType: string;
  supportSubject: string;
  supportSubjectHint: string;
  supportDetails: string;
  supportDetailsHint: string;
  supportSentSuccess: string;
  supportSending: string;
  supportSendRequest: string;
  supportYourRequests: string;
  supportEmpty: string;
  supportUpdate: string;
  supportLabel: (value: string) => string;
}

export function getAppStrings(language: AppLanguage): AppStrings {
  const bn = language === 'bangla';
  const t = (en: string, bangla: string) => (bn ? bangla : en);

  return {
    language,
    isBangla: bn,
    appTitle: 'Prep404',
    appTagline: 'Failure Not Found',
    selectLanguageTitle: t('Choose Your Preferred Language', 'আপনার পছন্দের ভাষা বেছে নিন'),
    selectLanguageSubtitle: t(
      'You can change the app language anytime in Settings.',
      'সেটিংস থেকে যেকোনো সময় অ্যাপের ভাষা পরিবর্তন করতে পারবেন।'
    ),
    continueBtn: t('Continue', 'চালিয়ে যান'),
    appLanguageLabel: t('App language', 'অ্যাপের ভাষা'),
    languageEnglish: t('English', 'ইংরেজি'),
    languageBangla: t('Bangla', 'বাংলা'),
    languageUpdated: t('Language updated', 'ভাষা পরিবর্তন হয়েছে'),

    signUpTab: t('Create Account', 'অ্যাকাউন্ট তৈরি করুন'),
    signInTab: t('Sign In', 'সাইন ইন'),
    continueWithGoogle: t('Continue with Google', 'Google দিয়ে চালিয়ে যান'),
    continueWithFacebook: t('Continue with Facebook', 'Facebook দিয়ে চালিয়ে যান'),
    orMobile: t('or with phone', 'অথবা ফোন নম্বর দিয়ে'),
    fullNameLabel: t('Full Name', 'পুরো নাম'),
    fullNameHint: t('e.g. Tanvir Ahmed', 'যেমন: তানভীর আহমেদ'),
    phoneLabel: t('Phone Number', 'ফোন নম্বর'),
    phoneHint: '017XXXXXXXX',
    sendOtpBtn: t('Send Verification OTP', 'যাচাইকরণ OTP পাঠান'),
    otpInputLabel: t('Enter 4-Digit OTP', '৪ সংখ্যার OTP লিখুন'),
    verifyOtpBtn: t('Verify & Enter', 'যাচাই করে প্রবেশ করুন'),
    demoLoginBtn: t('Explore as Guest (Preview)', 'অতিথি হিসেবে দেখুন (পূর্বরূপ)'),
    invalidPhoneMsg: t(
      'Please enter a valid 11-digit mobile number (e.g. 017XXXXXXXX)',
      'সঠিক ১১ সংখ্যার মোবাইল নম্বর লিখুন (যেমন: 017XXXXXXXX)'
    ),
    invalidOtpMsg: t(
      'Invalid code! Please enter the correct 4-digit OTP (use 1234 in preview).',
      'কোডটি সঠিক নয়। সঠিক ৪ সংখ্যার OTP লিখুন (প্রিভিউতে 1234 ব্যবহার করুন)।'
    ),
    otpSentMsg: (phone: string) =>
      t(`Verification OTP sent to ${phone}`, `${phone} নম্বরে যাচাইকরণ OTP পাঠানো হয়েছে`),

    onboardingTitle: t(
      'Private University Admission Setup',
      'বেসরকারি বিশ্ববিদ্যালয়ে ভর্তির প্রস্তুতি'
    ),
    step1Title: t('1. Medium', '১. মাধ্যম'),
    step2Title: t('2. Education History', '২. শিক্ষাগত তথ্য'),
    step3Title: t('3. Targets', '৩. পছন্দের বিষয়'),
    chooseMediumTitle: t('Select Your Academic Medium', 'আপনার শিক্ষার মাধ্যম বেছে নিন'),
    chooseMediumSubtitle: t(
      'Questions and curricula will be customized based on your medium.',
      'আপনার শিক্ষার মাধ্যম অনুযায়ী প্রশ্ন ও পাঠ্যক্রম সাজানো হবে।'
    ),
    banglaMediumTitle: t('Bangla Medium (NCTB)', 'বাংলা মাধ্যম (এনসিটিবি)'),
    banglaMediumSubtitle: t(
      'National Curriculum & Textbook Board (HSC)',
      'জাতীয় শিক্ষাক্রম ও পাঠ্যপুস্তক বোর্ড (এইচএসসি)'
    ),
    nctbVersionTitle: t('Select NCTB Version', 'এনসিটিবি সংস্করণ বেছে নিন'),
    nctbVersionSubtitle: t(
      'Questions will match your textbook curriculum language',
      'প্রশ্নের ভাষা আপনার পাঠ্যবইয়ের সঙ্গে মিলবে'
    ),
    banglaVersionTitle: t('Bangla Version', 'বাংলা সংস্করণ'),
    banglaVersionSubtitle: t(
      'National curriculum & tests in Bengali',
      'বাংলা ভাষায় জাতীয় শিক্ষাক্রম ও পরীক্ষা'
    ),
    englishVersionTitle: t('English Version', 'ইংরেজি সংস্করণ'),
    englishVersionSubtitle: t(
      'NCTB curriculum with English textbooks',
      'ইংরেজি পাঠ্যবইসহ এনসিটিবি শিক্ষাক্রম'
    ),
    englishMediumTitle: t('English Medium', 'ইংরেজি মাধ্যম'),
    englishMediumSubtitle: t(
      'International GCE (O / A Level)',
      'আন্তর্জাতিক GCE (O / A Level)'
    ),
    boardSelection: t('Select Examination Board', 'পরীক্ষা বোর্ড বেছে নিন'),

    academicInfoTitle: t('Enter Your Education History', 'আপনার শিক্ষাগত তথ্য দিন'),
    academicInfoSubtitle: t(
      'Enter your SSC and HSC credentials for admission eligibility and ranking calibration.',
      'ভর্তির যোগ্যতা ও র‍্যাঙ্কিং নির্ধারণে SSC ও HSC-এর তথ্য দিন।'
    ),
    personalGeoTitle: t('Personal & Geographic Info', 'ব্যক্তিগত ও ঠিকানার তথ্য'),
    candidateNameLabel: t("Candidate's Full Name *", 'শিক্ষার্থীর পুরো নাম *'),
    candidateNameHint: t('e.g. Tanvir Ahmed', 'যেমন: তানভীর আহমেদ'),
    confirmMobileLabel: t('Confirm Mobile Number *', 'মোবাইল নম্বর নিশ্চিত করুন *'),
    confirmMobileHint: '01XXXXXXXXX',
    divisionLabel: t('Division *', 'বিভাগ *'),
    districtLabel: t('District *', 'জেলা *'),
    selectDivisionHint: t('Select Division', 'বিভাগ বেছে নিন'),
    selectDistrictHint: t('Select District', 'জেলা বেছে নিন'),
    genderLabel: t('Gender *', 'লিঙ্গ *'),
    maleGender: t('Male', 'পুরুষ'),
    femaleGender: t('Female', 'নারী'),
    otherGender: t('Other', 'অন্যান্য'),

    sscTitle: t('SSC / Dakhil History (Optional)', 'SSC / দাখিলের তথ্য (ঐচ্ছিক)'),
    sscGroupLabel: t('SSC Group', 'SSC বিভাগ'),
    sscYearLabel: t('Passing Year', 'পাসের বছর'),
    sscGpaLabel: t('SSC Result (GPA)', 'SSC ফলাফল (GPA)'),
    sscSchoolLabel: t('School / Madrasah', 'স্কুল / মাদ্রাসা'),
    selectSchoolHint: t(
      'Click to select school or madrasah...',
      'স্কুল বা মাদ্রাসা বেছে নিতে ক্লিক করুন...'
    ),
    searchSchoolHint: t('Search school, madrasah or EIIN...', 'স্কুল, মাদ্রাসা বা EIIN খুঁজুন...'),

    oLevelTitle: t('O-Level / IGCSE Credentials (Optional)', 'O-Level / IGCSE-এর তথ্য (ঐচ্ছিক)'),
    oLevelBoardLabel: t('Examination Board', 'পরীক্ষা বোর্ড'),
    oLevelYearLabel: t('O-Level Exam Year', 'O-Level পরীক্ষার বছর'),
    oLevelGradesLabel: t('O-Level Results / Grades', 'O-Level ফলাফল / গ্রেড'),
    oLevelSchoolLabel: t('English Medium School', 'ইংরেজি মাধ্যমের স্কুল'),
    selectEnglishSchoolHint: t(
      'Click to select English Medium school...',
      'ইংরেজি মাধ্যমের স্কুল বেছে নিতে ক্লিক করুন...'
    ),
    searchEnglishSchoolHint: t(
      'Search school by name, area or board...',
      'নাম, এলাকা বা বোর্ড দিয়ে স্কুল খুঁজুন...'
    ),

    hscTitle: t('HSC / Alim History (Optional)', 'HSC / আলিমের তথ্য (ঐচ্ছিক)'),
    hscGroupLabel: t('HSC Group', 'HSC বিভাগ'),
    hscBatchLabel: t('HSC Batch', 'HSC ব্যাচ'),
    hscGpaLabel: t('HSC Result / Status', 'HSC ফলাফল / অবস্থা'),
    hscCollegeLabel: t('College / Madrasah', 'কলেজ / মাদ্রাসা'),
    aLevelBatchLabel: t('A-Level Session', 'A-Level সেশন'),
    selectCollegeHint: t(
      'Click to select college or madrasah...',
      'কলেজ বা মাদ্রাসা বেছে নিতে ক্লিক করুন...'
    ),
    searchCollegeHint: t('Search college, madrasah or EIIN...', 'কলেজ, মাদ্রাসা বা EIIN খুঁজুন...'),
    hscStatusAppearing: t('Appearing (Result Awaited)', 'পরীক্ষার্থী (ফলাফলের অপেক্ষায়)'),

    aLevelTitle: t('A-Level / IAL History (Optional)', 'A-Level / IAL-এর তথ্য (ঐচ্ছিক)'),
    aLevelBoardLabel: t('Examination Board', 'পরীক্ষা বোর্ড'),
    aLevelStatusLabel: t('Candidate Status', 'শিক্ষার্থীর অবস্থা'),
    aLevelGradesLabel: t('A-Level Results / Predicted Grades', 'A-Level ফলাফল / সম্ভাব্য গ্রেড'),
    aLevelCollegeLabel: t('English Medium College / School', 'ইংরেজি মাধ্যমের কলেজ / স্কুল'),
    selectEnglishCollegeHint: t(
      'Click to select college or school...',
      'কলেজ বা স্কুল বেছে নিতে ক্লিক করুন...'
    ),
    searchEnglishCollegeHint: t(
      'Search college by name, area or board...',
      'নাম, এলাকা বা বোর্ড দিয়ে কলেজ খুঁজুন...'
    ),

    targetUniTitle: t('Targeted Universities & Majors', 'পছন্দের বিশ্ববিদ্যালয় ও বিষয়'),
    targetUniSubtitle: t(
      'Review upcoming admission test schedules, slots and select your target programs.',
      'আসন্ন ভর্তি পরীক্ষার সময়সূচি দেখুন এবং পছন্দের প্রোগ্রাম বেছে নিন।'
    ),
    estimatedExamLabel: t('Estimated Exam', 'সম্ভাব্য পরীক্ষা'),
    targetedDisciplinesLabel: t(
      'Targeted Disciplines (Multiple allowed):',
      'পছন্দের বিষয় (একাধিক বেছে নিতে পারবেন):'
    ),
    undergraduateProgramsLabel: t(
      'Official Undergraduate Programs (Select Target Majors):',
      'অফিশিয়াল স্নাতক প্রোগ্রাম (পছন্দের বিষয় বেছে নিন):'
    ),
    prevBtn: t('Previous', 'আগের ধাপ'),
    nextBtn: t('Next Step', 'পরের ধাপ'),
    startPrepBtn: t('Start Preparation', 'প্রস্তুতি শুরু করুন'),
    missingTargetUniMsg: t(
      'Please select at least one university and major.',
      'অন্তত একটি বিশ্ববিদ্যালয় ও বিষয় বেছে নিন।'
    ),
    editAdmissionProfile: t('Edit Admission Profile', 'ভর্তি-সংক্রান্ত তথ্য সম্পাদনা'),
    saveChanges: t('Save Changes', 'পরিবর্তন সংরক্ষণ করুন'),
    back: t('Back', 'ফিরে যান'),
    signOut: t('Sign Out', 'সাইন আউট'),
    cancel: t('Cancel', 'বাতিল'),

    admissionCountdownTitle: t(
      'Private University Admissions 2026',
      'বেসরকারি বিশ্ববিদ্যালয়ে ভর্তি ২০২৬'
    ),
    targetSummary: t('Target', 'লক্ষ্য'),
    programsCount: t('Programs', 'প্রোগ্রাম'),
    daysLeft: t('Days Left', 'দিন বাকি'),
    yourUniversities: t('Your Selected Universities', 'আপনার নির্বাচিত বিশ্ববিদ্যালয়'),
    syllabusSections: t('Syllabus', 'সিলেবাস'),
    launchModelTest: t('Launch Model Test', 'মডেল টেস্ট শুরু করুন'),
    customModulesTitle: t('Curriculum Modules for Your Majors', 'আপনার বিষয়ের পাঠ্যক্রম'),
    questionsCount: t('Questions', 'প্রশ্ন'),
    navHome: t('Home', 'হোম'),
    navPlan: t('Plan', 'পরিকল্পনা'),
    navQuestionBank: t('Question Bank', 'প্রশ্নব্যাংক'),
    navDailyTest: t('Daily Test', 'দৈনিক পরীক্ষা'),
    navHistory: t('History', 'ইতিহাস'),
    navBattle: t('Live Battle', 'লাইভ প্রতিযোগিতা'),
    navMockTest: t('Mock Tests', 'মডেল পরীক্ষা'),
    navAnalytics: t('Analytics', 'বিশ্লেষণ'),
    profileAndAccount: t('Profile & Account', 'প্রোফাইল ও অ্যাকাউন্ট'),

    profileTitle: t('Profile & Settings', 'প্রোফাইল ও সেটিংস'),
    linkedAccounts: t('Linked Accounts', 'সংযুক্ত অ্যাকাউন্ট'),
    learningAnalytics: t('Learning analytics', 'শেখার বিশ্লেষণ'),
    shareActivityAnalytics: t('Share activity analytics', 'ব্যবহারের তথ্য শেয়ার করুন'),
    analyticsOn: t(
      'On · you can change this anytime',
      'চালু · যেকোনো সময় পরিবর্তন করতে পারবেন'
    ),
    analyticsOff: t(
      'Off · no activity events are collected',
      'বন্ধ · ব্যবহারের কোনো তথ্য সংগ্রহ হবে না'
    ),
    analyticsConsentDescription: t(
      'Optional events cover app opens, first onboarding completion, practice attempts, and exam submissions. Events are retained for up to 12 months. Turning this off immediately deletes your previously collected events.',
      'ঐচ্ছিকভাবে অ্যাপ খোলা, প্রথমবার সেটআপ সম্পন্ন, অনুশীলন ও পরীক্ষায় জমা দেওয়ার তথ্য সংগ্রহ করা হয়। তথ্য সর্বোচ্চ ১২ মাস রাখা হয়। বন্ধ করলে আগের সংগৃহীত তথ্য সঙ্গে সঙ্গে মুছে যাবে।'
    ),
    close: t('Close', 'বন্ধ করুন'),
    learnerSupport: t('Learner support', 'শিক্ষার্থী সহায়তা'),
    supportHelpTitle: t('How can we help?', 'কীভাবে আপনাকে সহায়তা করতে পারি?'),
    supportIntro: t(
      'Send a private request to the Prep404 support team. Do not include passwords, phone numbers, or email addresses; we can use the contact details on your account.',
      'Prep404 সহায়তা দলকে ব্যক্তিগতভাবে সমস্যাটি জানান। পাসওয়ার্ড, ফোন নম্বর বা ইমেইল লিখবেন না; আপনার অ্যাকাউন্টের যোগাযোগের তথ্য আমরা ব্যবহার করতে পারি।'
    ),
    supportRequestType: t('Request type', 'অনুরোধের ধরন'),
    supportSubject: t('Subject', 'বিষয়'),
    supportSubjectHint: t('A short summary of the issue', 'সমস্যাটি সংক্ষেপে লিখুন'),
    supportDetails: t('Details', 'বিস্তারিত'),
    supportDetailsHint: t(
      'Tell us what happened and what you need help with.',
      'কী ঘটেছে এবং কী বিষয়ে সহায়তা দরকার তা লিখুন।'
    ),
    supportSentSuccess: t(
      'Your request was sent. You can follow its status below.',
      'আপনার অনুরোধ পাঠানো হয়েছে। নিচে এর অবস্থা দেখতে পারবেন।'
    ),
    supportSending: t('Sending…', 'পাঠানো হচ্ছে…'),
    supportSendRequest: t('Send request', 'অনুরোধ পাঠান'),
    supportYourRequests: t('Your requests', 'আপনার অনুরোধগুলো'),
    supportEmpty: t('No support requests yet.', 'এখনো কোনো সহায়তার অনুরোধ নেই।'),
    supportUpdate: t('Support update', 'সহায়তা দলের আপডেট'),
    supportLabel: (value: string) => {
      const map: Record<string, [string, string]> = {
        account_access: ['Account access', 'অ্যাকাউন্টে প্রবেশ'],
        profile_update: ['Profile update', 'প্রোফাইল হালনাগাদ'],
        learning_progress: ['Learning progress', 'পড়াশোনার অগ্রগতি'],
        exam_access: ['Exam access', 'পরীক্ষায় প্রবেশ'],
        other: ['Other', 'অন্যান্য'],
        open: ['Open', 'খোলা'],
        in_progress: ['In Progress', 'চলমান'],
        resolved: ['Resolved', 'সমাধান হয়েছে'],
        closed: ['Closed', 'বন্ধ'],
      };
      if (map[value]) return bn ? map[value][1] : map[value][0];
      return value
        .split('_')
        .map((p) => (p ? p[0].toUpperCase() + p.slice(1) : p))
        .join(' ');
    },
  };
}

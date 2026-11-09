import 'package:flutter/material.dart';

enum AppLanguage { english, bangla }

class AppStrings {
  final AppLanguage language;

  const AppStrings([this.language = AppLanguage.english]);

  factory AppStrings.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AppStrings(code == 'bn' ? AppLanguage.bangla : AppLanguage.english);
  }

  Locale get locale => Locale(language == AppLanguage.bangla ? 'bn' : 'en');

  bool get isBangla => language == AppLanguage.bangla;

  String _text(String english, String bangla) => isBangla ? bangla : english;

  // Language picker and app preferences.
  String get selectLanguageTitle =>
      _text('Choose Your Preferred Language', 'আপনার পছন্দের ভাষা বেছে নিন');
  String get selectLanguageSubtitle => _text(
        'You can change the app language anytime in Settings.',
        'সেটিংস থেকে যেকোনো সময় অ্যাপের ভাষা পরিবর্তন করতে পারবেন।',
      );
  String get continueBtn => _text('Continue', 'চালিয়ে যান');
  String get appLanguageLabel => _text('App language', 'অ্যাপের ভাষা');
  String get languageEnglish => _text('English', 'ইংরেজি');
  String get languageBangla => _text('Bangla', 'বাংলা');
  String get languageUpdated =>
      _text('Language updated', 'ভাষা পরিবর্তন হয়েছে');

  // Auth screen.
  String get appTitle => 'Prep404';
  String get appTagline => _text(
        'Failure Not Found',
        'Failure Not Found',
      );
  String get signUpTab => _text('Create Account', 'অ্যাকাউন্ট তৈরি করুন');
  String get signInTab => _text('Sign In', 'সাইন ইন');
  String get continueWithGoogle =>
      _text('Continue with Google', 'Google দিয়ে চালিয়ে যান');
  String get continueWithFacebook =>
      _text('Continue with Facebook', 'Facebook দিয়ে চালিয়ে যান');
  String get orMobile => _text('or with phone', 'অথবা ফোন নম্বর দিয়ে');
  String get fullNameLabel => _text('Full Name', 'পুরো নাম');
  String get fullNameHint => _text('e.g. Tanvir Ahmed', 'যেমন: তানভীর আহমেদ');
  String get phoneLabel => _text('Phone Number', 'ফোন নম্বর');
  String get phoneHint => '017XXXXXXXX';
  String get sendOtpBtn => _text('Send Verification OTP', 'যাচাইকরণ OTP পাঠান');
  String get otpInputLabel => _text('Enter 4-Digit OTP', '৪ সংখ্যার OTP লিখুন');
  String get verifyOtpBtn => _text('Verify & Enter', 'যাচাই করে প্রবেশ করুন');
  String get demoLoginBtn =>
      _text('Explore as Guest (Preview)', 'অতিথি হিসেবে দেখুন (পূর্বরূপ)');
  String get invalidPhoneMsg => _text(
        'Please enter a valid 11-digit mobile number (e.g. 017XXXXXXXX)',
        'সঠিক ১১ সংখ্যার মোবাইল নম্বর লিখুন (যেমন: 017XXXXXXXX)',
      );
  String get invalidPhoneError => invalidPhoneMsg;
  String get invalidOtpMsg => _text(
        'Invalid code! Please enter the correct OTP.',
        'কোডটি সঠিক নয়। সঠিক OTP লিখুন।',
      );
  String get invalidOtpError => invalidOtpMsg;
  String get otpSentSuccess =>
      _text('OTP sent successfully.', 'OTP পাঠানো হয়েছে।');
  String otpSentMsg(String phone) => _text('Verification OTP sent to $phone',
      '$phone নম্বরে যাচাইকরণ OTP পাঠানো হয়েছে');
  String get signInError => _text(
        'Sign-in could not be completed. Check your connection and try again.',
        'সাইন ইন করা যায়নি। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।',
      );

  // Onboarding.
  String get onboardingTitle => _text('Private University Admission Setup',
      'বেসরকারি বিশ্ববিদ্যালয়ে ভর্তির প্রস্তুতি');
  String get step1Title => _text('1. Medium', '১. মাধ্যম');
  String get step2Title => _text('2. Education History', '২. শিক্ষাগত তথ্য');
  String get step3Title => _text('3. Targets', '৩. পছন্দের বিষয়');
  String get chooseMediumTitle =>
      _text('Select Your Academic Medium', 'আপনার শিক্ষার মাধ্যম বেছে নিন');
  String get chooseMediumSubtitle => _text(
        'Questions and curricula will be customized based on your medium.',
        'আপনার শিক্ষার মাধ্যম অনুযায়ী প্রশ্ন ও পাঠ্যক্রম সাজানো হবে।',
      );
  String get banglaMediumTitle =>
      _text('Bangla Medium (NCTB)', 'বাংলা মাধ্যম (এনসিটিবি)');
  String get banglaMediumSubtitle => _text(
        'National Curriculum & Textbook Board (HSC)',
        'জাতীয় শিক্ষাক্রম ও পাঠ্যপুস্তক বোর্ড (এইচএসসি)',
      );
  String get nctbVersionTitle =>
      _text('Select NCTB Version', 'এনসিটিবি সংস্করণ বেছে নিন');
  String get nctbVersionSubtitle => _text(
        'Questions will match your textbook curriculum language',
        'প্রশ্নের ভাষা আপনার পাঠ্যবইয়ের সঙ্গে মিলবে',
      );
  String get banglaVersionTitle => _text('Bangla Version', 'বাংলা সংস্করণ');
  String get banglaVersionSubtitle => _text(
      'National curriculum & tests in Bengali',
      'বাংলা ভাষায় জাতীয় শিক্ষাক্রম ও পরীক্ষা');
  String get englishVersionTitle => _text('English Version', 'ইংরেজি সংস্করণ');
  String get englishVersionSubtitle => _text(
      'NCTB curriculum with English textbooks',
      'ইংরেজি পাঠ্যবইসহ এনসিটিবি শিক্ষাক্রম');
  String get englishMediumTitle => _text('English Medium', 'ইংরেজি মাধ্যম');
  String get englishMediumSubtitle =>
      _text('International GCE (O / A Level)', 'আন্তর্জাতিক GCE (O / A Level)');
  String get boardSelection =>
      _text('Select Examination Board', 'পরীক্ষা বোর্ড বেছে নিন');

  String get academicInfoTitle =>
      _text('Enter Your Education History', 'আপনার শিক্ষাগত তথ্য দিন');
  String get academicInfoSubtitle => _text(
        'Enter your SSC and HSC credentials for admission eligibility and ranking calibration.',
        'ভর্তির যোগ্যতা ও র‍্যাঙ্কিং নির্ধারণে SSC ও HSC-এর তথ্য দিন।',
      );
  String get personalGeoTitle =>
      _text('Personal & Geographic Info', 'ব্যক্তিগত ও ঠিকানার তথ্য');
  String get candidateNameLabel =>
      _text("Candidate's Full Name *", 'শিক্ষার্থীর পুরো নাম *');
  String get candidateNameHint =>
      _text('e.g. Tanvir Ahmed', 'যেমন: তানভীর আহমেদ');
  String get confirmMobileLabel =>
      _text('Confirm Mobile Number *', 'মোবাইল নম্বর নিশ্চিত করুন *');
  String get confirmMobileHint => '01XXXXXXXXX';
  String get divisionLabel => _text('Division *', 'বিভাগ *');
  String get districtLabel => _text('District *', 'জেলা *');
  String get selectDivisionHint => _text('Select Division', 'বিভাগ বেছে নিন');
  String get selectDistrictHint => _text('Select District', 'জেলা বেছে নিন');
  String get genderLabel => _text('Gender *', 'লিঙ্গ *');
  String get maleGender => _text('Male', 'পুরুষ');
  String get femaleGender => _text('Female', 'নারী');
  String get otherGender => _text('Other', 'অন্যান্য');

  String get sscTitle =>
      _text('SSC / Dakhil History (Optional)', 'SSC / দাখিলের তথ্য (ঐচ্ছিক)');
  String get sscGroupLabel => _text('SSC Group', 'SSC বিভাগ');
  String get sscYearLabel => _text('Passing Year', 'পাসের বছর');
  String get sscGpaLabel => _text('SSC Result (GPA)', 'SSC ফলাফল (GPA)');
  String get sscSchoolLabel => _text('School / Madrasah', 'স্কুল / মাদ্রাসা');
  String get selectSchoolHint => _text('Tap to select school or madrasah...',
      'স্কুল বা মাদ্রাসা বেছে নিতে ট্যাপ করুন...');
  String get searchSchoolHint => _text('Search school, madrasah or EIIN...',
      'স্কুল, মাদ্রাসা বা EIIN খুঁজুন...');

  String get oLevelTitle => _text('O-Level / IGCSE Credentials (Optional)',
      'O-Level / IGCSE-এর তথ্য (ঐচ্ছিক)');
  String get oLevelBoardLabel => _text('Examination Board', 'পরীক্ষা বোর্ড');
  String get oLevelYearLabel =>
      _text('O-Level Exam Year', 'O-Level পরীক্ষার বছর');
  String get oLevelSubjectsLabel =>
      _text('Number of Subjects', 'বিষয়ের সংখ্যা');
  String get oLevelGradesLabel =>
      _text('O-Level Results / Grades', 'O-Level ফলাফল / গ্রেড');
  String get oLevelSchoolLabel =>
      _text('English Medium School', 'ইংরেজি মাধ্যমের স্কুল');
  String get selectEnglishSchoolHint => _text(
      'Tap to select English Medium school...',
      'ইংরেজি মাধ্যমের স্কুল বেছে নিতে ট্যাপ করুন...');
  String get searchEnglishSchoolHint => _text(
      'Search school by name, area or board...',
      'নাম, এলাকা বা বোর্ড দিয়ে স্কুল খুঁজুন...');

  String get hscTitle =>
      _text('HSC / Alim History (Optional)', 'HSC / আলিমের তথ্য (ঐচ্ছিক)');
  String get hscGroupLabel => _text('HSC Group', 'HSC বিভাগ');
  String get hscBatchLabel => _text('HSC Batch', 'HSC ব্যাচ');
  String get hscGpaLabel => _text('HSC Result / Status', 'HSC ফলাফল / অবস্থা');
  String get hscCollegeLabel => _text('College / Madrasah', 'কলেজ / মাদ্রাসা');
  String get aLevelBatchLabel => _text('A-Level Session', 'A-Level সেশন');
  String get selectCollegeHint => _text('Tap to select college or madrasah...',
      'কলেজ বা মাদ্রাসা বেছে নিতে ট্যাপ করুন...');
  String get searchCollegeHint => _text('Search college, madrasah or EIIN...',
      'কলেজ, মাদ্রাসা বা EIIN খুঁজুন...');
  String get hscStatusAppearing =>
      _text('Appearing (Result Awaited)', 'পরীক্ষার্থী (ফলাফলের অপেক্ষায়)');

  String get aLevelTitle => _text(
      'A-Level / IAL History (Optional)', 'A-Level / IAL-এর তথ্য (ঐচ্ছিক)');
  String get aLevelBoardLabel => _text('Examination Board', 'পরীক্ষা বোর্ড');
  String get aLevelStatusLabel =>
      _text('Candidate Status', 'শিক্ষার্থীর অবস্থা');
  String get aLevelSubjectsLabel =>
      _text('A-Level Subjects Count', 'A-Level বিষয়ের সংখ্যা');
  String get aLevelGradesLabel => _text(
      'A-Level Results / Predicted Grades', 'A-Level ফলাফল / সম্ভাব্য গ্রেড');
  String get aLevelCollegeLabel =>
      _text('English Medium College / School', 'ইংরেজি মাধ্যমের কলেজ / স্কুল');
  String get selectEnglishCollegeHint => _text(
      'Tap to select college or school...',
      'কলেজ বা স্কুল বেছে নিতে ট্যাপ করুন...');
  String get searchEnglishCollegeHint => _text(
      'Search college by name, area or board...',
      'নাম, এলাকা বা বোর্ড দিয়ে কলেজ খুঁজুন...');

  String get curriculumAlignmentTitle => _text(
      'Curriculum & Question Alignment', 'শিক্ষাক্রম ও প্রশ্নের সামঞ্জস্য');
  String get curriculumAlignmentBanglaDesc => _text(
        'Questions and solutions structured for NSU, BRACU, AIUB, IUB and other private universities.',
        'NSU, BRACU, AIUB, IUB-সহ বিভিন্ন বেসরকারি বিশ্ববিদ্যালয়ের জন্য প্রশ্ন ও সমাধান সাজানো হয়েছে।',
      );
  String get curriculumAlignmentEnglishVersionDesc => _text(
        'University-standard English questions and terminology tailored for NCTB English Version students.',
        'এনসিটিবি ইংরেজি সংস্করণের শিক্ষার্থীদের জন্য বিশ্ববিদ্যালয়-মানের ইংরেজি প্রশ্ন ও পরিভাষা।',
      );
  String get curriculumAlignmentGceDesc => _text(
        'SAT-pattern and English Medium specific questions tailored for Cambridge & Edexcel students.',
        'Cambridge ও Edexcel শিক্ষার্থীদের জন্য SAT-ধাঁচের ও ইংরেজি মাধ্যমের উপযোগী প্রশ্ন।',
      );
  String get selectedMediumPrefix =>
      _text('Selected Medium:', 'নির্বাচিত মাধ্যম:');
  String get noInstitutionsFound =>
      _text('No institutions found', 'কোনো প্রতিষ্ঠান পাওয়া যায়নি');
  String get institutionLabelBangla => _text('College Name *', 'কলেজের নাম *');
  String get institutionLabelEnglish => _text('School Name *', 'স্কুলের নাম *');
  String get popularInstitutions =>
      _text('Popular Institutions:', 'জনপ্রিয় প্রতিষ্ঠান:');

  String get targetUniTitle =>
      _text('Targeted Universities & Majors', 'পছন্দের বিশ্ববিদ্যালয় ও বিষয়');
  String get targetUniSubtitle => _text(
        'Review upcoming admission test schedules, slots and select your target programs.',
        'আসন্ন ভর্তি পরীক্ষার সময়সূচি দেখুন এবং পছন্দের প্রোগ্রাম বেছে নিন।',
      );
  String get estimatedExamLabel => _text('Estimated Exam', 'সম্ভাব্য পরীক্ষা');
  String get targetedDisciplinesLabel => _text(
      'Targeted Disciplines (Multiple allowed):',
      'পছন্দের বিষয় (একাধিক বেছে নিতে পারবেন):');
  String get upcomingAdmissionLabel =>
      _text('Upcoming Admission', 'আসন্ন ভর্তি');
  String get applicationDeadlineLabel => _text('Deadline', 'আবেদনের শেষ সময়');
  String get examDateLabel => _text('Exam Date', 'পরীক্ষার তারিখ');
  String get examTimeLabel => _text('Time', 'সময়');
  String get applicationFeeLabel => _text('Fee', 'ফি');
  String get venueLabel => _text('Venue', 'পরীক্ষার স্থান');
  String get slotLabel => _text('Slot', 'স্লট');
  String get centralizedExamBadge =>
      _text('Centralized Exam', 'কেন্দ্রীয় পরীক্ষা');
  String get facultyWideExamBadge =>
      _text('Faculty-wide Exam', 'অনুষদভিত্তিক পরীক্ষা');
  String get departmentWiseExamBadge =>
      _text('Department-wise Exam', 'বিভাগভিত্তিক পরীক্ষা');
  String get undergraduateProgramsLabel => _text(
      'Official Undergraduate Programs (Select Target Majors):',
      'অফিশিয়াল স্নাতক প্রোগ্রাম (পছন্দের বিষয় বেছে নিন):');
  String get prevBtn => _text('Previous', 'আগের ধাপ');
  String get nextBtn => _text('Next Step', 'পরের ধাপ');
  String get startPrepBtn => _text('Start Preparation', 'প্রস্তুতি শুরু করুন');
  String get missingAcademicInfoMsg => _text(
      'Please enter your name and confirm your mobile number.',
      'আপনার নাম লিখে মোবাইল নম্বর নিশ্চিত করুন।');
  String get missingTargetUniMsg => _text(
      'Please select at least one university and major.',
      'অন্তত একটি বিশ্ববিদ্যালয় ও বিষয় বেছে নিন।');
  String get editAdmissionProfile =>
      _text('Edit Admission Profile', 'ভর্তি-সংক্রান্ত তথ্য সম্পাদনা');
  String get saveChanges => _text('Save Changes', 'পরিবর্তন সংরক্ষণ করুন');
  String get back => _text('Back', 'ফিরে যান');
  String get signOut => _text('Sign Out', 'সাইন আউট');
  String get signOutBackToLogin =>
      _text('Sign Out / Back to Login', 'সাইন আউট / লগইনে ফিরে যান');
  String get signOutPrompt => _text(
      'Do you want to return to the login screen?',
      'আপনি কি লগইন স্ক্রিনে ফিরে যেতে চান?');
  String get cancel => _text('Cancel', 'বাতিল');

  // Dashboard and navigation labels.
  String get admissionCountdownTitle => _text(
      'Private University Admissions 2026',
      'বেসরকারি বিশ্ববিদ্যালয়ে ভর্তি ২০২৬');
  String get targetSummary => _text('Target', 'লক্ষ্য');
  String get programsCount => _text('Programs', 'প্রোগ্রাম');
  String get daysLeft => _text('Days Left', 'দিন বাকি');
  String get yourUniversities =>
      _text('Your Selected Universities', 'আপনার নির্বাচিত বিশ্ববিদ্যালয়');
  String get syllabusSections => _text('Syllabus', 'সিলেবাস');
  String get launchModelTest =>
      _text('Launch Model Test', 'মডেল টেস্ট শুরু করুন');
  String get customModulesTitle =>
      _text('Curriculum Modules for Your Majors', 'আপনার বিষয়ের পাঠ্যক্রম');
  String get questionsCount => _text('Questions', 'প্রশ্ন');
  String get navHome => _text('Home', 'হোম');
  String get navPlan => _text('Plan', 'পরিকল্পনা');
  String get navQuestionBank => _text('Question Bank', 'প্রশ্নব্যাংক');
  String get navDailyTest => _text('Daily Test', 'দৈনিক পরীক্ষা');
  String get navHistory => _text('History', 'ইতিহাস');
  String get navPracticeMap => _text('Practice Map', 'অনুশীলন মানচিত্র');
  String get navBattle => _text('Live Battle', 'লাইভ প্রতিযোগিতা');
  String get navMockTest => _text('Mock Tests', 'মডেল পরীক্ষা');
  String get navAnalytics => _text('Analytics', 'বিশ্লেষণ');
  String get profileAndAccount =>
      _text('Profile & Account', 'প্রোফাইল ও অ্যাকাউন্ট');

  // Profile, learner support, and privacy settings.
  String get profileTitle => _text('Profile & Settings', 'প্রোফাইল ও সেটিংস');
  String get linkedAccounts => _text('Linked Accounts', 'সংযুক্ত অ্যাকাউন্ট');
  String get linkFacebookAccount =>
      _text('Link Facebook account', 'Facebook অ্যাকাউন্ট যুক্ত করুন');
  String get linkGoogleAccount =>
      _text('Link Google account', 'Google অ্যাকাউন্ট যুক্ত করুন');
  String get linkAppleAccount =>
      _text('Link Apple account', 'Apple অ্যাকাউন্ট যুক্ত করুন');
  String get learningAnalytics => _text('Learning analytics', 'শেখার বিশ্লেষণ');
  String get shareActivityAnalytics =>
      _text('Share activity analytics', 'ব্যবহারের তথ্য শেয়ার করুন');
  String get loadingPreference =>
      _text('Loading preference…', 'পছন্দের সেটিং লোড হচ্ছে…');
  String get preferenceUnavailable => _text(
      'Could not load your saved preference', 'সংরক্ষিত পছন্দ লোড করা যায়নি');
  String get analyticsOn => _text('On · you can change this anytime',
      'চালু · যেকোনো সময় পরিবর্তন করতে পারবেন');
  String get analyticsOff => _text('Off · no activity events are collected',
      'বন্ধ · ব্যবহারের কোনো তথ্য সংগ্রহ হবে না');
  String get analyticsConsentDescription => _text(
        'Optional events cover app opens, first onboarding completion, practice attempts, and exam submissions. Events are retained for up to 12 months. Turning this off immediately deletes your previously collected events.',
        'ঐচ্ছিকভাবে অ্যাপ খোলা, প্রথমবার সেটআপ সম্পন্ন, অনুশীলন ও পরীক্ষায় জমা দেওয়ার তথ্য সংগ্রহ করা হয়। তথ্য সর্বোচ্চ ১২ মাস রাখা হয়। বন্ধ করলে আগের সংগৃহীত তথ্য সঙ্গে সঙ্গে মুছে যাবে।',
      );
  String get close => _text('Close', 'বন্ধ করুন');
  String get learnerSupport => _text('Learner support', 'শিক্ষার্থী সহায়তা');
  String get languagePreferenceHelp => _text(
      'Choose the language used in Prep404.',
      'Prep404-এ ব্যবহারের ভাষা বেছে নিন।');

  // Learner support intake and request history.
  String get supportHelpTitle =>
      _text('How can we help?', 'কীভাবে আপনাকে সহায়তা করতে পারি?');
  String get supportIntro => _text(
        'Send a private request to the Prep404 support team. Do not include passwords, phone numbers, or email addresses; we can use the contact details on your account.',
        'Prep404 সহায়তা দলকে ব্যক্তিগতভাবে সমস্যাটি জানান। পাসওয়ার্ড, ফোন নম্বর বা ইমেইল লিখবেন না; আপনার অ্যাকাউন্টের যোগাযোগের তথ্য আমরা ব্যবহার করতে পারি।',
      );
  String get supportRequestType => _text('Request type', 'অনুরোধের ধরন');
  String get supportSubject => _text('Subject', 'বিষয়');
  String get supportSubjectHint =>
      _text('A short summary of the issue', 'সমস্যাটি সংক্ষেপে লিখুন');
  String get supportSubjectValidation =>
      _text('Enter at least 5 characters.', 'কমপক্ষে ৫টি অক্ষর লিখুন।');
  String get supportDetails => _text('Details', 'বিস্তারিত');
  String get supportDetailsHint => _text(
        'Tell us what happened and what you need help with.',
        'কী ঘটেছে এবং কী বিষয়ে সহায়তা দরকার তা লিখুন।',
      );
  String get supportDetailsValidation => _text(
        'Add a little more detail (at least 10 characters).',
        'আরও কিছু তথ্য লিখুন (কমপক্ষে ১০টি অক্ষর)।',
      );
  String get supportSentSuccess => _text(
        'Your request was sent. You can follow its status below.',
        'আপনার অনুরোধ পাঠানো হয়েছে। নিচে এর অবস্থা দেখতে পারবেন।',
      );
  String get supportSending => _text('Sending…', 'পাঠানো হচ্ছে…');
  String get supportSendRequest => _text('Send request', 'অনুরোধ পাঠান');
  String get supportYourRequests => _text('Your requests', 'আপনার অনুরোধগুলো');
  String get supportRefreshRequests =>
      _text('Refresh requests', 'অনুরোধের তালিকা রিফ্রেশ করুন');
  String get supportLoadError => _text(
        'Your requests could not be loaded. Check your connection and retry.',
        'আপনার অনুরোধগুলো লোড করা যায়নি। সংযোগ দেখে আবার চেষ্টা করুন।',
      );
  String get supportEmpty =>
      _text('No support requests yet.', 'এখনো কোনো সহায়তার অনুরোধ নেই।');
  String get supportUpdate => _text('Support update', 'সহায়তা দলের আপডেট');

  String supportLabel(String value) => switch (value) {
        'account_access' => _text('Account access', 'অ্যাকাউন্টে প্রবেশ'),
        'profile_update' => _text('Profile update', 'প্রোফাইল হালনাগাদ'),
        'learning_progress' => _text('Learning progress', 'পড়াশোনার অগ্রগতি'),
        'exam_access' => _text('Exam access', 'পরীক্ষায় প্রবেশ'),
        'other' => _text('Other', 'অন্যান্য'),
        'open' => _text('Open', 'খোলা'),
        'in_progress' => _text('In Progress', 'চলমান'),
        'resolved' => _text('Resolved', 'সমাধান হয়েছে'),
        'closed' => _text('Closed', 'বন্ধ'),
        _ => value
            .split('_')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
      };
}

/// Offline Database Schema & Contract for Prep404
/// Provides standard DDL definitions and contract methods for local SQLite persistence.
class OfflineDatabaseContracts {
  OfflineDatabaseContracts._();

  // Database metadata
  static const String databaseName = 'prep404_offline.db';
  static const int databaseVersion = 1;

  // Table names
  static const String tableOnboardingDrafts = 'offline_onboarding_drafts';
  static const String tableCachedExams = 'offline_cached_exams';
  static const String tablePendingSubmissions = 'offline_pending_submissions';
  static const String tableCachedQuestions = 'offline_cached_questions';
  static const String tableOfflineMistakes = 'offline_mistakes';

  // DDL: Onboarding Drafts Table
  static const String createOnboardingDraftsTable = '''
    CREATE TABLE IF NOT EXISTS $tableOnboardingDrafts (
      id TEXT PRIMARY KEY,
      user_id TEXT,
      current_step INTEGER NOT NULL DEFAULT 0,
      medium TEXT,
      nctb_version TEXT,
      curriculum TEXT,
      student_name TEXT,
      phone TEXT,
      gender TEXT,
      division_id TEXT,
      division_name TEXT,
      district_id TEXT,
      district_name TEXT,
      ssc_group TEXT,
      ssc_year TEXT,
      ssc_gpa TEXT,
      ssc_institution TEXT,
      ssc_eiin TEXT,
      hsc_group TEXT,
      hsc_batch TEXT,
      hsc_gpa TEXT,
      hsc_institution TEXT,
      hsc_eiin TEXT,
      o_level_board TEXT,
      o_level_year TEXT,
      o_level_grades TEXT,
      o_level_school TEXT,
      a_level_board TEXT,
      a_level_batch TEXT,
      a_level_status TEXT,
      a_level_grades TEXT,
      a_level_college TEXT,
      target_selections_json TEXT,
      updated_at TEXT NOT NULL
    );
  ''';

  // DDL: Cached Offline Exams
  static const String createCachedExamsTable = '''
    CREATE TABLE IF NOT EXISTS $tableCachedExams (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      university_code TEXT,
      duration_minutes INTEGER NOT NULL,
      total_marks REAL NOT NULL,
      negative_marking REAL NOT NULL DEFAULT 0.25,
      questions_payload_json TEXT NOT NULL,
      downloaded_at TEXT NOT NULL,
      expires_at TEXT
    );
  ''';

  // DDL: Pending Submissions Queue
  static const String createPendingSubmissionsTable = '''
    CREATE TABLE IF NOT EXISTS $tablePendingSubmissions (
      id TEXT PRIMARY KEY,
      exam_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      answers_json TEXT NOT NULL,
      time_taken_seconds INTEGER NOT NULL,
      submitted_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'pending',
      retry_count INTEGER NOT NULL DEFAULT 0
    );
  ''';

  // DDL: Cached Questions
  static const String createCachedQuestionsTable = '''
    CREATE TABLE IF NOT EXISTS $tableCachedQuestions (
      id TEXT PRIMARY KEY,
      subject TEXT NOT NULL,
      chapter TEXT,
      stem TEXT NOT NULL,
      options_json TEXT NOT NULL,
      correct_option_index INTEGER NOT NULL,
      explanation TEXT,
      cached_at TEXT NOT NULL
    );
  ''';

  // DDL: Offline Mistake Vault
  static const String createOfflineMistakesTable = '''
    CREATE TABLE IF NOT EXISTS $tableOfflineMistakes (
      id TEXT PRIMARY KEY,
      question_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      wrong_count INTEGER NOT NULL DEFAULT 1,
      is_mastered INTEGER NOT NULL DEFAULT 0,
      last_reviewed_at TEXT NOT NULL
    );
  ''';

  /// All database initialization statements in order
  static const List<String> initStatements = [
    createOnboardingDraftsTable,
    createCachedExamsTable,
    createPendingSubmissionsTable,
    createCachedQuestionsTable,
    createOfflineMistakesTable,
  ];
}

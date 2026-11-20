import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/user_profile.dart';

/// Supabase Cloud Integration Service for Prep404
class SupabaseService {
  static String get supabaseUrl => AppConfig.supabaseUrl;
  static String get supabaseAnonKey => AppConfig.supabaseAnonKey;

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  SupabaseClient? _client;

  bool get isInitialized => _isInitialized;

  SupabaseClient get client {
    if (!_isInitialized || _client == null) {
      throw StateError('SupabaseService must be initialized before use.');
    }
    return _client!;
  }

  /// Initialize Supabase Flutter SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  /// Fetch private university catalog from Supabase
  Future<List<Map<String, dynamic>>> fetchUniversities() async {
    try {
      final data = await client
          .from('universities')
          .select('*, academic_units(*), programs(*), admission_cycles(*)')
          .eq('is_active', true)
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch community social links from Supabase
  Future<List<Map<String, dynamic>>> fetchCommunityLinks() async {
    try {
      final data = await client
          .from('community_links')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch admission test patterns from Supabase
  Future<List<Map<String, dynamic>>> fetchAdmissionPatterns() async {
    try {
      final data = await client
          .from('admission_test_patterns')
          .select('*, universities(id, code, short_name, full_name, slug)');
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch university blueprints from Supabase
  Future<List<Map<String, dynamic>>> fetchUniversityBlueprints() async {
    try {
      final data = await client.from('university_blueprints').select('*');
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch all 8 Administrative Divisions of Bangladesh
  Future<List<Map<String, dynamic>>> fetchDivisions() async {
    try {
      final data = await client
          .from('divisions')
          .select('id, name_en, name_bn, code')
          .order('name_en', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch Districts optionally filtered by division
  Future<List<Map<String, dynamic>>> fetchDistricts(
      {String? divisionId}) async {
    try {
      var query =
          client.from('districts').select('id, division_id, name_en, name_bn');
      if (divisionId != null && divisionId.isNotEmpty) {
        query = query.eq('division_id', divisionId);
      }
      final data = await query.order('name_en', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch Thanas / Upazilas optionally filtered by district
  Future<List<Map<String, dynamic>>> fetchThanas({String? districtId}) async {
    try {
      var query =
          client.from('thanas').select('id, district_id, name_en, name_bn');
      if (districtId != null && districtId.isNotEmpty) {
        query = query.eq('district_id', districtId);
      }
      final data = await query.order('name_en', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Search BANBEIS educational institutions with autocomplete & preloading
  Future<List<Map<String, dynamic>>> searchInstitutions(
    String query, {
    bool isHsc = true,
    bool? collegesOnly,
    int limit = 50,
  }) async {
    try {
      final trimmed = query.trim();
      final hscTarget = collegesOnly ?? isHsc;
      var baseQuery = client.from('institutions').select(
          'id, eiin, name_en, name_bn, is_college, is_school, is_madrasa');
      if (hscTarget) {
        baseQuery = baseQuery.or('is_college.eq.true,is_madrasa.eq.true');
      } else {
        baseQuery = baseQuery.or('is_school.eq.true,is_madrasa.eq.true');
      }

      final isWord = trimmed.length >= 2 || query.contains(' ');
      if (trimmed.isNotEmpty && isWord) {
        // Check if user is searching by EIIN (numeric) or name
        if (RegExp(r'^\d+$').hasMatch(trimmed)) {
          baseQuery = baseQuery.ilike('eiin', '$trimmed%');
        } else {
          // First word typed by user must match the first word of the college name
          final words =
              trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
          final pattern = words.join('%');
          final isBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed);
          final searchCol = isBangla ? 'name_bn' : 'name_en';
          baseQuery = baseQuery.ilike(searchCol, '$pattern%');
        }
      }

      final data = await baseQuery.order('name_en', ascending: true).limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Search English Medium institutions (Cambridge & Edexcel)
  Future<List<Map<String, dynamic>>> searchEnglishMediumInstitutions(
    String query, {
    bool isCollege = false,
    String? board,
    int limit = 250,
  }) async {
    try {
      final trimmed = query.trim();
      var baseQuery = client.from('english_medium_institutions').select(
            'id, name, district, area, institution_type, is_college, is_school, board_type, is_cambridge, is_edexcel, website, email',
          );

      if (isCollege) {
        baseQuery = baseQuery.eq('is_college', true);
      }

      if (trimmed.isNotEmpty) {
        baseQuery = baseQuery.or(
            'name.ilike.%$trimmed%,area.ilike.%$trimmed%,district.ilike.%$trimmed%');
      }

      final data = await baseQuery.order('name', ascending: true).limit(limit);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch active effective academic admission year from relational database
  Future<int> fetchEffectiveAdmissionYear() async {
    try {
      final res = await client
          .from('program_fee_structures')
          .select('effective_year')
          .order('effective_year', ascending: false)
          .limit(1);
      if (res.isNotEmpty && res.first['effective_year'] != null) {
        return (res.first['effective_year'] as num).toInt();
      }
    } catch (_) {}
    return DateTime.now().year;
  }

  /// Fetch distinct curriculum examination boards from relational English Medium database
  Future<List<String>> fetchEnglishMediumBoards() async {
    try {
      final res =
          await client.from('english_medium_institutions').select('board_type');
      final boards = res
          .map((e) => e['board_type']?.toString().trim())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (boards.isNotEmpty) {
        boards.sort();
        return boards;
      }
    } catch (_) {}
    return [
      'Cambridge International',
      'Pearson Edexcel',
      'Dual (Cambridge & Edexcel)',
      'International Baccalaureate (IB)',
    ];
  }

  /// Fetch dynamic active academic batches from public.academic_batches table
  Future<List<Map<String, dynamic>>> fetchAcademicBatches({
    String? examLevel,
    int? prerequisiteYear,
  }) async {
    try {
      var query =
          client.from('academic_batches').select().eq('is_active', true);

      if (examLevel != null && examLevel.isNotEmpty) {
        query = query.eq('exam_level', examLevel);
      }
      if (prerequisiteYear != null) {
        query = query.eq('linked_prerequisite_year', prerequisiteYear);
      }

      final data = await query.order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Fetch dynamic active examination boards from public.academic_boards table
  Future<List<String>> fetchAcademicBoards() async {
    try {
      final res = await client
          .from('academic_boards')
          .select('board_name')
          .eq('is_active', true)
          .order('board_name', ascending: true);
      final list = res
          .map((e) => e['board_name']?.toString().trim())
          .where((e) => e != null && e.isNotEmpty)
          .cast<String>()
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return fetchEnglishMediumBoards();
  }

  /// Fetch Degree Programs optionally filtered by university
  Future<List<Map<String, dynamic>>> fetchPrograms(
      {String? universityId}) async {
    try {
      var query =
          client.from('programs').select('*, program_fee_structures(*)');
      if (universityId != null && universityId.isNotEmpty) {
        query = query.eq('university_id', universityId);
      }
      final data = await query.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Launch Google Sign-In: uses native in-app Google bottom sheet on mobile
  /// when available, with graceful fallback to Supabase Web OAuth.
  Future<bool> signInWithGoogle() async {
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          await GoogleSignIn.instance.initialize(
            clientId: defaultTargetPlatform == TargetPlatform.android
                ? null
                : (AppConfig.googleClientId.isNotEmpty
                    ? AppConfig.googleClientId
                    : null),
            serverClientId: AppConfig.googleWebClientId.isNotEmpty
                ? AppConfig.googleWebClientId
                : null,
          );
          if (GoogleSignIn.instance.supportsAuthenticate()) {
            final account = await GoogleSignIn.instance.authenticate();
            final idToken = account.authentication.idToken;
            if (idToken != null && idToken.isNotEmpty) {
              await client.auth.signInWithIdToken(
                provider: OAuthProvider.google,
                idToken: idToken,
              );
              return true;
            }
          }
        } catch (nativeError) {
          debugPrint('Native Google sign-in fallback to web OAuth: $nativeError');
        }
      }

      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : AppConfig.authRedirectUri,
      );
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  /// Launch Facebook OAuth Sign-In via Supabase
  Future<bool> signInWithFacebook() async {
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : AppConfig.authRedirectUri,
      );
    } catch (e) {
      return false;
    }
  }

  /// Result wrapper for Email / Password authentication attempts
  Future<AuthResult> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final res = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: fullName != null && fullName.isNotEmpty
            ? {'full_name': fullName.trim()}
            : null,
      );
      if (res.session != null) {
        return AuthResult(
          success: true,
          token: res.session!.accessToken,
          needsVerification: false,
        );
      }
      return const AuthResult(
        success: true,
        needsVerification: true,
      );
    } on AuthException catch (e) {
      return AuthResult(
        success: false,
        needsVerification: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        needsVerification: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with email & password
  Future<AuthResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final res = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      if (res.session != null) {
        return AuthResult(
          success: true,
          token: res.session!.accessToken,
          needsVerification: false,
        );
      }
      return const AuthResult(
        success: false,
        needsVerification: false,
        errorMessage: 'Sign-in failed. Please check your credentials.',
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        try {
          await client.auth.resend(
            type: OtpType.signup,
            email: email.trim().toLowerCase(),
          );
        } catch (_) {}
        return const AuthResult(
          success: false,
          needsVerification: true,
          errorMessage: 'Email not verified. A 6-digit code has been sent.',
        );
      }
      return AuthResult(
        success: false,
        needsVerification: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        needsVerification: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Verify 6-digit email OTP (for signup or email verification)
  Future<String?> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    try {
      final res = await client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.signup,
      );
      if (res.session != null) return res.session!.accessToken;
    } catch (_) {}

    try {
      final res = await client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.email,
      );
      return res.session?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Send phone OTP via Supabase
  Future<bool> sendOtp(String phone) async {
    try {
      await client.auth
          .signInWithOtp(phone: phone.startsWith('+') ? phone : '+88$phone');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verify phone OTP via Supabase
  Future<String?> verifyOtp(String phone, String token) async {
    try {
      final response = await client.auth.verifyOTP(
        phone: phone.startsWith('+') ? phone : '+88$phone',
        token: token,
        type: OtpType.sms,
      );
      return response.session?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Sign out current candidate
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Current Supabase User
  User? get currentUser => _isInitialized ? _client?.auth.currentUser : null;

  /// Current Supabase access token for authenticated backend requests.
  String? get currentAccessToken =>
      _isInitialized ? _client?.auth.currentSession?.accessToken : null;

  /// Auth changes, including OAuth deep-link completion and refreshed sessions.
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Fetch individual student roadmap & section progress
  Future<Map<String, dynamic>?> fetchStudentRoadmap(
      String universityCode) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;
      final response = await client.rpc('get_student_roadmap', params: {
        'p_user_id': userId,
        'p_university_code': universityCode.toLowerCase(),
      });
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch questions from Mistake Vault
  Future<List<Map<String, dynamic>>> fetchMistakeVault(
      {String? universityCode}) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];
      var query = client
          .from('mistake_vault')
          .select('*, questions(*)')
          .eq('user_id', userId)
          .eq('is_mastered', false);

      if (universityCode != null && universityCode.isNotEmpty) {
        query = query.eq('university_code', universityCode.toLowerCase());
      }

      final data = await query.order('next_review_at').limit(50);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Record a wrong answer into student's Mistake Vault
  Future<void> recordMistake(String questionId, String universityCode) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      await client.from('mistake_vault').upsert({
        'user_id': userId,
        'question_id': questionId,
        'university_code': universityCode.toLowerCase(),
        'wrong_count': 1,
        'next_review_at':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'is_mastered': false,
        'last_reviewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,question_id');
    } catch (_) {}
  }

  /// Update student section progress
  Future<void> updateSectionProgress({
    required String universityCode,
    required String sectionId,
    required double masteryPercentage,
    required int questionsAttempted,
    required int correctCount,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      await client.from('student_section_progress').upsert({
        'user_id': userId,
        'university_code': universityCode.toLowerCase(),
        'section_id': sectionId,
        'mastery_percentage': masteryPercentage,
        'questions_attempted': questionsAttempted,
        'correct_count': correctCount,
        'last_practiced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,university_code,section_id');
    } catch (_) {}
  }

  /// Fetch candidate profile directly from Supabase users table
  Future<UserProfile?> fetchUserProfile([String? uid]) async {
    final userId = uid ?? currentUser?.id;
    if (userId == null) return null;
    try {
      final response = await client
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromDbMap(response);
    } catch (e) {
      debugPrint('Failed to fetch user profile from Supabase: $e');
      return null;
    }
  }

  /// Save candidate profile directly to Supabase users table.
  /// Handles duplicate phone unique constraint (23505) gracefully by retrying
  /// without phone so academics and target universities still persist.
  Future<bool> saveUserProfile(UserProfile profile) async {
    final dbMap = profile.toDbMap();
    try {
      await client.from('users').upsert(dbMap);
      return true;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('23505') || errStr.toLowerCase().contains('phone')) {
        try {
          final retryMap = Map<String, dynamic>.from(dbMap)..['phone'] = null;
          await client.from('users').upsert(retryMap);
          debugPrint('Saved user profile to Supabase (phone skipped due to uniqueness conflict)');
          return true;
        } catch (retryErr) {
          debugPrint('Failed retry saving user profile to Supabase: $retryErr');
        }
      }
      debugPrint('Failed to save user profile to Supabase: $e');
      return false;
    }
  }

  /// Fetch past exam submissions from Supabase
  Future<List<Map<String, dynamic>>> fetchExamSubmissions([String? uid]) async {
    final userId = uid ?? currentUser?.id;
    if (userId == null || !isInitialized) return [];
    try {
      final response = await client
          .from('exam_submissions')
          .select(
              'id, exam_id, score, correct_count, wrong_count, unanswered_count, time_taken_seconds, rank, submitted_at, answers, questions_snapshot, is_practice, university_code, exams(title, total_marks, negative_mark_per_question)')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Failed to fetch exam submissions from Supabase: $e');
      return [];
    }
  }
}

/// Authentication response container for email & password auth attempts
class AuthResult {
  final bool success;
  final String? token;
  final bool needsVerification;
  final String? errorMessage;

  const AuthResult({
    required this.success,
    this.token,
    this.needsVerification = false,
    this.errorMessage,
  });
}

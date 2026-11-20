import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../errors/app_logger.dart';
import '../models/question.dart';
import '../models/exam_models.dart';
import '../models/notification_model.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';
import '../network/resilient_api_client.dart';

/// Central Exam & Question Bank Repository
/// Connected directly to live Supabase Database, Pre-Materialized Edge Snapshots, and Redis Cache.
/// Single-query Edge Delivery with zero hardcoded question fallback lists.
class ExamRepository {
  static final ExamRepository _instance = ExamRepository._internal();
  factory ExamRepository() => _instance;
  ExamRepository._internal();

  /// Default API URL (Backend Engine with dynamic host configuration)
  String get baseUrl => AppConfig.apiHost;

  final CacheService _cache = CacheService();
  final Map<String, String> _subjectSlugCache = {};

  Map<String, String> get _appAuthHeaders => {
        'X-Prep404-App-Client': 'prep404-mobile-app',
        'Accept': 'application/json',
        if (SupabaseService().currentAccessToken != null)
          'Authorization': 'Bearer ${SupabaseService().currentAccessToken}',
      };

  /// Resolve human-readable subject slug to database UUID from academic_subjects table
  Future<String?> resolveSubjectId(String slugOrId) async {
    if (slugOrId.contains('-') && slugOrId.length >= 32) return slugOrId;
    final lower = slugOrId.toLowerCase().trim();
    if (_subjectSlugCache.containsKey(lower)) return _subjectSlugCache[lower];

    if (SupabaseService().isInitialized) {
      try {
        final supaClient = SupabaseService().client;
        final res = await supaClient
            .from('academic_subjects')
            .select('id, slug')
            .or('slug.ilike.%$lower%,name.ilike.%$lower%')
            .limit(1);
        if (res.isNotEmpty) {
          final id = res.first['id'] as String;
          _subjectSlugCache[lower] = id;
          return id;
        }
      } catch (_) {}
    }

    final cachedSub = _cache.read<String>('subject_slug_$lower');
    if (cachedSub != null) return cachedSub;

    return null;
  }

  /// Fetch questions dynamically from backend API with offline caching
  Future<List<Question>> fetchQuestions({
    String? subjectId,
    String? topicId,
    String? targetUni,
    int limit = 20,
  }) async {
    final cacheKey =
        'questions_${subjectId ?? 'all'}_${topicId ?? 'all'}_$limit';

    String? resolvedSubjectId = subjectId;
    if (subjectId != null && subjectId.isNotEmpty) {
      resolvedSubjectId = await resolveSubjectId(subjectId) ?? subjectId;
    }

    // 1. Backend server API endpoint
    try {
      final queryParams = <String, String>{
        if (resolvedSubjectId != null && resolvedSubjectId.isNotEmpty)
          'subjectId': resolvedSubjectId,
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        if (targetUni != null && targetUni.isNotEmpty) 'targetUni': targetUni,
        'limit': limit.toString(),
      };
      final uri =
          Uri.parse('/api/v1/questions').replace(queryParameters: queryParams);
      final response = await _getWithFallback(uri.toString());

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['questions'] as List? ?? [])
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .where((q) => q.options.length >= 2)
            .toList();

        if (list.isNotEmpty) {
          _cache.write(cacheKey, response.body);
          return list;
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch questions for subject: $subjectId, topic: $topicId', e);
    }

    // 2. Local Cache (Previously fetched data - instant view with 0 network)
    final cachedRaw = _cache.read<String>(cacheKey);
    if (cachedRaw != null) {
      try {
        final decoded = jsonDecode(cachedRaw);
        final listRaw =
            decoded is List ? decoded : (decoded['questions'] as List? ?? []);
        final parsed = listRaw
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      } catch (e) {
        AppLogger.warn('Failed to parse cached questions for $cacheKey', e);
      }
    }

    return [];
  }

  Future<http.Response?> _getWithFallback(String path) =>
      ResilientApiClient().getWithFallback(path, headers: _appAuthHeaders);

  /// Fetch full model test by exam ID or slug using Edge Pre-Materialized Snapshots
  /// 1 single HTTP request, 0 complex SQL joins, automatically cached on device.
  Future<DailyExamDetails?> fetchExamBySlug(String slug) async {
    final cacheKey = 'exam_slug_$slug';

    // 1. Local Runtime Cache (Fastest - 0 network, 0 database queries)
    final cachedRaw = _cache.read<String>(cacheKey);
    if (cachedRaw != null) {
      try {
        final json = jsonDecode(cachedRaw) as Map<String, dynamic>;
        return DailyExamDetails.fromJson(json);
      } catch (_) {}
    }

    // 0. If it's a daily test request, query the single pre-cached endpoint instantly
    if (slug.contains('daily')) {
      final uni = slug.replaceAll('_daily_slot', '').replaceAll('_daily', '');
      final dailyTest = await fetchTodayDailyTest(university: uni);
      if (dailyTest != null) return dailyTest;
    }

    // 2. Pre-Materialized Question Set Snapshot API from local Fastify engine
    final res = await _getWithFallback('/api/v1/qu/$slug');
    if (res != null && res.statusCode == 200) {
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final details = DailyExamDetails.fromJson(json);
        _cache.write(cacheKey, res.body);
        if (details.id.isNotEmpty && details.id != slug) {
          _cache.write('exam_slug_${details.id}', res.body);
        }
        return details;
      } catch (_) {}
    }

    return null;
  }

  /// Start a backend-owned attempt. This request is deliberately not retried
  /// through host fallbacks because starting a session writes telemetry rows.
  Future<StartedExamSession> startDynamicExamSession(String slug) async {
    final auth = SupabaseService();
    if (auth.currentUser == null || auth.currentAccessToken == null) {
      throw StateError('Sign in again before starting a ranked exam.');
    }

    final response = await ResilientApiClient().getWithFallback(
      '/api/v1/exam/${Uri.encodeComponent(slug)}/dynamic-session',
      headers: _appAuthHeaders,
      timeout: const Duration(seconds: 10),
    );
    if (response == null) {
      throw StateError('Unable to reach exam server.');
    }
    final data = _tryDecodeResponse(response.body);
    if (response.statusCode != 200 || data == null) {
      throw StateError(
          (data?['error'] as String?) ?? 'Unable to start this exam session.');
    }

    final sessionId = (data['sessionId'] ?? '').toString();
    if (!RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false)
        .hasMatch(sessionId)) {
      throw StateError('The server returned an invalid exam session.');
    }
    final examData = data['exam'];
    final rawQuestions = data['questions'];
    if (examData is! Map || rawQuestions is! List || rawQuestions.isEmpty) {
      throw StateError('This exam does not have a ready question set.');
    }

    final examJson = <String, dynamic>{
      ...Map<String, dynamic>.from(examData),
      'id': data['examId'] ?? examData['id'],
      'slug': slug,
      'negativeMark': examData['negativeMarking'],
      'shareableUrl': '${AppConfig.webBaseUrl}/m/$slug',
      'questions': rawQuestions,
    };
    return StartedExamSession(
      sessionId: sessionId,
      exam: DailyExamDetails.fromJson(examJson),
    );
  }

  /// Fetch today's daily test from backend single-endpoint or Supabase snapshot
  Future<DailyExamDetails?> fetchTodayDailyTest({String? university}) async {
    final uniParam = (university ?? 'all').toLowerCase();
    final cacheKey = 'daily_test_today_$uniParam';

    // 1. Try single-endpoint Fastify backend (<2ms, 0 DB joins)
    final res =
        await _getWithFallback('/api/v1/daily-test/today?university=$uniParam');
    if (res != null && res.statusCode == 200) {
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final qListRaw = data['questions'] as List? ?? [];
        final questions = qListRaw
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();

        if (questions.isNotEmpty) {
          final details = DailyExamDetails(
            id: data['examId'] as String? ?? 'today_daily',
            slug: data['examId'] as String? ?? 'today_daily',
            title: data['title'] as String? ?? 'Today\'s Daily Live Test',
            track: data['track'] as String? ?? 'private_uni',
            durationMinutes: (data['durationMinutes'] as num? ?? 30).toInt(),
            totalMarks: (data['totalMarks'] as num?)?.toDouble() ?? 50.0,
            negativeMark: (data['negativeMark'] as num?)?.toDouble() ?? 0.25,
            questionCount: questions.length,
            shareableUrl: '${AppConfig.webBaseUrl}/m/${data['examId']}',
            questions: questions,
          );

          _cache.write(cacheKey, res.body);
          return details;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Fetch active and scheduled live exams for private universities from Supabase or offline cache
  Future<List<Map<String, dynamic>>> fetchLiveExams({
    String? universityCode,
    String? examType,
    int limit = 100,
  }) async {
    final cleanUni = universityCode?.trim().toUpperCase();
    final cacheKey =
        'live_exams_${cleanUni ?? 'all'}_${examType ?? 'all'}_$limit';

    if (SupabaseService().isInitialized) {
      try {
        final supaClient = SupabaseService().client;
        var query = supaClient
            .from('exams')
            .select(
                'id, title, track, exam_type, duration_seconds, total_marks, negative_mark_per_question, starts_at, ends_at, is_active, target_university:universities(code, full_name, logo_url)')
            .eq('is_active', true);

        if (cleanUni != null && cleanUni.isNotEmpty && cleanUni != 'ALL') {
          query = query.eq('track', cleanUni);
        }
        if (examType != null && examType.isNotEmpty && examType != 'all') {
          query = query.eq('exam_type', examType);
        }

        final res =
            await query.order('starts_at', ascending: false).limit(limit);

        final list = (res as List).map((row) {
          final r = row as Map<String, dynamic>;
          final targetUni = r['target_university'] as Map<String, dynamic>?;
          final durationSec = r['duration_seconds'] as num? ?? 3600;

          return {
            'id': r['id'],
            'slug': r['id'],
            'title': r['title'] ?? 'Model Test',
            'track': r['track'] ?? targetUni?['code'] ?? 'Private University',
            'examType': r['exam_type'] ?? 'model_test',
            'universityCode': targetUni?['code'] ?? r['track'] ?? 'UNI',
            'universityName': targetUni?['full_name'] ?? '',
            'universityLogo': targetUni?['logo_url'],
            'durationMinutes': (durationSec / 60).round(),
            'totalMarks': (r['total_marks'] as num?)?.toDouble() ?? 50.0,
            'negativeMarking':
                (r['negative_mark_per_question'] as num?)?.toDouble() ?? 0.25,
            'isLiveNow': r['is_active'] == true,
            'startTime': r['starts_at'],
            'endTime': r['ends_at'],
          };
        }).toList();

        if (list.isNotEmpty) {
          _cache.write(cacheKey, jsonEncode(list));
          return list;
        }
      } catch (_) {
        // Fallback to backend API
        try {
          final uri = Uri.parse('$baseUrl/api/v1/exam/live').replace(
            queryParameters: {
              if (cleanUni != null && cleanUni != 'ALL')
                'universityCode': cleanUni,
              if (examType != null && examType != 'all') 'examType': examType,
              'limit': limit.toString(),
            },
          );
          final res = await http
              .get(uri, headers: _appAuthHeaders)
              .timeout(const Duration(seconds: 2));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            final examList =
                (data['exams'] as List? ?? []).cast<Map<String, dynamic>>();
            if (examList.isNotEmpty) {
              _cache.write(cacheKey, jsonEncode(examList));
              return examList;
            }
          }
        } catch (_) {}
      }
    }

    final cachedRaw = _cache.read<String>(cacheKey);
    if (cachedRaw != null) {
      try {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedRaw) as List);
      } catch (_) {}
    }

    return [];
  }

  /// Fetch university specific exams breakdown: Model Tests, Real Past Papers, and Section Exams
  Future<Map<String, dynamic>> fetchUniversityExamBreakdown(
      String universityCode) async {
    final cleanCode = universityCode.trim().toUpperCase();
    final cacheKey = 'uni_exam_breakdown_$cleanCode';

    if (SupabaseService().isInitialized) {
      try {
        final supaClient = SupabaseService().client;
        final res = await supaClient
            .from('exams')
            .select(
                'id, title, track, exam_type, duration_seconds, total_marks, negative_mark_per_question, starts_at, ends_at, is_active')
            .eq('track', cleanCode)
            .eq('is_active', true)
            .order('title', ascending: true);

        final list = (res as List).cast<Map<String, dynamic>>();

        final modelTests = <Map<String, dynamic>>[];
        final pastPapers = <Map<String, dynamic>>[];
        final sectionExams = <Map<String, dynamic>>[];

        for (final r in list) {
          final durationSec = r['duration_seconds'] as num? ?? 3600;
          final item = {
            'id': r['id'],
            'slug': r['id'],
            'title': r['title'] ?? 'Exam',
            'track': r['track'] ?? cleanCode,
            'examType': r['exam_type'] ?? 'model_test',
            'durationMinutes': (durationSec / 60).round(),
            'totalMarks': (r['total_marks'] as num?)?.toDouble() ?? 50.0,
            'negativeMarking':
                (r['negative_mark_per_question'] as num?)?.toDouble() ?? 0.25,
            'startTime': r['starts_at'],
            'endTime': r['ends_at'],
          };

          final type = r['exam_type'] as String? ?? '';
          if (type == 'model_test' || type == 'daily_live') {
            modelTests.add(item);
          } else if (type == 'uni_exam') {
            pastPapers.add(item);
          } else if (type == 'section_exam') {
            sectionExams.add(item);
          }
        }

        final breakdown = {
          'universityCode': cleanCode,
          'modelTests': modelTests,
          'pastPapers': pastPapers,
          'sectionExams': sectionExams,
          'totalCount': list.length,
        };

        if (list.isNotEmpty) {
          _cache.write(cacheKey, jsonEncode(breakdown));
          return breakdown;
        }
      } catch (_) {
        // Fallback to backend server API
        try {
          final uri =
              Uri.parse('$baseUrl/api/v1/exam/university/$cleanCode/breakdown');
          final res = await http
              .get(uri, headers: _appAuthHeaders)
              .timeout(const Duration(seconds: 2));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            _cache.write(cacheKey, res.body);
            return data;
          }
        } catch (_) {}
      }
    }

    final cachedRaw = _cache.read<String>(cacheKey);
    if (cachedRaw != null) {
      try {
        return jsonDecode(cachedRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    return {
      'universityCode': cleanCode,
      'modelTests': <Map<String, dynamic>>[],
      'pastPapers': <Map<String, dynamic>>[],
      'sectionExams': <Map<String, dynamic>>[],
      'totalCount': 0,
    };
  }

  /// Fetch full directory metadata (universities, exam counts, subjects) with offline cache fallback
  Future<Map<String, dynamic>> fetchDirectoryMetadata() async {
    const cacheKey = 'directory_metadata_cache';

    if (SupabaseService().isInitialized) {
      try {
        final supaClient = SupabaseService().client;
        final unis = await supaClient
            .from('universities')
            .select(
                'id, code, full_name, short_name, campus_location, logo_url')
            .eq('is_active', true)
            .order('code', ascending: true);

        final examRows = await supaClient
            .from('exams')
            .select('track, exam_type')
            .eq('is_active', true);

        final subjects = await supaClient
            .from('academic_subjects')
            .select('id, name, slug')
            .order('name', ascending: true);

        final data = {
          'universities': unis,
          'exams': examRows,
          'academic_subjects': subjects,
        };

        _cache.write(cacheKey, jsonEncode(data));
        return data;
      } catch (_) {}
    }

    final cachedRaw = _cache.read<String>(cacheKey);
    if (cachedRaw != null) {
      try {
        return jsonDecode(cachedRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    return {
      'universities': [],
      'exams': [],
      'academic_subjects': [],
      'academic_units': [],
    };
  }

  /// Fetch subject filters for dynamic practice view
  Future<List<Map<String, String>>> fetchSubjectFilters() async {
    const cacheKey = 'academic_subject_filters_cache';

    if (SupabaseService().isInitialized) {
      try {
        final supaClient = SupabaseService().client;
        final res = await supaClient
            .from('academic_subjects')
            .select('id, slug, name')
            .order('display_order', ascending: true);

        final filters = <Map<String, String>>[
          {'id': 'all', 'label': 'All Topics'},
        ];
        for (final row in res as List) {
          filters.add({
            'id': row['id'].toString(),
            'label': (row['name'] ?? '').toString(),
          });
        }
        filters.add({'id': 'bookmarked', 'label': 'Bookmarked ★'});

        _cache.write(cacheKey, jsonEncode(filters));
        return filters;
      } catch (_) {}
    }

    final cachedRaw = _cache.read<String>(cacheKey);
    if (cachedRaw != null) {
      try {
        final decoded = jsonDecode(cachedRaw) as List;
        return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
      } catch (_) {}
    }

    return [
      {'id': 'all', 'label': 'All Topics'},
      {'id': 'bookmarked', 'label': 'Bookmarked ★'},
    ];
  }

  /// Submit candidate answers and record in Supabase / Redis, with offline local scoring fallback
  Future<ExamSubmissionResult> submitExam({
    required String slug,
    required String candidateName,
    required String candidateInstitution,
    String? sessionId,
    String? userId,
    String? universityCode,
    bool isPractice = false,
    required Map<String, String> answers,
    required int timeTakenSeconds,
    required String idempotencyKey,
    List<Question>? questionsSnapshot,
  }) async {
    // 1. Try submitting to backend server for live Redis ZSET ranking
    final authenticatedUser = SupabaseService().currentUser;
    final effectiveUserId = authenticatedUser?.id ?? '';

    if (authenticatedUser != null) {
      if (SupabaseService().currentAccessToken == null) {
        throw StateError(
            'Your sign-in expired. Sign in again before submitting this exam.');
      }
      final hasSessionId = sessionId != null &&
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
                  caseSensitive: false)
              .hasMatch(sessionId);
      if (sessionId != null && !hasSessionId) {
        throw StateError(
            'The secure exam session is invalid. Restart the exam before submitting.');
      }
      if (!hasSessionId && !isPractice) {
        throw StateError(
            'The secure exam session is missing. Restart the exam before submitting.');
      }
      try {
        final endpoint = hasSessionId ? 'submit-session' : 'submit';
        final path = '/api/v1/exam/${Uri.encodeComponent(slug)}/$endpoint';
        final requestBody = jsonEncode({
          if (hasSessionId) 'sessionId': sessionId,
          'userId': effectiveUserId,
          'candidateName': candidateName,
          'candidateInstitution': candidateInstitution,
          'universityCode': universityCode,
          'isPractice': isPractice,
          'answers': answers,
          'timeTakenSeconds': timeTakenSeconds,
          if (questionsSnapshot != null && questionsSnapshot.isNotEmpty)
            'questionsSnapshot': questionsSnapshot.map((q) => q.toJson()).toList(),
        });
        http.Response? response;
        for (var attempt = 0; attempt < 3; attempt++) {
          response = await ResilientApiClient().postWithFallback(
            path,
            headers: {
              ..._appAuthHeaders,
              'Content-Type': 'application/json',
              'Idempotency-Key': idempotencyKey,
            },
            body: requestBody,
            timeout: const Duration(seconds: 8),
          );
          if (response == null) {
            if (attempt == 2) {
              throw StateError(
                  'The server did not confirm your submission. Tap Retry to try again.');
            }
            await Future<void>.delayed(
                Duration(milliseconds: 250 * (attempt + 1)));
            continue;
          }

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            return ExamSubmissionResult.fromJson(data);
          }

          final responseBody = _tryDecodeResponse(response.body);
          if (response.statusCode == 409 &&
              responseBody?['code'] == 'IDEMPOTENCY_IN_PROGRESS' &&
              attempt < 4) {
            await Future<void>.delayed(
                Duration(milliseconds: 250 * (attempt + 1)));
            continue;
          }

          if (response.statusCode == 503) {
            if (attempt < 4) {
              await Future<void>.delayed(
                  Duration(milliseconds: 250 * (attempt + 1)));
              continue;
            }
            throw StateError(
              (responseBody?['error'] as String?) ??
                  'The server could not save your exam. Please retry.',
            );
          }

          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw StateError(
              (responseBody?['error'] as String?) ??
                  'The exam submission was rejected.',
            );
          }
          break;
        }
        if (response == null || response.statusCode != 200) {
          throw StateError(
              'The server did not confirm your submission. Tap Retry to try again.');
        }
      } on StateError {
        rethrow;
      } catch (_) {
        throw StateError(
            'The server could not confirm your submission. Tap Retry to try again.');
      }
    }

    // Guests (no signed-in learner) are scored by the server as an unranked
    // practice attempt. The app never receives answer keys, so local scoring
    // marked every answer wrong and showed a near-zero score as real.
    final http.Response guestResponse;
    try {
      guestResponse = await http
          .post(
            Uri.parse('$baseUrl/api/v1/exam/$slug/submit'),
            headers: {
              ..._appAuthHeaders,
              'Content-Type': 'application/json',
              'Idempotency-Key': idempotencyKey,
            },
            body: jsonEncode({
              'candidateName': candidateName,
              'candidateInstitution': candidateInstitution,
              if (universityCode != null) 'universityCode': universityCode,
              'isPractice': true,
              'answers': answers,
              'timeTakenSeconds': timeTakenSeconds > 0 ? timeTakenSeconds : 1,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw StateError(
          'Connect to the internet to see your result, then tap Retry.');
    }
    if (guestResponse.statusCode == 200) {
      return ExamSubmissionResult.fromJson(
          jsonDecode(guestResponse.body) as Map<String, dynamic>);
    }
    final guestError = _tryDecodeResponse(guestResponse.body);
    throw StateError((guestError?['error'] as String?) ??
        'Your answers could not be scored. Tap Retry to try again.');
  }

  Map<String, dynamic>? _tryDecodeResponse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPastDailyTests({
    required String universityCode,
  }) async {
    final queryParams = {
      'university': universityCode.toLowerCase(),
    };
    final uri = Uri.parse('$baseUrl/api/v1/daily-test/past')
        .replace(queryParameters: queryParams);
    try {
      final res = await http
          .get(uri, headers: _appAuthHeaders)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['pastExams'] is List) {
          return List<Map<String, dynamic>>.from(data['pastExams'] as List);
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchOverallLeaderboard() async {
    final uri = Uri.parse('$baseUrl/api/v1/leaderboard/overall');
    try {
      final res = await http
          .get(uri, headers: _appAuthHeaders)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['rankings'] is List) {
          return List<Map<String, dynamic>>.from(data['rankings'] as List);
        }
      }
    } catch (_) {}
    return [];
  }

  /// Fetch complete submission review with verified answers and predefined explanations
  Future<List<Question>> fetchSubmissionReview(
    String submissionId, {
    String? examId,
  }) async {
    final cacheKey = 'submission_review_$submissionId';
    final cached = _cache.read<String>(cacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final rawQuestions = decoded['questions'] as List? ?? [];
        final questions = rawQuestions
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
        if (questions.isNotEmpty) return questions;
      } catch (_) {}
    }

    try {
      final uri = (examId != null && examId.isNotEmpty)
          ? '/api/v1/exam/submission/$submissionId/review?examId=$examId'
          : '/api/v1/exam/submission/$submissionId/review';
      final res = await _getWithFallback(uri);
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawQuestions = data['questions'] as List? ?? [];
        final questions = rawQuestions
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
        if (questions.isNotEmpty) {
          _cache.write(cacheKey, res.body);
          return questions;
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch submission review for $submissionId', e);
    }
    return [];
  }

  /// Fetch user-specific mistake & skipped questions vault with topic weakness rankings
  Future<Map<String, dynamic>?> fetchUserVaultSummary({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService().currentUser?.id;
    final path = (effectiveUserId != null && effectiveUserId.isNotEmpty)
        ? '/api/v1/user/vault/summary?userId=$effectiveUserId'
        : '/api/v1/user/vault/summary';

    try {
      final res = await _getWithFallback(path);
      if (res != null && res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch user vault summary', e);
    }
    return null;
  }

  static Map<String, dynamic>? _cachedStreakDetails;
  static Map<String, dynamic>? get cachedStreak => _cachedStreakDetails;

  /// Fetch user-specific study streak details, timeline, and scoreboard from PostgreSQL live database
  Future<Map<String, dynamic>?> fetchUserStreakDetails({String? userId}) async {
    final effectiveUserId = userId ??
        SupabaseService().currentUser?.id ??
        CacheService().loadProfile()?.id;
    final path = (effectiveUserId != null && effectiveUserId.isNotEmpty)
        ? '/api/v1/user/streak?userId=$effectiveUserId'
        : '/api/v1/user/streak';

    try {
      final res = await _getWithFallback(path);
      if (res != null && res.statusCode == 200) {
        final parsed = jsonDecode(res.body) as Map<String, dynamic>;
        _cachedStreakDetails = parsed;
        return parsed;
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch user streak details from database', e);
    }
    return _cachedStreakDetails;
  }

  /// Fetch live database questions for a specific topic for adaptive re-test & weakness optimization
  Future<List<Question>> fetchTopicPracticeQuestions(
    String topicId, {
    int limit = 15,
  }) async {
    final cacheKey = 'vault_practice_${topicId}_$limit';
    try {
      final res = await _getWithFallback(
        '/api/v1/user/vault/topic-practice/$topicId?limit=$limit',
      );
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawList = data['questions'] as List? ?? [];
        final list = rawList
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .where((q) => q.options.length >= 2)
            .toList();
        if (list.isNotEmpty) {
          _cache.write(cacheKey, res.body);
          return list;
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch topic practice for $topicId', e);
    }
    return fetchQuestions(topicId: topicId, limit: limit);
  }

  /// Fetch user notifications for in-app notification center / inbox
  Future<List<AppNotification>> fetchUserNotifications({
    String? userId,
    int limit = 30,
  }) async {
    final effectiveUserId = userId ?? SupabaseService().currentUser?.id;
    final path = (effectiveUserId != null && effectiveUserId.isNotEmpty)
        ? '/api/v1/user/notifications?userId=$effectiveUserId&limit=$limit'
        : '/api/v1/user/notifications?limit=$limit';

    try {
      final res = await _getWithFallback(path);
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawList = data['notifications'] as List? ?? [];
        return rawList
            .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.warn('Failed to fetch user notifications', e);
    }
    return [];
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(
    String notificationId, {
    String? userId,
  }) async {
    final effectiveUserId = userId ?? SupabaseService().currentUser?.id;
    try {
      final uri =
          Uri.parse('$baseUrl/api/v1/user/notifications/$notificationId/read');
      final res = await http
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ..._appAuthHeaders,
            },
            body: jsonEncode({
              if (effectiveUserId != null) 'userId': effectiveUserId,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      AppLogger.warn('Failed to mark notification as read: $notificationId', e);
      return false;
    }
  }

  /// Log telemetry event when notification is viewed, dismissed, or tapped
  Future<bool> recordNotificationTapEvent({
    required String notificationId,
    String? campaignId,
    String? userId,
    required String event,
    String? actionId,
    String appState = 'foreground',
  }) async {
    final effectiveUserId = userId ?? SupabaseService().currentUser?.id;
    try {
      final uri = Uri.parse('$baseUrl/api/v1/telemetry/notifications/event');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ..._appAuthHeaders,
            },
            body: jsonEncode({
              'notificationId': notificationId,
              if (campaignId != null) 'campaignId': campaignId,
              if (effectiveUserId != null) 'userId': effectiveUserId,
              'event': event,
              if (actionId != null) 'actionId': actionId,
              'appState': appState,
              'deviceInfo': {
                'platform': 'flutter',
                'timestamp': DateTime.now().toIso8601String(),
              },
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      AppLogger.warn('Failed to record notification tap event', e);
      return false;
    }
  }

  /// Register FCM push device token
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceId,
    required String platform,
    String? userId,
  }) async {
    final effectiveUserId = userId ?? SupabaseService().currentUser?.id;
    try {
      final uri = Uri.parse('$baseUrl/api/v1/user/device-token');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ..._appAuthHeaders,
            },
            body: jsonEncode({
              if (effectiveUserId != null) 'userId': effectiveUserId,
              'deviceId': deviceId,
              'fcmToken': fcmToken,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      AppLogger.warn('Failed to register device token', e);
      return false;
    }
  }
}

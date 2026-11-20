import 'dart:convert';
import '../network/resilient_api_client.dart';
import '../services/supabase_service.dart';

class PrintableOmrQuestion {
  final int order;
  final String questionId;
  final String subjectName;
  final String questionText;
  final String? passage;
  final List<Map<String, String>> options;
  final String? correctOption;
  final String? solutionMarkdown;

  const PrintableOmrQuestion({
    required this.order,
    required this.questionId,
    required this.subjectName,
    required this.questionText,
    this.passage,
    required this.options,
    this.correctOption,
    this.solutionMarkdown,
  });

  factory PrintableOmrQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List? ?? []);
    return PrintableOmrQuestion(
      order: (json['order'] as num?)?.toInt() ?? 0,
      questionId: json['questionId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? 'General',
      questionText: json['questionText']?.toString() ?? '',
      passage: json['passage']?.toString(),
      options: rawOptions
          .map((o) => {
                'id': (o is Map ? o['id']?.toString() : null) ?? '',
                'text': (o is Map ? o['text']?.toString() : null) ?? '',
              })
          .toList(),
      correctOption: json['correctOption']?.toString(),
      solutionMarkdown: json['solutionMarkdown']?.toString(),
    );
  }
}

class PrintableOmrPack {
  final String id;
  final String shortCode;
  final String qrPayload;
  final String? examId;
  final String title;
  final String? universityCode;
  final String setLabel;
  final int durationMinutes;
  final double negativeMark;
  final int totalQuestions;
  final int scanCount;
  final Map<String, String> answerKey;
  final List<PrintableOmrQuestion> questions;
  final List<Map<String, dynamic>> previousAttempts;

  const PrintableOmrPack({
    required this.id,
    required this.shortCode,
    required this.qrPayload,
    this.examId,
    required this.title,
    this.universityCode,
    required this.setLabel,
    required this.durationMinutes,
    required this.negativeMark,
    required this.totalQuestions,
    this.scanCount = 0,
    this.answerKey = const {},
    this.questions = const [],
    this.previousAttempts = const [],
  });

  factory PrintableOmrPack.fromApiResponse(Map<String, dynamic> json) {
    final pack = (json['pack'] as Map<String, dynamic>? ?? json);
    final rawKey = (pack['answerKey'] as Map? ?? {});
    final rawQuestions = (pack['questions'] as List? ?? []);
    final rawAttempts = (json['previousAttempts'] as List? ?? []);
    return PrintableOmrPack(
      id: pack['id']?.toString() ?? '',
      shortCode: pack['shortCode']?.toString() ?? '',
      qrPayload: pack['qrPayload']?.toString() ??
          'prep404://omr/${pack['shortCode'] ?? ''}',
      examId: pack['examId']?.toString(),
      title: pack['title']?.toString() ?? 'Prep404 Practice Set',
      universityCode: pack['universityCode']?.toString(),
      setLabel: pack['setLabel']?.toString() ?? 'SET-A',
      durationMinutes: (pack['durationMinutes'] as num?)?.toInt() ?? 30,
      negativeMark: (pack['negativeMark'] as num?)?.toDouble() ?? 0.0,
      totalQuestions: (pack['totalQuestions'] as num?)?.toInt() ?? rawQuestions.length,
      scanCount: (pack['scanCount'] as num?)?.toInt() ?? 0,
      answerKey: rawKey.map((k, v) => MapEntry(k.toString(), v.toString())),
      questions: rawQuestions
          .whereType<Map>()
          .map((q) => PrintableOmrQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
      previousAttempts: rawAttempts
          .whereType<Map>()
          .map((a) => Map<String, dynamic>.from(a))
          .toList(),
    );
  }
}

class PrintableOmrRepository {
  static final PrintableOmrRepository _instance = PrintableOmrRepository._internal();
  factory PrintableOmrRepository() => _instance;
  PrintableOmrRepository._internal();

  Map<String, String> _authHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SupabaseService().client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Extracts a clean set code from either `prep404://omr/P404-XXXXXX`, URL, or raw code.
  static String extractCode(String rawInput) {
    final trimmed = rawInput.trim();
    final uriMatch = RegExp(r'prep404://omr/([A-Za-z0-9-]+)', caseSensitive: false)
        .firstMatch(trimmed);
    if (uriMatch != null) return uriMatch.group(1)!.toUpperCase();
    final urlMatch = RegExp(r'/omr/([A-Za-z0-9-]+)', caseSensitive: false)
        .firstMatch(trimmed);
    if (urlMatch != null) return urlMatch.group(1)!.toUpperCase();
    return trimmed.toUpperCase();
  }

  /// Generates & persists a printable OMR + Question set on the backend.
  Future<PrintableOmrPack> generatePack({
    required String examId,
    String setLabel = 'SET-A',
    bool shuffleOptions = false,
  }) async {
    final res = await ResilientApiClient().postWithFallback(
      '/api/v1/omr-packs/generate',
      headers: _authHeaders(),
      body: jsonEncode({
        'examId': examId,
        'setLabel': setLabel,
        'shuffleOptions': shuffleOptions,
      }),
      timeout: const Duration(seconds: 12),
    );

    if (res == null) {
      throw Exception('Could not reach Prep404 server. Please check your connection.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
      return PrintableOmrPack.fromApiResponse(data);
    }
    throw Exception(data['error']?.toString() ?? 'Failed to generate printable OMR pack.');
  }

  /// Resolves a scanned QR payload or set code to its exact questions & answer key.
  Future<PrintableOmrPack> resolvePack(String rawQrOrCode) async {
    final code = extractCode(rawQrOrCode);
    if (code.isEmpty) {
      throw Exception('Invalid QR code or set code.');
    }

    final res = await ResilientApiClient().getWithFallback(
      '/api/v1/omr-packs/${Uri.encodeComponent(code)}',
      headers: _authHeaders(),
      timeout: const Duration(seconds: 10),
    );

    if (res == null) {
      throw Exception('Could not reach Prep404 server. Please check your connection.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
      return PrintableOmrPack.fromApiResponse(data);
    }
    throw Exception(data['error']?.toString() ?? 'Set not found for code "$code".');
  }

  /// Saves a student's offline paper answers to `public.printable_omr_attempts`.
  Future<Map<String, dynamic>> submitOfflineAttempt({
    required String shortCode,
    required Map<String, String> answers,
    int? timeSpentMinutes,
    String? notes,
  }) async {
    final res = await ResilientApiClient().postWithFallback(
      '/api/v1/omr-packs/${Uri.encodeComponent(shortCode)}/attempts',
      headers: _authHeaders(),
      body: jsonEncode({
        'answers': answers,
        if (timeSpentMinutes != null) 'timeSpentMinutes': timeSpentMinutes,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
      timeout: const Duration(seconds: 10),
    );

    if (res == null) {
      throw Exception('Could not reach Prep404 server to save your attempt.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
      return Map<String, dynamic>.from(data['attempt'] as Map? ?? {});
    }
    throw Exception(data['error']?.toString() ?? 'Failed to save offline practice record.');
  }

  /// Fetches the student's generated printable sets and recorded offline attempts.
  Future<Map<String, dynamic>> fetchMyHistory() async {
    final res = await ResilientApiClient().getWithFallback(
      '/api/v1/omr-packs/my-history',
      headers: _authHeaders(),
      timeout: const Duration(seconds: 10),
    );

    if (res == null || res.statusCode != 200) {
      return {'packs': <Map<String, dynamic>>[], 'attempts': <Map<String, dynamic>>[]};
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'packs': (data['packs'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      'attempts': (data['attempts'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    };
  }
}

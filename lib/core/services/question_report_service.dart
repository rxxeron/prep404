import 'api_client.dart';
import 'cache_service.dart';
import 'supabase_service.dart';

class QuestionReportService {
  static const categories = <String, String>{
    'incorrect_answer': 'Incorrect answer',
    'typo': 'Typo or formatting',
    'unclear': 'Unclear question',
    'missing_explanation': 'Missing explanation',
    'other': 'Other issue',
  };

  Future<List<Map<String, dynamic>>> fetchMine({String? userId}) async {
    final effectiveUid = userId ??
        SupabaseService().currentUser?.id ??
        CacheService().read<String>('user_id');

    // 1. Try Core API endpoint first (with question text & topic joins)
    try {
      final apiReports =
          await ApiClient().fetchLearnerQuestionReports(userId: effectiveUid);
      if (apiReports.isNotEmpty) return apiReports;
    } catch (_) {}

    // 2. Direct Supabase query fallback
    final supabase = SupabaseService();
    if (supabase.isInitialized && effectiveUid != null) {
      try {
        final rows = await supabase.client
            .from('question_reports')
            .select(
                'id, question_id, category, description, status, created_at, resolution_note, resolved_by, resolved_at')
            .eq('reporter_id', effectiveUid)
            .order('created_at', ascending: false)
            .limit(50);
        if (rows.isNotEmpty) {
          return List<Map<String, dynamic>>.from(rows);
        }
      } catch (_) {}
    }

    return const [];
  }

  Future<void> submit({
    required String questionId,
    required String category,
    required String description,
    String? userId,
  }) async {
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(questionId)) {
      throw StateError('This question cannot be reported from this screen.');
    }

    final effectiveUid = userId ??
        SupabaseService().currentUser?.id ??
        CacheService().read<String>('user_id');

    // 1. Try Core API endpoint first
    final apiSuccess = await ApiClient().submitLearnerQuestionReport(
      questionId: questionId,
      category: category,
      description: description,
      userId: effectiveUid,
    );
    if (apiSuccess) return;

    // 2. Fallback to direct Supabase insert
    final supabase = SupabaseService();
    if (!supabase.isInitialized) {
      throw StateError('Sign in before reporting a question.');
    }
    final user = supabase.client.auth.currentUser;
    final reporterId = effectiveUid ?? user?.id;
    if (reporterId == null) {
      throw StateError('Sign in before reporting a question.');
    }

    await supabase.client.from('question_reports').insert({
      'question_id': questionId,
      'reporter_id': reporterId,
      'category': category,
      'description': description.trim(),
    });
  }
}

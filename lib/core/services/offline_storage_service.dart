import 'dart:convert';
import '../errors/app_logger.dart';
import 'cache_service.dart';

/// Comprehensive Offline Storage & Persistence Coordinator
/// Provides robust local offline storage for:
/// 1. In-progress student onboarding drafts (auto-save on every keystroke/selection)
/// 2. Offline exam packs & question snapshots for zero-internet testing
/// 3. Offline pending exam submissions queue (auto-sync when back online)
/// 4. Bookmarks and Mistake Vault local caches
class OfflineStorageService {
  static final OfflineStorageService _instance =
      OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  final CacheService _cache = CacheService();

  static const String _draftKey = 'offline_student_onboarding_draft';
  static const String _pendingSubmissionsKey = 'offline_pending_exam_submissions';
  static const String _offlineExamPacksPrefix = 'offline_exam_pack_';
  static const String _offlineBookmarksKey = 'offline_bookmarked_questions';

  // ===========================================================================
  // 1. In-Progress Onboarding Draft Persistence
  // ===========================================================================

  /// Persists a student's partial/in-progress onboarding details locally
  Future<void> saveOnboardingDraft(Map<String, dynamic> draft) async {
    try {
      final enriched = Map<String, dynamic>.from(draft)
        ..['last_saved_at'] = DateTime.now().toIso8601String();
      final jsonStr = jsonEncode(enriched);
      _cache.write(_draftKey, jsonStr);
      AppLogger.info('Saved in-progress student onboarding draft locally');
    } catch (e) {
      AppLogger.warn('Failed to save onboarding draft locally', e);
    }
  }

  /// Retrieves the saved partial onboarding draft, or null if none exists
  Map<String, dynamic>? getOnboardingDraft() {
    try {
      final raw = _cache.read<String>(_draftKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      AppLogger.warn('Failed to read onboarding draft from offline cache', e);
    }
    return null;
  }

  /// Whether an in-progress onboarding draft currently exists
  bool hasOnboardingDraft() {
    return getOnboardingDraft() != null;
  }

  /// Clears the onboarding draft once the student completes onboarding
  Future<void> clearOnboardingDraft() async {
    try {
      _cache.remove(_draftKey);
      AppLogger.info('Cleared onboarding draft upon successful completion');
    } catch (e) {
      AppLogger.warn('Failed to clear onboarding draft', e);
    }
  }

  // ===========================================================================
  // 2. Offline Exam Packs (Full Question Snapshots for Offline Testing)
  // ===========================================================================

  /// Caches a full exam package (questions, options, timer, negative marking)
  Future<void> cacheExamPack(
      String examId, Map<String, dynamic> examPack) async {
    try {
      final key = '$_offlineExamPacksPrefix$examId';
      _cache.write(key, jsonEncode(examPack));
      AppLogger.info('Cached exam pack $examId for offline access');
    } catch (e) {
      AppLogger.warn('Failed to cache exam pack $examId', e);
    }
  }

  /// Loads a cached exam package for offline exam participation
  Map<String, dynamic>? getCachedExamPack(String examId) {
    try {
      final key = '$_offlineExamPacksPrefix$examId';
      final raw = _cache.read<String>(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      AppLogger.warn('Failed to load cached exam pack $examId', e);
    }
    return null;
  }

  // ===========================================================================
  // 3. Offline Pending Submissions Queue (Synced When Connection Restores)
  // ===========================================================================

  /// Enqueues an exam submission when candidate is offline during completion
  Future<void> enqueuePendingSubmission(Map<String, dynamic> submission) async {
    try {
      final list = getPendingSubmissions();
      list.add(Map<String, dynamic>.from(submission)
        ..['queued_at'] = DateTime.now().toIso8601String());
      _cache.write(_pendingSubmissionsKey, jsonEncode(list));
      AppLogger.info('Enqueued offline exam submission for background sync');
    } catch (e) {
      AppLogger.warn('Failed to enqueue offline submission', e);
    }
  }

  /// Returns all submissions waiting to be synced to server
  List<Map<String, dynamic>> getPendingSubmissions() {
    try {
      final raw = _cache.read<String>(_pendingSubmissionsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      }
    } catch (e) {
      AppLogger.warn('Failed to parse pending submissions', e);
    }
    return [];
  }

  /// Removes a synced submission from the offline queue
  Future<void> removePendingSubmission(String submissionId) async {
    try {
      final list = getPendingSubmissions();
      list.removeWhere((item) => item['id'] == submissionId);
      _cache.write(_pendingSubmissionsKey, jsonEncode(list));
    } catch (e) {
      AppLogger.warn('Failed to remove pending submission', e);
    }
  }

  // ===========================================================================
  // 4. Offline Bookmarks & Personal Notes
  // ===========================================================================

  /// Saves question IDs bookmarked by student for offline revision
  Future<void> saveBookmarks(List<String> questionIds) async {
    try {
      _cache.write(_offlineBookmarksKey, jsonEncode(questionIds));
    } catch (e) {
      AppLogger.warn('Failed to save offline bookmarks', e);
    }
  }

  /// Retrieves bookmarked question IDs
  List<String> getBookmarks() {
    try {
      final raw = _cache.read<String>(_offlineBookmarksKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.cast<String>();
      }
    } catch (_) {}
    return [];
  }
}

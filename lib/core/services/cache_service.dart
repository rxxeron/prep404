import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Fast In-Memory & Local Storage Cache Service
/// Keeps caching decoupled from network calls and UI widgets
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  UserProfile? _cachedProfile;
  final Map<String, dynamic> _memoryStore = {};

  /// Initialize persistent local storage
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
  }

  /// Get current user profile
  UserProfile? get profile => _cachedProfile;

  /// Cache user profile in memory and disk
  void saveProfile(UserProfile profile) {
    _cachedProfile = profile;
    final jsonStr = jsonEncode(profile.toJson());
    _memoryStore['user_profile'] = jsonStr;
    _prefs?.setString('user_profile', jsonStr);
  }

  /// Load profile from memory store or disk
  UserProfile? loadProfile() {
    if (_cachedProfile != null) return _cachedProfile;
    final raw = (_memoryStore['user_profile'] as String?) ??
        _prefs?.getString('user_profile');
    if (raw != null) {
      try {
        _cachedProfile =
            UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return _cachedProfile;
      } catch (_) {}
    }
    return null;
  }

  /// Generic key-value write
  void write(String key, dynamic value) {
    _memoryStore[key] = value;
    if (_prefs != null) {
      if (value is String) {
        _prefs!.setString(key, value);
      } else if (value is bool) {
        _prefs!.setBool(key, value);
      } else if (value is int) {
        _prefs!.setInt(key, value);
      } else if (value is double) {
        _prefs!.setDouble(key, value);
      } else if (value is List<String>) {
        _prefs!.setStringList(key, value);
      }
    }
  }

  /// Generic key-value read
  T? read<T>(String key) {
    if (_memoryStore.containsKey(key)) {
      return _memoryStore[key] as T?;
    }
    if (_prefs != null && _prefs!.containsKey(key)) {
      final val = _prefs!.get(key);
      if (val is T) {
        _memoryStore[key] = val;
        return val;
      }
    }
    return null;
  }

  /// Remove a specific key from cache
  void remove(String key) {
    _memoryStore.remove(key);
    _prefs?.remove(key);
  }

  /// Clear all cache (e.g. on logout)
  void clear() {
    _cachedProfile = null;
    _memoryStore.clear();
    _prefs?.clear();
  }

  /// Clear learner/session data while retaining device-level display choices.
  void clearAccountData() {
    const retainedKeys = {'app_language', 'theme_mode'};
    _cachedProfile = null;
    _memoryStore.removeWhere((key, _) => !retainedKeys.contains(key));
    final keys = _prefs?.getKeys() ?? const <String>{};
    for (final key in keys) {
      if (!retainedKeys.contains(key)) _prefs?.remove(key);
    }
  }

  /// Save submitted exam script/record to persistent history
  void saveExamScript(Map<String, dynamic> scriptJson) {
    try {
      final list = loadExamScripts();
      list.insert(0, scriptJson);
      if (list.length > 50) {
        list.removeRange(50, list.length);
      }
      final jsonStr = jsonEncode(list);
      _memoryStore['exam_scripts_history'] = jsonStr;
      _prefs?.setString('exam_scripts_history', jsonStr);
    } catch (_) {}
  }

  /// Load all submitted exam scripts/records from persistent history
  List<Map<String, dynamic>> loadExamScripts() {
    final raw = (_memoryStore['exam_scripts_history'] as String?) ??
        _prefs?.getString('exam_scripts_history');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }
}

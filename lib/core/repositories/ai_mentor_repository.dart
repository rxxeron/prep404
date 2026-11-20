import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../network/resilient_api_client.dart';
import '../services/supabase_service.dart';

class AiChatSessionItem {
  final String id;
  final String title;
  final String contextType;
  final String detectedLanguage;
  final int messageCount;
  final DateTime? lastMessageAt;

  const AiChatSessionItem({
    required this.id,
    required this.title,
    required this.contextType,
    required this.detectedLanguage,
    required this.messageCount,
    this.lastMessageAt,
  });

  factory AiChatSessionItem.fromJson(Map<String, dynamic> json) {
    return AiChatSessionItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Chat with Bhaiya',
      contextType: json['contextType']?.toString() ?? 'general',
      detectedLanguage: json['detectedLanguage']?.toString() ?? 'en',
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
    );
  }
}

class AiChatMessageItem {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final String? modelUsed;
  final String? nodeName;
  final int? latencyMs;
  final String? feedback; // 'up' | 'down' | null
  final bool isStreaming;

  const AiChatMessageItem({
    required this.id,
    required this.role,
    required this.content,
    this.modelUsed,
    this.nodeName,
    this.latencyMs,
    this.feedback,
    this.isStreaming = false,
  });

  AiChatMessageItem copyWith({
    String? id,
    String? content,
    String? modelUsed,
    String? nodeName,
    int? latencyMs,
    String? feedback,
    bool? isStreaming,
  }) {
    return AiChatMessageItem(
      id: id ?? this.id,
      role: role,
      content: content ?? this.content,
      modelUsed: modelUsed ?? this.modelUsed,
      nodeName: nodeName ?? this.nodeName,
      latencyMs: latencyMs ?? this.latencyMs,
      feedback: feedback ?? this.feedback,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  factory AiChatMessageItem.fromJson(Map<String, dynamic> json) {
    return AiChatMessageItem(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      modelUsed: json['modelUsed']?.toString(),
      nodeName: json['nodeName']?.toString(),
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      feedback: json['feedback']?.toString(),
    );
  }
}

class AiMentorRepository {
  static final AiMentorRepository _instance = AiMentorRepository._internal();
  factory AiMentorRepository() => _instance;
  AiMentorRepository._internal();

  Map<String, String> _authHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Prep404-App-Client': 'prep404-mobile-app',
    };
    final token = SupabaseService().client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> fetchFleetStatus() async {
    final res = await ResilientApiClient().getWithFallback(
      '/api/v1/ai/fleet/status',
      headers: _authHeaders(),
      timeout: const Duration(seconds: 6),
    );
    if (res == null || res.statusCode != 200) {
      return {'onlineCount': 0, 'totalConfigured': 0, 'onlineNodes': []};
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(data['fleet'] as Map? ?? {});
  }

  Future<List<AiChatSessionItem>> fetchSessions() async {
    final res = await ResilientApiClient().getWithFallback(
      '/api/v1/ai/chat/sessions',
      headers: _authHeaders(),
      timeout: const Duration(seconds: 8),
    );
    if (res == null || res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['sessions'] as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => AiChatSessionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AiChatSessionItem> createSession({
    String? title,
    String contextType = 'general',
    String? contextRefId,
    Map<String, dynamic>? contextPayload,
  }) async {
    final res = await ResilientApiClient().postWithFallback(
      '/api/v1/ai/chat/sessions',
      headers: _authHeaders(),
      body: jsonEncode({
        if (title != null) 'title': title,
        'contextType': contextType,
        if (contextRefId != null) 'contextRefId': contextRefId,
        if (contextPayload != null) 'contextPayload': contextPayload,
      }),
      timeout: const Duration(seconds: 8),
    );
    if (res == null) {
      throw Exception('Cannot reach Prep404 server. Please check your connection.');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
      return AiChatSessionItem.fromJson(
        Map<String, dynamic>.from(data['session'] as Map),
      );
    }
    throw Exception(data['error']?.toString() ?? 'Could not start chat session.');
  }

  Future<List<AiChatMessageItem>> fetchMessages(String sessionId) async {
    final res = await ResilientApiClient().getWithFallback(
      '/api/v1/ai/chat/sessions/$sessionId/messages',
      headers: _authHeaders(),
      timeout: const Duration(seconds: 8),
    );
    if (res == null || res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['messages'] as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => AiChatMessageItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Streams SSE events (`meta`, `token`, `done`) from the least-busy Lab PC.
  Stream<Map<String, dynamic>> streamMessage({
    required String sessionId,
    required String content,
  }) async* {
    final client = http.Client();
    try {
      http.StreamedResponse? streamed;
      String? lastError;

      for (final host in AppConfig.candidateApiHosts) {
        try {
          final uri = Uri.parse('$host/api/v1/ai/chat/sessions/$sessionId/messages');
          final req = http.Request('POST', uri);
          req.headers.addAll({
            ..._authHeaders(),
            'Accept': 'text/event-stream',
          });
          req.body = jsonEncode({'content': content});

          final res = await client.send(req).timeout(const Duration(seconds: 70));
          if (res.statusCode == 200) {
            streamed = res;
            break;
          }
          final errBody = await res.stream.bytesToString();
          try {
            final parsed = jsonDecode(errBody) as Map<String, dynamic>;
            lastError = parsed['error']?.toString() ?? 'HTTP ${res.statusCode}';
          } catch (_) {
            lastError = 'HTTP ${res.statusCode}';
          }
          if (res.statusCode >= 400 && res.statusCode < 500) break;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (streamed == null) {
        throw Exception(
          lastError ?? 'Lab AI server is currently unavailable. Please try again.',
        );
      }

      String buffer = '';
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final parts = buffer.split('\n\n');
        buffer = parts.removeLast();

        for (final part in parts) {
          for (final line in part.split('\n')) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('data:')) continue;
            final jsonStr = trimmed.substring(5).trim();
            if (jsonStr.isEmpty) continue;
            try {
              final event = jsonDecode(jsonStr);
              if (event is Map<String, dynamic>) {
                yield event;
              }
            } catch (_) {}
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> sendFeedback(String messageId, String feedback) async {
    await ResilientApiClient().postWithFallback(
      '/api/v1/ai/chat/messages/$messageId/feedback',
      headers: _authHeaders(),
      body: jsonEncode({'feedback': feedback}),
      timeout: const Duration(seconds: 6),
    );
  }

  Future<void> archiveSession(String sessionId) async {
    final headers = _authHeaders();
    for (final host in AppConfig.candidateApiHosts) {
      try {
        final res = await http
            .delete(
              Uri.parse('$host/api/v1/ai/chat/sessions/$sessionId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 6));
        if (res.statusCode >= 200 && res.statusCode < 300) return;
      } catch (_) {}
    }
  }
}

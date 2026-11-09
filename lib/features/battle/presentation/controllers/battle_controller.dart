import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/question.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/supabase_service.dart';

enum BattleStatus {
  idle,
  loadingPrograms,
  waitingInQueue,
  roomCreated,
  readyCountdown,
  questionActive,
  roundSummary,
  finished,
  error,
}

class DuelUniversity {
  final String id;
  final String code;
  final String shortName;
  final String fullName;
  final List<DuelProgram> programs;

  const DuelUniversity({
    required this.id,
    required this.code,
    required this.shortName,
    required this.fullName,
    required this.programs,
  });

  factory DuelUniversity.fromJson(Map<String, dynamic> json) {
    final rawPatterns = (json['patterns'] as List? ?? []);
    final programList = rawPatterns.map((p) => DuelProgram.fromJson(p as Map<String, dynamic>)).toList();
    return DuelUniversity(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      shortName: (json['short_name'] ?? json['code'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      programs: programList,
    );
  }
}

class DuelProgram {
  final String id;
  final String name;
  final String slug;
  final List<String> sections;

  const DuelProgram({
    required this.id,
    required this.name,
    required this.slug,
    required this.sections,
  });

  factory DuelProgram.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List? ?? []);
    final secNames = rawSections.map((s) {
      if (s is Map) return (s['name'] ?? 'Section').toString();
      return s.toString();
    }).toList();

    return DuelProgram(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      sections: secNames,
    );
  }
}

class BattlePlayer {
  final String id;
  final String name;
  final String college;
  final String avatarUrl;
  final int score;
  final bool hasAnswered;
  final int roundPoints;

  const BattlePlayer({
    required this.id,
    required this.name,
    this.college = 'Candidate',
    required this.avatarUrl,
    this.score = 0,
    this.hasAnswered = false,
    this.roundPoints = 0,
  });

  BattlePlayer copyWith({
    String? id,
    int? score,
    bool? hasAnswered,
    String? name,
    String? college,
    int? roundPoints,
  }) {
    return BattlePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      college: college ?? this.college,
      avatarUrl: avatarUrl,
      score: score ?? this.score,
      hasAnswered: hasAnswered ?? this.hasAnswered,
      roundPoints: roundPoints ?? this.roundPoints,
    );
  }
}

class BattleSummary {
  final int totalBattles;
  final int wins;
  final int losses;
  final int draws;
  final int winRate;

  const BattleSummary({
    this.totalBattles = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winRate = 0,
  });

  factory BattleSummary.fromJson(Map<String, dynamic> json) {
    return BattleSummary(
      totalBattles: (json['totalBattles'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toInt() ?? 0,
    );
  }
}

class BattleRoomParticipant {
  final String id;
  final String name;
  final String college;
  final bool isHost;
  final bool isReady;

  const BattleRoomParticipant({
    required this.id,
    required this.name,
    required this.college,
    this.isHost = false,
    this.isReady = false,
  });

  factory BattleRoomParticipant.fromJson(Map<String, dynamic> json) {
    return BattleRoomParticipant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Candidate').toString(),
      college: (json['college'] ?? 'Admission Candidate').toString(),
      isHost: json['isHost'] == true,
      isReady: json['isReady'] == true,
    );
  }
}

class BattleHistoryItem {
  final String id;
  final String roomCode;
  final String track;
  final String status;
  final String outcome; // 'victory' | 'defeat' | 'draw'
  final int yourScore;
  final int opponentScore;
  final String opponentName;
  final String opponentCollege;
  final DateTime createdAt;

  const BattleHistoryItem({
    required this.id,
    required this.roomCode,
    required this.track,
    required this.status,
    required this.outcome,
    required this.yourScore,
    required this.opponentScore,
    required this.opponentName,
    required this.opponentCollege,
    required this.createdAt,
  });

  factory BattleHistoryItem.fromJson(Map<String, dynamic> json) {
    final opp = json['opponent'] as Map<String, dynamic>? ?? {};
    return BattleHistoryItem(
      id: (json['id'] ?? '').toString(),
      roomCode: (json['roomCode'] ?? '').toString(),
      track: (json['track'] ?? 'General').toString(),
      status: (json['status'] ?? 'finished').toString(),
      outcome: (json['outcome'] ?? 'defeat').toString(),
      yourScore: (json['yourScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      opponentName: (opp['name'] ?? 'Candidate').toString(),
      opponentCollege: (opp['college'] ?? 'Admission Candidate').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BattleState {
  final BattleStatus status;
  final String? roomId;
  final String? roomCode;
  final String? universityCode;
  final String? programSlug;
  final String? currentSection;
  final List<String> sections;
  final BattlePlayer? myPlayer;
  final BattlePlayer? opponentPlayer;
  final Question? currentQuestion;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int timeRemainingSeconds;
  final String? selectedOptionId;
  final String? opponentSelectedOptionId;
  final String? correctOptionId;
  final bool showRoundResult;
  final String? queueWaitingMessage;
  final String? errorMessage;
  final bool isVictory;
  final bool isDraw;
  final int xpEarned;
  final List<DuelUniversity> universities;
  final DuelUniversity? selectedUniversity;
  final DuelProgram? selectedProgram;
  final List<BattleHistoryItem> matchHistory;
  final BattleSummary? matchSummary;
  final bool isLoadingHistory;
  final int activeLobbyTab; // 0: Matchmaking, 1: History
  final int roomMaxPlayers;
  final int roomTimeRemainingSeconds;
  final bool isHost;
  final bool isReady;
  final bool canHostStart;
  final List<BattleRoomParticipant> roomPlayers;
  final List<Map<String, dynamic>> leaderboard;

  const BattleState({
    this.status = BattleStatus.idle,
    this.roomId,
    this.roomCode,
    this.universityCode,
    this.programSlug,
    this.currentSection,
    this.sections = const [],
    this.myPlayer,
    this.opponentPlayer,
    this.currentQuestion,
    this.currentQuestionIndex = 0,
    this.totalQuestions = 6,
    this.timeRemainingSeconds = 15,
    this.selectedOptionId,
    this.opponentSelectedOptionId,
    this.correctOptionId,
    this.showRoundResult = false,
    this.queueWaitingMessage,
    this.errorMessage,
    this.isVictory = false,
    this.isDraw = false,
    this.xpEarned = 0,
    this.universities = const [],
    this.selectedUniversity,
    this.selectedProgram,
    this.matchHistory = const [],
    this.matchSummary,
    this.isLoadingHistory = false,
    this.activeLobbyTab = 0,
    this.roomMaxPlayers = 2,
    this.roomTimeRemainingSeconds = 90,
    this.isHost = false,
    this.isReady = false,
    this.canHostStart = false,
    this.roomPlayers = const [],
    this.leaderboard = const [],
  });

  BattleState copyWith({
    BattleStatus? status,
    String? roomId,
    String? roomCode,
    String? universityCode,
    String? programSlug,
    String? currentSection,
    List<String>? sections,
    BattlePlayer? myPlayer,
    BattlePlayer? opponentPlayer,
    Question? currentQuestion,
    int? currentQuestionIndex,
    int? totalQuestions,
    int? timeRemainingSeconds,
    String? selectedOptionId,
    bool clearSelectedOptionId = false,
    String? opponentSelectedOptionId,
    bool clearOpponentSelectedOptionId = false,
    String? correctOptionId,
    bool clearCorrectOptionId = false,
    bool? showRoundResult,
    String? queueWaitingMessage,
    String? errorMessage,
    bool? isVictory,
    bool? isDraw,
    int? xpEarned,
    List<DuelUniversity>? universities,
    DuelUniversity? selectedUniversity,
    DuelProgram? selectedProgram,
    List<BattleHistoryItem>? matchHistory,
    BattleSummary? matchSummary,
    bool? isLoadingHistory,
    int? activeLobbyTab,
    int? roomMaxPlayers,
    int? roomTimeRemainingSeconds,
    bool? isHost,
    bool? isReady,
    bool? canHostStart,
    List<BattleRoomParticipant>? roomPlayers,
    List<Map<String, dynamic>>? leaderboard,
  }) {
    return BattleState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      universityCode: universityCode ?? this.universityCode,
      programSlug: programSlug ?? this.programSlug,
      currentSection: currentSection ?? this.currentSection,
      sections: sections ?? this.sections,
      myPlayer: myPlayer ?? this.myPlayer,
      opponentPlayer: opponentPlayer ?? this.opponentPlayer,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      selectedOptionId: clearSelectedOptionId ? null : (selectedOptionId ?? this.selectedOptionId),
      opponentSelectedOptionId: clearOpponentSelectedOptionId ? null : (opponentSelectedOptionId ?? this.opponentSelectedOptionId),
      correctOptionId: clearCorrectOptionId ? null : (correctOptionId ?? this.correctOptionId),
      showRoundResult: showRoundResult ?? this.showRoundResult,
      queueWaitingMessage: queueWaitingMessage ?? this.queueWaitingMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      isVictory: isVictory ?? this.isVictory,
      isDraw: isDraw ?? this.isDraw,
      xpEarned: xpEarned ?? this.xpEarned,
      universities: universities ?? this.universities,
      selectedUniversity: selectedUniversity ?? this.selectedUniversity,
      selectedProgram: selectedProgram ?? this.selectedProgram,
      matchHistory: matchHistory ?? this.matchHistory,
      matchSummary: matchSummary ?? this.matchSummary,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      activeLobbyTab: activeLobbyTab ?? this.activeLobbyTab,
      roomMaxPlayers: roomMaxPlayers ?? this.roomMaxPlayers,
      roomTimeRemainingSeconds: roomTimeRemainingSeconds ?? this.roomTimeRemainingSeconds,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      canHostStart: canHostStart ?? this.canHostStart,
      roomPlayers: roomPlayers ?? this.roomPlayers,
      leaderboard: leaderboard ?? this.leaderboard,
    );
  }
}

/// Real-Time WebSocket Battle Controller
/// Directly interfaces with Prep404 WebSocket Battle Gateway.
/// Zero hardcoding: all universities, patterns, and questions are dynamically queried from PostgreSQL.
class BattleController extends ChangeNotifier {
  BattleState _state = const BattleState();
  BattleState get state => _state;
  @visibleForTesting
  set state(BattleState value) {
    _state = value;
    notifyListeners();
  }

  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool _isDisposed = false;
  void Function()? _onSocketAuthenticated;
  String get _currentUserId => SupabaseService().currentUser?.id ?? '';

  String get _wsUrl => AppConfig.wsBattleUrl;
  String get _apiBaseUrl => AppConfig.apiBaseUrl;

  BattleController() {
    loadUniversityPrograms();
    loadBattleHistory();
  }

  void switchLobbyTab(int tab) {
    _state = _state.copyWith(activeLobbyTab: tab);
    if (tab == 1) {
      loadBattleHistory();
    }
    notifyListeners();
  }

  Future<void> loadBattleHistory() async {
    final uid = _currentUserId.isNotEmpty
        ? _currentUserId
        : (CacheService().loadProfile()?.id ?? '');
    if (uid.isEmpty) return;

    _state = _state.copyWith(isLoadingHistory: true);
    notifyListeners();

    try {
      final token = SupabaseService().currentAccessToken ??
          CacheService().read<String>('auth_token');
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final res = await http.get(
        Uri.parse('$_apiBaseUrl/battle/history?userId=$uid'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true) {
          final summaryJson = body['summary'] as Map<String, dynamic>? ?? {};
          final historyList = (body['history'] as List? ?? [])
              .map((item) => BattleHistoryItem.fromJson(item as Map<String, dynamic>))
              .toList();
          _state = _state.copyWith(
            matchSummary: BattleSummary.fromJson(summaryJson),
            matchHistory: historyList,
            isLoadingHistory: false,
          );
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('[BattleController] Error loading battle history: $e');
    }
    _state = _state.copyWith(isLoadingHistory: false);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// 100% Dynamic: Fetches all universities and program patterns from PostgreSQL
  Future<void> loadUniversityPrograms() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/battle/university-programs'),
        headers: {
          'X-Prep404-App-Client': 'prep404-mobile-app',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final list = (body['data'] as List).map((u) => DuelUniversity.fromJson(u)).toList();
          DuelUniversity? defUni;
          DuelProgram? defProg;
          if (list.isNotEmpty) {
            defUni = list.firstWhere(
              (u) => u.code == 'BRACU',
              orElse: () => list.first,
            );
            if (defUni.programs.isNotEmpty) {
              defProg = defUni.programs.firstWhere(
                (p) => p.slug == 'eng',
                orElse: () => defUni!.programs.first,
              );
            }
          }
          _state = _state.copyWith(
            universities: list,
            selectedUniversity: defUni,
            selectedProgram: defProg,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[BattleController] Error loading university programs: $e');
    }
  }

  void selectUniversity(DuelUniversity uni) {
    DuelProgram? firstProg = uni.programs.isNotEmpty ? uni.programs.first : null;
    _state = _state.copyWith(
      selectedUniversity: uni,
      selectedProgram: firstProg,
    );
    notifyListeners();
  }

  void selectProgram(DuelProgram prog) {
    _state = _state.copyWith(selectedProgram: prog);
    notifyListeners();
  }

  /// Connects to real WebSocket battle gateway
  void _connectWebSocket(void Function() onAuthenticated) {
    _closeWebSocket();
    try {
      _onSocketAuthenticated = onAuthenticated;
      _wsChannel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _wsSubscription = _wsChannel!.stream.listen(
        _handleSocketMessage,
        onError: (err) {
          debugPrint('[BattleController] WS Error: $err');
          _state = _state.copyWith(
            status: BattleStatus.error,
            errorMessage: 'Connection lost to Battle Server. Ensure backend is running.',
          );
          notifyListeners();
        },
        onDone: () {
          debugPrint('[BattleController] WS Connection closed.');
        },
      );
      _sendSocketMessage({
        'type': 'AUTHENTICATE',
        'accessToken': SupabaseService().currentAccessToken,
      });
    } catch (e) {
      debugPrint('[BattleController] WS Connect exception: $e');
      _state = _state.copyWith(
        status: BattleStatus.error,
        errorMessage: 'Could not connect to $_wsUrl: $e',
      );
      notifyListeners();
    }
  }

  void joinQueue({String candidateName = 'You'}) {
    final uniCode = _state.selectedUniversity?.code ?? 'BRACU';
    final progSlug = _state.selectedProgram?.slug ?? 'eng';

    _state = _state.copyWith(
      status: BattleStatus.waitingInQueue,
      universityCode: uniCode,
      programSlug: progSlug,
      queueWaitingMessage: 'Searching for active candidate targeting $uniCode ($progSlug)...',
      myPlayer: BattlePlayer(
        id: _currentUserId,
        name: candidateName,
        avatarUrl: 'https://i.pravatar.cc/150?u=me',
      ),
    );
    notifyListeners();

    _connectWebSocket(() {
      _sendSocketMessage({
        'type': 'JOIN_QUEUE',
        'university': uniCode,
        'program': progSlug,
      });
    });
  }

  void startBotMatch({String candidateName = 'You'}) {
    final uniCode = _state.selectedUniversity?.code ?? 'BRACU';
    final progSlug = _state.selectedProgram?.slug ?? 'eng';

    _state = _state.copyWith(
      status: BattleStatus.waitingInQueue,
      universityCode: uniCode,
      programSlug: progSlug,
      queueWaitingMessage: 'Initializing live duel against Prep404 AI Engine...',
      myPlayer: BattlePlayer(
        id: _currentUserId,
        name: candidateName,
        avatarUrl: 'https://i.pravatar.cc/150?u=me',
      ),
    );
    notifyListeners();

    _connectWebSocket(() {
      _sendSocketMessage({
        'type': 'START_BOT_MATCH',
        'university': uniCode,
        'program': progSlug,
      });
    });
  }

  void createPrivateRoom({String candidateName = 'You', int maxPlayers = 2}) {
    final uniCode = _state.selectedUniversity?.code ?? 'BRACU';
    final progSlug = _state.selectedProgram?.slug ?? 'eng';
    final capacity = maxPlayers.clamp(2, 8);

    _state = _state.copyWith(
      status: BattleStatus.waitingInQueue,
      universityCode: uniCode,
      programSlug: progSlug,
      roomMaxPlayers: capacity,
      roomTimeRemainingSeconds: 90,
      isHost: true,
      isReady: true,
      canHostStart: false,
      myPlayer: BattlePlayer(
        id: _currentUserId,
        name: candidateName,
        avatarUrl: 'https://i.pravatar.cc/150?u=me',
      ),
    );
    notifyListeners();

    _connectWebSocket(() {
      _sendSocketMessage({
        'type': 'CREATE_ROOM',
        'university': uniCode,
        'program': progSlug,
        'maxPlayers': capacity,
      });
    });
  }

  void joinPrivateRoom({required String roomCode, String candidateName = 'You'}) {
    _state = _state.copyWith(
      status: BattleStatus.waitingInQueue,
      roomCode: roomCode,
      queueWaitingMessage: 'Joining room $roomCode...',
      isHost: false,
      isReady: false,
      myPlayer: BattlePlayer(
        id: _currentUserId,
        name: candidateName,
        avatarUrl: 'https://i.pravatar.cc/150?u=me',
      ),
    );
    notifyListeners();

    _connectWebSocket(() {
      _sendSocketMessage({
        'type': 'JOIN_ROOM',
        'roomCode': roomCode,
      });
    });
  }

  void toggleReady(bool isReady) {
    _state = _state.copyWith(isReady: isReady);
    notifyListeners();
    _sendSocketMessage({
      'type': 'TOGGLE_READY',
      'roomCode': _state.roomCode,
      'isReady': isReady,
    });
  }

  void hostStartRoom() {
    if (!_state.isHost) return;
    _sendSocketMessage({
      'type': 'HOST_START_ROOM',
      'roomCode': _state.roomCode,
    });
  }

  void leaveRoom() {
    if (_state.roomCode != null) {
      _sendSocketMessage({
        'type': 'LEAVE_ROOM',
        'roomCode': _state.roomCode,
      });
    }
    _closeWebSocket();
    _state = _state.copyWith(
      status: BattleStatus.idle,
      roomPlayers: const [],
      isHost: false,
      isReady: false,
      canHostStart: false,
    );
    notifyListeners();
  }

  void submitAnswer(String optionId) {
    if (_state.myPlayer?.hasAnswered ?? true) return;
    if (_state.status != BattleStatus.questionActive) return;

    _state = _state.copyWith(
      selectedOptionId: optionId,
      myPlayer: _state.myPlayer?.copyWith(hasAnswered: true),
    );
    notifyListeners();

    _sendSocketMessage({
      'type': 'SUBMIT_ANSWER',
      'roomId': _state.roomId,
      'optionId': optionId,
      'timeRemainingSeconds': _state.timeRemainingSeconds,
    });
  }

  void cancelMatchmaking() {
    _sendSocketMessage({'type': 'LEAVE_QUEUE'});
    _closeWebSocket();
    _state = _state.copyWith(status: BattleStatus.idle);
    notifyListeners();
  }

  void reset() {
    _closeWebSocket();
    _state = BattleState(
      status: BattleStatus.idle,
      universities: _state.universities,
      selectedUniversity: _state.selectedUniversity,
      selectedProgram: _state.selectedProgram,
    );
    notifyListeners();
  }

  void _handleSocketMessage(dynamic raw) {
    try {
      final msg = json.decode(raw.toString()) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'AUTHENTICATED':
          final callback = _onSocketAuthenticated;
          _onSocketAuthenticated = null;
          final publicId = msg['publicId']?.toString();
          if (publicId != null && _state.myPlayer != null) {
            _state = _state.copyWith(myPlayer: _state.myPlayer!.copyWith(id: publicId));
            notifyListeners();
          }
          callback?.call();
          break;

        case 'AUTH_ERROR':
          _onSocketAuthenticated = null;
          _state = _state.copyWith(
            status: BattleStatus.error,
            errorMessage: msg['message']?.toString() ?? 'Sign in before joining a battle.',
          );
          notifyListeners();
          break;

        case 'QUEUE_WAITING':
          _state = _state.copyWith(
            status: BattleStatus.waitingInQueue,
            queueWaitingMessage: msg['message']?.toString() ?? 'Waiting for live opponent...',
          );
          notifyListeners();
          break;

        case 'ROOM_CREATED':
          final maxP = (msg['maxPlayers'] as num?)?.toInt() ?? 2;
          final timeRem = (msg['timeRemainingSeconds'] as num?)?.toInt() ?? 90;
          final rawPlayers = (msg['players'] as List? ?? []);
          final participants = rawPlayers
              .map((p) => BattleRoomParticipant.fromJson(p as Map<String, dynamic>))
              .toList();
          _state = _state.copyWith(
            status: BattleStatus.roomCreated,
            roomCode: msg['roomCode']?.toString(),
            universityCode: msg['university']?.toString(),
            programSlug: msg['program']?.toString(),
            roomMaxPlayers: maxP,
            roomTimeRemainingSeconds: timeRem,
            isHost: true,
            isReady: true,
            canHostStart: false,
            roomPlayers: participants,
            queueWaitingMessage: msg['message']?.toString(),
          );
          notifyListeners();
          break;

        case 'ROOM_JOINED':
          final joinedMax = (msg['maxPlayers'] as num?)?.toInt() ?? 2;
          final joinedTime = (msg['timeRemainingSeconds'] as num?)?.toInt() ?? 90;
          final joinedRaw = (msg['players'] as List? ?? []);
          final joinedParts = joinedRaw
              .map((p) => BattleRoomParticipant.fromJson(p as Map<String, dynamic>))
              .toList();
          _state = _state.copyWith(
            status: BattleStatus.roomCreated,
            roomCode: msg['roomCode']?.toString(),
            universityCode: msg['university']?.toString(),
            programSlug: msg['program']?.toString(),
            roomMaxPlayers: joinedMax,
            roomTimeRemainingSeconds: joinedTime,
            isHost: false,
            isReady: false,
            canHostStart: false,
            roomPlayers: joinedParts,
          );
          notifyListeners();
          break;

        case 'ROOM_PLAYERS_UPDATE':
          final updateMax = (msg['maxPlayers'] as num?)?.toInt() ?? _state.roomMaxPlayers;
          final updateTime = (msg['timeRemainingSeconds'] as num?)?.toInt() ?? _state.roomTimeRemainingSeconds;
          final canStart = msg['canHostStart'] == true;
          final updateRaw = (msg['players'] as List? ?? []);
          final updateParticipants = updateRaw
              .map((p) => BattleRoomParticipant.fromJson(p as Map<String, dynamic>))
              .toList();

          bool myReady = _state.isReady;
          if (!_state.isHost && _state.myPlayer != null) {
            final me = updateParticipants
                .where((p) => p.name == _state.myPlayer!.name || p.id == _state.myPlayer!.id)
                .firstOrNull;
            if (me != null) myReady = me.isReady;
          }

          _state = _state.copyWith(
            roomMaxPlayers: updateMax,
            roomTimeRemainingSeconds: updateTime,
            canHostStart: canStart,
            roomPlayers: updateParticipants,
            isReady: myReady,
          );
          notifyListeners();
          break;

        case 'ROOM_TICK':
          final rem = (msg['timeRemaining'] as num?)?.toInt() ?? _state.roomTimeRemainingSeconds;
          _state = _state.copyWith(roomTimeRemainingSeconds: rem);
          notifyListeners();
          break;

        case 'ROOM_TIMEOUT':
          _state = _state.copyWith(
            status: BattleStatus.idle,
            errorMessage: msg['message']?.toString() ?? 'Room assembly timed out (1m 30s limit reached).',
            roomPlayers: const [],
            isHost: false,
            isReady: false,
            canHostStart: false,
          );
          notifyListeners();
          break;

        case 'ROOM_CLOSED':
          _state = _state.copyWith(
            status: BattleStatus.idle,
            errorMessage: msg['message']?.toString() ?? 'Room was closed by host.',
            roomPlayers: const [],
            isHost: false,
            isReady: false,
            canHostStart: false,
          );
          notifyListeners();
          break;

        case 'ROOM_ERROR':
          _state = _state.copyWith(
            status: BattleStatus.error,
            errorMessage: msg['message']?.toString() ?? 'Room error occurred.',
          );
          notifyListeners();
          break;

        case 'MATCH_FOUND':
          final opp = msg['opponent'] as Map<String, dynamic>? ?? {};
          final rawSections = (msg['sections'] as List? ?? []).map((s) => s.toString()).toList();
          _state = _state.copyWith(
            status: BattleStatus.readyCountdown,
            roomId: msg['roomId']?.toString(),
            totalQuestions: (msg['totalRounds'] as num?)?.toInt() ?? 6,
            sections: rawSections,
            clearSelectedOptionId: true,
            clearOpponentSelectedOptionId: true,
            clearCorrectOptionId: true,
            showRoundResult: false,
            opponentPlayer: BattlePlayer(
              id: (opp['id'] ?? 'opp').toString(),
              name: (opp['name'] ?? 'Candidate').toString(),
              college: (opp['college'] ?? 'Candidate').toString(),
              avatarUrl: 'https://i.pravatar.cc/150?u=opp',
            ),
          );
          notifyListeners();
          break;

        case 'ROUND_START':
          final qJson = msg['question'] as Map<String, dynamic>? ?? {};
          final currentQ = Question.fromJson(qJson);
          final scores = (msg['scores'] as Map<String, dynamic>?) ?? {};

          final myId = _state.myPlayer?.id;
          final oppId = _state.opponentPlayer?.id;

          final myUpdatedScore = myId != null && scores.containsKey(myId)
              ? (scores[myId] as num).toInt()
              : (_state.myPlayer?.score ?? 0);
          final oppUpdatedScore = oppId != null && scores.containsKey(oppId)
              ? (scores[oppId] as num).toInt()
              : (_state.opponentPlayer?.score ?? 0);

          _state = _state.copyWith(
            status: BattleStatus.questionActive,
            currentQuestion: currentQ,
            currentQuestionIndex: (msg['roundIndex'] as num?)?.toInt() ?? 1,
            totalQuestions: (msg['totalRounds'] as num?)?.toInt() ?? _state.totalQuestions,
            currentSection: msg['section']?.toString(),
            timeRemainingSeconds: (msg['durationSeconds'] as num?)?.toInt() ?? 15,
            clearSelectedOptionId: true,
            clearOpponentSelectedOptionId: true,
            clearCorrectOptionId: true,
            showRoundResult: false,
            myPlayer: _state.myPlayer?.copyWith(
              score: myUpdatedScore,
              hasAnswered: false,
              roundPoints: 0,
            ),
            opponentPlayer: _state.opponentPlayer?.copyWith(
              score: oppUpdatedScore,
              hasAnswered: false,
              roundPoints: 0,
            ),
          );
          notifyListeners();
          break;

        case 'ROUND_TICK':
          final time = (msg['timeRemaining'] as num?)?.toInt() ?? _state.timeRemainingSeconds;
          _state = _state.copyWith(timeRemainingSeconds: time);
          notifyListeners();
          break;

        case 'OPPONENT_ANSWERED':
          _state = _state.copyWith(
            opponentPlayer: _state.opponentPlayer?.copyWith(hasAnswered: true),
          );
          notifyListeners();
          break;

        case 'ROUND_RESULT':
          _state = _state.copyWith(
            status: BattleStatus.roundSummary,
            showRoundResult: true,
            correctOptionId: msg['correctOption']?.toString(),
            selectedOptionId: msg['yourAnswer']?.toString() ?? _state.selectedOptionId,
            opponentSelectedOptionId: msg['opponentAnswer']?.toString(),
            myPlayer: _state.myPlayer?.copyWith(
              score: (msg['yourScore'] as num?)?.toInt() ?? _state.myPlayer?.score ?? 0,
              roundPoints: (msg['yourPoints'] as num?)?.toInt() ?? 0,
              hasAnswered: true,
            ),
            opponentPlayer: _state.opponentPlayer?.copyWith(
              score: (msg['opponentScore'] as num?)?.toInt() ?? _state.opponentPlayer?.score ?? 0,
              roundPoints: (msg['opponentPoints'] as num?)?.toInt() ?? 0,
              hasAnswered: true,
            ),
          );
          notifyListeners();
          break;

        case 'DUEL_FINISHED':
          _state = _state.copyWith(
            status: BattleStatus.finished,
            isVictory: msg['isVictory'] as bool? ?? false,
            isDraw: msg['isDraw'] as bool? ?? false,
            xpEarned: (msg['xpEarned'] as num?)?.toInt() ?? 50,
            myPlayer: _state.myPlayer?.copyWith(
              score: (msg['yourScore'] as num?)?.toInt() ?? _state.myPlayer?.score ?? 0,
            ),
            opponentPlayer: _state.opponentPlayer?.copyWith(
              score: (msg['opponentScore'] as num?)?.toInt() ?? _state.opponentPlayer?.score ?? 0,
            ),
          );
          notifyListeners();
          loadBattleHistory();
          break;

        case 'OPPONENT_FORFEIT':
          _state = _state.copyWith(
            status: BattleStatus.finished,
            isVictory: true,
            xpEarned: 150,
            errorMessage: msg['message']?.toString() ?? 'Opponent forfeited. Victory awarded!',
          );
          notifyListeners();
          loadBattleHistory();
          break;
      }
    } catch (e) {
      debugPrint('[BattleController] Parse socket message error: $e');
    }
  }

  void _sendSocketMessage(Map<String, dynamic> data) {
    if (_wsChannel != null) {
      _wsChannel!.sink.add(json.encode(data));
    }
  }

  void _closeWebSocket() {
    _onSocketAuthenticated = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  Future<void> reportOpponent({required String category, required String details}) async {
    final roomId = _state.roomId;
    final token = SupabaseService().currentAccessToken ??
        CacheService().read<String>('auth_token');
    if (roomId == null || _state.opponentPlayer == null) {
      throw StateError('This battle is not available to report.');
    }
    if (token == null || token.isEmpty) {
      throw StateError('Please sign in to report a player.');
    }
    if (roomId.startsWith('room_bot_') || _state.opponentPlayer!.id.startsWith('bot_')) {
      throw StateError('Automated AI bot matches cannot be reported for player conduct. Use Question Report for question issues.');
    }
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/battle/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'battleId': roomId, 'category': category, 'details': details.trim()}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      dynamic body;
      try { body = json.decode(response.body); } catch (_) { body = null; }
      throw StateError(body is Map ? '${body['error'] ?? 'Unable to send this report.'}' : 'Unable to send this report.');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _closeWebSocket();
    super.dispose();
  }
}

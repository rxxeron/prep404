import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/battle/presentation/controllers/battle_controller.dart';
import 'package:prep404/features/battle/presentation/widgets/battle_arena_view.dart';

void main() {
  group('Battle PvP Flow Tests', () {
    test('BattleController starts matchmaking and progresses correctly', () async {
      final controller = BattleController();

      expect(controller.state.status, BattleStatus.idle);

      controller.joinQueue(candidateName: 'Test Student');
      expect(controller.state.status, BattleStatus.waitingInQueue);
      expect(controller.state.myPlayer?.name, 'Test Student');

      // Cancel matchmaking
      controller.cancelMatchmaking();
      expect(controller.state.status, BattleStatus.idle);

      controller.dispose();
    });

    testWidgets('BattleArenaView renders lobby and responds to find match', (WidgetTester tester) async {
      final controller = BattleController();
      addTearDown(() => controller.dispose());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattleArenaView(controller: controller),
          ),
        ),
      );

      // Verify lobby UI elements
      expect(find.text('Admission Quiz Duel'), findsOneWidget);
      expect(find.text('REAL-LIFE 1v1 DUEL ARENA'), findsOneWidget);

      // Tap Primary Action (Join Queue)
      final findMatchButton = find.byType(ElevatedButton);
      expect(findMatchButton, findsOneWidget);
      await tester.tap(findMatchButton);
      await tester.pump();

      // Verify state changed to queue waiting
      expect(find.text('Searching for Opponent...'), findsOneWidget);
      expect(find.text('Cancel Search'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel Search'));
      await tester.pump();

      expect(find.text('Admission Quiz Duel'), findsOneWidget);

      // Switch to Match History tab
      await tester.tap(find.textContaining('Match History'));
      await tester.pump();

      // Verify history view is visible
      expect(find.text('PAST 1V1 DUELS'), findsOneWidget);
      expect(find.text('DUELS'), findsOneWidget);
      expect(find.text('WIN RATE'), findsOneWidget);

      // Switch back to Duel Arena
      await tester.tap(find.text('Duel Arena'));
      await tester.pump();

      expect(find.text('Admission Quiz Duel'), findsOneWidget);
    });

    testWidgets('BattleArenaView displays room build modal and assembly lobby', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = BattleController();
      addTearDown(() => controller.dispose());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattleArenaView(controller: controller),
          ),
        ),
      );
      await tester.pump();

      // Tap Create Room to trigger room capacity modal
      final createRoomFinder = find.text('Create Room');
      await tester.ensureVisible(createRoomFinder);
      await tester.tap(createRoomFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Build Battle Room'), findsOneWidget);
      expect(find.text('ROOM CAPACITY (PLAYERS)'), findsOneWidget);
      expect(find.text('4 Players'), findsOneWidget);
      expect(find.text('8 Players'), findsOneWidget);

      // Select 4 Players
      await tester.tap(find.text('4 Players'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Build Room (4 Players)'), findsOneWidget);

      // Close modal
      Navigator.of(tester.element(find.text('Build Battle Room'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Simulate room created state with 4 players capacity and 90s countdown
      controller.state = controller.state.copyWith(
        status: BattleStatus.roomCreated,
        roomCode: 'BRACU-777',
        roomMaxPlayers: 4,
        roomTimeRemainingSeconds: 90,
        isHost: true,
        roomPlayers: const [
          BattleRoomParticipant(
            id: 'host-1',
            name: 'Candidate Host',
            college: 'BRACU Aspirant',
            isHost: true,
            isReady: true,
          ),
          BattleRoomParticipant(
            id: 'client-2',
            name: 'Friend Candidate',
            college: 'BRACU Aspirant',
            isHost: false,
            isReady: false,
          ),
        ],
      );
      await tester.pump();

      // Verify Assembly Lobby elements
      expect(find.text('Duel Assembly Room'), findsOneWidget);
      expect(find.text('BRACU-777'), findsOneWidget);
      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('2 / 4 PLAYERS'), findsOneWidget);
      expect(find.text('Candidate Host'), findsOneWidget);
      expect(find.text('Friend Candidate'), findsOneWidget);
      expect(find.text('Waiting for Clients to be Ready'), findsOneWidget);

      // Simulate friend marking Ready
      controller.state = controller.state.copyWith(
        canHostStart: true,
        roomPlayers: const [
          BattleRoomParticipant(
            id: 'host-1',
            name: 'Candidate Host',
            college: 'BRACU Aspirant',
            isHost: true,
            isReady: true,
          ),
          BattleRoomParticipant(
            id: 'client-2',
            name: 'Friend Candidate',
            college: 'BRACU Aspirant',
            isHost: false,
            isReady: true,
          ),
        ],
      );
      await tester.pump();

      // Host can now start battle
      expect(find.text('Start Battle (2 Players Ready)'), findsOneWidget);
    });
  });
}

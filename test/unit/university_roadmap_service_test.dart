import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/core/services/university_roadmap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UniversityRoadmapService Decoupled Dynamic Catalog Tests', () {
    late UniversityRoadmapService service;

    setUp(() {
      service = UniversityRoadmapService();
    });

    test('Initializes all 8 private university roadmaps with brand configs', () {
      final all = service.allRoadmaps;
      expect(all.length, greaterThanOrEqualTo(8));

      final keys = all.map((r) => r.key).toSet();
      expect(keys.contains('brac'), isTrue);
      expect(keys.contains('nsu'), isTrue);
      expect(keys.contains('aiub'), isTrue);
      expect(keys.contains('aust'), isTrue);
      expect(keys.contains('ewu'), isTrue);
      expect(keys.contains('uiu'), isTrue);
      expect(keys.contains('diu'), isTrue);
      expect(keys.contains('uap'), isTrue);
    });

    test('Provides valid sections and weightages for all academic disciplines', () {
      for (final discipline in DisciplineCategory.values) {
        final sections = service.getSectionsForProgram('brac', discipline);
        expect(sections.isNotEmpty, isTrue);

        final totalWeight =
            sections.fold<int>(0, (sum, section) => sum + section.weight);
        expect(totalWeight, equals(100));

        for (final section in sections) {
          expect(section.name.isNotEmpty, isTrue);
          expect(section.marks.isNotEmpty, isTrue);
          expect(section.chapters.isNotEmpty, isTrue);
        }
      }
    });

    test('ensureActiveTarget switches active key to candidate selection', () {
      service.setActiveUniversity('brac');
      expect(service.activeUniversityKey.value, equals('brac'));

      service.ensureActiveTarget(['NSU']);
      expect(service.activeUniversityKey.value, equals('nsu'));

      service.ensureActiveTarget(['AUST']);
      expect(service.activeUniversityKey.value, equals('aust'));
    });

    test('getRoadmapsForTargets filters accurately', () {
      final filtered = service.getRoadmapsForTargets(['brac', 'nsu']);
      expect(filtered.length, equals(2));
      expect(filtered.any((r) => r.key == 'brac'), isTrue);
      expect(filtered.any((r) => r.key == 'nsu'), isTrue);

      final emptyFallback = service.getRoadmapsForTargets([]);
      expect(emptyFallback.length, greaterThanOrEqualTo(8));
    });

    test('Hiking nodes and leaderboards are properly populated per roadmap', () {
      final roadmap = service.getRoadmap('brac');
      expect(roadmap.hikingNodes.length, equals(5));
      expect(roadmap.hikingNodes.first.type, equals(HikingNodeType.active));
      expect(roadmap.hikingNodes.last.type, equals(HikingNodeType.summit));

      expect(roadmap.leaderboard.length, greaterThanOrEqualTo(3));
      expect(roadmap.leaderboard.first.rank, equals('#1'));
    });
  });
}

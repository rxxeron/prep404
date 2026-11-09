import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/core/models/user_profile.dart';

void main() {
  group('UserProfile & UniversityCatalog Tests', () {
    test('UniversityCatalog has expected universities and disciplines in alphabetical order', () {
      expect(UniversityCatalog.universities, isNotEmpty);
      final names = UniversityCatalog.universities.map((u) => u.fullName).toList();
      final sortedNames = List<String>.from(names)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(names, equals(sortedNames), reason: 'Universities must be arranged in alphabetical order A-Z');

      final nsu = UniversityCatalog.universities.firstWhere((u) => u.id == 'nsu');
      expect(nsu.code, 'NSU');
      expect(nsu.disciplines.any((d) => d.id == 'nsu_cse'), isTrue);
    });

    test('UserProfile computes totalTargetedPrograms and daysUntilEarliestExam correctly', () {
      const profile = UserProfile(
        id: 'u_101',
        name: 'Sadik Rahman',
        phone: '01712345678',
        medium: StudentMedium.bangla,
        academicBatch: "HSC '24",
        institutionName: 'Dhaka College',
        targetSelections: {
          'nsu': ['nsu_cse', 'nsu_bba'],
          'brac': ['brac_cse'],
        },
      );

      expect(profile.isOnboarded, isTrue);
      expect(profile.totalTargetedPrograms, 3);
      expect(profile.daysUntilEarliestExam, isPositive);

      final json = profile.toJson();
      expect(json['id'], 'u_101');
      expect(json['targetSelections']['nsu'].length, 2);

      final restored = UserProfile.fromJson(json);
      expect(restored.name, 'Sadik Rahman');
      expect(restored.medium, StudentMedium.bangla);
      expect(restored.nctbVersion, NctbVersion.bangla);
      expect(restored.targetSelections['brac']?.first, 'brac_cse');
    });

    test('Bangla medium with English Version correctly serializes and deserializes', () {
      const profile = UserProfile(
        id: 'u_103',
        name: 'Rafiqul Islam',
        phone: '01912345678',
        medium: StudentMedium.bangla,
        nctbVersion: NctbVersion.english,
        academicBatch: "HSC '24",
        institutionName: 'Notre Dame College',
        targetSelections: {
          'nsu': ['nsu_cse'],
        },
      );

      expect(profile.medium.displayName, 'Bangla Medium (NCTB)');
      expect(profile.nctbVersion?.displayName, 'NCTB English Version');

      final json = profile.toJson();
      expect(json['nctbVersion'], 'english');

      final restored = UserProfile.fromJson(json);
      expect(restored.nctbVersion, NctbVersion.english);
    });

    test('English medium profile correctly parses curriculum', () {
      const profile = UserProfile(
        id: 'u_102',
        name: 'Ayesha Khan',
        phone: '01812345678',
        medium: StudentMedium.english,
        englishCurriculum: EnglishCurriculum.cambridge,
        academicBatch: "A-Level '24",
        institutionName: 'Mastermind',
        targetSelections: {
          'iub': ['iub_cse'],
        },
      );

      expect(profile.medium.displayName, 'English Medium');
      expect(profile.englishCurriculum?.displayName, 'Cambridge (CAIE)');

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      expect(restored.englishCurriculum, EnglishCurriculum.cambridge);
    });
  });
}

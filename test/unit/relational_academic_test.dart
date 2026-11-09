import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/repositories/institution_repository.dart';

void main() {
  group('Relational Academic Calculations & Transitions', () {
    final repo = InstitutionRepository();
    const baseYear = 2026;

    test('getSscPassingYears returns 6 consecutive years ending at baseYear - 2', () {
      final sscYears = repo.getSscPassingYears(baseYear);
      expect(sscYears, equals(['2024', '2023', '2022', '2021', '2020', '2019']));
    });

    test('getHscBatchesForSscYear computes regular and second timer batches relationally', () {
      // SSC 2024 -> Regular HSC 2026 (Appearing), Second Timer 2025
      final hscBatches2024 = repo.getHscBatchesForSscYear('2024', baseYear);
      expect(hscBatches2024, equals(["HSC '26 (Appearing)", "HSC '25 (2nd Time)"]));

      // SSC 2023 -> Regular HSC 2025, Second Timer 2024
      final hscBatches2023 = repo.getHscBatchesForSscYear('2023', baseYear);
      expect(hscBatches2023, equals(["HSC '25", "HSC '24 (2nd Time)"]));

      // SSC 2022 -> Regular HSC 2024, Second Timer 2023
      final hscBatches2022 = repo.getHscBatchesForSscYear('2022', baseYear);
      expect(hscBatches2022, equals(["HSC '24", "HSC '23 (2nd Time)"]));
    });

    test('getOLevelPassingYears returns 6 consecutive years ending at baseYear - 2', () {
      final oLevelYears = repo.getOLevelPassingYears(baseYear);
      expect(oLevelYears, equals(['2024', '2023', '2022', '2021', '2020', '2019']));
    });

    test('getALevelBatchesForOLevelYear computes regular and second timer batches relationally', () {
      // O-Level 2024 -> Regular A-Level 2026 (Appearing), Second Timer 2025
      final aLevelBatches2024 = repo.getALevelBatchesForOLevelYear('2024', baseYear);
      expect(aLevelBatches2024, equals(["A-Level '26 (Appearing)", "A-Level '25 (2nd Time)"]));

      // O-Level 2023 -> Regular A-Level 2025, Second Timer 2024
      final aLevelBatches2023 = repo.getALevelBatchesForOLevelYear('2023', baseYear);
      expect(aLevelBatches2023, equals(["A-Level '25", "A-Level '24 (2nd Time)"]));
    });

    test('getAllHscBatches returns all eligible batches allowing gap years and retakes', () {
      final allHsc = repo.getAllHscBatches(baseYear);
      expect(allHsc, contains("HSC '26 (Appearing)"));
      expect(allHsc, contains("HSC '25"));
      expect(allHsc, contains("HSC '24"));
      expect(allHsc, contains("HSC '24 (2nd Time)"));
    });

    test('getAllALevelBatches returns all eligible batches allowing gap years and retakes', () {
      final allALevel = repo.getAllALevelBatches(baseYear);
      expect(allALevel, contains("A-Level '26 (Appearing)"));
      expect(allALevel, contains("A-Level '25"));
      expect(allALevel, contains("A-Level '24"));
    });

    test('getEligibleHscGroups adheres strictly to NCTB transition rules', () {
      // Science students can pursue Science, Business Studies, or Humanities
      expect(
        repo.getEligibleHscGroups('Science'),
        equals(['Science', 'Business Studies', 'Humanities']),
      );

      // Business Studies students can pursue Business Studies or Humanities
      expect(
        repo.getEligibleHscGroups('Business Studies'),
        equals(['Business Studies', 'Humanities']),
      );

      // Humanities students can only pursue Humanities
      expect(
        repo.getEligibleHscGroups('Humanities'),
        equals(['Humanities']),
      );
    });
  });
}

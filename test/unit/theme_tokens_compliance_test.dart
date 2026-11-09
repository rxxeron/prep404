import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/theme/app_theme.dart';
import 'package:prep404/core/errors/app_failure.dart';
import 'package:prep404/core/errors/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F6 & F7 Theme Tokens and Typed Error Handling Compliance Tests', () {
    test('AppColors light & dark tokens provide complete semantic contrast', () {
      const light = AppColors.light;
      const dark = AppColors.dark;

      // Primary identity
      expect(light.primary, equals(const Color(0xFFFF7A36)));
      expect(dark.primary, equals(const Color(0xFFFF7A36)));

      // Semantic surfaces
      expect(light.background, isNot(equals(dark.background)));
      expect(light.surface, isNot(equals(dark.surface)));
      expect(light.textPrimary, isNot(equals(dark.textPrimary)));

      // Status tokens
      expect(light.accentEmerald, equals(const Color(0xFF10B981)));
      expect(dark.accentEmerald, equals(const Color(0xFF10B981)));
      expect(light.dangerRed, equals(const Color(0xFFEF4444)));
      expect(dark.dangerRed, equals(const Color(0xFFEF4444)));

      // Primary light / cream wash adaptive to dark mode
      expect(light.primaryLight, equals(const Color(0xFFFFF3E6)));
      expect(dark.primaryLight, equals(const Color(0xFF542747)));
    });

    test('Result monad and AppFailure hierarchy handle success and failure paths', () {
      // Success path
      final successResult = Result.success('test_data');
      expect(successResult.isSuccess, isTrue);
      expect(successResult.isFailure, isFalse);
      expect(successResult.dataOrNull, equals('test_data'));
      expect(successResult.failureOrNull, isNull);

      final foldedSuccess = successResult.fold(
        (data) => 'resolved: $data',
        (fail) => 'failed',
      );
      expect(foldedSuccess, equals('resolved: test_data'));

      // Failure path with typed failure
      const networkFail = NetworkFailure('Connection timed out');
      final failResult = Result.failure<String>(networkFail);
      expect(failResult.isSuccess, isFalse);
      expect(failResult.isFailure, isTrue);
      expect(failResult.dataOrNull, isNull);
      expect(failResult.failureOrNull, isA<NetworkFailure>());
      expect(failResult.failureOrNull?.message, equals('Connection timed out'));

      final foldedFail = failResult.fold(
        (data) => 'resolved: $data',
        (fail) => 'caught: ${fail.message}',
      );
      expect(foldedFail, equals('caught: Connection timed out'));
    });

    test('AppLogger handles error, warn, and info calls without throwing', () {
      expect(() => AppLogger.info('Informational check'), returnsNormally);
      expect(() => AppLogger.warn('Warning check', Exception('warn_cause')), returnsNormally);
      expect(() => AppLogger.error('Error check', Exception('error_cause'), StackTrace.current), returnsNormally);
    });
  });
}

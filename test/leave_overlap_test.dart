import 'package:flutter_test/flutter_test.dart';
import 'package:ilk_mobil_uygulamam/leave_overlap.dart';
import 'package:ilk_mobil_uygulamam/services/api_service.dart';

void main() {
  test('recognizes supported leave overlap error codes', () {
    for (final code in const [
      'LEAVE_OVERLAP',
      'CONFLICTING_LEAVE_REQUEST',
      'OVERLAPPING_LEAVE_REQUEST',
    ]) {
      final details = LeaveOverlapDetails.fromException(
        ApiException('Çakışma', code: code, statusCode: 409),
      );

      expect(details, isNotNull, reason: code);
    }
  });

  test('recognizes HTTP 409 even when backend code is not available', () {
    final details = LeaveOverlapDetails.fromException(
      const ApiException('Çakışma', statusCode: 409),
    );

    expect(details, isNotNull);
  });

  test('does not treat other API failures as leave overlap', () {
    final details = LeaveOverlapDetails.fromException(
      const ApiException(
        'Sunucu hatası',
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      ),
    );

    expect(details, isNull);
  });

  test('formats conflicting leave date range from API errors', () {
    final details = LeaveOverlapDetails.fromException(
      const ApiException(
        'Çakışma',
        code: 'LEAVE_OVERLAP',
        statusCode: 409,
        errors: {
          'conflictingStartDate': ['2026-07-16'],
          'conflictingEndDate': ['2026-09-30'],
        },
      ),
    );

    expect(details?.formattedRange, '16.07.2026 – 30.09.2026');
  });
}

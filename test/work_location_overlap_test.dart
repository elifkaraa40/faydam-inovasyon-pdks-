import 'package:flutter_test/flutter_test.dart';
import 'package:ilk_mobil_uygulamam/services/api_service.dart';
import 'package:ilk_mobil_uygulamam/work_location_overlap.dart';

void main() {
  test('recognizes supported work location overlap error codes', () {
    for (final code in [
      'WORK_LOCATION_OVERLAP',
      'CONFLICTING_WORK_LOCATION_REQUEST',
      'OVERLAPPING_WORK_LOCATION_REQUEST',
    ]) {
      final details = WorkLocationOverlapDetails.fromException(
        ApiException('Çakışma', code: code, statusCode: 409),
      );
      expect(details, isNotNull);
    }
  });

  test('recognizes HTTP 409 when code is missing', () {
    final details = WorkLocationOverlapDetails.fromException(
      const ApiException('Çakışma', statusCode: 409),
    );
    expect(details, isNotNull);
  });

  test('does not treat validation errors as overlap', () {
    final details = WorkLocationOverlapDetails.fromException(
      const ApiException(
        'Tarih aralığı en fazla 90 gün olabilir.',
        code: 'WORK_LOCATION_REQUEST_REJECTED',
        statusCode: 400,
      ),
    );
    expect(details, isNull);
  });

  test('formats conflict dates and identifies leave conflicts', () {
    final details = WorkLocationOverlapDetails.fromException(
      const ApiException(
        'Çakışma',
        code: 'WORK_LOCATION_OVERLAP',
        statusCode: 409,
        errors: {
          'conflictingStartDate': ['2026-07-27'],
          'conflictingEndDate': ['2026-07-29'],
          'conflictingRecordType': ['Leave'],
        },
      ),
    );

    expect(details, isNotNull);
    expect(details!.formattedRange, '27.07.2026 – 29.07.2026');
    expect(details.isLeave, isTrue);
  });
}

import 'services/api_service.dart';

class WorkLocationOverlapDetails {
  const WorkLocationOverlapDetails({
    this.startDate,
    this.endDate,
    this.recordType,
  });

  static const _codes = {
    'WORK_LOCATION_OVERLAP',
    'CONFLICTING_WORK_LOCATION_REQUEST',
    'OVERLAPPING_WORK_LOCATION_REQUEST',
  };

  final DateTime? startDate;
  final DateTime? endDate;
  final String? recordType;

  bool get isLeave =>
      recordType?.trim().toLowerCase() == 'leave';

  static WorkLocationOverlapDetails? fromException(ApiException exception) {
    final code = exception.code?.trim().toUpperCase();
    if (!_codes.contains(code) && exception.statusCode != 409) return null;
    final errors = exception.errors;
    return WorkLocationOverlapDetails(
      startDate: _date(errors, const [
        'conflictingStartDate',
        'conflictingWorkLocationStartDate',
        'startDate',
      ]),
      endDate: _date(errors, const [
        'conflictingEndDate',
        'conflictingWorkLocationEndDate',
        'endDate',
      ]),
      recordType: _text(errors, const [
        'conflictingRecordType',
        'recordType',
      ]),
    );
  }

  String? get formattedRange {
    if (startDate == null || endDate == null) return null;
    return '${_format(startDate!)} – ${_format(endDate!)}';
  }

  static DateTime? _date(
    Map<String, dynamic>? errors,
    List<String> keys,
  ) {
    final raw = _text(errors, keys);
    return DateTime.tryParse(raw ?? '');
  }

  static String? _text(
    Map<String, dynamic>? errors,
    List<String> keys,
  ) {
    if (errors == null) return null;
    for (final key in keys) {
      final value = errors[key];
      final raw = value is List && value.isNotEmpty
          ? value.first?.toString()
          : value?.toString();
      if (raw != null && raw.trim().isNotEmpty) return raw;
    }
    return null;
  }

  static String _format(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${value.year}';
}

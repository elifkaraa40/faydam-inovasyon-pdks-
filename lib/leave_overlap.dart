import 'services/api_service.dart';

class LeaveOverlapDetails {
  const LeaveOverlapDetails({
    this.startDate,
    this.endDate,
  });

  static const _codes = {
    'LEAVE_OVERLAP',
    'CONFLICTING_LEAVE_REQUEST',
    'OVERLAPPING_LEAVE_REQUEST',
  };

  final DateTime? startDate;
  final DateTime? endDate;

  static LeaveOverlapDetails? fromException(ApiException exception) {
    final code = exception.code?.trim().toUpperCase();
    if (!_codes.contains(code) && exception.statusCode != 409) return null;
    final errors = exception.errors;
    return LeaveOverlapDetails(
      startDate: _date(errors, const [
        'conflictingStartDate',
        'conflictingLeaveStartDate',
        'startDate',
      ]),
      endDate: _date(errors, const [
        'conflictingEndDate',
        'conflictingLeaveEndDate',
        'endDate',
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
    if (errors == null) return null;
    for (final key in keys) {
      final value = errors[key];
      final raw = value is List && value.isNotEmpty
          ? value.first?.toString()
          : value?.toString();
      final parsed = DateTime.tryParse(raw ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _format(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${value.year}';
}

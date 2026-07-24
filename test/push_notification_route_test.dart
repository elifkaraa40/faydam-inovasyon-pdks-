import 'package:flutter_test/flutter_test.dart';
import 'package:ilk_mobil_uygulamam/services/push_notification_service.dart';

void main() {
  test('notification types navigate to their related screens', () {
    final service = PushNotificationService.instance;

    expect(service.routeForType('LeaveApproved'), 'leave_requests');
    expect(
      service.routeForType('AttendanceCorrectionRejected'),
      'attendance_corrections',
    );
    expect(
      service.routeForType('FieldWorkRequestApproved'),
      'work_locations',
    );
    expect(
      service.routeForType('LeaveRequestCreated'),
      'manager_approvals',
    );
    expect(service.routeForType('System'), 'notifications');
  });
}

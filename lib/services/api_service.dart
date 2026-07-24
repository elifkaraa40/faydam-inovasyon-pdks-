import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../models/break_models.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.errors,
  });
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String baseUrl = ApiConfig.baseUrl;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'authenticated_user';
  static const _deviceIdKey = 'device_installation_id';
  static String? _accessTokenCache;
  static String? _refreshTokenCache;
  static String? _deviceIdCache;
  static Map<String, dynamic>? _userCache;

  Future<Map<String, dynamic>> login(
      {required String email,
      required String password,
      String? deviceName}) async {
    final deviceId = await getDeviceId();
    final data = _map(await _send('POST', '/auth/login',
        body: {
          'email': email,
          'password': password,
          'deviceId': deviceId,
          'deviceName': deviceName ?? 'Faydam PDKS Mobil',
        },
        authenticated: false));
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> register(
      {required String fullName,
      required String email,
      required String password,
      String? deviceName}) async {
    final deviceId = await getDeviceId();
    final data = _map(await _send('POST', '/auth/register',
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'deviceId': deviceId,
          'deviceName': deviceName ?? 'Faydam PDKS Mobil',
        },
        authenticated: false));
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> scanAttendanceQr(
      {required String qrValue,
      required String occurredAt,
      required String deviceEventId}) async {
    final deviceId = await getDeviceId();
    return _map(await _send('POST', '/qr-attendance/scan', body: {
      'qrValue': qrValue,
      'occurredAt': occurredAt,
      'deviceEventId': deviceEventId,
      'deviceId': deviceId,
    }));
  }

  Future<Map<String, dynamic>> getTodayAttendance() async =>
      _map(await _send('GET', '/attendance/today'));

  Future<List<Map<String, dynamic>>> getAttendanceRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final query = Uri(queryParameters: {
      'from': _dateOnly(from),
      'to': _dateOnly(to),
    }).query;
    final value = await _send('GET', '/attendance?$query');
    if (value is! List) {
      throw const ApiException('Sunucudan geçersiz puantaj listesi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Uint8List> exportAttendance({
    required DateTime from,
    required DateTime to,
    required String format,
    required String language,
  }) async {
    final query = Uri(queryParameters: {
      'from': _dateOnly(from),
      'to': _dateOnly(to),
      'format': format,
      'language': language,
    }).query;
    return _getBytes('/attendance/export?$query');
  }

  Future<List<Map<String, dynamic>>> getWorkLocationRequests() async {
    final value = await _send('GET', '/work-locations/requests');
    if (value is! List) {
      throw const ApiException(
          'Sunucudan geçersiz çalışma konumu listesi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> createWorkLocationRequest({
    required String locationType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? projectName,
    String? customerName,
    String? fieldAddress,
  }) async {
    await _send('POST', '/work-locations/requests', body: {
      'locationType': locationType,
      'startDate': _dateOnly(startDate),
      'endDate': _dateOnly(endDate),
      'recurrenceType': 'EveryWorkday',
      'days': <String>[],
      'reason': reason,
      'projectName': projectName,
      'customerName': customerName,
      'fieldAddress': fieldAddress,
    });
  }

  Future<void> cancelWorkLocationRequest(Object id) async =>
      _send('DELETE', '/work-locations/requests/$id');

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final value = await _send('GET', '/notifications');
    if (value is! List) {
      throw const ApiException('Sunucudan geçersiz bildirim listesi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> markNotificationRead(Object id) async =>
      _send('POST', '/notifications/$id/read');

  Future<CurrentBreak> getCurrentBreak() async => CurrentBreak.fromJson(
        _map(await _send('GET', '/breaks/current')),
      );

  Future<CurrentBreak> startBreak() async => CurrentBreak.fromJson(
        _map(await _send('POST', '/breaks/start', body: {
          'deviceEventId': _deviceEventId('break-start'),
        })),
      );

  Future<CurrentBreak> endBreak(String breakId) async => CurrentBreak.fromJson(
        _map(await _send('POST', '/breaks/$breakId/end', body: {
          'deviceEventId': _deviceEventId('break-end'),
        })),
      );

  Future<List<BreakHistoryItem>> getBreakHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    final query = Uri(queryParameters: {
      'from': _dateOnly(from),
      'to': _dateOnly(to),
    }).query;
    final value = await _send('GET', '/breaks?$query');
    if (value is! List) {
      throw const ApiException('Sunucudan geçersiz mola geçmişi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => BreakHistoryItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<ActiveColleagueBreak>> getActiveColleagueBreaks() async {
    final value = await _send('GET', '/breaks/active-colleagues');
    if (value is! List) {
      throw const ApiException('Sunucudan geçersiz aktif mola listesi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => ActiveColleagueBreak.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> createLeaveRequest(
      {required String leaveType,
      required String startDate,
      required String endDate,
      required String reason,
      required String dayPortion}) async {
    await _send('POST', '/leave-requests', body: {
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
      'dayPortion': dayPortion.isEmpty ? 'FullDay' : dayPortion,
    });
  }

  Future<void> deleteLeaveRequest(Object requestId) async =>
      _send('DELETE', '/leave-requests/$requestId');

  Future<List<dynamic>> getLeaveRequests() async {
    final value = await _send('GET', '/leave-requests');
    if (value is List) return value;
    throw const ApiException('Sunucudan geçersiz izin listesi alındı.');
  }

  Future<List<Map<String, dynamic>>> getAttendanceCorrections() async {
    final value = await _send('GET', '/attendance-corrections');
    if (value is! List) {
      throw const ApiException(
          'Sunucudan geçersiz puantaj düzeltme listesi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> createAttendanceCorrection({
    required DateTime workDate,
    required String requestedEntry,
    required String requestedExit,
    required String reason,
  }) async {
    await _send('POST', '/attendance-corrections', body: {
      'correctionType': 1,
      'workDate': _dateOnly(workDate),
      // System.Text.Json'ın TimeOnly dönüştürücüsü saniye bilgisini bekler.
      'requestedEntry': _timeOnly(requestedEntry),
      'requestedExit': _timeOnly(requestedExit),
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> getUserProfile() async =>
      _map(await _send('GET', '/me'));

  Future<Map<String, dynamic>> updateUserProfile({
    required String? phoneNumber,
    required bool isEmailNotificationEnabled,
    required bool isSmsNotificationEnabled,
  }) async =>
      _map(await _send('PUT', '/me', body: {
        'phoneNumber': phoneNumber,
        'isEmailNotificationEnabled': isEmailNotificationEnabled,
        'isSmsNotificationEnabled': isSmsNotificationEnabled,
      }));

  Future<Uint8List> exportPersonalData() => _getBytes('/me/export');

  Future<Map<String, dynamic>> getAccountStatus() async =>
      _map(await _send('GET', '/me/status'));

  Future<List<Map<String, dynamic>>> getDeviceSessions() async {
    final value = await _send('GET', '/auth/devices');
    if (value is! List) {
      throw const ApiException(
          'Sunucudan geçersiz cihaz oturumu listesi alındı.');
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> logoutAllDevices() async {
    try {
      await _send('POST', '/auth/logout-all');
    } finally {
      await clearSession();
    }
  }

  Future<Map<String, dynamic>> getManagerDashboard() async =>
      _map(await _send('GET', '/manager/dashboard'));

  Future<Map<String, dynamic>> getManagerApprovalsSummary() async =>
      _map(await _send('GET', '/manager/approvals/summary'));

  Future<Map<String, dynamic>> getManagerApprovalItems(String kind) async =>
      _map(await _send('GET', '/manager/$kind?page=1&pageSize=50'));

  Future<void> reviewManagerItem({
    required String kind,
    required Object id,
    required bool approve,
    String? note,
  }) async {
    final path = kind == 'registrations'
        ? '/manager/registrations/$id/review'
        : '/manager/$kind/$id/review';
    await _send('POST', path,
        body: kind == 'registrations'
            ? {'approve': approve, 'note': note}
            : {'approve': approve, 'note': note});
  }

  Future<Map<String, dynamic>> getManagerPersonnelStatus({
    int page = 1,
    int pageSize = 100,
  }) async {
    final query = Uri(queryParameters: {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    }).query;
    return _map(await _send('GET', '/manager/personnel-status?$query'));
  }

  Future<bool> refreshSession() => _refreshSession();

  Future<void> clearSession() async {
    _accessTokenCache = null;
    _refreshTokenCache = null;
    _userCache = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userKey),
    ]);
  }

  Future<String?> getAccessToken() async {
    _accessTokenCache ??= await _storage.read(key: _accessTokenKey);
    return _accessTokenCache;
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    if (_userCache != null) return _userCache;
    final value = await _storage.read(key: _userKey);
    if (value == null || value.isEmpty) return null;
    _userCache = _map(jsonDecode(value));
    return _userCache;
  }

  Future<bool> hasSession() async =>
      (await getAccessToken())?.isNotEmpty == true;

  Future<void> logout() async {
    final refreshToken = await _getRefreshToken();
    final deviceId = await getDeviceId();
    try {
      if (refreshToken != null) {
        await _send('POST', '/auth/logout',
            body: {'refreshToken': refreshToken, 'deviceId': deviceId});
      }
    } finally {
      await clearSession();
    }
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body,
      bool authenticated = true,
      bool retryAfterRefresh = true}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final token = await getAccessToken();
      if (token == null) {
        throw const ApiException(
            'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
            code: 'UNAUTHENTICATED');
      }
      headers['Authorization'] = 'Bearer $token';
      headers['X-Device-Id'] = await getDeviceId();
    }
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(uri,
              headers: headers, body: body == null ? null : jsonEncode(body));
          break;
        case 'PUT':
          response = await _client.put(uri,
              headers: headers, body: body == null ? null : jsonEncode(body));
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw ArgumentError('Desteklenmeyen HTTP metodu: $method');
      }
    } catch (_) {
      throw const ApiException(
          'Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.');
    }
    if (response.statusCode == 401 &&
        authenticated &&
        retryAfterRefresh &&
        await _refreshSession()) {
      return _send(method, path, body: body, retryAfterRefresh: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFrom(response);
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Uint8List> _getBytes(
    String path, {
    bool retryAfterRefresh = true,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw const ApiException(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
        code: 'UNAUTHENTICATED',
      );
    }
    late http.Response response;
    try {
      response = await _client.get(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Accept': 'application/octet-stream',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      throw const ApiException(
        'Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.',
      );
    }
    if (response.statusCode == 401 &&
        retryAfterRefresh &&
        await _refreshSession()) {
      return _getBytes(path, retryAfterRefresh: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFrom(response);
    }
    return response.bodyBytes;
  }

  Future<bool> _refreshSession() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final deviceId = await getDeviceId();
      final data = _map(await _send('POST', '/auth/refresh',
          body: {'refreshToken': refreshToken, 'deviceId': deviceId},
          authenticated: false));
      await _saveSession(data);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    final user = data['user'];
    if (accessToken == null || refreshToken == null || user is! Map) {
      throw const ApiException('Sunucudan geçersiz oturum yanıtı alındı.');
    }
    _accessTokenCache = accessToken;
    _refreshTokenCache = refreshToken;
    _userCache = Map<String, dynamic>.from(user);
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userKey, value: jsonEncode(user)),
    ]);
  }

  Future<String?> _getRefreshToken() async {
    _refreshTokenCache ??= await _storage.read(key: _refreshTokenKey);
    return _refreshTokenCache;
  }

  Future<String> getDeviceId() async {
    if (_deviceIdCache?.isNotEmpty == true) return _deviceIdCache!;
    final stored = await _storage.read(key: _deviceIdKey);
    if (stored?.isNotEmpty == true) {
      _deviceIdCache = stored;
      return stored!;
    }
    final created = const Uuid().v4();
    _deviceIdCache = created;
    await _storage.write(key: _deviceIdKey, value: created);
    return created;
  }

  String _deviceEventId(String operation) =>
      '$operation-${DateTime.now().microsecondsSinceEpoch}';

  String _timeOnly(String value) =>
      value.trim().split(':').length == 2 ? '${value.trim()}:00' : value.trim();

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException('Sunucudan geçersiz yanıt alındı.');
  }

  ApiException _errorFrom(http.Response response) {
    try {
      final data = _map(jsonDecode(utf8.decode(response.bodyBytes)));
      final rawErrors = data['errors'];
      return ApiException(data['message']?.toString() ?? 'İşlem başarısız.',
          code: data['code']?.toString(),
          statusCode: response.statusCode,
          errors:
              rawErrors is Map ? Map<String, dynamic>.from(rawErrors) : null);
    } catch (_) {
      return ApiException('İşlem başarısız (${response.statusCode}).',
          statusCode: response.statusCode);
    }
  }
}

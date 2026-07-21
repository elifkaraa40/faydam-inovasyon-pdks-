import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
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
  static String? _accessTokenCache;
  static String? _refreshTokenCache;
  static Map<String, dynamic>? _userCache;

  Future<Map<String, dynamic>> login(
      {required String email,
      required String password,
      String? deviceName}) async {
    final data = _map(await _send('POST', '/auth/login',
        body: {
          'email': email,
          'password': password,
          'deviceName': deviceName,
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
    final data = _map(await _send('POST', '/auth/register',
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'deviceName': deviceName,
        },
        authenticated: false));
    await _saveSession(data);
    return data;
  }

  Future<Map<String, dynamic>> scanAttendanceQr(
          {required String qrValue,
          required String occurredAt,
          required String deviceEventId}) async =>
      _map(await _send('POST', '/qr-attendance/scan', body: {
        'qrValue': qrValue,
        'occurredAt': occurredAt,
        'deviceEventId': deviceEventId,
      }));

  Future<Map<String, dynamic>> getTodayAttendance() async =>
      _map(await _send('GET', '/attendance/today'));

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

  Future<Map<String, dynamic>> getUserProfile() async =>
      _map(await _send('GET', '/me'));

  Future<Map<String, dynamic>> getAccountStatus() async =>
      _map(await _send('GET', '/me/status'));

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
    try {
      if (refreshToken != null) {
        await _send('POST', '/auth/logout',
            body: {'refreshToken': refreshToken});
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

  Future<bool> _refreshSession() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final data = _map(await _send('POST', '/auth/refresh',
          body: {'refreshToken': refreshToken}, authenticated: false));
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

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException('Sunucudan geçersiz yanıt alındı.');
  }

  ApiException _errorFrom(http.Response response) {
    try {
      final data = _map(jsonDecode(utf8.decode(response.bodyBytes)));
      return ApiException(data['message']?.toString() ?? 'İşlem başarısız.',
          code: data['code']?.toString(), statusCode: response.statusCode);
    } catch (_) {
      return ApiException('İşlem başarısız (${response.statusCode}).',
          statusCode: response.statusCode);
    }
  }
}

// TODO Implement this library.import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

class ApiService {
  ApiService({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _addInterceptors();
  }

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'access_token_expires_at';

  bool _refreshInProgress = false;

  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isPublicRequest =
              options.path == '/auth/login' || options.path == '/auth/refresh';

          if (!isPublicRequest) {
            final accessToken = await getAccessToken();

            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final requestOptions = error.requestOptions;
          final wasRetried = requestOptions.extra['alreadyRetried'] == true;
          final isRefreshRequest = requestOptions.path == '/auth/refresh';

          if (statusCode == 401 &&
              !wasRetried &&
              !isRefreshRequest &&
              !_refreshInProgress) {
            try {
              _refreshInProgress = true;

              final refreshSuccessful = await refreshSession();

              if (refreshSuccessful) {
                final newAccessToken = await getAccessToken();

                requestOptions.extra['alreadyRetried'] = true;
                requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final response = await _dio.fetch<dynamic>(requestOptions);

                handler.resolve(response);
                return;
              }
            } catch (_) {
              await clearSession();
            } finally {
              _refreshInProgress = false;
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // OTURUM VE TOKEN İŞLEMLERİ
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String deviceName,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email.trim(),
          // Parolaya trim uygulanmamalıdır.
          'password': password,
          'deviceName': deviceName,
        },
      );

      final data = response.data;

      if (data == null) {
        throw Exception(
          'Sunucudan geçerli bir giriş cevabı alınamadı.',
        );
      }

      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final expiresAt = data['expiresAt']?.toString() ?? '';

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw Exception(
          'Sunucu geçerli oturum bilgisi döndürmedi.',
        );
      }

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      return data;
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  Future<bool> refreshSession() async {
    final refreshToken = await _secureStorage.read(
      key: _refreshTokenKey,
    );

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      // Ayrı Dio kullanılması refresh isteğinin kendi
      // interceptor döngüsüne girmesini önler.
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final data = response.data;

      if (data == null) {
        await clearSession();
        return false;
      }

      final newAccessToken = data['accessToken']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString() ?? '';
      final expiresAt = data['expiresAt']?.toString() ?? '';

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        await clearSession();
        return false;
      }

      await _saveSession(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresAt: expiresAt,
      );

      return true;
    } on DioException {
      await clearSession();
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.read(
      key: _refreshTokenKey,
    );

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post<void>(
          '/auth/logout',
          data: {
            'refreshToken': refreshToken,
          },
        );
      }
    } on DioException {
      // Sunucuya ulaşılamasa bile cihazdaki oturum silinir.
    } finally {
      await clearSession();
    }
  }

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required String expiresAt,
  }) async {
    await Future.wait([
      _secureStorage.write(
        key: _accessTokenKey,
        value: accessToken,
      ),
      _secureStorage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      ),
      _secureStorage.write(
        key: _expiresAtKey,
        value: expiresAt,
      ),
    ]);
  }

  Future<String?> getAccessToken() {
    return _secureStorage.read(
      key: _accessTokenKey,
    );
  }

  Future<String?> getRefreshToken() {
    return _secureStorage.read(
      key: _refreshTokenKey,
    );
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  Future<void> clearSession() {
    return _secureStorage.deleteAll();
  }

  // ------------------------------------------------------------
  // QR İLE GİRİŞ-ÇIKIŞ
  // ------------------------------------------------------------

  /// Doğru ve yeni QR endpoint'idir.
  ///
  /// QR okuyucudan gelen rawValue hiçbir şekilde
  /// parçalanmadan veya değiştirilmeden qrValue olarak gönderilir.
  Future<Map<String, dynamic>> scanAttendanceQr({
    required String qrValue,
    required String occurredAt,
    required String deviceEventId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/qr-attendance/scan',
        data: {
          'qrValue': qrValue,
          'occurredAt': occurredAt,
          'deviceEventId': deviceEventId,
        },
      );

      final data = response.data;

      if (data == null) {
        throw Exception(
          'Sunucudan geçiş sonucu alınamadı.',
        );
      }

      return data;
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  /// Bu metot yalnızca mevcut eski QrScreen kodunun
  /// analiz sırasında bozulmaması için geçici olarak tutulmuştur.
  ///
  /// Yeni QR sistemi bu metodu kullanmamalıdır.
  /// QrScreen, scanAttendanceQr metoduna geçirilince silinebilir.
  Future<void> createAttendanceEvent({
    required String eventType,
    required String occurredAt,
    required String deviceEventId,
    required int zoneId,
  }) async {
    try {
      await _dio.post<void>(
        '/attendance/events',
        data: {
          'eventType': eventType,
          'occurredAt': occurredAt,
          'deviceEventId': deviceEventId,
          'zoneId': zoneId,
        },
      );
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/attendance/today',
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  // ------------------------------------------------------------
  // İZİN İŞLEMLERİ
  // ------------------------------------------------------------

  Future<List<dynamic>> getLeaveRequests() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/leave-requests',
      );

      return response.data ?? <dynamic>[];
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  Future<Map<String, dynamic>> createLeaveRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/leave-requests',
        data: {
          'leaveType': leaveType,
          'startDate': startDate,
          'endDate': endDate,
          'reason':
              reason == null || reason.trim().isEmpty ? null : reason.trim(),
        },
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  /// Backend izin kimliği Guid olduğu için requestId
  /// String veya Object olarak kabul edilir.
  Future<void> deleteLeaveRequest(
    Object requestId,
  ) async {
    try {
      await _dio.delete<void>(
        '/leave-requests/${requestId.toString()}',
      );
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  // ------------------------------------------------------------
  // PROFİL
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/me',
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/me',
        data: {
          'fullName': fullName.trim(),
          'phoneNumber':
              phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
        },
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw Exception(_getErrorMessage(error));
    }
  }

  // ------------------------------------------------------------
  // HATA YÖNETİMİ
  // ------------------------------------------------------------

  String _getErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String? errorCode;
    String? serverMessage;

    if (responseData is Map) {
      errorCode = responseData['code']?.toString();
      serverMessage = responseData['message']?.toString();
    }

    switch (errorCode) {
      case 'INVALID_CREDENTIALS':
        return 'E-posta veya parola hatalı.';

      case 'INVALID_OR_INACTIVE_QR':
        return 'QR kod geçersiz, yenilenmiş veya kullanım dışı.';

      case 'DUPLICATE_EVENT':
        return 'Bu geçiş daha önce kaydedilmiş.';

      case 'INVALID_EVENT_TIME':
        return 'Telefon tarihi veya saati geçersiz.';

      case 'INVALID_REFRESH_TOKEN':
      case 'UNAUTHENTICATED':
        return 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';

      case 'INVALID_LEAVE_REQUEST':
        return serverMessage ?? 'İzin talebi bilgileri geçersiz.';

      case 'OVERLAPPING_LEAVE_REQUEST':
        return serverMessage ??
            'Seçilen tarihlerde başka bir izin talebi bulunuyor.';

      case 'LEAVE_REQUEST_NOT_CANCELLABLE':
        return serverMessage ?? 'Bu izin talebi artık iptal edilemez.';
    }

    if (statusCode == 401) {
      return 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.';
    }

    if (statusCode == 403) {
      return 'Bu işlem için yetkiniz bulunmuyor.';
    }

    if (statusCode == 404) {
      return 'İstenen kayıt bulunamadı.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'Sunucuda bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Sunucuya ulaşılamadı. API bağlantısını ve Wi-Fi ağını kontrol edin.';

      case DioExceptionType.cancel:
        return 'İstek iptal edildi.';

      default:
        return serverMessage ?? 'İşlem sırasında beklenmeyen bir hata oluştu.';
    }
  }
}

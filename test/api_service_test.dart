import 'package:flutter_test/flutter_test.dart';
import 'package:ilk_mobil_uygulamam/config/api_config.dart';
import 'package:ilk_mobil_uygulamam/services/api_service.dart';

void main() {
  test('API base URL points to the versioned backend contract', () {
    expect(ApiConfig.baseUrl, endsWith('/api/v1'));
  });

  test('API errors expose the backend message to the UI', () {
    const error = ApiException(
      'Geçersiz kimlik bilgileri.',
      code: 'INVALID_CREDENTIALS',
      statusCode: 401,
    );

    expect(error.toString(), 'Geçersiz kimlik bilgileri.');
    expect(error.code, 'INVALID_CREDENTIALS');
    expect(error.statusCode, 401);
  });
}

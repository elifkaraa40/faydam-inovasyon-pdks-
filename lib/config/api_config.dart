class ApiConfig {
static const String baseUrl = String.fromEnvironment(
'API_BASE_URL',
defaultValue: 'http://10.0.2.2:5055/api/v1',
);
}
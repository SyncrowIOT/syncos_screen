import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiEndpoints {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  static const login = '/authentication/user/login';
  static const refreshToken = '/authentication/refresh-token';
}

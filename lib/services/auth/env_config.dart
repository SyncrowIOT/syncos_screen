import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static String get defaultEmail => dotenv.env['DEFAULT_EMAIL'] ?? '';
  static String get defaultPassword => dotenv.env['DEFAULT_PASSWORD'] ?? '';
}

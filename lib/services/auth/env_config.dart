import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads default POC login credentials from the gitignored `.env.local`
/// file (loaded in `bootstrap.dart` on top of `.env.staging`).
abstract final class EnvConfig {
  static String get defaultEmail => dotenv.env['DEFAULT_EMAIL'] ?? '';
  static String get defaultPassword => dotenv.env['DEFAULT_PASSWORD'] ?? '';
}

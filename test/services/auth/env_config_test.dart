import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncos_screen/services/auth/env_config.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString: 'DEFAULT_EMAIL=test@example.com\nDEFAULT_PASSWORD=secret123',
    );
  });

  test('defaultEmail reads DEFAULT_EMAIL from dotenv', () {
    expect(EnvConfig.defaultEmail, 'test@example.com');
  });

  test('defaultPassword reads DEFAULT_PASSWORD from dotenv', () {
    expect(EnvConfig.defaultPassword, 'secret123');
  });

  test('falls back to empty string when keys are absent', () {
    dotenv.loadFromString(isOptional: true);
    expect(EnvConfig.defaultEmail, '');
    expect(EnvConfig.defaultPassword, '');
  });
}

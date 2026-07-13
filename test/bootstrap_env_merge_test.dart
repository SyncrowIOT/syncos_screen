import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'passing the live dotenv.env reference as mergeWith loses prior keys '
    '(clean() clears the same map before it is read back)',
    () {
      final env = DotEnv();
      env
        ..loadFromString(envString: 'BASE_URL=https://api.example.com')
        ..loadFromString(
          envString: 'DEFAULT_EMAIL=a@b.com',
          mergeWith: env.env,
        );

      expect(env.env['BASE_URL'], isNull);
    },
  );

  test(
    'passing a copy of dotenv.env as mergeWith preserves prior keys',
    () {
      final env = DotEnv()
        ..loadFromString(envString: 'BASE_URL=https://api.example.com');

      env.loadFromString(
        envString: 'DEFAULT_EMAIL=a@b.com',
        mergeWith: Map<String, String>.from(env.env),
      );

      expect(env.env['BASE_URL'], 'https://api.example.com');
      expect(env.env['DEFAULT_EMAIL'], 'a@b.com');
    },
  );
}

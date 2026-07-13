import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/dio_client.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(isOptional: true);
  });

  test('tokenRefreshService returns the same instance on repeated access', () {
    DioClient.instance;
    final first = DioClient.tokenRefreshService;
    final second = DioClient.tokenRefreshService;
    expect(identical(first, second), isTrue);
    expect(first, isA<RemoteTokenRefreshService>());
  });
}

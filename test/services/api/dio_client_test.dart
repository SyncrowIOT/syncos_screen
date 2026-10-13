import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/dio_client.dart';
import 'package:syncos_screen/services/api/notifying_token_store_decorator.dart';

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

  test(
    'configureSessionExpiredHandler wires a handler debugInvokeSessionExpiredHandler can trigger',
    () {
      var callCount = 0;
      DioClient.configureSessionExpiredHandler(() => callCount++);

      DioClient.debugInvokeSessionExpiredHandler();

      expect(callCount, 1);
    },
  );

  test(
    'configureSessionRecoveryWaiter wires a waiter '
    'awaitSessionRecovery can trigger',
    () async {
      DioClient.configureSessionRecoveryWaiter(() async => true);

      expect(await DioClient.awaitSessionRecovery(), isTrue);
    },
  );

  test(
    'tokenStore returns the same notifying decorator on repeated access',
    () {
      final first = DioClient.tokenStore;
      final second = DioClient.tokenStore;
      expect(identical(first, second), isTrue);
      expect(first, isA<NotifyingTokenStoreDecorator>());
    },
  );
}

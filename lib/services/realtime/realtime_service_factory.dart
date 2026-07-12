import 'dart:async';

import 'package:device_manager/device_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:networking/networking.dart';
import 'package:socketio_client/socketio_client.dart';
import 'package:syncos_screen/secure_storage.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/auth_session_memory.dart';
import 'package:syncos_screen/services/api/dio_client.dart';
import 'package:syncos_screen/services/api/secure_token_store.dart';

abstract final class RealtimeServiceFactory {
  static WebSocketDeviceStatusRealtimeService? _instance;
  static String? _lastAuthorizationHeader;
  static AppLifecycleListener? _lifecycleListener;

  static void registerLifecycleDisposal(WidgetsBinding binding) {
    _lifecycleListener ??= AppLifecycleListener(
      binding: binding,
      onDetach: () => unawaited(dispose()),
    );
  }

  static Future<WebSocketDeviceStatusRealtimeService> create() async {
    final webSocketUri = Uri.parse(dotenv.env['WS_URL']!);
    final storedAccessToken = await flutterSecureStorage.read(
      key: 'access_token',
    );
    final accessToken =
        storedAccessToken != null && storedAccessToken.isNotEmpty
            ? storedAccessToken
            : AuthSessionMemory.accessToken;
    final authorizationHeader = accessToken.isNotEmpty
        ? 'Bearer $accessToken'
        : null;

    if (_instance != null && _lastAuthorizationHeader != authorizationHeader) {
      final previous = _instance;
      _instance = null;
      await previous?.dispose();
    }

    _lastAuthorizationHeader = authorizationHeader;
    final webSocketioClientServiceCreator = _WebSocketioClientServiceCreator(
      webSocketUri: webSocketUri,
    );

    return _instance ??= WebSocketDeviceStatusRealtimeService(
      socketClient: TokenRefreshSocketioClientServiceDecorator(
        tokenRefresher: RemoteTokenRefreshService(
          dio: DioClient.instance,
          tokenStore: SecureTokenStore(),
          refreshPath: ApiEndpoints.refreshToken,
        ).call,
        socketioClientServiceCreator: webSocketioClientServiceCreator,
        tokenExpiredEvent: 'err',
        socketioClientService: webSocketioClientServiceCreator.call(
          SocketioClientServiceCreatorParam(token: authorizationHeader ?? ''),
        ),
      ),
    );
  }

  static Future<void> dispose() async {
    final instance = _instance;
    _instance = null;
    _lastAuthorizationHeader = null;
    if (instance != null) {
      await instance.dispose();
    }
  }
}

final class _WebSocketioClientServiceCreator
    implements SocketioClientServiceCreator {
  _WebSocketioClientServiceCreator({required this._webSocketUri});

  final Uri _webSocketUri;

  @override
  SocketioClientService call(SocketioClientServiceCreatorParam param) {
    final authorizationHeader = param.token;
    return SocketIoClientServiceImpl.fromOptions(
      SocketioClientOptions(
        url: _webSocketUri,
        path: '/device-gateway',
        authorizationHeader: authorizationHeader,
        transports: ['websocket'],
      ),
    );
  }
}

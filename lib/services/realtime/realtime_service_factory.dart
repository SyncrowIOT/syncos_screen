import 'package:device_manager/device_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:socketio_client/socketio_client.dart';
import 'package:syncos_screen/services/api/api_links_endpoints.dart';
import 'package:syncos_screen/services/api/dio_client.dart';
import 'package:syncos_screen/services/api/notifying_token_store_decorator.dart';
import 'package:syncos_screen/services/auth/remote_token_refresh_service_adapter.dart';
import 'package:syncos_screen/services/auth/token_refresh_service.dart';
import 'package:syncos_screen/services/realtime/reconnect_safe_socketio_client_service_decorator.dart';
import 'package:syncos_screen/services/realtime/recovering_socket_token_refresher.dart';
import 'package:syncos_screen/services/realtime/remote_socketio_client_service_creator.dart';
import 'package:syncos_screen/services/realtime/socket_access_token_sync.dart';

abstract final class RealtimeServiceFactory {
  static DeviceStatusRealtimeService? _instance;

  static DeviceStatusRealtimeService get instance => _instance ??= create(
    tokenStore: DioClient.tokenStore,
    tokenRefreshService: RemoteTokenRefreshServiceAdapter(
      tokenRefreshService: DioClient.tokenRefreshService,
    ),
    awaitRecovery: DioClient.awaitSessionRecovery,
    socketioClientServiceCreator: RemoteSocketioClientServiceCreator(
      webSocketUri: Uri.parse(ApiEndpoints.webSocketUrl),
    ),
  );

  @visibleForTesting
  static DeviceStatusRealtimeService create({
    required NotifyingTokenStoreDecorator tokenStore,
    required TokenRefreshService tokenRefreshService,
    required Future<bool> Function() awaitRecovery,
    required SocketioClientServiceCreator socketioClientServiceCreator,
  }) {
    final initialToken = tokenStore.currentAccessToken;
    final tokenRefreshDecorator = TokenRefreshSocketioClientServiceDecorator(
      socketioClientService: socketioClientServiceCreator(
        SocketioClientServiceCreatorParam(token: initialToken),
      ),
      tokenRefresher: RecoveringSocketTokenRefresher(
        tokenRefreshService: tokenRefreshService,
        tokenStore: tokenStore,
        awaitRecovery: awaitRecovery,
      ).call,
      socketioClientServiceCreator: socketioClientServiceCreator,
      tokenExpiredEvent: 'err',
    );
    SocketAccessTokenSync(
      accessTokenWrites: tokenStore.accessTokenWrites,
      applyAccessToken: tokenRefreshDecorator.applyAccessToken,
      initialToken: initialToken,
    );
    return WebSocketDeviceStatusRealtimeService(
      socketClient: ReconnectSafeSocketioClientServiceDecorator(
        decoratee: tokenRefreshDecorator,
        suppressTokenExpiredErrors: true,
      ),
    );
  }
}

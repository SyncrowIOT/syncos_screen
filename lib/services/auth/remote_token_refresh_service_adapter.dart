import 'package:networking/networking.dart';
import 'package:syncos_screen/services/auth/token_refresh_service.dart';

final class RemoteTokenRefreshServiceAdapter implements TokenRefreshService {
  RemoteTokenRefreshServiceAdapter({required this._tokenRefreshService});

  final RemoteTokenRefreshService _tokenRefreshService;

  @override
  Future<String> call() => _tokenRefreshService.call();
}

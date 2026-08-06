import 'package:networking/networking.dart';
import 'package:syncos_screen/services/api/dio_client.dart';

abstract final class NetworkingServiceFactory {
  const NetworkingServiceFactory._();

  static final NetworkingService _instance = DioNetworkingService(
    dio: DioClient.instance,
  );

  static NetworkingService create() => _instance;
}

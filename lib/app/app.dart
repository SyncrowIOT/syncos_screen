import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncos_screen/app/router/app_router.dart';
import 'package:syncos_screen/app/router/auth_controller.dart';
import 'package:syncos_screen/l10n/l10n.dart';
import 'package:syncos_screen/services/api/dio_client.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';
import 'package:syncos_screen/services/api/secure_token_store.dart';
import 'package:syncos_screen/services/auth/session_bootstrapper.dart';

const _initialDevice = Device(
  uuid: '89c096bb-c291-432a-91e6-da3eb6b32226',
  name: 'Power Clamp',
  productType: ProductType.powerClamp,
  productUuid: '',
  productName: 'Power Clamp',
  subspaceName: '',
  subspaceUuid: '',
  online: true,
  icon: '',
  spaces: [],
);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(
      ensureAuthenticated: SessionBootstrapper(
        tokenStore: SecureTokenStore(),
        tokenRefreshService: DioClient.tokenRefreshService,
        loginService: RemoteLoginService(
          networkingService: NetworkingServiceFactory.create(),
        ),
      ).ensureAuthenticated,
    );
    _router = buildAppRouter(
      authController: _authController,
      initialDevice: _initialDevice,
    );
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.light();
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: appTheme.colors.text.brand,
        ),
        extensions: [appTheme],
        appBarTheme: AppBarTheme(
          backgroundColor: appTheme.colors.background.neutralPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

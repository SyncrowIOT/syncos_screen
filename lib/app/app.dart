import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/app/auth_gate.dart';
import 'package:syncos_screen/features/devices/power_clamp/presentation/views/power_clamp_view.dart';
import 'package:syncos_screen/l10n/l10n.dart';
import 'package:syncos_screen/services/api/dio_client.dart';
import 'package:syncos_screen/services/api/networking_service_factory.dart';
import 'package:syncos_screen/services/api/secure_token_store.dart';
import 'package:syncos_screen/services/auth/session_bootstrapper.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.light();
    return MaterialApp(
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
      home: AuthGate(
        ensureAuthenticated: SessionBootstrapper(
          tokenStore: SecureTokenStore(),
          tokenRefreshService: DioClient.tokenRefreshService,
          loginService: RemoteLoginService(
            networkingService: NetworkingServiceFactory.create(),
          ),
        ).ensureAuthenticated,
        child: const PowerClampView(
          device: Device(
            uuid: '6b54c0d5-906e-4836-b63c-de96b515c640',
            name: 'Power Clamp',
            productType: ProductType.powerClamp,
            productUuid: '',
            productName: 'Power Clamp',
            subspaceName: '',
            subspaceUuid: '',
            online: true,
            icon: '',
            spaces: [],
          ),
        ),
      ),
    );
  }
}

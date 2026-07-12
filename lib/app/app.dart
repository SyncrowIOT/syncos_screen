import 'package:design_system/design_system.dart';
import 'package:devices/devices.dart';
import 'package:flutter/material.dart';
import 'package:syncos_screen/features/devices/view/widgets/power_clamp/power_clamp_page.dart';
import 'package:syncos_screen/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.light();
    return MaterialApp(
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
      home: const PowerClampPage(
        device: Device(
          uuid: 'REPLACE_WITH_DEVICE_UUID',
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
    );
  }
}

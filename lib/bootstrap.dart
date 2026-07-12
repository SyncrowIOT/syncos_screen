import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncos_screen/services/realtime/realtime_service_factory.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.staging');
  try {
    await dotenv.load(fileName: '.env.local', mergeWith: dotenv.env);
  } on Object catch (error, stackTrace) {
    log('No .env.local found, skipping default credentials.',
        error: error, stackTrace: stackTrace);
  }
  RealtimeServiceFactory.registerLifecycleDisposal(widgetsBinding);

  runApp(await builder());
}

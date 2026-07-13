import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncos_screen/firebase_options.dart';
import 'package:syncos_screen/services/realtime/realtime_service_factory.dart';

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required String environment,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: '.env.$environment');
  try {
    await dotenv.load(
      fileName: '.env.local.$environment',
      mergeWith: Map<String, String>.from(dotenv.env),
    );
  } on Object catch (error, stackTrace) {
    log(
      'No .env.local.$environment found, skipping default credentials.',
      error: error,
      stackTrace: stackTrace,
    );
  }
  RealtimeServiceFactory.registerLifecycleDisposal(widgetsBinding);

  runApp(await builder());
}

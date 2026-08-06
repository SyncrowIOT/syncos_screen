import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncos_screen/firebase_options.dart';

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required String environment,
}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: 'env/.env.$environment');
  try {
    await dotenv.load(
      fileName: 'env/.env.local.$environment',
      mergeWith: Map<String, String>.from(dotenv.env),
    );
  } on Object catch (error, stackTrace) {
    log(
      'No env/.env.local.$environment found, skipping default credentials.',
      error: error,
      stackTrace: stackTrace,
    );
  }

  runApp(await builder());
}

import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:syncos_screen/firebase_options.dart';

String buildNumber = 'N/A';

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required String environment,
}) async {
  BindingBase.debugZoneErrorsAreFatal = true;

  if (kDebugMode) {
    WidgetsFlutterBinding.ensureInitialized();
  } else {
    SentryWidgetsFlutterBinding.ensureInitialized();
  }
  final capturedBindingZone = Zone.current;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: 'env/.env.$environment');
  await dotenv.load(
    fileName: 'env/.env.local.$environment',
    mergeWith: Map<String, String>.from(dotenv.env),
    isOptional: true,
  );

  final packageInfo = await PackageInfo.fromPlatform();
  buildNumber = '${packageInfo.version}+${packageInfo.buildNumber}';
  final dsn = dotenv.env['SENTRY_DSN']?.trim() ?? '';
  final sentryEnvironment = dotenv.env['ENV_NAME'] ?? environment;

  Future<void> startApp() async {
    if (kDebugMode || dsn.isEmpty) {
      FlutterError.onError = (details) {
        log(details.exceptionAsString(), stackTrace: details.stack);
      };
    }

    final app = await builder();
    capturedBindingZone.run(() => runApp(app));
  }

  if (kDebugMode || dsn.isEmpty) {
    runZonedGuarded(
      () {
        unawaited(startApp());
      },
      (error, stackTrace) {
        log('Error: $error', name: 'Main');
        log('StackTrace: $stackTrace', name: 'Main');
      },
    );
    return;
  }

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = dsn
        ..environment = sentryEnvironment
        ..tracesSampleRate = 1.0
        ..enableAutoPerformanceTracing = true
        ..release =
            'syncos_screen@${packageInfo.version}+${packageInfo.buildNumber}';
    },
    appRunner: () async {
      await startApp();
    },
  );
}

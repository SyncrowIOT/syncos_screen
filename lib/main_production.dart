import 'package:syncos_screen/app/app.dart';
import 'package:syncos_screen/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App(), environment: 'production');
}

import 'package:devices/devices.dart';
import 'package:go_router/go_router.dart';
import 'package:syncos_screen/app/router/auth_controller.dart';
import 'package:syncos_screen/app/router/power_clamp_route.dart';
import 'package:syncos_screen/app/screens/auth_error_screen.dart';
import 'package:syncos_screen/app/screens/splash_screen.dart';

String? authGateRedirect(AuthController authController, GoRouterState state) {
  final atSplash = state.matchedLocation == '/splash';
  final atAuthError = state.matchedLocation == '/auth-error';

  switch (authController.status) {
    case AuthStatus.loading:
      return atSplash ? null : '/splash';
    case AuthStatus.error:
      return atAuthError ? null : '/auth-error';
    case AuthStatus.authenticated:
      return (atSplash || atAuthError) ? '/' : null;
  }
}

GoRouter buildAppRouter({
  required AuthController authController,
  required Device initialDevice,
}) {
  return GoRouter(
    initialLocation: '/',
    initialExtra: initialDevice,
    refreshListenable: authController,
    redirect: (context, state) => authGateRedirect(authController, state),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth-error',
        builder: (context, state) => AuthErrorScreen(
          onRetry: authController.retry,
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) =>
            PowerClampRoute(device: state.extra! as Device),
      ),
    ],
  );
}

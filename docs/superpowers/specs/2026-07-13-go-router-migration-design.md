# go_router Migration: Auth Gate + Power Clamp Bloc Creation

## Context

The app currently has no routing package and no navigation calls anywhere in
`lib/`. `lib/app/app.dart` hard-codes `MaterialApp.home` to an `AuthGate`
wrapping a single `const PowerClampView(device: ...)` — the only device
screen that exists. `AuthGate` (`lib/app/auth_gate.dart`) is a `StatefulWidget`
that runs `ensureAuthenticated()` in `initState` and uses a `FutureBuilder` to
show a spinner, the child, or an inline "Unable to sign in" + Retry UI.

`PowerClampView` (`lib/features/devices/power_clamp/presentation/views/power_clamp_view.dart`)
similarly uses `initState` + `FutureBuilder` to call
`DeviceManagerFactory.create<PowerClampStatusModel>()` (which awaits
`RealtimeServiceFactory.create()` internally) and then wraps
`PowerClampForm` in a `MultiBlocProvider` with the resulting
`DevicesManagerBloc` and a new `PowerClampDeviceHistoryBloc`.

This spec introduces `go_router` and uses it to own both of these concerns —
the auth gate and the per-route bloc creation — instead of ad-hoc
`FutureBuilder`s in widget `initState`/`build`. This is architectural prep:
today there is still only one route (`power_clamp`) and one device (a
hardcoded const literal), but the structure should make it straightforward to
add a device-list screen and additional device types later without
duplicating this pattern.

## Non-goals

- No device-list screen, login screen, or additional device types are being
  built now.
- No change to `SessionBootstrapper`, `DeviceManagerFactory`, or any
  service/bloc internals — only where/how they're invoked.

## Design

### 1. New files / removed files

- `pubspec.yaml`: add `go_router` dependency.
- `lib/app/router/auth_controller.dart` (new): `AuthController extends ChangeNotifier`.
- `lib/app/router/app_router.dart` (new): builds the `GoRouter` instance.
- `lib/app/router/power_clamp_route.dart` (new): route-level widget that owns
  bloc creation for the power clamp route.
- `lib/app/screens/splash_screen.dart` (new): loading UI, shown at `/splash`.
- `lib/app/screens/auth_error_screen.dart` (new): "Unable to sign in" + Retry
  UI, shown at `/auth-error`.
- `lib/app/auth_gate.dart` — deleted; superseded by `AuthController` +
  redirect logic + the two new screens.
- `lib/features/devices/power_clamp/presentation/views/power_clamp_view.dart`
  — deleted; its logic moves into `power_clamp_route.dart`.
- `lib/app/app.dart` — becomes `MaterialApp.router(routerConfig: appRouter)`.

### 2. Auth flow (`AuthController` + redirect)

```dart
enum AuthStatus { loading, authenticated, error }

class AuthController extends ChangeNotifier {
  AuthController({required Future<bool> Function() ensureAuthenticated})
      : _ensureAuthenticated = ensureAuthenticated {
    _run();
  }

  final Future<bool> Function() _ensureAuthenticated;
  AuthStatus status = AuthStatus.loading;

  Future<void> _run() async {
    status = AuthStatus.loading;
    notifyListeners();
    final ok = await _ensureAuthenticated();
    status = ok ? AuthStatus.authenticated : AuthStatus.error;
    notifyListeners();
  }

  void retry() => _run();
}
```

`GoRouter` is constructed with `refreshListenable: authController` and a
`redirect` callback:

- `status == loading` → redirect to `/splash` (unless already there)
- `status == error` → redirect to `/auth-error`
- `status == authenticated` and current location is `/splash` or
  `/auth-error` → redirect to `/`
- otherwise → no redirect

Because `refreshListenable` triggers `redirect` re-evaluation on every
`notifyListeners()`, calling `authController.retry()` from the
`/auth-error` screen automatically navigates back to `/` once
authentication succeeds — no manual `context.go(...)` needed at the retry
call site.

`SplashScreen` and `AuthErrorScreen` reproduce today's `AuthGate` UI
(spinner; "Unable to sign in" + `ElevatedButton` calling
`authController.retry()`), just as standalone route widgets instead of
branches inside one `FutureBuilder`.

### 3. Route table

```dart
GoRouter appRouter({required AuthController authController, required Device initialDevice}) {
  return GoRouter(
    initialLocation: '/',
    initialExtra: initialDevice,
    refreshListenable: authController,
    redirect: (context, state) { /* as above */ },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth-error', builder: (_, __) => AuthErrorScreen(onRetry: authController.retry)),
      GoRoute(
        path: '/',
        builder: (context, state) => PowerClampRoute(device: state.extra! as Device),
      ),
    ],
  );
}
```

### 4. Bloc creation extraction (`PowerClampRoute`)

`PowerClampRoute` is a `StatefulWidget` taking `device` as a constructor
param. Its `initState`/`build` are a direct move of the current
`PowerClampView` logic:

- `initState`: kick off
  `DeviceManagerFactory.create<PowerClampStatusModel>(deviceUuid: device.uuid, fromStatusList: ...)`
  and store the `Future`.
- `build`: `FutureBuilder` — loading spinner while pending; error text on
  failure; on success, `MultiBlocProvider` with `BlocProvider.value` for the
  resolved `DevicesManagerBloc` and a `BlocProvider` creating
  `PowerClampDeviceHistoryBloc` (same `DebouncedPowerClampDeviceHistoryService`
  / `RemotePowerClampDeviceHistoryService` wiring as today), rendering
  `PowerClampForm(device: device)`.

No behavior change versus today's `PowerClampView` — only the source of
`device` (constructor param from route `extra`, instead of a `StatefulWidget`
field) and its registration point (a `GoRoute` builder instead of
`MaterialApp.home`).

### 5. Device source

The `Device` passed to `/` is still the same hardcoded `const Device(...)`
literal that exists today in `app.dart`, now supplied via `GoRouter`'s
`initialExtra` rather than as a widget constructor argument. The `/` route's
`builder` reads it from `GoRouterState.extra`, so once a real device source
(e.g. a device-list screen) exists, it can `context.go('/', extra: device)`
with no route-table changes.

### 6. `app.dart`

```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController(
      ensureAuthenticated: SessionBootstrapper(...).ensureAuthenticated,
    );
    final router = appRouter(
      authController: authController,
      initialDevice: const Device(...), // same literal as today
    );
    return MaterialApp.router(
      routerConfig: router,
      theme: ...,
      localizationsDelegates: ...,
      supportedLocales: ...,
    );
  }
}
```

`AuthController` is created once per `App` build. Since `App` is a
`StatelessWidget` built once at the root, this matches today's lifecycle
(one `SessionBootstrapper`/auth check for the app's lifetime).

## Testing

- No existing tests reference `AuthGate` or `PowerClampView` (none found in
  the codebase search). No test updates required beyond what the compiler
  surfaces from the deleted files.
- Manually verify: cold start shows splash then power clamp screen; forcing
  `ensureAuthenticated` to fail shows the auth-error screen with a working
  Retry; power clamp screen behaves identically to today (device status,
  history, form).

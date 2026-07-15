# Re-login on refresh-token failure

## Problem

This app has no interactive login screen — it's a kiosk-style device screen that
authenticates on startup using default credentials (`SessionBootstrapper`,
`lib/services/auth/session_bootstrapper.dart`). At startup, if a silent token
refresh fails, the app automatically logs in again with those credentials.

That recovery only runs once, at startup. Mid-session, when the refresh-token
API call fails (e.g. the refresh token is expired/invalid), the shared
`TokenRefreshInterceptor` / `RemoteTokenRefreshService` (in the
`frontend-microservices` `networking` package) already clear the stored tokens
and expose an `onRefreshFailed` hook for exactly this situation — but
`DioClient` never wires it up. The result: a 401 that survives a failed
refresh just propagates as an error to whatever screen/repo made the call, and
the app never re-authenticates until it's restarted.

## Goal

When a mid-session refresh-token call fails (not a transport/network error —
a deterministic rejection from the refresh endpoint, or a missing/invalid
refresh token), the app should automatically log back in with the same
default credentials used at startup, reusing the existing retry/backoff
logic, and reflect that recovery in the existing auth-gated router UI
(splash while retrying, `/auth-error` if it ultimately fails).

## Non-goals

- Retrying the original request that triggered the 401 once re-login
  succeeds. It surfaces its error to the caller as it does today (consistent
  with how transport failures during refresh are already handled); the next
  request after recovery just works with fresh tokens.
- Any change to the shared `frontend-microservices` package. All changes stay
  in `syncos-screen`, using the `onRefreshFailed` hooks it already exposes.
- Interactive login UI of any kind — this app doesn't have one and isn't
  getting one.

## Design

### Data flow

1. An API call gets a 401.
2. `TokenRefreshInterceptor` tries a refresh via `RemoteTokenRefreshService`.
3. The refresh fails in a way that can't be recovered (missing/invalid
   refresh token, or a non-transport failure response from the refresh
   endpoint). Tokens are cleared and `onRefreshFailed` fires.
4. `onRefreshFailed` is wired to `AuthController.retry()`.
5. `AuthController` re-runs `SessionBootstrapper.ensureAuthenticated()`:
   silent refresh short-circuits (no refresh token left), falling straight
   to `_loginWithRetries()` with the same default credentials used at
   startup.
6. `AuthController.status` goes `loading` → `authenticated`/`error`. The
   router (already wired via `refreshListenable: authController`) redirects
   to `/splash` and back to `/`, or to `/auth-error` if all login retries
   fail — identical to the existing startup behavior.

Transport-level failures on the refresh call itself (timeouts, connection
errors) do **not** trigger `onRefreshFailed` — that's existing behavior in
the shared package and is unchanged. This feature only engages when the
refresh endpoint deterministically rejects the session.

### Components

**`lib/services/api/dio_client.dart`**
- Add a static nullable field `void Function()? _onSessionExpired`.
- Add `static void configureSessionExpiredHandler(void Function() handler)`
  that sets it.
- In `_makeDio()`, pass `onRefreshFailed: () => _onSessionExpired?.call()` to
  both `RemoteTokenRefreshService` and `TokenRefreshInterceptor`. This
  indirection is required because the real handler (`AuthController.retry`)
  doesn't exist yet when `DioClient` first constructs its Dio instance and
  interceptors.

**`lib/app/app.dart`**
- After constructing `_authController` in `_AppState.initState()`, call:
  ```dart
  DioClient.configureSessionExpiredHandler(_authController.retry);
  ```

**`lib/app/router/auth_controller.dart`**
- Add a reentrancy guard to `_run()` so overlapping triggers (e.g. two
  in-flight requests both hitting a dead refresh token around the same
  time) don't stack duplicate login-retry cycles. Track an in-flight
  `Future<void>?`; if `_run()` is called while one is already in progress,
  return the existing future instead of starting a second one.

### Edge cases

- **Concurrent 401s**: `RemoteTokenRefreshService` already dedupes concurrent
  refresh attempts via its own in-flight future, so normally only one
  failure/callback fires per real refresh cycle. The `AuthController` guard
  is a backstop for the case where a second cycle starts right after the
  first one's in-flight future clears.
- **Failure during startup itself**: the callback is wired only after
  `AuthController` already exists (and has already kicked off its first
  `_run()` in its constructor), so this doesn't change behavior for the very
  first `ensureAuthenticated()` call — it only affects failures that happen
  after the app is already authenticated.
- **Re-login fails after retries**: `AuthController.status` becomes `error`,
  router shows the existing `/auth-error` screen with its existing "Retry"
  button, which already calls `retry()`. No new UI needed.

## Testing

- Add a test to the existing `AuthController` test coverage (or a new
  `auth_controller_test.dart` if none exists) asserting that calling
  `retry()` while a `_run()` is already in flight does not start a second
  concurrent `ensureAuthenticated` invocation — e.g. via a call-counting
  fake `ensureAuthenticated`.
- No changes needed to `session_bootstrapper_test.dart` or
  `http_interceptor_test.dart` — the retry/backoff logic they cover is
  reused unchanged.
- Manual verification: force a refresh-token failure (e.g. clear/corrupt the
  stored refresh token while the app is running, or point `refreshToken` at
  an endpoint that returns a deterministic rejection) and confirm the app
  transitions through the splash screen and re-authenticates without a
  restart.

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
logic. Unlike the startup flow, this recovery must be silent: no splash
screen, no visible navigation away from the current screen. Only if the
re-login ultimately fails does the app surface the existing `/auth-error`
screen. If the re-login succeeds, the original request that triggered the
401 is retried once with the new access token, so the screen that made that
call actually gets its data instead of surfacing a stale error.

## Non-goals

- Any change to the shared `frontend-microservices` package. All changes stay
  in `syncos-screen`, using the `onRefreshFailed` hooks it already exposes,
  plus a new app-level Dio interceptor.
- Interactive login UI of any kind — this app doesn't have one and isn't
  getting one.

**Revised 2026-07-15 (later same day):** the original request retry was
initially scoped as a non-goal — the assumption was that surfacing the
error and letting the *next* request pick up fresh tokens was good enough.
In practice, testing surfaced that the screen making the original call
(e.g. the Power Clamp chart on a date-filter change) never re-fetches on
its own, so it just stays empty even though the session silently recovered
moments later. Retrying the original request is now in scope; see
"Original-request retry" below.

## Design

### Data flow

1. An API call gets a 401.
2. `TokenRefreshInterceptor` tries a refresh via `RemoteTokenRefreshService`.
3. The refresh fails in a way that can't be recovered (missing/invalid
   refresh token, or a non-transport failure response from the refresh
   endpoint). Tokens are cleared and `onRefreshFailed` fires.
4. `onRefreshFailed` is wired to `AuthController.retrySilently()`.
5. `AuthController` re-runs `SessionBootstrapper.ensureAuthenticated()`:
   silent refresh short-circuits (no refresh token left), falling straight
   to `_loginWithRetries()` with the same default credentials used at
   startup. Unlike `retry()` (used by the auth-error screen's manual "Retry"
   button), `retrySilently()` does **not** set `AuthController.status` to
   `loading` first, so the router never redirects to `/splash` — the current
   screen stays put while the login retries run in the background.
6. `AuthController.status` goes straight to `authenticated` (no-op for the
   router — already on `/`) or `error` (router redirects to `/auth-error`,
   same as the startup failure path).
7. Meanwhile, back where the original 401 was thrown: `TokenRefreshInterceptor`
   already gave up and called `handler.next(err)` (step 3) before the
   re-login even finished — the two happen concurrently, not sequentially.
   A new app-level `SessionRecoveryInterceptor` sees that forwarded error,
   awaits the same recovery attempt from step 5 via
   `AuthController.awaitRecovery()`, and once it settles either retries the
   original request with the fresh access token (recovered) or forwards the
   original error (not recovered — `/auth-error` is already showing anyway).

Transport-level failures on the refresh call itself (timeouts, connection
errors) do **not** trigger `onRefreshFailed` — that's existing behavior in
the shared package and is unchanged. This feature only engages when the
refresh endpoint deterministically rejects the session.

### Original-request retry

`TokenRefreshInterceptor.handleError` (in the shared package) forwards the
original error via `handler.next(err)` as soon as its own refresh attempt
fails — it has no way to know about, or wait for, the app-level re-login
that `onRefreshFailed` just kicked off. Retrying the original request
therefore can't happen inside the shared package's interceptor; it needs a
second, app-level interceptor that sees the error *after* the shared one
gives up.

Dio runs `onError` (like `onRequest` and `onResponse`) in the **same FIFO
order** interceptors were added — confirmed by reading `dio_mixin.dart`'s
`fetch` implementation, which chains `.catchError()` calls in a single
forward loop over `interceptors`, not a reversed one. So a new
`SessionRecoveryInterceptor`, added to `dio.interceptors` **after**
`TokenRefreshInterceptor`, has its `onError` run *after*
`TokenRefreshInterceptor`'s — exactly the ordering needed. (An earlier
draft of this spec assumed the opposite — an "onion" reverse order — and
that assumption shipped briefly: with `SessionRecoveryInterceptor` added
*before* `TokenRefreshInterceptor`, it saw every 401 first, before any
refresh was attempted, and retried immediately with the still-stale token.
Caught via manual testing; fixed by swapping the order, with a regression
test that runs both interceptors together and fails/times out if the order
is wrong again.)

`SessionRecoveryInterceptor` (new file,
`lib/services/api/session_recovery_interceptor.dart`):
- On a 401 (skipping requests already flagged via
  `skipTokenRefreshExtraKey` or a new `skipSessionRecoveryExtraKey`, the
  latter set on its own retried request to prevent retrying the same
  request twice if the retry itself 401s again):
  1. `await`s an injected `Future<bool> Function() awaitRecovery` —
     wired to `AuthController.awaitRecovery()`.
  2. If it resolves `false` (no recovery, or recovery failed), forwards
     the original error via `handler.next(err)` — same behavior as today.
  3. If it resolves `true`, reads the fresh access token from the
     `TokenStore`, rebuilds the original request's headers with it, and
     retries via `dio.fetch`, resolving the handler with that response on
     success or forwarding whatever error the retry produced.

`AuthController.awaitRecovery()` (new method): resolves once the
controller's current in-flight recovery run (if any) settles, then reports
`status == AuthStatus.authenticated`. If no recovery is in flight when
called, it resolves immediately with the current status — this covers the
case where, by the time the interceptor runs, the recovery (kicked off
synchronously from inside `RemoteTokenRefreshService._refresh()`, before
its `StateError` even propagates back up through
`TokenRefreshInterceptor`) has already finished.

`DioClient` wiring mirrors the existing `onRefreshFailed` indirection: a
new static `Future<bool> Function()? _awaitSessionRecovery` field, a
`configureSessionRecoveryWaiter(...)` setter, and the interceptor is
constructed with `awaitRecovery: () => _awaitSessionRecovery?.call() ??
Future.value(false)`. Wired in `app.dart` alongside the existing handler:
```dart
DioClient.configureSessionRecoveryWaiter(_authController.awaitRecovery);
```

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
  DioClient.configureSessionExpiredHandler(_authController.retrySilently);
  ```

**`lib/app/router/auth_controller.dart`**
- Add a reentrancy guard shared by `retry()` and `retrySilently()` so
  overlapping triggers (e.g. two in-flight requests both hitting a dead
  refresh token around the same time) don't stack duplicate login-retry
  cycles. Track an in-flight `Future<void>?`; if a run is triggered while
  one is already in progress, return the existing future instead of
  starting a second one.
- `retry()` and `retrySilently()` share one internal runner, parameterized
  on whether to transition through `AuthStatus.loading` first. `retry()`
  (used by the auth-error screen's manual button) still does; `retrySilently()`
  (used by the `DioClient` session-expired hook) does not.

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
- **Re-login succeeds silently**: `AuthController.status` goes straight back
  to `authenticated` with no visible transition — the user never sees the
  splash screen or any indication a recovery happened.

## Testing

- Add a test to the existing `AuthController` test coverage asserting that
  calling `retry()` while a run is already in flight does not start a second
  concurrent `ensureAuthenticated` invocation — e.g. via a call-counting
  fake `ensureAuthenticated`.
- Add tests asserting `retrySilently()` never transitions `status` through
  `AuthStatus.loading` (tracked via `addListener`), landing on
  `authenticated` on success and `error` on failure.
- No changes needed to `session_bootstrapper_test.dart` or
  `http_interceptor_test.dart` — the retry/backoff logic they cover is
  reused unchanged.
- Manual verification: force a refresh-token failure (e.g. clear/corrupt the
  stored refresh token while the app is running, or point `refreshToken` at
  an endpoint that returns a deterministic rejection) and confirm the app
  stays on its current screen with no visible splash/navigation, then
  either recovers invisibly or lands on `/auth-error` if the login retries
  are exhausted.

// Centralised API base URL + path helpers.
//
// New revamp surface lives under `howwow(...)`. The legacy helpers (`fam`,
// `famV2`, `tutor`) exist only for the older curriculum endpoints — do NOT
// extend them. Anything new goes through `Endpoints.howwow(...)`.
//
// Default host: `https://glutaclass.com:8080`. The port is required: the
// Spring backend listens on 8080 (HTTPS) and the nginx vhost on standard
// 443 is the SuperPadhai marketing site, not an API proxy — `/gluta/*` on
// port 443 returns index.html, not JSON. Both `superpadhai.com` and
// `glutaclass.com` resolve to the same backend (43.205.68.78), BUT the TLS
// cert at :8080 covers `glutaclass.com` / `www.glutaclass.com` only — it
// has no SAN for `superpadhai.com`, so browsers (which can't be told to
// skip cert verification) refuse the connection. Keep the host as
// `glutaclass.com` until a cert covering both domains is provisioned.
//
// To point the app at a different host (e.g. a staging box) build with:
//   flutter run --dart-define=HOWWOW_BASE_URL=https://staging.example.com:8080
class Endpoints {
  Endpoints._();

  static const String baseUrl = String.fromEnvironment(
    'HOWWOW_BASE_URL',
    defaultValue: 'https://glutaclass.com:8080',
  );

  /// Revamp surface — the howwow namespace lives under the global /gluta
  /// context-path of the Spring backend, so `Endpoints.howwow('/career/home')`
  /// resolves to `<host>/gluta/howwow/career/home`.
  static String howwow(String path) => '$baseUrl/gluta/howwow$path';

  // ── legacy helpers (do not extend) ───────────────────────────────────
  static String fam(String path) => '$baseUrl/gluta/fam$path';
  static String famV2(String path) => '$baseUrl/gluta/famV2$path';
  static String tutor(String path) => '$baseUrl/gluta/tutor$path';
}

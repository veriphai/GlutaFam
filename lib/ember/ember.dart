// Ember — ember.dart
//
// THE PUBLIC BARREL. This is the ONLY file the host app may import from the
// Ember module. It re-exports exactly the public surface: the self-contained
// [EmberApp] root widget (mount it anywhere — it ships its own ProviderScope,
// theme, persistence, and assets) and the internal route names for callers that
// embed Ember under their own navigator.
//
// Everything else under lib/ember/ is private to the module. Keeping the surface
// tiny is what enforces the zero-coupling rule: the host can launch Ember but
// cannot reach into its internals.

export 'ember_app.dart' show EmberApp;
export 'ember_routes.dart' show EmberRoutes;

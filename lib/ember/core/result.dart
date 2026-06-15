// Ember — core/result.dart
//
// A tiny sealed Result<T> used for placement + activity outcomes. Pure value
// type; no exceptions on the happy path. Failures carry a stable [code] (for
// branching/i18n) plus a human-readable [message].

/// A recoverable failure with a machine code and a readable message.
class Failure {
  const Failure(this.code, this.message);

  final String code;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is Failure && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'Failure($code: $message)';
}

/// Outcome of an operation: either an [Ok] carrying a value or an [Err].
sealed class Result<T> {
  const Result();

  /// Convenience constructor for success.
  const factory Result.ok(T value) = Ok<T>;

  /// Convenience constructor for failure.
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value if [isOk], else null.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final T value) => value,
        Err<T>() => null,
      };

  /// The failure if [isErr], else null.
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final Failure failure) => failure,
      };

  /// Folds both branches into a single value.
  R fold<R>(R Function(T value) onOk, R Function(Failure f) onErr) =>
      switch (this) {
        Ok<T>(:final T value) => onOk(value),
        Err<T>(:final Failure failure) => onErr(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err($failure)';
}

/// Typed Failure and Error Hierarchy for Prep404
sealed class AppFailure {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppFailure(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message';
}

/// Network communication failures (e.g. timeout, DNS resolution failure)
class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

/// Server response errors (4xx, 5xx)
class ServerFailure extends AppFailure {
  final int? statusCode;
  const ServerFailure(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });
}

/// Cache & local persistence errors
class CacheFailure extends AppFailure {
  const CacheFailure(super.message, {super.cause, super.stackTrace});
}

/// Unhandled or unexpected exceptions
class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause, super.stackTrace});
}

/// Functional Result Monad representing either Success or Failure
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;
  AppFailure? get failureOrNull =>
      isFailure ? (this as Failure<T>).failure : null;

  R fold<R>(
    R Function(T data) onSuccess,
    R Function(AppFailure failure) onFailure,
  ) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as Failure<T>).failure);
    }
  }

  static Result<T> success<T>(T data) => Success<T>(data);
  static Result<T> failure<T>(AppFailure failure) => Failure<T>(failure);
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

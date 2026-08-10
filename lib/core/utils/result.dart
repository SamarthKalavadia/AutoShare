/// A wrapper class for handling success and failure states gracefully.
/// Follows the Result Pattern to prevent unhandled exceptions.
abstract class Result<T> {
  const Result();
}

/// Represents a successful operation containing the [data].
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Represents a failed operation containing a [message] and an optional [exception].
class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);
}

/// Base class for all custom application exceptions.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

/// Custom exception for authentication related errors.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Custom exception for Firestore database related errors.
class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

/// Custom exception for network or connectivity related errors.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Custom exception for Cloudinary/Storage upload related errors.
class StorageException extends AppException {
  const StorageException(super.message);
}

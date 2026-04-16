/// Base exception for all app-level errors.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the device cannot reach the server (no internet, timeout, etc.).
class NetworkException extends AppException {
  const NetworkException([super.message = 'Could not connect to the server. Check your internet connection.']);
}

/// Thrown on 401 Unauthorized responses (invalid or expired token).
class AuthException extends AppException {
  const AuthException([super.message = 'Session expired. Please log in again.']);
}

/// Thrown on 403 Forbidden responses.
class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'You do not have permission to perform this action.']);
}

/// Thrown on 404 Not Found responses.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'The requested resource was not found.']);
}

/// Thrown on 422 Unprocessable Entity (validation errors from the API).
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Thrown on 5xx server errors.
class ServerException extends AppException {
  final int statusCode;
  const ServerException(this.statusCode, [super.message = 'An unexpected server error occurred.']);
}

/// Thrown when an API response has an unexpected format.
class ParseException extends AppException {
  const ParseException([super.message = 'Failed to read server response.']);
}

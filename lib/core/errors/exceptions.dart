/// Data-layer exceptions mapped to [Failure] in repositories.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;
}

final class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

final class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

final class BleException extends AppException {
  const BleException(super.message, {super.code});
}

final class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}
import 'package:equatable/equatable.dart';

/// Base failure type for domain layer error handling.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

final class BleFailure extends Failure {
  const BleFailure(super.message, {super.code});
}

final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

final class HosFailure extends Failure {
  const HosFailure(super.message, {super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}
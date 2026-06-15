import 'package:eld_management_system/core/utils/typedefs.dart';
import 'package:eld_management_system/features/auth/domain/entities/user.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);
  final AuthRepository _repository;

  ResultFuture<User> call({required String email, required String password}) =>
      _repository.signInWithEmail(email: email, password: password);
}
import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/failures.dart';

/// Use case para login de utilizador
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // Validar parâmetros
    if (params.email.isEmpty) {
      return Left(ValidationFailure.requiredField('email'));
    }
    if (params.password.isEmpty) {
      return Left(ValidationFailure.requiredField('password'));
    }
    if (!_isValidEmail(params.email)) {
      return Left(ValidationFailure.invalidFormat('email', 'exemplo@dominio.pt'));
    }

    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}

/// Parâmetros para o login
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}

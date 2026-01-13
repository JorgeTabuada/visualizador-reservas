import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../../../../core/utils/failures.dart';

/// Repositório abstrato de autenticação
abstract class AuthRepository {
  /// Faz login com email e password
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Faz logout do utilizador atual
  Future<Either<Failure, void>> logout();

  /// Obtém o utilizador atualmente autenticado
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Verifica se existe um utilizador autenticado
  Future<bool> isAuthenticated();

  /// Regista um novo utilizador (apenas para admins)
  Future<Either<Failure, UserEntity>> registerUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String organizationId,
    String? departmentId,
  });

  /// Atualiza dados do utilizador
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);

  /// Envia email de recuperação de password
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Atualiza password do utilizador
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Stream de alterações no estado de autenticação
  Stream<UserEntity?> get authStateChanges;
}

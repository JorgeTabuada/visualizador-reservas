import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/utils/failures.dart';

/// Implementação do repositório de autenticação
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Verificar se o utilizador está ativo
      if (!user.isActive) {
        return Left(AuthFailure.userDisabled());
      }

      return Right(user.toEntity());
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user?.toEntity());
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await remoteDataSource.isAuthenticated();
  }

  @override
  Future<Either<Failure, UserEntity>> registerUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String organizationId,
    String? departmentId,
  }) async {
    try {
      final user = await remoteDataSource.registerUser(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        organizationId: organizationId,
        departmentId: departmentId,
      );
      return Right(user.toEntity());
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final updatedUser = await remoteDataSource.updateUser(userModel);
      return Right(updatedUser.toEntity());
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges.map((user) => user?.toEntity());
  }

  /// Mapeia exceções do Firebase Auth para Failures
  AuthFailure _mapFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.invalidCredentials();
      case 'user-disabled':
        return AuthFailure.userDisabled();
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'too-many-requests':
        return AuthFailure.tooManyRequests();
      case 'invalid-email':
        return const AuthFailure(
          message: 'Email inválido',
          code: 'invalid-email',
        );
      default:
        return AuthFailure.unknown(e.message);
    }
  }
}

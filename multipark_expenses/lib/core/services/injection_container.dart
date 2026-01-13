import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/expenses/data/datasources/expenses_remote_datasource.dart';
import '../../features/expenses/data/repositories/expenses_repository_impl.dart';
import '../../features/expenses/domain/repositories/expenses_repository.dart';
import '../../features/expenses/domain/usecases/create_expense_usecase.dart';
import '../../features/expenses/domain/usecases/get_expenses_usecase.dart';
import '../../features/expenses/domain/usecases/update_expense_usecase.dart';
import '../../features/expenses/domain/usecases/delete_expense_usecase.dart';
import '../../features/expenses/domain/usecases/scan_receipt_usecase.dart';
import '../../features/expenses/presentation/bloc/expenses_bloc.dart';

import '../../features/projects/data/repositories/projects_repository_impl.dart';
import '../../features/projects/domain/repositories/projects_repository.dart';

import 'ocr_service.dart';
import 'notification_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ============ FIREBASE INSTANCES ============
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  getIt.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);

  // ============ SERVICES ============
  getIt.registerLazySingleton<OcrService>(() => OcrService());
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<FirebaseMessaging>()),
  );

  // ============ DATA SOURCES ============
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );

  getIt.registerLazySingleton<ExpensesRemoteDataSource>(
    () => ExpensesRemoteDataSourceImpl(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );

  // ============ REPOSITORIES ============
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt<AuthRemoteDataSource>()),
  );

  getIt.registerLazySingleton<ExpensesRepository>(
    () => ExpensesRepositoryImpl(
      remoteDataSource: getIt<ExpensesRemoteDataSource>(),
      ocrService: getIt<OcrService>(),
    ),
  );

  getIt.registerLazySingleton<ProjectsRepository>(
    () => ProjectsRepositoryImpl(firestore: getIt<FirebaseFirestore>()),
  );

  // ============ USE CASES - AUTH ============
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt<AuthRepository>()));

  // ============ USE CASES - EXPENSES ============
  getIt.registerLazySingleton(() => CreateExpenseUseCase(getIt<ExpensesRepository>()));
  getIt.registerLazySingleton(() => GetExpensesUseCase(getIt<ExpensesRepository>()));
  getIt.registerLazySingleton(() => UpdateExpenseUseCase(getIt<ExpensesRepository>()));
  getIt.registerLazySingleton(() => DeleteExpenseUseCase(getIt<ExpensesRepository>()));
  getIt.registerLazySingleton(() => ScanReceiptUseCase(getIt<ExpensesRepository>()));

  // ============ BLOCS ============
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    ),
  );

  getIt.registerFactory<ExpensesBloc>(
    () => ExpensesBloc(
      createExpenseUseCase: getIt<CreateExpenseUseCase>(),
      getExpensesUseCase: getIt<GetExpensesUseCase>(),
      updateExpenseUseCase: getIt<UpdateExpenseUseCase>(),
      deleteExpenseUseCase: getIt<DeleteExpenseUseCase>(),
      scanReceiptUseCase: getIt<ScanReceiptUseCase>(),
    ),
  );
}

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_remote_datasource.dart';
import '../models/expense_model.dart';
import '../../../../core/utils/failures.dart';
import '../../../../core/services/ocr_service.dart';

/// Implementação do repositório de despesas
class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesRemoteDataSource remoteDataSource;
  final OcrService ocrService;

  ExpensesRepositoryImpl({
    required this.remoteDataSource,
    required this.ocrService,
  });

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense(
      ExpenseEntity expense) async {
    try {
      // Validar que tem projeto associado
      if (expense.projectId.isEmpty) {
        return Left(ExpenseFailure.projectRequired());
      }

      final expenseModel = ExpenseModel.fromEntity(expense);
      final created = await remoteDataSource.createExpense(expenseModel);
      return Right(created.toEntity());
    } catch (e) {
      return Left(ExpenseFailure.createFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> getExpenseById(String id) async {
    try {
      final expense = await remoteDataSource.getExpenseById(id);
      return Right(expense.toEntity());
    } catch (e) {
      return Left(ExpenseFailure.notFound());
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    String? projectId,
    String? departmentId,
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      final expenses = await remoteDataSource.getExpenses(
        projectId: projectId,
        departmentId: departmentId,
        userId: userId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
      return Right(expenses.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> updateExpense(
      ExpenseEntity expense) async {
    try {
      // Verificar se não está aprovada (não pode editar despesas aprovadas)
      if (expense.isApproved) {
        return Left(ExpenseFailure.alreadyApproved());
      }

      final expenseModel = ExpenseModel.fromEntity(expense);
      final updated = await remoteDataSource.updateExpense(expenseModel);
      return Right(updated.toEntity());
    } catch (e) {
      return Left(ExpenseFailure.updateFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await remoteDataSource.deleteExpense(id);
      return const Right(null);
    } catch (e) {
      return Left(ExpenseFailure.deleteFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadReceiptImage({
    required File image,
    required String expenseId,
  }) async {
    try {
      final url = await remoteDataSource.uploadReceiptImage(
        image: image,
        expenseId: expenseId,
      );
      return Right(url);
    } catch (e) {
      return Left(StorageFailure.uploadFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OcrResult>> scanReceipt(File image) async {
    try {
      final result = await ocrService.processReceipt(image);

      if (!result.isValid) {
        return Left(OcrFailure.lowConfidence());
      }

      if (result.rawText.isEmpty) {
        return Left(OcrFailure.noTextFound());
      }

      return Right(result);
    } catch (e) {
      return Left(OcrFailure.processingFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> approveExpense({
    required String expenseId,
    required String approverId,
    String? comment,
  }) async {
    try {
      final expenseResult = await getExpenseById(expenseId);

      return expenseResult.fold(
        (failure) => Left(failure),
        (expense) async {
          final updatedApproval = expense.approval.copyWith(
            status: ApprovalStatus.approved,
            approvedBy: approverId,
            approvedAt: DateTime.now(),
            history: [
              ...expense.approval.history,
              ApprovalHistoryEntry(
                action: 'approved',
                userId: approverId,
                timestamp: DateTime.now(),
                comment: comment,
              ),
            ],
          );

          final updatedExpense = expense.copyWith(
            approval: updatedApproval,
            updatedAt: DateTime.now(),
          );

          return await updateExpense(updatedExpense);
        },
      );
    } catch (e) {
      return Left(ExpenseFailure.updateFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> rejectExpense({
    required String expenseId,
    required String approverId,
    required String reason,
  }) async {
    try {
      final expenseResult = await getExpenseById(expenseId);

      return expenseResult.fold(
        (failure) => Left(failure),
        (expense) async {
          final updatedApproval = expense.approval.copyWith(
            status: ApprovalStatus.rejected,
            approvedBy: approverId,
            approvedAt: DateTime.now(),
            rejectionReason: reason,
            history: [
              ...expense.approval.history,
              ApprovalHistoryEntry(
                action: 'rejected',
                userId: approverId,
                timestamp: DateTime.now(),
                comment: reason,
              ),
            ],
          );

          final updatedExpense = expense.copyWith(
            approval: updatedApproval,
            updatedAt: DateTime.now(),
          );

          // Não validamos isApproved aqui porque estamos a rejeitar
          final expenseModel = ExpenseModel.fromEntity(updatedExpense);
          final updated = await remoteDataSource.updateExpense(expenseModel);
          return Right(updated.toEntity());
        },
      );
    } catch (e) {
      return Left(ExpenseFailure.updateFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> markAsPaid({
    required String expenseId,
    required String paidBy,
    DateTime? paidAt,
  }) async {
    try {
      final expenseResult = await getExpenseById(expenseId);

      return expenseResult.fold(
        (failure) => Left(failure),
        (expense) async {
          final updatedPayment = expense.paymentInfo.copyWith(
            status: PaymentStatus.paid,
            paidBy: paidBy,
            paidAt: paidAt ?? DateTime.now(),
            paidAmount: expense.totalAmount,
          );

          final updatedExpense = expense.copyWith(
            paymentInfo: updatedPayment,
            updatedAt: DateTime.now(),
          );

          final expenseModel = ExpenseModel.fromEntity(updatedExpense);
          final updated = await remoteDataSource.updateExpense(expenseModel);
          return Right(updated.toEntity());
        },
      );
    } catch (e) {
      return Left(ExpenseFailure.updateFailed(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseStatistics>> getStatistics({
    required String organizationId,
    String? projectId,
    String? departmentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final expenses = await remoteDataSource.getExpenses(
        projectId: projectId,
        departmentId: departmentId,
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // Para estatísticas, obtemos mais registos
      );

      double totalAmount = 0;
      double pendingAmount = 0;
      double approvedAmount = 0;
      double paidAmount = 0;
      int pendingCount = 0;
      int approvedCount = 0;
      int overdueCount = 0;
      final byCategory = <String, double>{};
      final byProject = <String, double>{};

      for (final expense in expenses) {
        final amount = expense.totalAmount;
        totalAmount += amount;

        // Por status
        switch (expense.approval.status) {
          case ApprovalStatus.pending:
            pendingAmount += amount;
            pendingCount++;
            break;
          case ApprovalStatus.approved:
            approvedAmount += amount;
            approvedCount++;
            break;
          default:
            break;
        }

        // Pagos
        if (expense.isPaid) {
          paidAmount += amount;
        }

        // Vencidos
        if (expense.isOverdue) {
          overdueCount++;
        }

        // Por categoria
        if (expense.categoryId != null) {
          byCategory[expense.categoryId!] =
              (byCategory[expense.categoryId!] ?? 0) + amount;
        }

        // Por projeto
        byProject[expense.projectId] =
            (byProject[expense.projectId] ?? 0) + amount;
      }

      return Right(ExpenseStatistics(
        totalAmount: totalAmount,
        pendingAmount: pendingAmount,
        approvedAmount: approvedAmount,
        paidAmount: paidAmount,
        totalCount: expenses.length,
        pendingCount: pendingCount,
        approvedCount: approvedCount,
        overdueCount: overdueCount,
        byCategory: byCategory,
        byProject: byProject,
      ));
    } catch (e) {
      return Left(ServerFailure.serverError(e.toString()));
    }
  }

  @override
  Stream<List<ExpenseEntity>> watchExpenses({
    String? projectId,
    String? userId,
  }) {
    return remoteDataSource
        .watchExpenses(projectId: projectId, userId: userId)
        .map((expenses) => expenses.map((e) => e.toEntity()).toList());
  }
}

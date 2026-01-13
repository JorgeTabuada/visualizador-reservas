import 'dart:io';
import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../../../../core/utils/failures.dart';
import '../../../../core/services/ocr_service.dart';

/// Repositório abstrato de despesas
abstract class ExpensesRepository {
  /// Cria uma nova despesa
  Future<Either<Failure, ExpenseEntity>> createExpense(ExpenseEntity expense);

  /// Obtém uma despesa por ID
  Future<Either<Failure, ExpenseEntity>> getExpenseById(String id);

  /// Obtém lista de despesas com filtros
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    String? projectId,
    String? departmentId,
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    String? lastDocumentId,
  });

  /// Atualiza uma despesa existente
  Future<Either<Failure, ExpenseEntity>> updateExpense(ExpenseEntity expense);

  /// Elimina uma despesa (soft delete)
  Future<Either<Failure, void>> deleteExpense(String id);

  /// Faz upload de imagem de recibo e retorna a URL
  Future<Either<Failure, String>> uploadReceiptImage({
    required File image,
    required String expenseId,
  });

  /// Processa imagem com OCR e extrai dados
  Future<Either<Failure, OcrResult>> scanReceipt(File image);

  /// Aprova uma despesa
  Future<Either<Failure, ExpenseEntity>> approveExpense({
    required String expenseId,
    required String approverId,
    String? comment,
  });

  /// Rejeita uma despesa
  Future<Either<Failure, ExpenseEntity>> rejectExpense({
    required String expenseId,
    required String approverId,
    required String reason,
  });

  /// Marca despesa como paga
  Future<Either<Failure, ExpenseEntity>> markAsPaid({
    required String expenseId,
    required String paidBy,
    DateTime? paidAt,
  });

  /// Obtém estatísticas de despesas
  Future<Either<Failure, ExpenseStatistics>> getStatistics({
    required String organizationId,
    String? projectId,
    String? departmentId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Stream de despesas em tempo real
  Stream<List<ExpenseEntity>> watchExpenses({
    String? projectId,
    String? userId,
  });
}

/// Estatísticas de despesas
class ExpenseStatistics {
  final double totalAmount;
  final double pendingAmount;
  final double approvedAmount;
  final double paidAmount;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int overdueCount;
  final Map<String, double> byCategory;
  final Map<String, double> byProject;
  final List<DailyExpense> dailyBreakdown;

  const ExpenseStatistics({
    this.totalAmount = 0,
    this.pendingAmount = 0,
    this.approvedAmount = 0,
    this.paidAmount = 0,
    this.totalCount = 0,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.overdueCount = 0,
    this.byCategory = const {},
    this.byProject = const {},
    this.dailyBreakdown = const [],
  });
}

class DailyExpense {
  final DateTime date;
  final double amount;
  final int count;

  const DailyExpense({
    required this.date,
    required this.amount,
    required this.count,
  });
}

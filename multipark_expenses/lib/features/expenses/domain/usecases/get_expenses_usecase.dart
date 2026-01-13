import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expenses_repository.dart';
import '../../../../core/utils/failures.dart';

/// Use case para obter despesas
class GetExpensesUseCase {
  final ExpensesRepository repository;

  GetExpensesUseCase(this.repository);

  Future<Either<Failure, List<ExpenseEntity>>> call(GetExpensesParams params) async {
    return await repository.getExpenses(
      projectId: params.projectId,
      departmentId: params.departmentId,
      userId: params.userId,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
      limit: params.limit,
      lastDocumentId: params.lastDocumentId,
    );
  }
}

class GetExpensesParams {
  final String? projectId;
  final String? departmentId;
  final String? userId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final String? lastDocumentId;

  const GetExpensesParams({
    this.projectId,
    this.departmentId,
    this.userId,
    this.status,
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.lastDocumentId,
  });
}

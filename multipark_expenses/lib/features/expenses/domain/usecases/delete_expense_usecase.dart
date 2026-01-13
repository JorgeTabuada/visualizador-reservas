import 'package:dartz/dartz.dart';
import '../repositories/expenses_repository.dart';
import '../../../../core/utils/failures.dart';

/// Use case para eliminar uma despesa
class DeleteExpenseUseCase {
  final ExpensesRepository repository;

  DeleteExpenseUseCase(this.repository);

  Future<Either<Failure, void>> call(String expenseId) async {
    return await repository.deleteExpense(expenseId);
  }
}

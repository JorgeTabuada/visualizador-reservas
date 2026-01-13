import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expenses_repository.dart';
import '../../../../core/utils/failures.dart';

/// Use case para criar uma despesa
class CreateExpenseUseCase {
  final ExpensesRepository repository;

  CreateExpenseUseCase(this.repository);

  Future<Either<Failure, ExpenseEntity>> call(ExpenseEntity expense) async {
    // Validações
    if (expense.projectId.isEmpty) {
      return Left(ExpenseFailure.projectRequired());
    }

    if (expense.totalAmount <= 0) {
      return Left(ValidationFailure.invalidData('O valor deve ser maior que zero'));
    }

    return await repository.createExpense(expense);
  }
}

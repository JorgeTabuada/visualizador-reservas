import 'package:dartz/dartz.dart';
import '../entities/expense_entity.dart';
import '../repositories/expenses_repository.dart';
import '../../../../core/utils/failures.dart';

/// Use case para atualizar uma despesa
class UpdateExpenseUseCase {
  final ExpensesRepository repository;

  UpdateExpenseUseCase(this.repository);

  Future<Either<Failure, ExpenseEntity>> call(ExpenseEntity expense) async {
    return await repository.updateExpense(expense);
  }
}

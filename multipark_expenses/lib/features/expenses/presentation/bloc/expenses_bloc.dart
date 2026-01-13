import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/scan_receipt_usecase.dart';
import '../../../../core/services/ocr_service.dart';

// ============ EVENTS ============

abstract class ExpensesEvent extends Equatable {
  const ExpensesEvent();

  @override
  List<Object?> get props => [];
}

class ExpensesLoadRequested extends ExpensesEvent {
  final String? projectId;
  final String? departmentId;
  final String? userId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExpensesLoadRequested({
    this.projectId,
    this.departmentId,
    this.userId,
    this.status,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [projectId, departmentId, userId, status, startDate, endDate];
}

class ExpensesLoadMoreRequested extends ExpensesEvent {
  final String lastDocumentId;

  const ExpensesLoadMoreRequested(this.lastDocumentId);

  @override
  List<Object?> get props => [lastDocumentId];
}

class ExpenseCreateRequested extends ExpensesEvent {
  final ExpenseEntity expense;

  const ExpenseCreateRequested(this.expense);

  @override
  List<Object?> get props => [expense];
}

class ExpenseUpdateRequested extends ExpensesEvent {
  final ExpenseEntity expense;

  const ExpenseUpdateRequested(this.expense);

  @override
  List<Object?> get props => [expense];
}

class ExpenseDeleteRequested extends ExpensesEvent {
  final String expenseId;

  const ExpenseDeleteRequested(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

class ReceiptScanRequested extends ExpensesEvent {
  final File image;

  const ReceiptScanRequested(this.image);

  @override
  List<Object?> get props => [image];
}

class ExpenseFilterChanged extends ExpensesEvent {
  final ExpenseFilter filter;

  const ExpenseFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

// ============ STATES ============

abstract class ExpensesState extends Equatable {
  const ExpensesState();

  @override
  List<Object?> get props => [];
}

class ExpensesInitial extends ExpensesState {}

class ExpensesLoading extends ExpensesState {}

class ExpensesLoaded extends ExpensesState {
  final List<ExpenseEntity> expenses;
  final ExpenseFilter filter;
  final bool hasMore;
  final bool isLoadingMore;

  const ExpensesLoaded({
    required this.expenses,
    this.filter = const ExpenseFilter(),
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [expenses, filter, hasMore, isLoadingMore];

  ExpensesLoaded copyWith({
    List<ExpenseEntity>? expenses,
    ExpenseFilter? filter,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ExpensesLoaded(
      expenses: expenses ?? this.expenses,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ExpensesError extends ExpensesState {
  final String message;

  const ExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceiptScanning extends ExpensesState {}

class ReceiptScanned extends ExpensesState {
  final OcrResult result;

  const ReceiptScanned(this.result);

  @override
  List<Object?> get props => [result];
}

class ReceiptScanError extends ExpensesState {
  final String message;

  const ReceiptScanError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExpenseOperationSuccess extends ExpensesState {
  final String message;
  final ExpenseEntity? expense;

  const ExpenseOperationSuccess({required this.message, this.expense});

  @override
  List<Object?> get props => [message, expense];
}

// ============ FILTER ============

class ExpenseFilter extends Equatable {
  final String? projectId;
  final String? departmentId;
  final String? userId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  const ExpenseFilter({
    this.projectId,
    this.departmentId,
    this.userId,
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  ExpenseFilter copyWith({
    String? projectId,
    String? departmentId,
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return ExpenseFilter(
      projectId: projectId ?? this.projectId,
      departmentId: departmentId ?? this.departmentId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props =>
      [projectId, departmentId, userId, status, startDate, endDate, searchQuery];
}

// ============ BLOC ============

class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  final CreateExpenseUseCase createExpenseUseCase;
  final GetExpensesUseCase getExpensesUseCase;
  final UpdateExpenseUseCase updateExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final ScanReceiptUseCase scanReceiptUseCase;

  ExpenseFilter _currentFilter = const ExpenseFilter();

  ExpensesBloc({
    required this.createExpenseUseCase,
    required this.getExpensesUseCase,
    required this.updateExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.scanReceiptUseCase,
  }) : super(ExpensesInitial()) {
    on<ExpensesLoadRequested>(_onExpensesLoadRequested);
    on<ExpensesLoadMoreRequested>(_onExpensesLoadMoreRequested);
    on<ExpenseCreateRequested>(_onExpenseCreateRequested);
    on<ExpenseUpdateRequested>(_onExpenseUpdateRequested);
    on<ExpenseDeleteRequested>(_onExpenseDeleteRequested);
    on<ReceiptScanRequested>(_onReceiptScanRequested);
    on<ExpenseFilterChanged>(_onExpenseFilterChanged);
  }

  Future<void> _onExpensesLoadRequested(
    ExpensesLoadRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(ExpensesLoading());

    _currentFilter = ExpenseFilter(
      projectId: event.projectId,
      departmentId: event.departmentId,
      userId: event.userId,
      status: event.status,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    final result = await getExpensesUseCase(GetExpensesParams(
      projectId: event.projectId,
      departmentId: event.departmentId,
      userId: event.userId,
      status: event.status,
      startDate: event.startDate,
      endDate: event.endDate,
    ));

    result.fold(
      (failure) => emit(ExpensesError(failure.message)),
      (expenses) => emit(ExpensesLoaded(
        expenses: expenses,
        filter: _currentFilter,
        hasMore: expenses.length >= 20,
      )),
    );
  }

  Future<void> _onExpensesLoadMoreRequested(
    ExpensesLoadMoreRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ExpensesLoaded || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getExpensesUseCase(GetExpensesParams(
      projectId: _currentFilter.projectId,
      departmentId: _currentFilter.departmentId,
      userId: _currentFilter.userId,
      status: _currentFilter.status,
      startDate: _currentFilter.startDate,
      endDate: _currentFilter.endDate,
      lastDocumentId: event.lastDocumentId,
    ));

    result.fold(
      (failure) => emit(ExpensesError(failure.message)),
      (expenses) => emit(currentState.copyWith(
        expenses: [...currentState.expenses, ...expenses],
        hasMore: expenses.length >= 20,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onExpenseCreateRequested(
    ExpenseCreateRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    final currentState = state;

    final result = await createExpenseUseCase(event.expense);

    result.fold(
      (failure) => emit(ExpensesError(failure.message)),
      (expense) {
        emit(ExpenseOperationSuccess(
          message: 'Despesa criada com sucesso',
          expense: expense,
        ));

        // Recarregar lista
        if (currentState is ExpensesLoaded) {
          emit(currentState.copyWith(
            expenses: [expense, ...currentState.expenses],
          ));
        }
      },
    );
  }

  Future<void> _onExpenseUpdateRequested(
    ExpenseUpdateRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    final currentState = state;

    final result = await updateExpenseUseCase(event.expense);

    result.fold(
      (failure) => emit(ExpensesError(failure.message)),
      (expense) {
        emit(ExpenseOperationSuccess(
          message: 'Despesa atualizada com sucesso',
          expense: expense,
        ));

        // Atualizar na lista
        if (currentState is ExpensesLoaded) {
          final updatedExpenses = currentState.expenses.map((e) {
            return e.id == expense.id ? expense : e;
          }).toList();

          emit(currentState.copyWith(expenses: updatedExpenses));
        }
      },
    );
  }

  Future<void> _onExpenseDeleteRequested(
    ExpenseDeleteRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    final currentState = state;

    final result = await deleteExpenseUseCase(event.expenseId);

    result.fold(
      (failure) => emit(ExpensesError(failure.message)),
      (_) {
        emit(const ExpenseOperationSuccess(message: 'Despesa eliminada'));

        // Remover da lista
        if (currentState is ExpensesLoaded) {
          final updatedExpenses = currentState.expenses
              .where((e) => e.id != event.expenseId)
              .toList();

          emit(currentState.copyWith(expenses: updatedExpenses));
        }
      },
    );
  }

  Future<void> _onReceiptScanRequested(
    ReceiptScanRequested event,
    Emitter<ExpensesState> emit,
  ) async {
    emit(ReceiptScanning());

    final result = await scanReceiptUseCase(event.image);

    result.fold(
      (failure) => emit(ReceiptScanError(failure.message)),
      (ocrResult) => emit(ReceiptScanned(ocrResult)),
    );
  }

  Future<void> _onExpenseFilterChanged(
    ExpenseFilterChanged event,
    Emitter<ExpensesState> emit,
  ) async {
    _currentFilter = event.filter;

    add(ExpensesLoadRequested(
      projectId: event.filter.projectId,
      departmentId: event.filter.departmentId,
      userId: event.filter.userId,
      status: event.filter.status,
      startDate: event.filter.startDate,
      endDate: event.filter.endDate,
    ));
  }
}

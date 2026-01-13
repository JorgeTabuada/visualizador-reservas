import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/domain/entities/expense_entity.dart';

class RecentExpensesList extends StatelessWidget {
  const RecentExpensesList({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Obter dados reais do BLoC
    final mockExpenses = _getMockExpenses();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: mockExpenses.map((expense) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExpenseCard(expense: expense),
          );
        }).toList(),
      ),
    );
  }

  List<_MockExpense> _getMockExpenses() {
    return [
      _MockExpense(
        vendor: 'Continente',
        amount: 125.50,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        status: ApprovalStatus.pending,
        category: 'Material Escritório',
      ),
      _MockExpense(
        vendor: 'Galp Energia',
        amount: 85.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: ApprovalStatus.approved,
        category: 'Combustível',
      ),
      _MockExpense(
        vendor: 'Worten',
        amount: 299.99,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: ApprovalStatus.rejected,
        category: 'Equipamento',
      ),
      _MockExpense(
        vendor: 'Restaurante Tascaria',
        amount: 45.00,
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: ApprovalStatus.approved,
        category: 'Refeições',
      ),
    ];
  }
}

class _MockExpense {
  final String vendor;
  final double amount;
  final DateTime date;
  final ApprovalStatus status;
  final String category;

  _MockExpense({
    required this.vendor,
    required this.amount,
    required this.date,
    required this.status,
    required this.category,
  });
}

class _ExpenseCard extends StatelessWidget {
  final _MockExpense expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_PT', symbol: '€');
    final dateFormat = DateFormat('dd MMM, HH:mm', 'pt_PT');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Ícone da categoria
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(),
              color: _getCategoryColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.vendor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      expense.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(expense.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Valor e Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(expense.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (expense.status) {
      case ApprovalStatus.pending:
        color = AppTheme.warningColor;
        label = 'Pendente';
        icon = Icons.schedule;
        break;
      case ApprovalStatus.approved:
        color = AppTheme.successColor;
        label = 'Aprovado';
        icon = Icons.check_circle_outline;
        break;
      case ApprovalStatus.rejected:
        color = AppTheme.errorColor;
        label = 'Rejeitado';
        icon = Icons.cancel_outlined;
        break;
      case ApprovalStatus.revisionRequired:
        color = AppTheme.infoColor;
        label = 'Revisão';
        icon = Icons.edit_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (expense.category) {
      case 'Material Escritório':
        return AppTheme.primaryColor;
      case 'Combustível':
        return AppTheme.warningColor;
      case 'Equipamento':
        return AppTheme.infoColor;
      case 'Refeições':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getCategoryIcon() {
    switch (expense.category) {
      case 'Material Escritório':
        return Icons.description;
      case 'Combustível':
        return Icons.local_gas_station;
      case 'Equipamento':
        return Icons.devices;
      case 'Refeições':
        return Icons.restaurant;
      default:
        return Icons.receipt;
    }
  }
}

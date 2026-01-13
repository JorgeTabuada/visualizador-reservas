import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/ocr_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expenses_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ExpenseFormScreen extends StatefulWidget {
  final OcrResult? ocrResult;
  final ExpenseEntity? existingExpense;

  const ExpenseFormScreen({
    super.key,
    this.ocrResult,
    this.existingExpense,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorController;
  late TextEditingController _invoiceNumberController;
  late TextEditingController _totalController;
  late TextEditingController _taxController;
  late TextEditingController _notesController;

  DateTime? _invoiceDate;
  DateTime? _dueDate;
  PaymentMethod _paymentMethod = PaymentMethod.companyCard;
  String? _selectedProjectId;

  // Lista mock de projetos
  final List<_MockProject> _projects = [
    _MockProject(id: 'proj1', name: 'Parque Aeroporto Lisboa'),
    _MockProject(id: 'proj2', name: 'Parque Gaia'),
    _MockProject(id: 'proj3', name: 'Projeto Multibags'),
    _MockProject(id: 'proj4', name: 'Parque Faro'),
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final ocr = widget.ocrResult;
    final expense = widget.existingExpense;

    _vendorController = TextEditingController(
      text: ocr?.vendor ?? expense?.extractedData.vendor ?? '',
    );
    _invoiceNumberController = TextEditingController(
      text: ocr?.invoiceNumber ?? expense?.extractedData.invoiceNumber ?? '',
    );
    _totalController = TextEditingController(
      text: ocr?.totalAmount?.toStringAsFixed(2) ??
          expense?.totalAmount.toStringAsFixed(2) ??
          '',
    );
    _taxController = TextEditingController(
      text: ocr?.taxAmount?.toStringAsFixed(2) ??
          expense?.extractedData.taxAmount?.toStringAsFixed(2) ??
          '',
    );
    _notesController = TextEditingController(
      text: expense?.notes ?? '',
    );

    _invoiceDate = ocr?.invoiceDate ?? expense?.extractedData.invoiceDate;
    _dueDate = ocr?.dueDate ?? expense?.extractedData.dueDate;

    if (ocr?.paymentMethod != null) {
      _paymentMethod = PaymentMethod.fromString(ocr!.paymentMethod!);
    } else if (expense != null) {
      _paymentMethod = expense.paymentInfo.method;
    }

    _selectedProjectId = expense?.projectId;
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _invoiceNumberController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExpense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Despesa' : 'Nova Despesa'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: BlocListener<ExpensesBloc, ExpensesState>(
        listener: (context, state) {
          if (state is ExpenseOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
            Navigator.pop(context);
          } else if (state is ExpensesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // OCR Confidence
              if (widget.ocrResult != null) _buildOcrConfidenceCard(),

              // Projeto (OBRIGATÓRIO)
              _buildSectionTitle('Projeto *'),
              _buildProjectSelector(),
              const SizedBox(height: 24),

              // Informações do Fornecedor
              _buildSectionTitle('Informações do Fornecedor'),
              _buildTextField(
                controller: _vendorController,
                label: 'Nome do Fornecedor',
                icon: Icons.store,
                validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _invoiceNumberController,
                label: 'Número da Fatura',
                icon: Icons.receipt,
              ),
              const SizedBox(height: 24),

              // Valores
              _buildSectionTitle('Valores'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalController,
                      label: 'Total (€)',
                      icon: Icons.euro,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Campo obrigatório';
                        if (double.tryParse(v!) == null) return 'Valor inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _taxController,
                      label: 'IVA (€)',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Datas
              _buildSectionTitle('Datas'),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Data da Fatura',
                      value: _invoiceDate,
                      onChanged: (d) => setState(() => _invoiceDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Data de Vencimento',
                      value: _dueDate,
                      onChanged: (d) => setState(() => _dueDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Método de Pagamento
              _buildSectionTitle('Método de Pagamento'),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),

              // Notas
              _buildSectionTitle('Notas'),
              _buildTextField(
                controller: _notesController,
                label: 'Observações',
                icon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Botão Guardar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  child: Text(isEditing ? 'Atualizar' : 'Guardar Despesa'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrConfidenceCard() {
    final confidence = widget.ocrResult!.confidence;
    final color = confidence >= 0.8
        ? AppTheme.successColor
        : confidence >= 0.6
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            confidence >= 0.8
                ? Icons.check_circle
                : confidence >= 0.6
                    ? Icons.info
                    : Icons.warning,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dados extraídos automaticamente',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  'Confiança: ${(confidence * 100).toStringAsFixed(0)}% - Verifique os dados',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProjectSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedProjectId == null
              ? AppTheme.errorColor.withOpacity(0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProjectId,
          hint: const Text('Selecione um projeto'),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _projects.map((project) {
            return DropdownMenuItem(
              value: project.id,
              child: Text(project.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedProjectId = value),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textHint),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.textHint, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
                Text(
                  value != null ? dateFormat.format(value) : 'Selecionar',
                  style: TextStyle(
                    color: value != null
                        ? AppTheme.textPrimary
                        : AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.values.map((method) {
        final isSelected = _paymentMethod == method;

        return FilterChip(
          label: Text(method.label),
          selected: isSelected,
          onSelected: (_) => setState(() => _paymentMethod = method),
          backgroundColor: Colors.white,
          selectedColor: AppTheme.primaryColor.withOpacity(0.1),
          checkmarkColor: AppTheme.primaryColor,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        );
      }).toList(),
    );
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um projeto'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final expense = ExpenseEntity(
      id: widget.existingExpense?.id ?? '',
      organizationId: authState.user.organizationId,
      projectId: _selectedProjectId!,
      createdBy: authState.user.id,
      extractedData: ExtractedData(
        vendor: _vendorController.text,
        invoiceNumber: _invoiceNumberController.text,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        totalAmount: double.tryParse(_totalController.text) ?? 0,
        taxAmount: double.tryParse(_taxController.text),
      ),
      paymentInfo: PaymentInfo(method: _paymentMethod),
      approval: const ApprovalInfo(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      metadata: const ExpenseMetadata(source: ExpenseSource.mobileScan),
      createdAt: widget.existingExpense?.createdAt ?? DateTime.now(),
    );

    if (widget.existingExpense != null) {
      context.read<ExpensesBloc>().add(ExpenseUpdateRequested(expense));
    } else {
      context.read<ExpensesBloc>().add(ExpenseCreateRequested(expense));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Despesa'),
        content: const Text('Tem a certeza que deseja eliminar esta despesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ExpensesBloc>().add(
                    ExpenseDeleteRequested(widget.existingExpense!.id),
                  );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockProject {
  final String id;
  final String name;

  _MockProject({required this.id, required this.name});
}

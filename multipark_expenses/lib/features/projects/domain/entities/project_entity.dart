import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

/// Entidade de Projeto
class ProjectEntity extends Equatable {
  final String id;
  final String organizationId;
  final String name;
  final String code;
  final ProjectType type;
  final ProjectStatus status;
  final ProjectBudget budget;
  final String? managerId;
  final String? departmentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectEntity({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    this.type = ProjectType.other,
    this.status = ProjectStatus.active,
    required this.budget,
    this.managerId,
    this.departmentId,
    this.startDate,
    this.endDate,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// Percentagem do orçamento gasto
  double get budgetUsedPercentage {
    if (budget.total == 0) return 0;
    return (budget.spent / budget.total) * 100;
  }

  /// Verifica se está ativo
  bool get isActive => status == ProjectStatus.active;

  /// Verifica se o orçamento foi excedido
  bool get isBudgetExceeded => budget.spent > budget.total;

  ProjectEntity copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? code,
    ProjectType? type,
    ProjectStatus? status,
    ProjectBudget? budget,
    String? managerId,
    String? departmentId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      managerId: managerId ?? this.managerId,
      departmentId: departmentId ?? this.departmentId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        name,
        code,
        type,
        status,
        budget,
        managerId,
        departmentId,
        startDate,
        endDate,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Orçamento do projeto
class ProjectBudget extends Equatable {
  final double total;
  final double spent;
  final double remaining;

  const ProjectBudget({
    this.total = 0,
    this.spent = 0,
    this.remaining = 0,
  });

  factory ProjectBudget.fromSpent({
    required double total,
    required double spent,
  }) {
    return ProjectBudget(
      total: total,
      spent: spent,
      remaining: total - spent,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'spent': spent,
        'remaining': remaining,
      };

  factory ProjectBudget.fromJson(Map<String, dynamic> json) {
    return ProjectBudget(
      total: (json['total'] as num?)?.toDouble() ?? 0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, spent, remaining];
}

enum ProjectType {
  parking,
  multibags,
  other;

  String get value {
    switch (this) {
      case ProjectType.parking:
        return AppConstants.projectParking;
      case ProjectType.multibags:
        return AppConstants.projectMultibags;
      case ProjectType.other:
        return AppConstants.projectOther;
    }
  }

  String get label {
    switch (this) {
      case ProjectType.parking:
        return 'Parque';
      case ProjectType.multibags:
        return 'Multibags';
      case ProjectType.other:
        return 'Outro';
    }
  }

  static ProjectType fromString(String value) {
    switch (value) {
      case AppConstants.projectParking:
        return ProjectType.parking;
      case AppConstants.projectMultibags:
        return ProjectType.multibags;
      default:
        return ProjectType.other;
    }
  }
}

enum ProjectStatus {
  active,
  inactive,
  completed;

  String get value {
    switch (this) {
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.inactive:
        return 'inactive';
      case ProjectStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case ProjectStatus.active:
        return 'Ativo';
      case ProjectStatus.inactive:
        return 'Inativo';
      case ProjectStatus.completed:
        return 'Concluído';
    }
  }

  static ProjectStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ProjectStatus.active;
      case 'inactive':
        return ProjectStatus.inactive;
      case 'completed':
        return ProjectStatus.completed;
      default:
        return ProjectStatus.active;
    }
  }
}

import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

/// Entidade de utilizador do sistema MultiPark
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final String? departmentId;
  final String organizationId;
  final UserPermissions permissions;
  final NotificationSettings notificationSettings;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.departmentId,
    required this.organizationId,
    required this.permissions,
    required this.notificationSettings,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  /// Verifica se o utilizador é Super Admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Verifica se o utilizador é Admin ou superior
  bool get isAdmin => role == UserRole.superAdmin || role == UserRole.admin;

  /// Verifica se pode aprovar despesas
  bool get canApproveExpenses => permissions.canApproveExpenses;

  /// Verifica se pode ver todas as despesas
  bool get canViewAllExpenses => permissions.canViewAllExpenses;

  /// Verifica se pode gerir utilizadores
  bool get canManageUsers => permissions.canManageUsers;

  /// Verifica se pode gerir projetos
  bool get canManageProjects => permissions.canManageProjects;

  /// Retorna o limite máximo de aprovação
  double get maxApprovalAmount => permissions.maxApprovalAmount;

  /// Verifica se pode aprovar um valor específico
  bool canApproveAmount(double amount) {
    return canApproveExpenses && amount <= maxApprovalAmount;
  }

  /// Cria uma cópia com campos alterados
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    String? departmentId,
    String? organizationId,
    UserPermissions? permissions,
    NotificationSettings? notificationSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      departmentId: departmentId ?? this.departmentId,
      organizationId: organizationId ?? this.organizationId,
      permissions: permissions ?? this.permissions,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        role,
        departmentId,
        organizationId,
        permissions,
        notificationSettings,
        createdAt,
        updatedAt,
        lastLoginAt,
        isActive,
      ];
}

/// Roles de utilizador no sistema
enum UserRole {
  superAdmin,
  admin,
  backoffice,
  teamLeader;

  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return AppConstants.roleSuperAdmin;
      case UserRole.admin:
        return AppConstants.roleAdmin;
      case UserRole.backoffice:
        return AppConstants.roleBackoffice;
      case UserRole.teamLeader:
        return AppConstants.roleTeamLeader;
    }
  }

  String get label => RoleLabels.getLabel(value);

  static UserRole fromString(String value) {
    switch (value) {
      case AppConstants.roleSuperAdmin:
        return UserRole.superAdmin;
      case AppConstants.roleAdmin:
        return UserRole.admin;
      case AppConstants.roleBackoffice:
        return UserRole.backoffice;
      case AppConstants.roleTeamLeader:
        return UserRole.teamLeader;
      default:
        return UserRole.teamLeader;
    }
  }

  /// Hierarquia de roles (quanto menor o número, maior a autoridade)
  int get hierarchy {
    switch (this) {
      case UserRole.superAdmin:
        return 0;
      case UserRole.admin:
        return 1;
      case UserRole.backoffice:
        return 2;
      case UserRole.teamLeader:
        return 3;
    }
  }

  /// Verifica se este role tem autoridade sobre outro
  bool hasAuthorityOver(UserRole other) {
    return hierarchy < other.hierarchy;
  }
}

/// Permissões do utilizador
class UserPermissions extends Equatable {
  final bool canApproveExpenses;
  final bool canViewAllExpenses;
  final bool canManageUsers;
  final bool canManageProjects;
  final double maxApprovalAmount;

  const UserPermissions({
    this.canApproveExpenses = false,
    this.canViewAllExpenses = false,
    this.canManageUsers = false,
    this.canManageProjects = false,
    this.maxApprovalAmount = 0.0,
  });

  /// Permissões padrão para Super Admin
  factory UserPermissions.superAdmin() {
    return const UserPermissions(
      canApproveExpenses: true,
      canViewAllExpenses: true,
      canManageUsers: true,
      canManageProjects: true,
      maxApprovalAmount: double.infinity,
    );
  }

  /// Permissões padrão para Admin
  factory UserPermissions.admin() {
    return const UserPermissions(
      canApproveExpenses: true,
      canViewAllExpenses: true,
      canManageUsers: false,
      canManageProjects: true,
      maxApprovalAmount: 10000.0,
    );
  }

  /// Permissões padrão para Backoffice
  factory UserPermissions.backoffice() {
    return const UserPermissions(
      canApproveExpenses: true,
      canViewAllExpenses: true,
      canManageUsers: false,
      canManageProjects: false,
      maxApprovalAmount: 1000.0,
    );
  }

  /// Permissões padrão para Team Leader
  factory UserPermissions.teamLeader() {
    return const UserPermissions(
      canApproveExpenses: false,
      canViewAllExpenses: false,
      canManageUsers: false,
      canManageProjects: false,
      maxApprovalAmount: 0.0,
    );
  }

  /// Cria permissões baseadas no role
  factory UserPermissions.fromRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return UserPermissions.superAdmin();
      case UserRole.admin:
        return UserPermissions.admin();
      case UserRole.backoffice:
        return UserPermissions.backoffice();
      case UserRole.teamLeader:
        return UserPermissions.teamLeader();
    }
  }

  Map<String, dynamic> toJson() => {
        'canApproveExpenses': canApproveExpenses,
        'canViewAllExpenses': canViewAllExpenses,
        'canManageUsers': canManageUsers,
        'canManageProjects': canManageProjects,
        'maxApprovalAmount': maxApprovalAmount == double.infinity ? -1 : maxApprovalAmount,
      };

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    final maxAmount = json['maxApprovalAmount'] as num?;
    return UserPermissions(
      canApproveExpenses: json['canApproveExpenses'] as bool? ?? false,
      canViewAllExpenses: json['canViewAllExpenses'] as bool? ?? false,
      canManageUsers: json['canManageUsers'] as bool? ?? false,
      canManageProjects: json['canManageProjects'] as bool? ?? false,
      maxApprovalAmount: maxAmount == -1 || maxAmount == null
          ? double.infinity
          : maxAmount.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        canApproveExpenses,
        canViewAllExpenses,
        canManageUsers,
        canManageProjects,
        maxApprovalAmount,
      ];
}

/// Configurações de notificação do utilizador
class NotificationSettings extends Equatable {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool paymentAlerts;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.paymentAlerts = true,
  });

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'paymentAlerts': paymentAlerts,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      paymentAlerts: json['paymentAlerts'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [pushEnabled, emailEnabled, paymentAlerts];
}

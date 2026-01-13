import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Modelo de dados do utilizador para serialização/deserialização
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.role,
    super.departmentId,
    required super.organizationId,
    required super.permissions,
    required super.notificationSettings,
    required super.createdAt,
    super.updatedAt,
    super.lastLoginAt,
    super.isActive,
  });

  /// Cria UserModel a partir de DocumentSnapshot do Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'id': doc.id});
  }

  /// Cria UserModel a partir de JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'team_leader'),
      departmentId: json['departmentId'] as String?,
      organizationId: json['organizationId'] as String,
      permissions: json['permissions'] != null
          ? UserPermissions.fromJson(json['permissions'] as Map<String, dynamic>)
          : UserPermissions.teamLeader(),
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettings.fromJson(
              json['notificationSettings'] as Map<String, dynamic>)
          : const NotificationSettings(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updatedAt']),
      lastLoginAt: _parseDateTimeNullable(json['lastLoginAt']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Converte para JSON para guardar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.value,
      'departmentId': departmentId,
      'organizationId': organizationId,
      'permissions': permissions.toJson(),
      'notificationSettings': notificationSettings.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  /// Converte UserEntity para UserModel
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      role: entity.role,
      departmentId: entity.departmentId,
      organizationId: entity.organizationId,
      permissions: entity.permissions,
      notificationSettings: entity.notificationSettings,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastLoginAt: entity.lastLoginAt,
      isActive: entity.isActive,
    );
  }

  /// Converte para UserEntity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      departmentId: departmentId,
      organizationId: organizationId,
      permissions: permissions,
      notificationSettings: notificationSettings,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      isActive: isActive,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense_entity.dart';

/// Modelo de dados da Despesa para serialização/deserialização
class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.organizationId,
    required super.projectId,
    super.departmentId,
    super.categoryId,
    required super.createdBy,
    super.assignedTo,
    super.receiptData,
    required super.extractedData,
    super.items,
    required super.paymentInfo,
    required super.approval,
    super.tags,
    super.notes,
    required super.metadata,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  /// Cria ExpenseModel a partir de DocumentSnapshot do Firestore
  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel.fromJson({...data, 'id': doc.id});
  }

  /// Cria ExpenseModel a partir de JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      projectId: json['projectId'] as String,
      departmentId: json['departmentId'] as String?,
      categoryId: json['categoryId'] as String?,
      createdBy: json['createdBy'] as String,
      assignedTo: json['assignedTo'] as String?,
      receiptData: json['receiptData'] != null
          ? ReceiptData.fromJson(json['receiptData'] as Map<String, dynamic>)
          : null,
      extractedData: json['extractedData'] != null
          ? ExtractedData.fromJson(json['extractedData'] as Map<String, dynamic>)
          : const ExtractedData(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ExpenseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'] as Map<String, dynamic>)
          : const PaymentInfo(method: PaymentMethod.cash),
      approval: json['approval'] != null
          ? ApprovalInfo.fromJson(json['approval'] as Map<String, dynamic>)
          : const ApprovalInfo(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      notes: json['notes'] as String?,
      metadata: json['metadata'] != null
          ? ExpenseMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : const ExpenseMetadata(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTimeNullable(json['updatedAt']),
      deletedAt: _parseDateTimeNullable(json['deletedAt']),
    );
  }

  /// Converte para JSON para guardar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'projectId': projectId,
      'departmentId': departmentId,
      'categoryId': categoryId,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'receiptData': receiptData?.toJson(),
      'extractedData': extractedData.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'paymentInfo': paymentInfo.toJson(),
      'approval': approval.toJson(),
      'tags': tags,
      'notes': notes,
      'metadata': metadata.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  /// Converte ExpenseEntity para ExpenseModel
  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      organizationId: entity.organizationId,
      projectId: entity.projectId,
      departmentId: entity.departmentId,
      categoryId: entity.categoryId,
      createdBy: entity.createdBy,
      assignedTo: entity.assignedTo,
      receiptData: entity.receiptData,
      extractedData: entity.extractedData,
      items: entity.items,
      paymentInfo: entity.paymentInfo,
      approval: entity.approval,
      tags: entity.tags,
      notes: entity.notes,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  /// Converte para ExpenseEntity
  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      organizationId: organizationId,
      projectId: projectId,
      departmentId: departmentId,
      categoryId: categoryId,
      createdBy: createdBy,
      assignedTo: assignedTo,
      receiptData: receiptData,
      extractedData: extractedData,
      items: items,
      paymentInfo: paymentInfo,
      approval: approval,
      tags: tags,
      notes: notes,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
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

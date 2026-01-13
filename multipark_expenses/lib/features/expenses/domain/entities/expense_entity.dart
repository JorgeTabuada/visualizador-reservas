import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

/// Entidade principal de Despesa
class ExpenseEntity extends Equatable {
  final String id;
  final String organizationId;
  final String projectId; // OBRIGATÓRIO
  final String? departmentId;
  final String? categoryId;
  final String createdBy;
  final String? assignedTo;
  final ReceiptData? receiptData;
  final ExtractedData extractedData;
  final List<ExpenseItem> items;
  final PaymentInfo paymentInfo;
  final ApprovalInfo approval;
  final List<String> tags;
  final String? notes;
  final ExpenseMetadata metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ExpenseEntity({
    required this.id,
    required this.organizationId,
    required this.projectId,
    this.departmentId,
    this.categoryId,
    required this.createdBy,
    this.assignedTo,
    this.receiptData,
    required this.extractedData,
    this.items = const [],
    required this.paymentInfo,
    required this.approval,
    this.tags = const [],
    this.notes,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Total da despesa
  double get totalAmount => extractedData.totalAmount ?? 0.0;

  /// Verifica se está pendente de aprovação
  bool get isPendingApproval => approval.status == ApprovalStatus.pending;

  /// Verifica se foi aprovada
  bool get isApproved => approval.status == ApprovalStatus.approved;

  /// Verifica se foi rejeitada
  bool get isRejected => approval.status == ApprovalStatus.rejected;

  /// Verifica se está paga
  bool get isPaid => paymentInfo.status == PaymentStatus.paid;

  /// Verifica se está vencida
  bool get isOverdue {
    if (paymentInfo.status == PaymentStatus.paid) return false;
    if (extractedData.dueDate == null) return false;
    return DateTime.now().isAfter(extractedData.dueDate!);
  }

  /// Dias até o vencimento (negativo se vencida)
  int? get daysUntilDue {
    if (extractedData.dueDate == null) return null;
    return extractedData.dueDate!.difference(DateTime.now()).inDays;
  }

  ExpenseEntity copyWith({
    String? id,
    String? organizationId,
    String? projectId,
    String? departmentId,
    String? categoryId,
    String? createdBy,
    String? assignedTo,
    ReceiptData? receiptData,
    ExtractedData? extractedData,
    List<ExpenseItem>? items,
    PaymentInfo? paymentInfo,
    ApprovalInfo? approval,
    List<String>? tags,
    String? notes,
    ExpenseMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      projectId: projectId ?? this.projectId,
      departmentId: departmentId ?? this.departmentId,
      categoryId: categoryId ?? this.categoryId,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      receiptData: receiptData ?? this.receiptData,
      extractedData: extractedData ?? this.extractedData,
      items: items ?? this.items,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      approval: approval ?? this.approval,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        projectId,
        departmentId,
        categoryId,
        createdBy,
        assignedTo,
        receiptData,
        extractedData,
        items,
        paymentInfo,
        approval,
        tags,
        notes,
        metadata,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

/// Dados do recibo/fatura digitalizado
class ReceiptData extends Equatable {
  final String imageUrl;
  final String? thumbnailUrl;
  final String? ocrRawText;
  final double ocrConfidence;
  final DateTime? ocrProcessedAt;

  const ReceiptData({
    required this.imageUrl,
    this.thumbnailUrl,
    this.ocrRawText,
    this.ocrConfidence = 0.0,
    this.ocrProcessedAt,
  });

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'ocrRawText': ocrRawText,
        'ocrConfidence': ocrConfidence,
        'ocrProcessedAt': ocrProcessedAt?.toIso8601String(),
      };

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      ocrRawText: json['ocrRawText'] as String?,
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble() ?? 0.0,
      ocrProcessedAt: json['ocrProcessedAt'] != null
          ? DateTime.parse(json['ocrProcessedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        imageUrl,
        thumbnailUrl,
        ocrRawText,
        ocrConfidence,
        ocrProcessedAt,
      ];
}

/// Dados extraídos da fatura
class ExtractedData extends Equatable {
  final String? vendor;
  final String? vendorTaxId;
  final String? invoiceNumber;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final double? subtotal;
  final double? taxAmount;
  final double? totalAmount;
  final String currency;

  const ExtractedData({
    this.vendor,
    this.vendorTaxId,
    this.invoiceNumber,
    this.invoiceDate,
    this.dueDate,
    this.subtotal,
    this.taxAmount,
    this.totalAmount,
    this.currency = 'EUR',
  });

  Map<String, dynamic> toJson() => {
        'vendor': vendor,
        'vendorTaxId': vendorTaxId,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'currency': currency,
      };

  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      vendor: json['vendor'] as String?,
      vendorTaxId: json['vendorTaxId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
    );
  }

  @override
  List<Object?> get props => [
        vendor,
        vendorTaxId,
        invoiceNumber,
        invoiceDate,
        dueDate,
        subtotal,
        taxAmount,
        totalAmount,
        currency,
      ];
}

/// Item individual da despesa
class ExpenseItem extends Equatable {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int? taxRate;

  const ExpenseItem({
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.taxRate,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'taxRate': taxRate,
      };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      description: json['description'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      taxRate: json['taxRate'] as int?,
    );
  }

  @override
  List<Object?> get props => [description, quantity, unitPrice, totalPrice, taxRate];
}

/// Informação de pagamento
class PaymentInfo extends Equatable {
  final PaymentMethod method;
  final PaymentStatus status;
  final double paidAmount;
  final DateTime? paidAt;
  final String? paidBy;
  final String? reference;

  const PaymentInfo({
    required this.method,
    this.status = PaymentStatus.pending,
    this.paidAmount = 0.0,
    this.paidAt,
    this.paidBy,
    this.reference,
  });

  Map<String, dynamic> toJson() => {
        'method': method.value,
        'status': status.value,
        'paidAmount': paidAmount,
        'paidAt': paidAt?.toIso8601String(),
        'paidBy': paidBy,
        'reference': reference,
      };

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: PaymentMethod.fromString(json['method'] as String? ?? 'cash'),
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      paidBy: json['paidBy'] as String?,
      reference: json['reference'] as String?,
    );
  }

  PaymentInfo copyWith({
    PaymentMethod? method,
    PaymentStatus? status,
    double? paidAmount,
    DateTime? paidAt,
    String? paidBy,
    String? reference,
  }) {
    return PaymentInfo(
      method: method ?? this.method,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      reference: reference ?? this.reference,
    );
  }

  @override
  List<Object?> get props => [method, status, paidAmount, paidAt, paidBy, reference];
}

/// Informação de aprovação
class ApprovalInfo extends Equatable {
  final ApprovalStatus status;
  final String? requiredLevel;
  final String? currentLevel;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final List<ApprovalHistoryEntry> history;

  const ApprovalInfo({
    this.status = ApprovalStatus.pending,
    this.requiredLevel,
    this.currentLevel,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.history = const [],
  });

  Map<String, dynamic> toJson() => {
        'status': status.value,
        'requiredLevel': requiredLevel,
        'currentLevel': currentLevel,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory ApprovalInfo.fromJson(Map<String, dynamic> json) {
    return ApprovalInfo(
      status: ApprovalStatus.fromString(json['status'] as String? ?? 'pending'),
      requiredLevel: json['requiredLevel'] as String?,
      currentLevel: json['currentLevel'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => ApprovalHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ApprovalInfo copyWith({
    ApprovalStatus? status,
    String? requiredLevel,
    String? currentLevel,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    List<ApprovalHistoryEntry>? history,
  }) {
    return ApprovalInfo(
      status: status ?? this.status,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      currentLevel: currentLevel ?? this.currentLevel,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        status,
        requiredLevel,
        currentLevel,
        approvedBy,
        approvedAt,
        rejectionReason,
        history,
      ];
}

/// Entrada no histórico de aprovação
class ApprovalHistoryEntry extends Equatable {
  final String action;
  final String userId;
  final DateTime timestamp;
  final String? comment;

  const ApprovalHistoryEntry({
    required this.action,
    required this.userId,
    required this.timestamp,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'comment': comment,
      };

  factory ApprovalHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ApprovalHistoryEntry(
      action: json['action'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      comment: json['comment'] as String?,
    );
  }

  @override
  List<Object?> get props => [action, userId, timestamp, comment];
}

/// Metadados da despesa
class ExpenseMetadata extends Equatable {
  final ExpenseSource source;
  final String? deviceInfo;
  final String? appVersion;

  const ExpenseMetadata({
    this.source = ExpenseSource.manual,
    this.deviceInfo,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'source': source.value,
        'deviceInfo': deviceInfo,
        'appVersion': appVersion,
      };

  factory ExpenseMetadata.fromJson(Map<String, dynamic> json) {
    return ExpenseMetadata(
      source: ExpenseSource.fromString(json['source'] as String? ?? 'manual'),
      deviceInfo: json['deviceInfo'] as String?,
      appVersion: json['appVersion'] as String?,
    );
  }

  @override
  List<Object?> get props => [source, deviceInfo, appVersion];
}

// ============ ENUMS ============

enum PaymentMethod {
  cash,
  companyCard,
  personalCard,
  transfer,
  mbway;

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return AppConstants.paymentCash;
      case PaymentMethod.companyCard:
        return AppConstants.paymentCompanyCard;
      case PaymentMethod.personalCard:
        return AppConstants.paymentPersonalCard;
      case PaymentMethod.transfer:
        return AppConstants.paymentTransfer;
      case PaymentMethod.mbway:
        return AppConstants.paymentMBWay;
    }
  }

  String get label => PaymentMethodLabels.getLabel(value);

  static PaymentMethod fromString(String value) {
    switch (value) {
      case AppConstants.paymentCash:
        return PaymentMethod.cash;
      case AppConstants.paymentCompanyCard:
        return PaymentMethod.companyCard;
      case AppConstants.paymentPersonalCard:
        return PaymentMethod.personalCard;
      case AppConstants.paymentTransfer:
        return PaymentMethod.transfer;
      case AppConstants.paymentMBWay:
        return PaymentMethod.mbway;
      default:
        return PaymentMethod.cash;
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  partial,
  overdue;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return AppConstants.paymentPending;
      case PaymentStatus.paid:
        return AppConstants.paymentPaid;
      case PaymentStatus.partial:
        return AppConstants.paymentPartial;
      case PaymentStatus.overdue:
        return AppConstants.paymentOverdue;
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case AppConstants.paymentPending:
        return PaymentStatus.pending;
      case AppConstants.paymentPaid:
        return PaymentStatus.paid;
      case AppConstants.paymentPartial:
        return PaymentStatus.partial;
      case AppConstants.paymentOverdue:
        return PaymentStatus.overdue;
      default:
        return PaymentStatus.pending;
    }
  }
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  revisionRequired;

  String get value {
    switch (this) {
      case ApprovalStatus.pending:
        return AppConstants.statusPending;
      case ApprovalStatus.approved:
        return AppConstants.statusApproved;
      case ApprovalStatus.rejected:
        return AppConstants.statusRejected;
      case ApprovalStatus.revisionRequired:
        return AppConstants.statusRevisionRequired;
    }
  }

  String get label => ApprovalStatusLabels.getLabel(value);

  static ApprovalStatus fromString(String value) {
    switch (value) {
      case AppConstants.statusPending:
        return ApprovalStatus.pending;
      case AppConstants.statusApproved:
        return ApprovalStatus.approved;
      case AppConstants.statusRejected:
        return ApprovalStatus.rejected;
      case AppConstants.statusRevisionRequired:
        return ApprovalStatus.revisionRequired;
      default:
        return ApprovalStatus.pending;
    }
  }
}

enum ExpenseSource {
  mobileScan,
  manual,
  emailForward;

  String get value {
    switch (this) {
      case ExpenseSource.mobileScan:
        return 'mobile_scan';
      case ExpenseSource.manual:
        return 'manual';
      case ExpenseSource.emailForward:
        return 'email_forward';
    }
  }

  static ExpenseSource fromString(String value) {
    switch (value) {
      case 'mobile_scan':
        return ExpenseSource.mobileScan;
      case 'manual':
        return ExpenseSource.manual;
      case 'email_forward':
        return ExpenseSource.emailForward;
      default:
        return ExpenseSource.manual;
    }
  }
}

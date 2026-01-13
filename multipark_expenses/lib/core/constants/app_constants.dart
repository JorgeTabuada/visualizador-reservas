/// Constantes globais da aplicação MultiPark
class AppConstants {
  AppConstants._();

  // ============ APP INFO ============
  static const String appName = 'MultiPark';
  static const String appVersion = '1.0.0';
  static const String moduleName = 'Despesas';

  // ============ FIREBASE COLLECTIONS ============
  static const String usersCollection = 'users';
  static const String organizationsCollection = 'organizations';
  static const String projectsCollection = 'projects';
  static const String expensesCollection = 'expenses';
  static const String expenseCategoriesCollection = 'expense_categories';
  static const String paymentAlertsCollection = 'payment_alerts';
  static const String departmentsCollection = 'departments';

  // ============ STORAGE PATHS ============
  static const String receiptImagesPath = 'receipts';
  static const String userAvatarsPath = 'avatars';
  static const String documentsPath = 'documents';

  // ============ USER ROLES ============
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleBackoffice = 'backoffice';
  static const String roleTeamLeader = 'team_leader';

  // ============ EXPENSE STATUS ============
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusRevisionRequired = 'revision_required';

  // ============ PAYMENT STATUS ============
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentPartial = 'partial';
  static const String paymentOverdue = 'overdue';

  // ============ PAYMENT METHODS ============
  static const String paymentCash = 'cash';
  static const String paymentCompanyCard = 'company_card';
  static const String paymentPersonalCard = 'personal_card';
  static const String paymentTransfer = 'transfer';
  static const String paymentMBWay = 'mbway';

  // ============ ALERT TYPES ============
  static const String alertPaymentDue = 'payment_due';
  static const String alertPaymentOverdue = 'payment_overdue';
  static const String alertBudgetExceeded = 'budget_exceeded';

  // ============ ALERT SEVERITY ============
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';

  // ============ PROJECT TYPES ============
  static const String projectParking = 'parking';
  static const String projectMultibags = 'multibags';
  static const String projectOther = 'other';

  // ============ DATE FORMATS ============
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String monthYearFormat = 'MMMM yyyy';

  // ============ CURRENCY ============
  static const String defaultCurrency = 'EUR';
  static const String currencySymbol = '€';
  static const int decimalPlaces = 2;

  // ============ PAGINATION ============
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============ CACHE ============
  static const Duration cacheDuration = Duration(hours: 1);
  static const String cacheBoxExpenses = 'expenses_cache';
  static const String cacheBoxProjects = 'projects_cache';
  static const String cacheBoxUser = 'user_cache';

  // ============ OCR ============
  static const double ocrMinConfidence = 0.7;
  static const int maxReceiptImageSize = 2048; // pixels
  static const int imageQuality = 85; // percentage

  // ============ VALIDATION ============
  static const int minPasswordLength = 8;
  static const int maxNotesLength = 500;
  static const double maxExpenseAmount = 100000.0;
  static const double minExpenseAmount = 0.01;

  // ============ TIMEOUTS ============
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration ocrTimeout = Duration(seconds: 60);

  // ============ NOTIFICATION CHANNELS ============
  static const String notificationChannelExpenses = 'expenses';
  static const String notificationChannelAlerts = 'alerts';
  static const String notificationChannelGeneral = 'general';
}

/// Mapeamento de roles para labels em português
class RoleLabels {
  static const Map<String, String> labels = {
    AppConstants.roleSuperAdmin: 'Super Administrador',
    AppConstants.roleAdmin: 'Administrador',
    AppConstants.roleBackoffice: 'Backoffice',
    AppConstants.roleTeamLeader: 'Team Leader',
  };

  static String getLabel(String role) => labels[role] ?? role;
}

/// Mapeamento de métodos de pagamento para labels
class PaymentMethodLabels {
  static const Map<String, String> labels = {
    AppConstants.paymentCash: 'Dinheiro',
    AppConstants.paymentCompanyCard: 'Cartão Empresa',
    AppConstants.paymentPersonalCard: 'Cartão Pessoal',
    AppConstants.paymentTransfer: 'Transferência',
    AppConstants.paymentMBWay: 'MB Way',
  };

  static String getLabel(String method) => labels[method] ?? method;
}

/// Mapeamento de status de aprovação para labels
class ApprovalStatusLabels {
  static const Map<String, String> labels = {
    AppConstants.statusPending: 'Pendente',
    AppConstants.statusApproved: 'Aprovado',
    AppConstants.statusRejected: 'Rejeitado',
    AppConstants.statusRevisionRequired: 'Revisão Necessária',
  };

  static String getLabel(String status) => labels[status] ?? status;
}

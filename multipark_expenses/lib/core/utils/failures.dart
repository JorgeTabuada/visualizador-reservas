import 'package:equatable/equatable.dart';

/// Classe base para falhas na aplicação
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Falha de autenticação
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});

  factory AuthFailure.invalidCredentials() {
    return const AuthFailure(
      message: 'Email ou password incorretos',
      code: 'invalid-credentials',
    );
  }

  factory AuthFailure.userNotFound() {
    return const AuthFailure(
      message: 'Utilizador não encontrado',
      code: 'user-not-found',
    );
  }

  factory AuthFailure.userDisabled() {
    return const AuthFailure(
      message: 'Esta conta foi desativada',
      code: 'user-disabled',
    );
  }

  factory AuthFailure.emailAlreadyInUse() {
    return const AuthFailure(
      message: 'Este email já está em uso',
      code: 'email-already-in-use',
    );
  }

  factory AuthFailure.weakPassword() {
    return const AuthFailure(
      message: 'A password é demasiado fraca',
      code: 'weak-password',
    );
  }

  factory AuthFailure.tooManyRequests() {
    return const AuthFailure(
      message: 'Demasiadas tentativas. Tente novamente mais tarde',
      code: 'too-many-requests',
    );
  }

  factory AuthFailure.sessionExpired() {
    return const AuthFailure(
      message: 'Sessão expirada. Por favor, faça login novamente',
      code: 'session-expired',
    );
  }

  factory AuthFailure.unknown([String? details]) {
    return AuthFailure(
      message: details ?? 'Erro de autenticação desconhecido',
      code: 'unknown',
    );
  }
}

/// Falha de servidor/rede
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});

  factory ServerFailure.noConnection() {
    return const ServerFailure(
      message: 'Sem ligação à internet',
      code: 'no-connection',
    );
  }

  factory ServerFailure.timeout() {
    return const ServerFailure(
      message: 'O servidor demorou demasiado a responder',
      code: 'timeout',
    );
  }

  factory ServerFailure.serverError([String? details]) {
    return ServerFailure(
      message: details ?? 'Erro no servidor',
      code: 'server-error',
    );
  }

  factory ServerFailure.unknown([String? details]) {
    return ServerFailure(
      message: details ?? 'Erro desconhecido',
      code: 'unknown',
    );
  }
}

/// Falha de validação de dados
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    this.fieldErrors,
  });

  factory ValidationFailure.invalidData([String? details]) {
    return ValidationFailure(
      message: details ?? 'Dados inválidos',
      code: 'invalid-data',
    );
  }

  factory ValidationFailure.requiredField(String fieldName) {
    return ValidationFailure(
      message: 'O campo $fieldName é obrigatório',
      code: 'required-field',
      fieldErrors: {fieldName: 'Campo obrigatório'},
    );
  }

  factory ValidationFailure.invalidFormat(String fieldName, String expected) {
    return ValidationFailure(
      message: 'Formato inválido para $fieldName. Esperado: $expected',
      code: 'invalid-format',
      fieldErrors: {fieldName: 'Formato inválido'},
    );
  }

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Falha de permissão
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});

  factory PermissionFailure.accessDenied() {
    return const PermissionFailure(
      message: 'Acesso negado. Não tem permissões para esta ação',
      code: 'access-denied',
    );
  }

  factory PermissionFailure.insufficientRole(String requiredRole) {
    return PermissionFailure(
      message: 'Necessita do role $requiredRole para esta ação',
      code: 'insufficient-role',
    );
  }

  factory PermissionFailure.approvalLimitExceeded(double limit) {
    return PermissionFailure(
      message: 'O valor excede o seu limite de aprovação (€${limit.toStringAsFixed(2)})',
      code: 'approval-limit-exceeded',
    );
  }
}

/// Falha de armazenamento
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});

  factory StorageFailure.uploadFailed([String? details]) {
    return StorageFailure(
      message: details ?? 'Falha ao carregar ficheiro',
      code: 'upload-failed',
    );
  }

  factory StorageFailure.downloadFailed([String? details]) {
    return StorageFailure(
      message: details ?? 'Falha ao descarregar ficheiro',
      code: 'download-failed',
    );
  }

  factory StorageFailure.fileTooLarge(int maxSizeMb) {
    return StorageFailure(
      message: 'Ficheiro demasiado grande. Tamanho máximo: ${maxSizeMb}MB',
      code: 'file-too-large',
    );
  }

  factory StorageFailure.invalidFileType(List<String> allowedTypes) {
    return StorageFailure(
      message: 'Tipo de ficheiro não permitido. Tipos aceites: ${allowedTypes.join(", ")}',
      code: 'invalid-file-type',
    );
  }
}

/// Falha de OCR
class OcrFailure extends Failure {
  const OcrFailure({required super.message, super.code});

  factory OcrFailure.processingFailed([String? details]) {
    return OcrFailure(
      message: details ?? 'Falha ao processar imagem',
      code: 'processing-failed',
    );
  }

  factory OcrFailure.lowConfidence() {
    return const OcrFailure(
      message: 'Não foi possível ler a fatura com confiança suficiente. Por favor, tire uma nova foto',
      code: 'low-confidence',
    );
  }

  factory OcrFailure.noTextFound() {
    return const OcrFailure(
      message: 'Não foi encontrado texto na imagem',
      code: 'no-text-found',
    );
  }
}

/// Falha de despesa
class ExpenseFailure extends Failure {
  const ExpenseFailure({required super.message, super.code});

  factory ExpenseFailure.notFound() {
    return const ExpenseFailure(
      message: 'Despesa não encontrada',
      code: 'not-found',
    );
  }

  factory ExpenseFailure.projectRequired() {
    return const ExpenseFailure(
      message: 'É obrigatório associar um projeto à despesa',
      code: 'project-required',
    );
  }

  factory ExpenseFailure.alreadyApproved() {
    return const ExpenseFailure(
      message: 'Esta despesa já foi aprovada e não pode ser alterada',
      code: 'already-approved',
    );
  }

  factory ExpenseFailure.createFailed([String? details]) {
    return ExpenseFailure(
      message: details ?? 'Falha ao criar despesa',
      code: 'create-failed',
    );
  }

  factory ExpenseFailure.updateFailed([String? details]) {
    return ExpenseFailure(
      message: details ?? 'Falha ao atualizar despesa',
      code: 'update-failed',
    );
  }

  factory ExpenseFailure.deleteFailed([String? details]) {
    return ExpenseFailure(
      message: details ?? 'Falha ao eliminar despesa',
      code: 'delete-failed',
    );
  }
}

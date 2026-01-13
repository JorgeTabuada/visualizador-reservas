import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Serviço de notificações push
class NotificationService {
  final FirebaseMessaging _messaging;
  String? _fcmToken;

  NotificationService(this._messaging);

  String? get fcmToken => _fcmToken;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    // Solicitar permissão
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Permissão de notificações: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Obter token FCM
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Subscrever a tópicos
      await _subscribeToTopics();

      // Configurar handlers
      _configureMessageHandlers();
    }
  }

  /// Subscreve aos tópicos de notificação relevantes
  Future<void> _subscribeToTopics() async {
    await _messaging.subscribeToTopic(AppConstants.notificationChannelGeneral);
    await _messaging.subscribeToTopic(AppConstants.notificationChannelExpenses);
  }

  /// Subscreve ao tópico de alertas (apenas para Super Admin)
  Future<void> subscribeToAlerts() async {
    await _messaging.subscribeToTopic(AppConstants.notificationChannelAlerts);
    debugPrint('Subscrito a alertas de pagamento');
  }

  /// Cancela subscrição aos alertas
  Future<void> unsubscribeFromAlerts() async {
    await _messaging.unsubscribeFromTopic(AppConstants.notificationChannelAlerts);
  }

  /// Configura os handlers de mensagens
  void _configureMessageHandlers() {
    // Mensagem recebida com app em primeiro plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensagem recebida quando app é aberto via notificação
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar se app foi aberto via notificação
    _checkInitialMessage();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Mensagem em foreground: ${message.notification?.title}');

    // TODO: Mostrar notificação local ou atualizar UI
    // Pode-se usar flutter_local_notifications para mostrar a notificação
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App aberto via notificação: ${message.notification?.title}');

    // TODO: Navegar para o ecrã apropriado baseado nos dados da mensagem
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'expense_approved':
        case 'expense_rejected':
          // Navegar para detalhes da despesa
          break;
        case 'payment_alert':
          // Navegar para alertas
          break;
      }
    }
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Atualiza o token FCM do utilizador no Firestore
  Future<void> updateUserToken(String userId) async {
    if (_fcmToken == null) return;

    // TODO: Guardar token no documento do utilizador
    debugPrint('Token FCM atualizado para utilizador: $userId');
  }

  /// Envia notificação local (para alertas do sistema)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // TODO: Implementar com flutter_local_notifications
    debugPrint('Notificação local: $title - $body');
  }
}

/// Tipos de notificação suportados
enum NotificationType {
  expenseCreated('expense_created'),
  expenseApproved('expense_approved'),
  expenseRejected('expense_rejected'),
  expenseRevisionRequired('expense_revision_required'),
  paymentDue('payment_due'),
  paymentOverdue('payment_overdue'),
  budgetExceeded('budget_exceeded');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.expenseCreated,
    );
  }
}

/// Modelo de dados de uma notificação
class NotificationData {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationData.fromFirestore(Map<String, dynamic> json, String id) {
    return NotificationData(
      id: id,
      type: NotificationType.fromString(json['type'] as String? ?? ''),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

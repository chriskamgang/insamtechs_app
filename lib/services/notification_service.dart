import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase and notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      throw Exception('Failed to initialize notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permissions');
    } else {
      print('❌ User declined or has not accepted notification permissions');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token refreshed: $newToken');
        // Send updated token to server
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is launched from terminated state
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Received foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔓 App opened from notification: ${message.messageId}');

    // Navigate to appropriate screen based on message data
    _handleNotificationNavigation(message);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');

    // Handle local notification tap
    if (response.payload != null) {
      // Parse payload and navigate
      _handleLocalNotificationNavigation(response.payload!);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel for INSAM TCHS',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'INSAM TCHS',
      message.notification?.body ?? 'Nouvelle notification',
      details,
      payload: _createNotificationPayload(message),
    );
  }

  /// Create notification payload
  String _createNotificationPayload(RemoteMessage message) {
    return '''
{
  "messageId": "${message.messageId}",
  "data": ${message.data.toString()},
  "type": "${message.data['type'] ?? 'general'}"
}
''';
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(RemoteMessage message) {
    final type = message.data['type'];
    final data = message.data;

    switch (type) {
      case 'message':
        _navigateToMessage(data);
        break;
      case 'course_update':
        _navigateToCourse(data);
        break;
      case 'payment_confirmation':
        _navigateToPayment(data);
        break;
      case 'exam_reminder':
        _navigateToExam(data);
        break;
      default:
        _navigateToHome();
    }
  }

  /// Handle local notification navigation
  void _handleLocalNotificationNavigation(String payload) {
    try {
      // Parse payload and navigate accordingly
      print('Handling local notification navigation: $payload');
      // Implement navigation logic based on payload
    } catch (e) {
      print('Error handling local notification navigation: $e');
    }
  }

  /// Navigation methods
  void _navigateToMessage(Map<String, dynamic> data) {
    final conversationId = data['conversation_id'];
    print('Navigate to message: $conversationId');
    // TODO: Implement navigation to specific conversation
  }

  void _navigateToCourse(Map<String, dynamic> data) {
    final courseId = data['course_id'];
    print('Navigate to course: $courseId');
    // TODO: Implement navigation to specific course
  }

  void _navigateToPayment(Map<String, dynamic> data) {
    final orderId = data['order_id'];
    print('Navigate to payment: $orderId');
    // TODO: Implement navigation to payment confirmation
  }

  void _navigateToExam(Map<String, dynamic> data) {
    final examId = data['exam_id'];
    print('Navigate to exam: $examId');
    // TODO: Implement navigation to exam
  }

  void _navigateToHome() {
    print('Navigate to home');
    // TODO: Implement navigation to home screen
  }

  /// Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: Send token to your backend server
      print('📤 Sending FCM token to server: $token');

      // Example API call (implement with your ApiService)
      /*
      await ApiService().post('/user/fcm-token', data: {
        'token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
      });
      */
    } catch (e) {
      print('❌ Error sending FCM token to server: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications for development',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Test Notification',
      'This is a test notification from INSAM TCHS',
      details,
    );
  }

  /// Predefined topics for subscriptions
  static const String topicAllUsers = 'all_users';
  static const String topicCourseUpdates = 'course_updates';
  static const String topicPaymentNotifications = 'payment_notifications';
  static const String topicExamReminders = 'exam_reminders';
  static const String topicMaintenanceNotifications = 'maintenance_notifications';

  /// Subscribe to default topics
  Future<void> subscribeToDefaultTopics() async {
    await subscribeToTopic(topicAllUsers);
    await subscribeToTopic(topicCourseUpdates);
    await subscribeToTopic(topicPaymentNotifications);
    await subscribeToTopic(topicExamReminders);
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final settings = await _firebaseMessaging.getNotificationSettings();

    return {
      'enabled': settings.authorizationStatus == AuthorizationStatus.authorized,
      'alert': settings.alert == AppleNotificationSetting.enabled,
      'badge': settings.badge == AppleNotificationSetting.enabled,
      'sound': settings.sound == AppleNotificationSetting.enabled,
    };
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message received: ${message.messageId}');

  // Handle background message processing here
  // This runs even when the app is completely closed
}
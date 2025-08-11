import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: kReleaseMode ? Level.warning : Level.debug,
  );
  bool _isInitialized = false;

  /// Initialize notification service and timezone
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      final location = tz.getLocation('Asia/Kolkata'); // Adjust to your timezone
      tz.setLocalLocation(location);

      // Initialize settings for Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize settings for iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      _logger.d('Notification service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing notification service: $e');
    }
  }

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'splitzy_channel',
        'Splitzy Notifications',
        channelDescription: 'Notifications from Splitzy app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
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

      await _localNotifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      _logger.e('Error showing notification: $e');
    }
  }

  /// Show expense reminder notification
  Future<void> showExpenseReminder({
    required String groupName,
    required String expenseTitle,
    required double amount,
  }) async {
    await showNotification(
      title: 'Expense Reminder',
      body:
      'New expense in $groupName: $expenseTitle (₹${amount.toStringAsFixed(2)})',
      id: 1,
      payload: 'expense_reminder',
    );
  }

  /// Show settlement reminder notification
  Future<void> showSettlementReminder({
    required String groupName,
    required String fromUser,
    required String toUser,
    required double amount,
  }) async {
    await showNotification(
      title: 'Settlement Reminder',
      body:
      '$fromUser owes $toUser ₹${amount.toStringAsFixed(2)} in $groupName',
      id: 2,
      payload: 'settlement_reminder',
    );
  }

  /// Show recurring expense notification
  Future<void> showRecurringExpenseReminder({
    required String expenseTitle,
    required double amount,
    required String nextDueDate,
  }) async {
    await showNotification(
      title: 'Recurring Expense Due',
      body:
      '$expenseTitle (₹${amount.toStringAsFixed(2)}) is due on $nextDueDate',
      id: 3,
      payload: 'recurring_expense',
    );
  }

  /// Show group activity notification
  Future<void> showGroupActivity({
    required String groupName,
    required String activity,
    required String userName,
  }) async {
    await showNotification(
      title: 'Group Activity',
      body: '$userName $activity in $groupName',
      id: 4,
      payload: 'group_activity',
    );
  }

  /// Show balance update notification
  Future<void> showBalanceUpdate({
    required String groupName,
    required double newBalance,
  }) async {
    final balanceText = newBalance >= 0
        ? 'You are owed ₹${newBalance.toStringAsFixed(2)}'
        : 'You owe ₹${newBalance.abs().toStringAsFixed(2)}';

    await showNotification(
      title: 'Balance Updated',
      body: 'Your balance in $groupName: $balanceText',
      id: 5,
      payload: 'balance_update',
    );
  }

  /// Schedule a notification for later
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int id = 0,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'splitzy_scheduled_channel',
        'Scheduled Notifications',
        channelDescription: 'Scheduled notifications from Splitzy app',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
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

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      _logger.e('Error scheduling notification: $e');
    }
  }

  /// Schedule recurring expense reminder
  Future<void> scheduleRecurringExpenseReminder({
    required String expenseTitle,
    required double amount,
    required DateTime dueDate,
    int id = 0,
  }) async {
    await scheduleNotification(
      title: 'Recurring Expense Due',
      body: '$expenseTitle (₹${amount.toStringAsFixed(2)}) is due today',
      scheduledDate: dueDate,
      payload: 'recurring_expense_reminder',
      id: id,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      _logger.e('Error canceling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      _logger.e('Error canceling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      _logger.e('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle different notification types
      switch (payload) {
        case 'expense_reminder':
          _handleExpenseReminder();
          break;
        case 'settlement_reminder':
          _handleSettlementReminder();
          break;
        case 'recurring_expense':
          _handleRecurringExpense();
          break;
        case 'group_activity':
          _handleGroupActivity();
          break;
        case 'balance_update':
          _handleBalanceUpdate();
          break;
        case 'recurring_expense_reminder':
          _handleRecurringExpenseReminder();
          break;
      }
    }
  }

  /// Handle expense reminder tap
  void _handleExpenseReminder() {
    // Navigate to expenses screen
    _logger.d('Expense reminder tapped');
  }

  /// Handle settlement reminder tap
  void _handleSettlementReminder() {
    // Navigate to settlements screen
    _logger.d('Settlement reminder tapped');
  }

  /// Handle recurring expense tap
  void _handleRecurringExpense() {
    // Navigate to recurring expenses screen
    _logger.d('Recurring expense tapped');
  }

  /// Handle group activity tap
  void _handleGroupActivity() {
    // Navigate to group activity screen
    _logger.d('Group activity tapped');
  }

  /// Handle balance update tap
  void _handleBalanceUpdate() {
    // Navigate to balance screen
    _logger.d('Balance update tapped');
  }

  /// Handle recurring expense reminder tap
  void _handleRecurringExpenseReminder() {
    // Navigate to recurring expenses screen
    _logger.d('Recurring expense reminder tapped');
  }

  /// Save notification preferences
  Future<void> saveNotificationPreferences({
    required bool enableNotifications,
    required bool enableExpenseReminders,
    required bool enableSettlementReminders,
    required bool enableRecurringReminders,
    required bool enableGroupActivity,
    required bool enableBalanceUpdates,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enable_notifications', enableNotifications);
      await prefs.setBool('enable_expense_reminders', enableExpenseReminders);
      await prefs.setBool(
          'enable_settlement_reminders', enableSettlementReminders);
      await prefs.setBool('enable_recurring_reminders', enableRecurringReminders);
      await prefs.setBool('enable_group_activity', enableGroupActivity);
      await prefs.setBool('enable_balance_updates', enableBalanceUpdates);
    } catch (e) {
      _logger.e('Error saving notification preferences: $e');
    }
  }

  /// Load notification preferences
  Future<Map<String, bool>> loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enable_notifications': prefs.getBool('enable_notifications') ?? true,
        'enable_expense_reminders':
        prefs.getBool('enable_expense_reminders') ?? true,
        'enable_settlement_reminders':
        prefs.getBool('enable_settlement_reminders') ?? true,
        'enable_recurring_reminders':
        prefs.getBool('enable_recurring_reminders') ?? true,
        'enable_group_activity': prefs.getBool('enable_group_activity') ?? true,
        'enable_balance_updates':
        prefs.getBool('enable_balance_updates') ?? true,
      };
    } catch (e) {
      _logger.e('Error loading notification preferences: $e');
      return {
        'enable_notifications': true,
        'enable_expense_reminders': true,
        'enable_settlement_reminders': true,
        'enable_recurring_reminders': true,
        'enable_group_activity': true,
        'enable_balance_updates': true,
      };
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final prefs = await loadNotificationPreferences();
      return prefs['enable_notifications'] ?? true;
    } catch (e) {
      _logger.e('Error checking notification preferences: $e');
      return true;
    }
  }

  /// Show notification permission request
  Future<bool> requestNotificationPermission() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      final androidGranted = await androidPlugin?.requestNotificationsPermission();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle null cases explicitly
      return (androidGranted ?? false) || (iosGranted ?? false);
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      final preferences = await loadNotificationPreferences();

      return {
        'pendingNotifications': pendingNotifications.length,
        'preferences': preferences,
        'isEnabled': await areNotificationsEnabled(),
      };
    } catch (e) {
      _logger.e('Error getting notification stats: $e');
      return {};
    }
  }
}
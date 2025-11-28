import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

// Define notification action IDs
const String markAsDoneActionId = 'mark_as_done';
const String skipActionId = 'skip';

// Top-level function for background notification handling
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('notificationTapBackground: ${notificationResponse.payload}');
}

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? navigatorKey;
  bool _isInitialized = false;

  Future<void> init(GlobalKey<NavigatorState> key) async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized');
      return;
    }

    navigatorKey = key;
    await _configureLocalTimeZone();

    // Create the habit reminders Android notification channel
    const AndroidNotificationChannel habitReminderChannel = AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Reminders for your habits.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(habitReminderChannel);

    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'habit_reminder_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(markAsDoneActionId, 'Mark as Done'),
            DarwinNotificationAction.plain(skipActionId, 'Skip'),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        final String? actionId = notificationResponse.actionId;

        if (payload != null && payload.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            if (data['type'] == 'habit_reminder' && data['habitId'] != null) {
              if (actionId == markAsDoneActionId) {
                debugPrint('Foreground: Habit ${data['habitId']} marked as done!');
              } else if (actionId == skipActionId) {
                debugPrint('Foreground: Habit ${data['habitId']} skipped!');
              } else {
                navigatorKey?.currentState?.pushNamed(
                  '/habitDetail',
                  arguments: {'habitId': data['habitId']},
                );
              }
            }
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully');
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    if (timeZoneName != null) {
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Timezone set to: $timeZoneName');
      } catch (e) {
        debugPrint('Error setting timezone: $e, falling back to UTC');
        tz.setLocalLocation(tz.UTC);
      }
    } else {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermissions() async {
    bool allGranted = true;

    // Request notification permission for Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? androidResult = await androidImplementation.requestNotificationsPermission();
        allGranted = allGranted && (androidResult ?? false);
        debugPrint('Android notification permission: ${androidResult ?? false}');
      }
    }

    // Request permissions for iOS
    if (Platform.isIOS) {
      final bool? iosResult = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      allGranted = allGranted && (iosResult ?? false);
      debugPrint('iOS notification permission: ${iosResult ?? false}');
    }

    return allGranted;
  }

  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationService.flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
    }
    return true;
  }

  static Future<void> requestNotificationPermissions() async {
    await _notificationService.requestPermissions();
  }

  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Reminders for your habits.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode({'type': 'general_notification'}),
    );
  }

  Future<void> showNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Reminders for your habits',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'type': 'general_notification', 'id': id}),
    );
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders for your habits',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Notification scheduled: $id at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleHabitReminders(Habit habit) async {
    await cancelHabitReminders(habit.id);

    if (habit.reminderTimes.isEmpty) {
      debugPrint('No reminder times for habit ${habit.id}');
      return;
    }

    for (int i = 0; i < habit.reminderTimes.length; i++) {
      final reminderTime = habit.reminderTimes[i];
      final int notificationId = _generateNotificationId(habit.id, i);

      DateTime scheduledDate = DateTime(
        habit.startDate.year,
        habit.startDate.month,
        habit.startDate.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // Adjust if scheduled date is in the past
      if (scheduledDate.isBefore(DateTime.now())) {
        if (habit.repeatType == RepeatType.oneTime) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        } else {
          switch (habit.repeatType) {
            case RepeatType.daily:
              scheduledDate = _nextInstanceOfTime(reminderTime);
              break;
            case RepeatType.weekly:
              // Will be handled in the loop below
              break;
            case RepeatType.monthly:
              scheduledDate = _nextInstanceOfTimeForDayOfMonth(reminderTime, habit.repeatDateOfMonth);
              break;
            case RepeatType.oneTime:
              break;
          }
        }
      }

      // Schedule based on repeat type
      switch (habit.repeatType) {
        case RepeatType.daily:
          await _scheduleDailyNotification(notificationId, habit, scheduledDate);
          break;
        case RepeatType.weekly:
          await _scheduleWeeklyNotifications(habit, i, reminderTime);
          break;
        case RepeatType.monthly:
          await _scheduleMonthlyNotification(notificationId, habit, scheduledDate);
          break;
        case RepeatType.oneTime:
          await _scheduleOneTimeNotification(notificationId, habit, scheduledDate);
          break;
      }
    }
  }

  Future<void> _scheduleDailyNotification(
    int notificationId,
    Habit habit,
    DateTime scheduledDate,
  ) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Habit Reminder: ${habit.name}',
        'It\'s time to do your habit: ${habit.name}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders for your habits',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                markAsDoneActionId,
                'Mark as Done',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                skipActionId,
                'Skip',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'habit_reminder_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}),
      );
      debugPrint('Daily notification scheduled for habit ${habit.id}');
    } catch (e) {
      debugPrint('Error scheduling daily notification: $e');
    }
  }

  Future<void> _scheduleWeeklyNotifications(
    Habit habit,
    int reminderIndex,
    TimeOfDay reminderTime,
  ) async {
    for (final day in habit.repeatDays) {
      final int notificationId = _generateNotificationId(habit.id, reminderIndex + day * 100);
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Habit Reminder: ${habit.name}',
          'It\'s time to do your habit: ${habit.name}',
          _nextInstanceOfTimeForWeekday(reminderTime, day),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Habit Reminders',
              channelDescription: 'Reminders for your habits',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  markAsDoneActionId,
                  'Mark as Done',
                  showsUserInterface: true,
                ),
                AndroidNotificationAction(
                  skipActionId,
                  'Skip',
                  showsUserInterface: true,
                ),
              ],
            ),
            iOS: DarwinNotificationDetails(
              categoryIdentifier: 'habit_reminder_category',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}),
        );
        debugPrint('Weekly notification scheduled for habit ${habit.id} on day $day');
      } catch (e) {
        debugPrint('Error scheduling weekly notification: $e');
      }
    }
  }

  Future<void> _scheduleMonthlyNotification(
    int notificationId,
    Habit habit,
    DateTime scheduledDate,
  ) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Habit Reminder: ${habit.name}',
        'It\'s time to do your habit: ${habit.name}',
        _nextInstanceOfTimeForDayOfMonth(
          TimeOfDay(hour: scheduledDate.hour, minute: scheduledDate.minute),
          habit.repeatDateOfMonth,
        ),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders for your habits',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                markAsDoneActionId,
                'Mark as Done',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                skipActionId,
                'Skip',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'habit_reminder_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}),
      );
      debugPrint('Monthly notification scheduled for habit ${habit.id}');
    } catch (e) {
      debugPrint('Error scheduling monthly notification: $e');
    }
  }

  Future<void> _scheduleOneTimeNotification(
    int notificationId,
    Habit habit,
    DateTime scheduledDate,
  ) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Habit Reminder: ${habit.name}',
        'It\'s time to do your habit: ${habit.name}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders for your habits',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                markAsDoneActionId,
                'Mark as Done',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                skipActionId,
                'Skip',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'habit_reminder_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}),
      );
      debugPrint('One-time notification scheduled for habit ${habit.id}');
    } catch (e) {
      debugPrint('Error scheduling one-time notification: $e');
    }
  }

  Future<void> cancelHabitReminders(String habitId) async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();

      for (final notification in pendingNotifications) {
        if (notification.payload != null && notification.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(notification.payload!);
            if (data['type'] == 'habit_reminder' && data['habitId'] == habitId) {
              await flutterLocalNotificationsPlugin.cancel(notification.id);
              debugPrint('Cancelled notification ${notification.id} for habit $habitId');
            }
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cancelling habit reminders: $e');
    }
  }

  // Helper methods
  int _generateNotificationId(String habitId, int index) {
    return habitId.hashCode + index;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTimeForWeekday(TimeOfDay time, int weekday) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTimeForDayOfMonth(TimeOfDay time, int dayOfMonth) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        dayOfMonth,
        time.hour,
        time.minute,
      );
    }

    return scheduledDate;
  }
}

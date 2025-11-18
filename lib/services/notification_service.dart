import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart'; // Import Habit model
import 'package:flutter/material.dart'; // For TimeOfDay
import 'dart:convert'; // For jsonEncode/jsonDecode
import 'package:flutter_native_timezone/flutter_native_timezone.dart'; // For native timezone
import 'package:permission_handler/permission_handler.dart'; // For permission handling

// Define notification action IDs
const String markAsDoneActionId = 'mark_as_done';
const String skipActionId = 'skip';

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? navigatorKey; // Add navigatorKey

  Future<void> init(GlobalKey<NavigatorState> key) async {
    navigatorKey = key; // Assign the navigatorKey

    _configureLocalTimeZone(); // Configure local timezone

    // Create a high-importance Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Define Android notification actions

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

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsIOS);

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
                // Handle "Mark as Done" action
                // You'll need to implement the logic to mark the habit as done
                // This might involve calling a method in HabitService
                debugPrint('Habit ${data['habitId']} marked as done!');
              } else if (actionId == skipActionId) {
                // Handle "Skip" action
                debugPrint('Habit ${data['habitId']} skipped!');
              } else {
                // Default action: navigate to habit detail screen
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
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    if (timeZoneName != null) {
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } else {
    // Fallback to UTC or a default timezone if local timezone cannot be determined
    tz.setLocalLocation(tz.UTC);
  }
  }

  Future<bool> requestPermissions() async {
    // Request permissions for both Android and iOS
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request notification permission for Android 13+
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }

    return (result ?? false);
  }

  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationService.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final bool? enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }
    }
    // For other platforms, assume enabled or implement platform-specific checks
    return await Permission.notification.isGranted;
  }

  static Future<void> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await _notificationService.flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> openAppSettingsPage() async {
    await openAppSettings(); // This is from permission_handler
  }

  Future<void> showLocalNotification(
      String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> showNotification(int id, String title, String body) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders', // Consistent channel ID
          'Habit Reminders',
          channelDescription: 'Reminders for your habits',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'type': 'general_notification', 'id': id}), // Add payload
    );
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate, {String? payload}) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders', // Consistent channel ID
          'Habit Reminders',
          channelDescription: 'Reminders for your habits',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload, // Pass payload to scheduled notifications
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleHabitReminders(Habit habit) async {
    await cancelHabitReminders(habit.id); // Cancel existing reminders before scheduling new ones

    if (habit.reminderTimes.isEmpty) {
      return;
    }

    for (int i = 0; i < habit.reminderTimes.length; i++) {
      final reminderTime = habit.reminderTimes[i];
      final int notificationId = _generateNotificationId(habit.id, i);

      // Combine habit's start date with reminder time
      DateTime scheduledDate = DateTime(
        habit.startDate.year,
        habit.startDate.month,
        habit.startDate.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // For one-time habits, if the scheduled date is in the past, reschedule for the next day.
      // For recurring habits, _nextInstanceOfTime functions already handle future scheduling.
      if (habit.repeatType == RepeatType.oneTime && scheduledDate.isBefore(DateTime.now())) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (scheduledDate.isBefore(DateTime.now()) && habit.repeatType != RepeatType.oneTime) {
        // For recurring habits, if the initial scheduledDate is in the past,
        // we should use the _nextInstanceOfTime functions to get the next valid occurrence.
        // This ensures that if a habit is created with a start date in the past,
        // its first reminder is still scheduled correctly.
        switch (habit.repeatType) {
          case RepeatType.daily:
            scheduledDate = _nextInstanceOfTime(reminderTime);
            break;
          case RepeatType.weekly:
            // This case is handled by iterating through repeatDays,
            // and _nextInstanceOfTimeForWeekday already ensures future dates.
            // We'll let the loop below handle it.
            break;
          case RepeatType.monthly:
            scheduledDate = _nextInstanceOfTimeForDayOfMonth(reminderTime, habit.repeatDateOfMonth);
            break;
          case RepeatType.oneTime:
            // Handled above
            break;
        }
      }

      // Schedule based on repeat type
      switch (habit.repeatType) {
        case RepeatType.daily:
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            'Habit Reminder: ${habit.name}',
            'It\'s time to do your habit: ${habit.name}',
            tz.TZDateTime.from(scheduledDate, tz.local), // Use the adjusted scheduledDate
            NotificationDetails(
              android: AndroidNotificationDetails(
                'habit_reminders',
                'Habit Reminders',
                channelDescription: 'Reminders for your habits',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(markAsDoneActionId, 'Mark as Done', showsUserInterface: true),
                  AndroidNotificationAction(skipActionId, 'Skip', showsUserInterface: true),
                ],
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'habit_reminder_category',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time, // Daily recurrence
            payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}), // Add payload
          );
          break;
        case RepeatType.weekly:
          for (final day in habit.repeatDays) {
            await flutterLocalNotificationsPlugin.zonedSchedule(
              _generateNotificationId(habit.id, i + day * 100), // Unique ID for each day
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
                    AndroidNotificationAction(markAsDoneActionId, 'Mark as Done', showsUserInterface: true),
                    AndroidNotificationAction(skipActionId, 'Skip', showsUserInterface: true),
                  ],
                ),
                iOS: DarwinNotificationDetails(
                  categoryIdentifier: 'habit_reminder_category',
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Weekly recurrence
              payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}), // Add payload
            );
          }
          break;
        case RepeatType.monthly:
          // For monthly, we schedule for the day of the month specified in repeatDateOfMonth
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            'Habit Reminder: ${habit.name}',
            'It\'s time to do your habit: ${habit.name}',
            _nextInstanceOfTimeForDayOfMonth(reminderTime, habit.repeatDateOfMonth),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'habit_reminders',
                'Habit Reminders',
                channelDescription: 'Reminders for your habits',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(markAsDoneActionId, 'Mark as Done', showsUserInterface: true),
                  AndroidNotificationAction(skipActionId, 'Skip', showsUserInterface: true),
                ],
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'habit_reminder_category',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, // Monthly recurrence
            payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}), // Add payload
          );
          break;
        case RepeatType.oneTime:
          // For one-time habits, schedule using the adjusted scheduledDate
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
                  AndroidNotificationAction(markAsDoneActionId, 'Mark as Done', showsUserInterface: true),
                  AndroidNotificationAction(skipActionId, 'Skip', showsUserInterface: true),
                ],
              ),
              iOS: DarwinNotificationDetails(
                categoryIdentifier: 'habit_reminder_category',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: jsonEncode({'type': 'habit_reminder', 'habitId': habit.id}), // Add payload
          );
          break;
      }
    }
  }

  Future<void> cancelHabitReminders(String habitId) async {
    // Retrieve all pending notifications
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    // Filter and cancel notifications related to this habitId by parsing the payload
    for (final notification in pendingNotifications) {
      if (notification.payload != null && notification.payload!.isNotEmpty) {
        try {
          final Map<String, dynamic> data = jsonDecode(notification.payload!);
          if (data['type'] == 'habit_reminder' && data['habitId'] == habitId) {
            await flutterLocalNotificationsPlugin.cancel(notification.id);
          }
        } catch (e) {
          debugPrint('Error parsing notification payload for cancellation: $e');
        }
      }
    }
  }

  int _generateNotificationId(String habitId, int reminderIndex) {
    // Generate a unique ID by combining habitId hash and reminderIndex.
    // This approach is more robust than just hashCode and ensures uniqueness
    // within the context of a habit's reminders.
    // We use a large prime number multiplier to reduce collision risk,
    // and ensure the result fits within a 32-bit signed integer.
    final int baseId = habitId.hashCode % 1000000000; // Keep it within a reasonable range
    return (baseId * 31 + reminderIndex) % 2147483647; // Max 32-bit signed int
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, now.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTimeForWeekday(TimeOfDay time, int weekday) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, now.minute);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTimeForDayOfMonth(TimeOfDay time, int dayOfMonth) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth,
      time.hour,
      time.minute,
    );

    // If the scheduled date is in the past, or the dayOfMonth was invalid for the current month
    // (e.g., Feb 30th, which TZDateTime would clamp to Feb 28/29),
    // we need to advance to the next month until we find a valid future date.
    while (scheduledDate.isBefore(now) || scheduledDate.day != dayOfMonth) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month + 1, // Advance to the next month
        dayOfMonth,
        time.hour,
        time.minute,
      );
    }
    return scheduledDate;
  }
}

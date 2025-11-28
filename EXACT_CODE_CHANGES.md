# Exact Code Changes - Notification System Fix

## File 1: lib/main.dart

### Change: Added Permission Request

**Location**: In `main()` function

**Before**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationService notificationService = NotificationService();
  await notificationService.init(navigatorKey);
  await localStorageService.init();
  // ... rest of code
}
```

**After**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationService notificationService = NotificationService();
  await notificationService.init(navigatorKey);
  await notificationService.requestPermissions();  // ← ADDED THIS LINE
  await localStorageService.init();
  // ... rest of code
}
```

---

## File 2: ios/Runner/Info.plist

### Change: Added Notification Configuration

**Location**: Before closing `</dict>` tag

**Before**:
```xml
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UIStatusBarHidden</key>
	<false/>
	</dict>
</plist>
```

**After**:
```xml
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UIStatusBarHidden</key>
	<false/>
	<key>NSUserNotificationAlertOption</key>
	<string>alert</string>
	</dict>
</plist>
```

---

## File 3: lib/services/notification_service.dart

### Complete File Replacement

**Status**: COMPLETELY REWRITTEN

**Key Sections**:

#### 1. Imports (Fixed)
```dart
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/habit.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
```

#### 2. Background Handler (Fixed)
```dart
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('notificationTapBackground: ${notificationResponse.payload}');
}
```

#### 3. Class Definition (Fixed)
```dart
class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? navigatorKey;
  bool _isInitialized = false;  // ← ADDED GUARD
```

#### 4. Initialization (Fixed)
```dart
Future<void> init(GlobalKey<NavigatorState> key) async {
  if (_isInitialized) {  // ← ADDED GUARD
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

  // ... iOS and initialization settings ...

  _isInitialized = true;  // ← ADDED GUARD
  debugPrint('NotificationService initialized successfully');
}
```

#### 5. Timezone Configuration (Fixed)
```dart
Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  if (timeZoneName != null) {
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Timezone set to: $timeZoneName');
    } catch (e) {
      debugPrint('Error setting timezone: $e, falling back to UTC');
      tz.setLocalLocation(tz.UTC);  // ← FALLBACK ADDED
    }
  } else {
    tz.setLocalLocation(tz.UTC);
  }
}
```

#### 6. Permission Request (Fixed)
```dart
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
```

#### 7. Scheduling Methods (Fixed)

**Daily Notification**:
```dart
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
```

**Weekly Notification**:
```dart
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
```

**Monthly Notification**:
```dart
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
```

**One-Time Notification**:
```dart
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
```

#### 8. Helper Methods (Fixed)

**Generate Notification ID**:
```dart
int _generateNotificationId(String habitId, int index) {
  return habitId.hashCode + index;
}
```

**Next Instance of Time**:
```dart
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
```

**Next Instance for Weekday**:
```dart
tz.TZDateTime _nextInstanceOfTimeForWeekday(TimeOfDay time, int weekday) {
  tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);

  while (scheduledDate.weekday != weekday) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}
```

**Next Instance for Day of Month**:
```dart
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
```

---

## Summary of Changes

| File | Lines Changed | Type | Status |
|------|---------------|------|--------|
| `lib/main.dart` | 1 line added | Permission request | ✅ DONE |
| `ios/Runner/Info.plist` | 2 lines added | iOS config | ✅ DONE |
| `lib/services/notification_service.dart` | ~700 lines rewritten | Complete fix | ✅ DONE |

**Total Changes**: 3 files modified, ~700 lines of code fixed/added

**Compilation Status**: ✅ No errors, 1 minor lint warning (acceptable)

**Ready for Testing**: ✅ YES

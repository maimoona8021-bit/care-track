import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FlutterLocalNotificationsPlugin
  _notifications =
  FlutterLocalNotificationsPlugin();

  // Maximum number of days for a medicine
  // that has a fixed end date.
  static const int _maxFiniteScheduleDays = 90;

  // =====================================================
  // INITIALIZE
  // =====================================================
  Future<void> initialize() async {
    // Load timezone database.
    tz_data.initializeTimeZones();

    try {
      final currentTimezone =
      await FlutterTimezone
          .getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(
          currentTimezone.identifier,
        ),
      );
    } catch (_) {
      // Fallback for this project if device timezone
      // cannot be obtained.
      tz.setLocalLocation(
        tz.getLocation('Asia/Karachi'),
      );
    }

    const AndroidInitializationSettings
    androidSettings =
    AndroidInitializationSettings(
      'mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
    iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings
    initializationSettings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
    );
  }

  // =====================================================
  // REQUEST PERMISSIONS
  // =====================================================
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin?
      android =
      _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final bool? notificationPermission =
      await android
          ?.requestNotificationsPermission();

      // On newer Android versions this may open
      // the Exact Alarm settings page.
      await android
          ?.requestExactAlarmsPermission();

      return notificationPermission ?? true;
    }

    if (Platform.isIOS) {
      final bool? result =
      await _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return result ?? false;
    }

    return true;
  }

  // =====================================================
  // FIND BEST ANDROID SCHEDULE MODE
  // =====================================================
  Future<AndroidScheduleMode>
  _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode
          .inexactAllowWhileIdle;
    }

    final AndroidFlutterLocalNotificationsPlugin?
    android =
    _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final bool? canScheduleExact =
    await android
        ?.canScheduleExactNotifications();

    if (canScheduleExact == false) {
      return AndroidScheduleMode
          .inexactAllowWhileIdle;
    }

    return AndroidScheduleMode
        .exactAllowWhileIdle;
  }

  // =====================================================
  // NOTIFICATION DETAILS
  // =====================================================
  NotificationDetails get _details {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription:
        'Reminders for scheduled medicines',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  // =====================================================
  // CREATE STABLE NOTIFICATION ID
  // =====================================================
  int _stableBaseId(
      String medicineId,
      ) {
    int hash = 0;

    for (final int unit
    in medicineId.codeUnits) {
      hash =
      ((hash * 31) + unit) &
      0x7fffffff;
    }

    return hash % 1500000000;
  }

  int _notificationId({
    required String medicineId,
    required int index,
  }) {
    return (_stableBaseId(medicineId) +
        index +
        1) &
    0x7fffffff;
  }

  // =====================================================
  // "08:00" -> hour/minute
  // =====================================================
  ({int hour, int minute})
  _parseTime(
      String time,
      ) {
    final parts = time.split(':');

    return (
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1]),
    );
  }

  // =====================================================
  // SCHEDULE MEDICINE REMINDERS
  // =====================================================
  Future<List<int>>
  scheduleMedicineReminders({
    required String medicineId,
    required String medicineName,
    required String profileName,
    required String dosage,
    required String quantity,
    required List<String> reminderTimes,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (reminderTimes.isEmpty) {
      return [];
    }

    final List<int> notificationIds =
    [];

    final AndroidScheduleMode scheduleMode =
    await _androidScheduleMode();

    final tz.TZDateTime now =
    tz.TZDateTime.now(tz.local);

    final String body =
    quantity.trim().isNotEmpty
        ? 'Take $quantity'
        '${dosage.trim().isNotEmpty ? ' • $dosage' : ''}'
        : dosage.trim().isNotEmpty
        ? 'Take $dosage'
        : 'It is time to take your medicine';

    // ===================================================
    // MEDICINE WITH AN END DATE
    //
    // Schedule individual reminders until the end date.
    // ===================================================
    if (endDate != null) {
      DateTime scheduleDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final DateTime finalDay =
      DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      int dayCount = 0;
      int notificationIndex = 0;

      while (!scheduleDay
          .isAfter(finalDay) &&
          dayCount <
              _maxFiniteScheduleDays) {
        for (final String time
        in reminderTimes) {
          final parsed =
          _parseTime(time);

          final tz.TZDateTime
          scheduled =
          tz.TZDateTime(
            tz.local,
            scheduleDay.year,
            scheduleDay.month,
            scheduleDay.day,
            parsed.hour,
            parsed.minute,
          );

          if (scheduled.isAfter(now)) {
            final int id =
            _notificationId(
              medicineId:
              medicineId,
              index:
              notificationIndex,
            );

            await _notifications
                .zonedSchedule(
              id,
              'Medicine Reminder • $profileName',
              '$medicineName\n$body',
              scheduled,
              _details,
              androidScheduleMode:
              scheduleMode,
              payload:
              'medicine:$medicineId',
            );

            notificationIds.add(id);
          }

          notificationIndex++;
        }

        scheduleDay =
            scheduleDay.add(
              const Duration(days: 1),
            );

        dayCount++;
      }

      return notificationIds;
    }

    // ===================================================
    // LONG-TERM MEDICINE
    //
    // No end date = repeat every day.
    // ===================================================
    for (int index = 0;
    index < reminderTimes.length;
    index++) {
      final parsed =
      _parseTime(
        reminderTimes[index],
      );

      tz.TZDateTime scheduled =
      tz.TZDateTime(
        tz.local,
        startDate.year,
        startDate.month,
        startDate.day,
        parsed.hour,
        parsed.minute,
      );

      while (!scheduled.isAfter(now)) {
        scheduled =
            scheduled.add(
              const Duration(days: 1),
            );
      }

      final int id =
      _notificationId(
        medicineId: medicineId,
        index: index,
      );

      await _notifications.zonedSchedule(
        id,
        'Medicine Reminder • $profileName',
        '$medicineName\n$body',
        scheduled,
        _details,
        androidScheduleMode:
        scheduleMode,

        // Repeat every day at this time.
        matchDateTimeComponents:
        DateTimeComponents.time,

        payload:
        'medicine:$medicineId',
      );

      notificationIds.add(id);
    }

    return notificationIds;
  }

  // =====================================================
  // CANCEL MEDICINE REMINDERS
  // =====================================================
  Future<void> cancelMedicineReminders(
      List<dynamic> ids,
      ) async {
    for (final dynamic value in ids) {
      final int? id =
      value is int
          ? value
          : int.tryParse(
        value.toString(),
      );

      if (id != null) {
        await _notifications.cancel(id);
      }
    }
  }

  // =====================================================
  // TEST NOTIFICATION NOW
  // =====================================================
  Future<void> showTestNotification()
  async {
    await _notifications.show(
      999999,
      'Care Track',
      'Medicine reminders are working.',
      _details,
    );
  }
}
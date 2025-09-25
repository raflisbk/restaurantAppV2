import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../services/api_service.dart';
import '../models/restaurant.dart';
import '../models/api_response.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationHelper {
  static NotificationHelper? _instance;
  static bool _isInitialized = false;

  NotificationHelper._internal() {
    _instance = this;
  }

  factory NotificationHelper() => _instance ?? NotificationHelper._internal();

  bool get isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isLinux ||
        Platform.isMacOS;
  }

  Future<bool> initNotifications() async {
    if (_isInitialized) return true;

    if (!isPlatformSupported) {
      debugPrint('Notifications not supported on this platform');
      return false;
    }

    try {
      // Initialize timezone data and set local timezone
      tz.initializeTimeZones();

      // Set timezone to device's local timezone
      final String timeZoneName = await _getDeviceTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      debugPrint('Timezone set to: $timeZoneName');

      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettingsLinux = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        linux: initializationSettingsLinux,
      );

      final bool? result = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      _isInitialized = result ?? false;
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      return false;
    }
  }

  Future<bool> requestIOSPermissions() async {
    final result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  Future<bool> _requestAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation
            .requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Failed to request Android permissions: $e');
      return false;
    }
  }

  Future<bool> showNotification(String title, String body) async {
    if (!isPlatformSupported) {
      debugPrint(
        'Notifications are not supported on this platform (Windows/Web)',
      );
      return false;
    }

    try {
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Failed to initialize notifications');
          return false;
        }
      }

      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'restaurant_channel',
        'Restaurant Notifications',
        channelDescription: 'Daily restaurant recommendations',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Restaurant App Notification',
        showWhen: true,
        enableVibration: true,
        enableLights: true,
      );

      const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxPlatformChannelSpecifics = LinuxNotificationDetails();

      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        linux: linuxPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
      );

      debugPrint('Notification shown successfully: $title');
      return true;
    } catch (e) {
      debugPrint('Failed to show notification: $e');
      return false;
    }
  }

  /// Get device timezone name
  Future<String> _getDeviceTimeZone() async {
    try {
      // Try to get system timezone, fallback to UTC if failed
      final DateTime now = DateTime.now();
      final String timeZoneOffset = now.timeZoneOffset.toString();

      // Common timezone mappings for Indonesia
      final Map<String, String> indonesianTimeZones = {
        '7:00:00.000000': 'Asia/Jakarta', // WIB (Western Indonesia Time)
        '8:00:00.000000': 'Asia/Makassar', // WITA (Central Indonesia Time)
        '9:00:00.000000': 'Asia/Jayapura', // WIT (Eastern Indonesia Time)
      };

      // Check if it's Indonesian timezone
      if (indonesianTimeZones.containsKey(timeZoneOffset)) {
        return indonesianTimeZones[timeZoneOffset]!;
      }

      // For other countries, try common timezones based on offset
      final int offsetHours = now.timeZoneOffset.inHours;
      final Map<int, String> commonTimeZones = {
        -8: 'America/Los_Angeles', // PST/PDT
        -7: 'America/Denver', // MST/MDT
        -6: 'America/Chicago', // CST/CDT
        -5: 'America/New_York', // EST/EDT
        0: 'Europe/London', // GMT/BST
        1: 'Europe/Paris', // CET/CEST
        2: 'Europe/Helsinki', // EET/EEST
        3: 'Europe/Moscow', // MSK
        5: 'Asia/Karachi', // PKT
        7: 'Asia/Jakarta', // WIB
        8: 'Asia/Singapore', // SGT
        9: 'Asia/Tokyo', // JST
      };

      if (commonTimeZones.containsKey(offsetHours)) {
        return commonTimeZones[offsetHours]!;
      }

      // Default fallback
      return 'Asia/Jakarta'; // Default to Jakarta time (WIB) for Indonesian users
    } catch (e) {
      debugPrint('Failed to get device timezone, using Asia/Jakarta: $e');
      return 'Asia/Jakarta';
    }
  }

  Future<void> scheduleDailyReminder() async {
    try {
      await _scheduleDailyNotification();

      await Workmanager().registerPeriodicTask(
        'daily_reminder',
        'dailyReminderTask',
        frequency: const Duration(hours: 24),
        initialDelay: _getInitialDelay(),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  Future<void> _scheduleDailyNotification() async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Waktunya Makan Siang!',
        'Jangan lupa cek rekomendasi restoran hari ini!',
        _nextInstanceOfElevenAM(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'restaurant_channel',
            'Restaurant Notifications',
            channelDescription: 'Daily restaurant recommendations',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Failed to schedule zoned notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfElevenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      11, // 11 AM in 24-hour format
      0, // 0 minutes
      0, // 0 seconds
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('Next notification scheduled for: $scheduledDate (Local time)');
    debugPrint('Current time: $now');

    return scheduledDate;
  }

  Future<void> cancelDailyReminder() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(0);
      await Workmanager().cancelByUniqueName('daily_reminder');
    } catch (e) {
      debugPrint('Failed to cancel daily reminder: $e');
    }
  }

  Duration _getInitialDelay() {
    // Use timezone-aware calculation for consistency
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime targetTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      11, // 11 AM
      0, // 0 minutes
    );

    tz.TZDateTime nextTarget = targetTime;
    if (now.isAfter(targetTime)) {
      nextTarget = targetTime.add(const Duration(days: 1));
    }

    final Duration delay = nextTarget.difference(now);
    debugPrint(
      'Initial delay calculated: ${delay.inHours}h ${delay.inMinutes.remainder(60)}m',
    );

    return delay;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'dailyReminderTask') {
      try {
        final response = await ApiService.getRestaurantsStatic();

        if (response is ApiSuccess<List<Restaurant>> &&
            response.data.isNotEmpty) {
          final randomIndex = Random().nextInt(response.data.length);
          final randomRestaurant = response.data[randomIndex];

          await NotificationHelper().showNotification(
            'Waktunya Makan Siang!',
            'Bagaimana dengan ${randomRestaurant.name} di ${randomRestaurant.city} hari ini?',
          );
        } else {
          await NotificationHelper().showNotification(
            'Waktunya Makan Siang!',
            'Jangan lupa makan siang hari ini!',
          );
        }
      } catch (e) {
        await NotificationHelper().showNotification(
          'Waktunya Makan Siang!',
          'Jangan lupa makan siang hari ini!',
        );
      }
    }
    return Future.value(true);
  });
}

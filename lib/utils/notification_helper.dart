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
      tz.initializeTimeZones();

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
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
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
      debugPrint('Notifications are not supported on this platform (Windows/Web)');
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
      11,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

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
    final now = DateTime.now();
    final targetTime = DateTime(now.year, now.month, now.day, 11, 0);

    if (now.isAfter(targetTime)) {
      return targetTime.add(const Duration(days: 1)).difference(now);
    } else {
      return targetTime.difference(now);
    }
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

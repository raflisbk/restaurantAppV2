import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
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
      if (!isPlatformSupported) {
        debugPrint('Notifications not supported on this platform');
        return;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Failed to initialize notifications for daily reminder');
          return;
        }
      }

      // Cancel any existing timer
      _dailyReminderTimer?.cancel();

      // Get custom time
      final notificationTime = await _getNotificationTime();
      final now = DateTime.now();

      // Calculate time until next occurrence
      DateTime targetTime = DateTime(
        now.year,
        now.month,
        now.day,
        notificationTime.hour,
        notificationTime.minute,
      );

      // If target time is in the past today, schedule for tomorrow
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }

      final Duration delay = targetTime.difference(now);

      debugPrint('🔔 === TIMER-BASED DAILY REMINDER ===');
      debugPrint(
        'Current time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      debugPrint(
        'Target time: ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
      );
      debugPrint(
        'Initial delay: ${delay.inHours}h ${delay.inMinutes.remainder(60)}m',
      );
      debugPrint('Next notification scheduled for: ${targetTime.toString()}');

      // Create recurring timer
      _dailyReminderTimer = Timer(delay, () async {
        final fireTime = DateTime.now();
        debugPrint(
          '🔥 DAILY REMINDER FIRED! Time: ${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}',
        );

        // Show notification
        final success = await showNotification(
          'Waktunya Makan Siang! 🍽️',
          'Jangan lupa cek rekomendasi restoran hari ini! Waktu: ${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}',
        );

        debugPrint('✅ Daily reminder notification result: $success');

        // Schedule next day's notification
        _scheduleNextDayReminder();
      });

      debugPrint('✅ Daily reminder timer set successfully!');
      debugPrint('Current time: ${now.toString().substring(11, 19)}');
      debugPrint(
        'Next notification scheduled for: ${targetTime.toString().substring(11, 19)}',
      );
      debugPrint('🔔 === END DAILY REMINDER SETUP ===');
    } catch (e) {
      debugPrint('❌ Failed to schedule daily reminder: $e');
    }
  }

  void _scheduleNextDayReminder() {
    // Schedule the next day's reminder
    Timer(const Duration(minutes: 1), () async {
      await scheduleDailyReminder();
    });
  }

  Future<TimeOfDay> _getNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('notificationTime');

      if (timeString != null) {
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 11;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Default to 11:00 if no custom time is set
      return const TimeOfDay(hour: 11, minute: 0);
    } catch (e) {
      debugPrint('Error getting notification time: $e');
      return const TimeOfDay(hour: 11, minute: 0);
    }
  }

  Future<tz.TZDateTime> _nextInstanceOfCustomTime() async {
    final notificationTime = await _getNotificationTime();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
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
      // Cancel timer
      _dailyReminderTimer?.cancel();
      _dailyReminderTimer = null;

      // Cancel WorkManager task (if any)
      try {
        await Workmanager().cancelByUniqueName('daily_reminder');
      } catch (e) {
        debugPrint('WorkManager cancel failed (may not exist): $e');
      }

      // Cancel any pending local notifications
      await flutterLocalNotificationsPlugin.cancel(0);
      await flutterLocalNotificationsPlugin.cancelAll();

      debugPrint('Daily reminder cancelled successfully');
    } catch (e) {
      debugPrint('Failed to cancel daily reminder: $e');
    }
  }

  static Timer? _testTimer;
  static Timer? _dailyReminderTimer;

  /// Test notification function that schedules a notification 2 minutes from now
  /// Uses Timer instead of scheduled notifications for more reliable testing
  Future<bool> scheduleTestNotification() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifications not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Failed to initialize notifications for test');
          return false;
        }
      }

      // Cancel any existing timer
      _testTimer?.cancel();

      final DateTime now = DateTime.now();
      final DateTime targetTime = now.add(const Duration(minutes: 2));

      debugPrint('🕐 === TIMER-BASED TEST NOTIFICATION ===');
      debugPrint(
        'Current time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      );
      debugPrint(
        'Target time: ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}:${targetTime.second.toString().padLeft(2, '0')}',
      );
      debugPrint('Will fire in: 120 seconds');

      // Use Timer instead of scheduled notification
      _testTimer = Timer(const Duration(minutes: 2), () async {
        final DateTime fireTime = DateTime.now();
        debugPrint(
          '🔥 TIMER FIRED! Time: ${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}:${fireTime.second.toString().padLeft(2, '0')}',
        );

        final success = await showNotification(
          '🎯 Timer Test BERHASIL!',
          'Test notifikasi 2 menit berhasil muncul pada ${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}. Timer bekerja dengan sempurna!',
        );

        debugPrint('✅ Timer notification result: $success');
      });

      debugPrint('✅ Timer set successfully for 2 minutes!');
      debugPrint(
        'Timer akan memunculkan notifikasi pada: ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
      );
      debugPrint('🕐 === END TIMER SETUP ===');

      return true;
    } catch (e) {
      debugPrint('❌ Failed to set timer test notification: $e');
      return false;
    }
  }

  /// Test immediate notification
  Future<bool> showTestNotification() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifications not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Failed to initialize notifications for test');
          return false;
        }
      }

      final DateTime now = DateTime.now();
      final String timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      debugPrint('=== SENDING IMMEDIATE TEST NOTIFICATION ===');
      debugPrint('Time: $timeString');

      final success = await showNotification(
        'Test Notifikasi Segera 🧪',
        'BERHASIL! Test notifikasi langsung berhasil pada waktu: $timeString',
      );

      debugPrint('✅ Immediate test notification result: $success');
      debugPrint('=== END IMMEDIATE TEST ===');
      return success;
    } catch (e) {
      debugPrint('❌ Failed to show immediate test notification: $e');
      return false;
    }
  }

  /// Cancel test notifications and timers
  Future<void> cancelTestNotifications() async {
    try {
      // Cancel timer if running
      _testTimer?.cancel();
      _testTimer = null;

      // Cancel any scheduled test notifications
      await flutterLocalNotificationsPlugin.cancel(999);
      debugPrint('Test notifications and timers cancelled');
    } catch (e) {
      debugPrint('Failed to cancel test notifications: $e');
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('WorkManager task executed: $task with data: $inputData');

      if (task == 'dailyReminderTask') {
        try {
          // Initialize timezone first to prevent timezone errors
          tz.initializeTimeZones();

          // Initialize notifications
          final notificationHelper = NotificationHelper();
          final initSuccess = await notificationHelper.initNotifications();

          if (!initSuccess) {
            debugPrint('Failed to initialize notifications in background task');
            return Future.value(false);
          }

          // Try to fetch restaurant data
          try {
            final response = await ApiService.getRestaurantsStatic();

            if (response is ApiSuccess<List<Restaurant>> &&
                response.data.isNotEmpty) {
              final randomIndex = Random().nextInt(response.data.length);
              final randomRestaurant = response.data[randomIndex];

              final success = await notificationHelper.showNotification(
                'Waktunya Makan Siang! 🍽️',
                'Bagaimana dengan ${randomRestaurant.name} di ${randomRestaurant.city} hari ini?',
              );

              debugPrint(
                'Restaurant notification shown: $success for ${randomRestaurant.name}',
              );
              return Future.value(success);
            }
          } catch (apiError) {
            debugPrint('API error in background task: $apiError');
          }

          // Fallback notification if API fails or no data
          final success = await notificationHelper.showNotification(
            'Waktunya Makan Siang! 🍽️',
            'Jangan lupa makan siang hari ini! Cek aplikasi untuk rekomendasi restoran.',
          );

          debugPrint('Fallback notification shown: $success');
          return Future.value(success);
        } catch (e) {
          debugPrint('Error in background task: $e');

          // Last resort notification
          try {
            final notificationHelper = NotificationHelper();
            await notificationHelper.initNotifications();
            final success = await notificationHelper.showNotification(
              'Waktunya Makan Siang! 🍽️',
              'Jangan lupa makan siang hari ini!',
            );
            debugPrint('Last resort notification shown: $success');
            return Future.value(success);
          } catch (notifError) {
            debugPrint('Failed to show last resort notification: $notifError');
            return Future.value(false);
          }
        }
      }

      debugPrint('WorkManager task completed: $task');
      return Future.value(true);
    } catch (e) {
      debugPrint('Critical error in WorkManager callback: $e');
      return Future.value(false);
    }
  });
}

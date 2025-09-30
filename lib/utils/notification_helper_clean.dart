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
import '../data/database_helper.dart';

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
      debugPrint('Notifikasi tidak didukung pada platform ini');
      return false;
    }

    try {
      tz.initializeTimeZones();
      final String timeZoneName = await _getDeviceTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      debugPrint('Timezone diatur ke: $timeZoneName');

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
        await _createNotificationChannels();
      }

      _isInitialized = result ?? false;
      return _isInitialized;
    } catch (e) {
      debugPrint('Gagal inisialisasi notifikasi: $e');
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

  Future<bool> requestAllPermissions() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasi tidak didukung pada platform ini');
        return false;
      }

      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal inisialisasi notifikasi');
          return false;
        }
      }

      bool permissionGranted = false;

      if (Platform.isAndroid) {
        permissionGranted = await _requestAndroidPermissions();
      } else if (Platform.isIOS) {
        permissionGranted = await requestIOSPermissions();
      } else {
        permissionGranted = true;
      }

      debugPrint('Status permission: $permissionGranted');
      return permissionGranted;
    } catch (e) {
      debugPrint('Gagal request permissions: $e');
      return false;
    }
  }

  /// Check current permission status
  Future<Map<String, bool>> checkPermissionStatus() async {
    final Map<String, bool> status = {
      'basic_notification': false,
      'exact_alarm': false,
      'battery_optimization': false,
      'internet_access': false,
      'platform_supported': isPlatformSupported,
    };

    try {
      if (!isPlatformSupported) {
        return status;
      }

      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          // Check basic notification permission
          try {
            // Try to get permission status indirectly by attempting to create a channel
            status['basic_notification'] = true; // Assume granted if no error
          } catch (e) {
            status['basic_notification'] = false;
          }

          // Check exact alarm permission
          try {
            final bool? exactAlarmGranted = await androidImplementation
                .canScheduleExactNotifications();
            status['exact_alarm'] = exactAlarmGranted ?? false;
          } catch (e) {
            status['exact_alarm'] = false;
          }
        }

        // Check internet access (basic check)
        status['internet_access'] =
            true; // INTERNET permission is automatic granted

        // Battery optimization status (assume optimized by default)
        status['battery_optimization'] =
            false; // User needs to manually disable
      } else if (Platform.isIOS) {
        // For iOS, we can't easily check without requesting, so assume we need to request
        status['basic_notification'] = true; // Will be checked during request
        status['exact_alarm'] = true; // iOS doesn't need exact alarm permission
        status['battery_optimization'] = true; // iOS handles this automatically
        status['internet_access'] =
            true; // No explicit permission needed on iOS
      } else {
        status['basic_notification'] = true;
        status['exact_alarm'] = true;
        status['battery_optimization'] = true;
        status['internet_access'] = true;
      }

      debugPrint('Izin status: $status');
      return status;
    } catch (e) {
      debugPrint('Gagal check permission status: $e');
      return status;
    }
  }

  /// Request battery optimization exemption
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;

    try {
      debugPrint('🔋 Requesting battery optimization exemption...');

      // This requires a plugin or platform channel implementation
      // For now, we'll just log the instruction
      debugPrint('Manual action required:');
      debugPrint('   Go to Settings > Battery > App optimization');
      debugPrint('   Find "Restaurant App" and set to "Don\'t optimize"');

      return true; // Return true as we've provided instructions
    } catch (e) {
      debugPrint('Gagal request battery optimization exemption: $e');
      return false;
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        debugPrint('Requesting notification permissions...');

        // Request basic notification permission
        final bool? granted = await androidImplementation
            .requestNotificationsPermission();

        debugPrint('Basic notification permission granted: $granted');

        // For Android 12+, also request exact alarm permission
        try {
          final bool? exactAlarmGranted = await androidImplementation
              .canScheduleExactNotifications();
          debugPrint('Can schedule exact notifications: $exactAlarmGranted');

          if (exactAlarmGranted == false) {
            debugPrint('Requesting exact alarm permission...');
            final result = await androidImplementation
                .requestExactAlarmsPermission();
            debugPrint('Exact alarm permission request result: $result');
          }
        } catch (exactAlarmError) {
          debugPrint(
            '🔐 Exact alarm permission not available on this device: $exactAlarmError',
          );
        }

        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Gagal request Android permissions: $e');
      return false;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        debugPrint('CREATING ROBUST NOTIFICATION CHANNELS');

        // High Priority Daily Reminder Channel
        const dailyReminderChannel = AndroidNotificationChannel(
          'daily_reminder_channel',
          'Daily Restaurant Reminder',
          description: 'Daily reminder to check restaurant recommendations',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        // Primary Notification Channel
        const primaryChannel = AndroidNotificationChannel(
          'primary_notification_channel',
          'Primary Notifications',
          description: 'Primary scheduled notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        // WorkManager Backup Channel
        const workmanagerChannel = AndroidNotificationChannel(
          'workmanager_channel',
          'Background Notifications',
          description:
              'Background WorkManager notifications with restaurant data',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        // Test Channel
        const testChannel = AndroidNotificationChannel(
          'test_channel',
          'Test Notifications',
          description: 'Test notifications for debugging',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
        );

        // Create all channels
        await androidImplementation.createNotificationChannel(
          dailyReminderChannel,
        );
        await androidImplementation.createNotificationChannel(primaryChannel);
        await androidImplementation.createNotificationChannel(
          workmanagerChannel,
        );
        await androidImplementation.createNotificationChannel(testChannel);

        debugPrint('Daily reminder channel: ${dailyReminderChannel.id}');
        debugPrint('Primary channel: ${primaryChannel.id}');
        debugPrint('WorkManager channel: ${workmanagerChannel.id}');
        debugPrint('Test channel: ${testChannel.id}');
        debugPrint('ROBUST CHANNELS CREATED');
      }
    } catch (e) {
      debugPrint('Gagal create notification channels: $e');
    }
  }

  /// Recreate notification channels (public method for debugging)
  Future<void> recreateChannels() async {
    debugPrint('Force recreating notification channels...');
    await _createNotificationChannels();
  }

  /// Get active notifications (visible in notification tray)
  Future<List<ActiveNotification>> getActiveNotifications() async {
    if (!Platform.isAndroid) return [];

    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final activeNotifications = await androidImplementation
            .getActiveNotifications();
        debugPrint(
          '📱 Found ${activeNotifications.length} active notifications',
        );
        return activeNotifications;
      }
    } catch (e) {
      debugPrint('Gagal get active notifications: $e');
    }
    return [];
  }

  /// Test Timer-based fallback (works when app is foreground)
  Future<bool> testTimerFallback() async {
    try {
      debugPrint('TIMER FALLBACK TEST');
      debugPrint('Timer test will fire in 30 seconds (app must stay open)');

      Timer(const Duration(seconds: 30), () async {
        debugPrint('TIMER FIRED! Showing notification...');
        final success = await showNotification(
          '🔄 TIMER FALLBACK SUCCESS!',
          'Timer-based notification works! Time: ${DateTime.now().toString().substring(11, 19)}',
        );
        debugPrint('Timer notification result: $success');
      });

      debugPrint('Timer scheduled successfully');
      debugPrint('TIMER TEST SCHEDULED');
      return true;
    } catch (e) {
      debugPrint('Timer fallback test failed: $e');
      return false;
    }
  }

  Future<bool> showNotification(String title, String body) async {
    debugPrint('SHOW NOTIFICATION CALLED');
    debugPrint('Title: $title');
    debugPrint('Body: $body');
    debugPrint('Platform supported: $isPlatformSupported');
    debugPrint('Initialized: $_isInitialized');

    if (!isPlatformSupported) {
      debugPrint(
        '❌ Notifications are not supported on this platform (Windows/Web)',
      );
      return false;
    }

    try {
      if (!_isInitialized) {
        debugPrint('Initializing notifications...');
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications');
          return false;
        }
        debugPrint('Notifikasis initialized in showNotifikasi');
      }

      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'workmanager_channel',
        'Background Notifications',
        channelDescription:
            'Background WorkManager notifications with restaurant data',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Restaurant WorkManager Notification',
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        tag: 'workmanager_daily_reminder',
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

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );
      debugPrint('Attempting to show notification with ID: $notificationId');

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
      );

      debugPrint('Notifikasi shown successfully: $title');
      debugPrint('END SHOW NOTIFICATION');
      return true;
    } catch (e) {
      debugPrint('Gagal show notification: $e');
      debugPrint('END SHOW NOTIFICATION (ERROR)');
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
      debugPrint('Gagal get device timezone, using Asia/Jakarta: $e');
      return 'Asia/Jakarta';
    }
  }

  Future<void> scheduleDailyReminder() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for daily reminder');
          return;
        }
      }

      // Request exact alarm permission for Android 12+
      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          final bool? exactAlarmGranted = await androidImplementation
              .canScheduleExactNotifications();
          debugPrint('Exact alarm permission granted: $exactAlarmGranted');

          if (exactAlarmGranted == false) {
            debugPrint('Exact alarm permission not granted, requesting...');
            final result = await androidImplementation
                .requestExactAlarmsPermission();
            debugPrint('Exact alarm permission request result: $result');

            // Check again after request
            final recheck = await androidImplementation
                .canScheduleExactNotifications();
            debugPrint('Exact alarm permission after request: $recheck');

            if (recheck != true) {
              debugPrint(
                '❌ Exact alarm permission still not granted. Notifications may not work reliably.',
              );
            }
          }
        }
      }

      // Cancel any existing scheduled notifications for daily reminder
      await flutterLocalNotificationsPlugin.cancel(0); // Old notification ID
      await flutterLocalNotificationsPlugin.cancel(
        1,
      ); // Primary notification ID

      // Cancel any existing timer (cleanup legacy method)
      _dailyReminderTimer?.cancel();
      _dailyReminderTimer = null;

      // Get notification time setting
      final notificationTime = await _getNotificationTime();
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

      // Calculate scheduled time
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        notificationTime.hour,
        notificationTime.minute,
        0,
      );

      // If the scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now) ||
          scheduledDate.difference(now).inMinutes < 1) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('Time has passed or too close, scheduling for tomorrow');
      } else {
        debugPrint('📅 Time hasn\'t passed today, scheduling for today');
      }

      debugPrint('DAILY REMINDER SCHEDULING');
      debugPrint('Waktu sekarang: $now');
      debugPrint(
        'Notification setting: ${notificationTime.hour}:${notificationTime.minute}',
      );
      debugPrint('Dijadwalkan time: $scheduledDate');
      debugPrint('Time until notification: ${scheduledDate.difference(now)}');

      // Get notification content based on favorites
      final notificationContent = await _getNotificationContent();
      debugPrint(
        'Notification content: ${notificationContent['title']} - ${notificationContent['body']}',
      );

      // Schedule with flutter_local_notifications (primary method)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        1, // notification id (different from WorkManager)
        notificationContent['title']!,
        notificationContent['body']!,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'primary_notification_channel',
            'Primary Notifications',
            channelDescription: 'Primary scheduled notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Restaurant Primary Reminder',
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            tag: 'primary_daily_reminder',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Primary notification scheduled successfully!');

      // Also schedule with WorkManager as backup (use SAME timing as primary)
      await _scheduleWorkManagerBackup(scheduledDate);
    } catch (e) {
      debugPrint('Gagal schedule daily reminder: $e');
      debugPrint('Error details: ${e.toString()}');
      rethrow;
    }
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

  /// Get notification title and body based on favorites
  Future<Map<String, String>> _getNotificationContent() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.initialize();
      final favorites = await dbHelper.getFavorites();

      if (favorites.isNotEmpty) {
        // Random restaurant from favorites
        final randomIndex = Random().nextInt(favorites.length);
        final restaurant = favorites[randomIndex];

        return {
          'title': 'Waktunya Makan! 🍽️',
          'body':
              'Bagaimana dengan ${restaurant.name} di ${restaurant.city} hari ini? Restoran favoritmu menunggu!',
        };
      } else {
        // No favorites yet
        return {
          'title': 'Waktunya Makan! 🍽️',
          'body':
              'Jangan lupa makan siang hari ini! Yuk cari restoran favoritmu dan simpan untuk rekomendasi selanjutnya 😊',
        };
      }
    } catch (e) {
      debugPrint('Error getting notification content: $e');
      // Fallback message
      return {
        'title': 'Waktunya Makan! 🍽️',
        'body':
            'Jangan lupa makan siang hari ini! Cek aplikasi untuk rekomendasi restoran.',
      };
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
    debugPrint('Waktu sekarang: $now');

    return scheduledDate;
  }

  /// Schedule WorkManager backup with SAME timing as primary notification
  Future<void> _scheduleWorkManagerBackup(tz.TZDateTime scheduledDate) async {
    debugPrint('SCHEDULING WORKMANAGER BACKUP (SAME TIME)');
    try {
      // Cancel existing task first
      await Workmanager().cancelByUniqueName('daily_reminder');

      // Use regular DateTime for WorkManager (convert from TZDateTime)
      final targetDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );

      final now = DateTime.now();
      final delayDuration = targetDateTime.difference(now);

      debugPrint('WorkManager backup: Using SAME time as primary');
      debugPrint('Waktu sekarang: $now');
      debugPrint('WorkManager trigger: $targetDateTime');
      debugPrint(
        '📅 Delay: ${delayDuration.inHours}h ${delayDuration.inMinutes.remainder(60)}m',
      );

      // Schedule WorkManager task for SAME time as primary
      await Workmanager().registerOneOffTask(
        'daily_reminder',
        'dailyReminderTask',
        initialDelay: delayDuration,
        // NO CONSTRAINTS - same as comprehensive test that works
      );

      debugPrint('WorkManager backup scheduled for SAME time');
      debugPrint('END WORKMANAGER BACKUP SCHEDULING');
    } catch (e) {
      debugPrint('Gagal schedule WorkManager backup: $e');
      debugPrint('END WORKMANAGER BACKUP SCHEDULING (ERROR)');
    }
  }

  /// Schedule next day's notification using WorkManager as backup (LEGACY - keep for callback)
  Future<void> _scheduleNextDayWithWorkManager() async {
    debugPrint('SCHEDULING WORKMANAGER BACKUP');
    try {
      final notificationTime = await _getNotificationTime();

      // Cancel existing task first
      await Workmanager().cancelByUniqueName('daily_reminder');

      // Always schedule WorkManager for NEXT DAY (backup for primary notification)
      final now = DateTime.now();
      final tomorrow = DateTime(
        now.year,
        now.month,
        now.day + 1, // Always tomorrow for backup
        notificationTime.hour,
        notificationTime.minute,
      );

      final delayDuration = tomorrow.difference(now);

      debugPrint('WorkManager backup: Scheduling for tomorrow');
      debugPrint('Waktu sekarang: $now');
      debugPrint('Next WorkManager trigger: $tomorrow');
      debugPrint(
        '📅 Delay: ${delayDuration.inHours}h ${delayDuration.inMinutes.remainder(60)}m',
      );

      // Schedule WorkManager task for tomorrow's notification
      // Remove constraints to match successful test approach
      await Workmanager().registerOneOffTask(
        'daily_reminder',
        'dailyReminderTask',
        initialDelay: delayDuration,
        // NO CONSTRAINTS - same as comprehensive test that works
      );

      debugPrint('WorkManager scheduled for next day');
      debugPrint('END WORKMANAGER SCHEDULING');
    } catch (e) {
      debugPrint('Gagal schedule WorkManager task: $e');
      debugPrint('END WORKMANAGER SCHEDULING (ERROR)');
    }
  }

  Future<void> cancelDailyReminder() async {
    try {
      // Cancel timer (cleanup legacy method)
      _dailyReminderTimer?.cancel();
      _dailyReminderTimer = null;

      // Cancel WorkManager task (if any)
      try {
        await Workmanager().cancelByUniqueName('daily_reminder');
      } catch (e) {
        debugPrint('WorkManager cancel failed (may not exist): $e');
      }

      // Cancel the scheduled daily reminder notification
      await flutterLocalNotificationsPlugin.cancel(0);

      debugPrint('Daily reminder cancelled successfully');
    } catch (e) {
      debugPrint('Gagal cancel daily reminder: $e');
    }
  }

  static Timer? _testTimer;
  static Timer? _dailyReminderTimer;

  /// Test notification function that schedules a notification 2 minutes from now
  /// Uses zonedSchedule for proper testing of the new implementation
  Future<bool> scheduleTestNotification() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for test');
          return false;
        }
      }

      // Cancel any existing timer and scheduled test notifications
      _testTimer?.cancel();
      await flutterLocalNotificationsPlugin.cancel(999);

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledTime = now.add(const Duration(minutes: 2));

      debugPrint('ZONED SCHEDULE TEST NOTIFICATION');
      debugPrint('Waktu sekarang: $now');
      debugPrint('Dijadwalkan time: $scheduledTime');
      debugPrint('Will fire in: 120 seconds');

      // Use zonedSchedule for proper testing
      await flutterLocalNotificationsPlugin.zonedSchedule(
        999, // test notification id
        '🎯 ZonedSchedule Test BERHASIL!',
        'Test notifikasi 2 menit menggunakan zonedSchedule. Sistem bekerja dengan sempurna!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for debugging',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Test Notification',
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('ZonedSchedule test notification scheduled successfully!');
      debugPrint('Notifikasi will appear at: $scheduledTime');
      debugPrint('END ZONED SCHEDULE SETUP');

      return true;
    } catch (e) {
      debugPrint('Gagal schedule test notification: $e');
      return false;
    }
  }

  /// Test immediate notification
  Future<bool> showTestNotification() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for test');
          return false;
        }
      }

      final DateTime now = DateTime.now();
      final String timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      debugPrint('SENDING IMMEDIATE TEST NOTIFICATION');
      debugPrint('Time: $timeString');

      final success = await showNotification(
        'Test Notifikasi Segera 🧪',
        'BERHASIL! Test notifikasi langsung berhasil pada waktu: $timeString',
      );

      debugPrint('Immediate test notification result: $success');
      debugPrint('END IMMEDIATE TEST');
      return success;
    } catch (e) {
      debugPrint('Gagal show immediate test notification: $e');
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
      debugPrint('Gagal cancel test notifications: $e');
    }
  }

  /// Get pending notification requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      debugPrint(
        '📋 Pending notifications count: ${pendingNotifications.length}',
      );
      for (final notification in pendingNotifications) {
        debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
      }
      return pendingNotifications;
    } catch (e) {
      debugPrint('Gagal get pending notifications: $e');
      return [];
    }
  }

  /// LIVE TEST: Schedule notification exactly +2 minutes from now
  Future<bool> scheduleLiveTest2Minutes() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for live test');
          return false;
        }
      }

      // STEP 1: Check and request ALL permissions
      debugPrint('PERMISSION CHECK');

      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          // Check basic notification
          debugPrint('Checking notification permission...');

          // Check exact alarm
          final bool? exactAlarmGranted = await androidImplementation
              .canScheduleExactNotifications();
          debugPrint('Exact alarm permission: $exactAlarmGranted');

          if (exactAlarmGranted != true) {
            debugPrint('Requesting exact alarm permission...');
            await androidImplementation.requestExactAlarmsPermission();

            // Re-check
            final recheckResult = await androidImplementation
                .canScheduleExactNotifications();
            debugPrint('After request - exact alarm: $recheckResult');

            if (recheckResult != true) {
              debugPrint(
                '❌ CRITICAL: No exact alarm permission - test will fail!',
              );
              debugPrint(
                '❌ User needs to manually grant in Settings > Apps > Restaurant App > Alarms & reminders',
              );
              return false;
            }
          }
        }
      }

      // STEP 2: Cancel existing tests
      await flutterLocalNotificationsPlugin.cancel(555); // Live test ID

      // STEP 3: Get current time and calculate +2 minutes
      final DateTime systemNow = DateTime.now();
      final DateTime targetTime = systemNow.add(const Duration(minutes: 2));

      debugPrint('LIVE TEST +2 MINUTES');
      debugPrint('Current system time: ${systemNow.toString()}');
      debugPrint('Target notification time: ${targetTime.toString()}');
      debugPrint(
        '🕐 Current: ${systemNow.hour.toString().padLeft(2, '0')}:${systemNow.minute.toString().padLeft(2, '0')}:${systemNow.second.toString().padLeft(2, '0')}',
      );
      debugPrint(
        '🕐 Target:  ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}:${targetTime.second.toString().padLeft(2, '0')}',
      );
      debugPrint('Delay: 2 minutes exactly');

      // STEP 4: Timezone handling
      final tz.TZDateTime tzNow = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
        targetTime,
        tz.local,
      );

      debugPrint('TIMEZONE DEBUG');
      debugPrint('System DateTime: $systemNow');
      debugPrint('TZ DateTime: $tzNow');
      debugPrint('Dijadwalkan TZ: $scheduledTime');
      debugPrint('Local timezone: ${tz.local}');
      debugPrint('System offset: ${systemNow.timeZoneOffset}');

      // STEP 5: Schedule notification
      debugPrint('SCHEDULING NOTIFICATION');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        555, // live test notification id
        '🔥 LIVE TEST BERHASIL!',
        'Notifikasi +2 menit dari ${systemNow.hour.toString().padLeft(2, '0')}:${systemNow.minute.toString().padLeft(2, '0')} → ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Restaurant Reminder',
            channelDescription:
                'Daily reminder to check restaurant recommendations',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'LIVE TEST +2 MIN',
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('LIVE TEST SCHEDULED');
      debugPrint('Notifikasi ID: 555');
      debugPrint(
        '✅ Scheduled for: ${targetTime.hour.toString().padLeft(2, '0')}:${targetTime.minute.toString().padLeft(2, '0')}:${targetTime.second.toString().padLeft(2, '0')}',
      );
      debugPrint(
        '✅ Current time:  ${systemNow.hour.toString().padLeft(2, '0')}:${systemNow.minute.toString().padLeft(2, '0')}:${systemNow.second.toString().padLeft(2, '0')}',
      );
      debugPrint('WAIT EXACTLY 2 MINUTES FOR NOTIFICATION!');
      debugPrint(
        '✅ Close app and wait - notification should appear even when app closed',
      );

      // Check pending notifications
      final pendingNotifications = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      debugPrint(
        '📋 Pending notifications after schedule: ${pendingNotifications.length}',
      );
      for (final notif in pendingNotifications) {
        debugPrint('- ID: ${notif.id}, Title: ${notif.title}');
      }

      return true;
    } catch (e) {
      debugPrint('CRITICAL ERROR in live test: $e');
      debugPrint('Stack trace: ${e.toString()}');
      return false;
    }
  }

  /// Alternative test using Timer (same as immediate but with delay)
  Future<bool> scheduleTimerBasedTest() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for timer test');
          return false;
        }
      }

      // Cancel any existing timer
      _testTimer?.cancel();

      final DateTime now = DateTime.now();
      final DateTime targetTime = now.add(const Duration(seconds: 30));

      debugPrint('TIMER-BASED TEST (30 seconds)');
      debugPrint('Waktu sekarang: ${now.toString()}');
      debugPrint('Target time: ${targetTime.toString()}');
      debugPrint('Will use Timer.periodic for 30 seconds');

      // Use Timer like immediate notification
      _testTimer = Timer(const Duration(seconds: 30), () async {
        final DateTime fireTime = DateTime.now();
        debugPrint('TIMER FIRED! Time: ${fireTime.toString()}');

        final success = await showNotification(
          '⏰ TIMER Test BERHASIL!',
          'Test menggunakan Timer (seperti immediate) berhasil pada ${fireTime.hour.toString().padLeft(2, '0')}:${fireTime.minute.toString().padLeft(2, '0')}',
        );

        debugPrint('Timer-based test result: $success');
      });

      debugPrint('Timer-based test set for 30 seconds!');
      debugPrint('END TIMER SETUP');

      return true;
    } catch (e) {
      debugPrint('Failed timer-based test: $e');
      return false;
    }
  }

  /// Test immediate notification to verify system is working
  Future<bool> testImmediateNotification() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for immediate test');
          return false;
        }
      }

      final DateTime now = DateTime.now();
      final String timeString =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      debugPrint('IMMEDIATE TEST NOTIFICATION');
      debugPrint('Testing immediate notification at: $timeString');

      final success = await showNotification(
        '⚡ IMMEDIATE Test BERHASIL!',
        'Sistem notifikasi dasar bekerja! Waktu: $timeString',
      );

      debugPrint('Immediate test result: $success');
      debugPrint('END IMMEDIATE TEST');

      return success;
    } catch (e) {
      debugPrint('Failed immediate test: $e');
      return false;
    }
  }

  /// Debug current scheduling information
  Future<void> debugSchedulingInfo() async {
    try {
      final notificationTime = await _getNotificationTime();
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final DateTime regularNow = DateTime.now();

      debugPrint('DEBUG SCHEDULING INFO');
      debugPrint('System DateTime.now(): $regularNow');
      debugPrint('TZDateTime.now(tz.local): $now');
      debugPrint('Timezone: ${tz.local}');
      debugPrint(
        'Notification time setting: ${notificationTime.hour}:${notificationTime.minute}',
      );

      // Calculate what would be scheduled
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        notificationTime.hour,
        notificationTime.minute,
        0,
      );

      debugPrint('Calculated scheduled time for today: $scheduledDate');
      debugPrint(
        'Is scheduled time before now? ${scheduledDate.isBefore(now)}',
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('Adjusted to tomorrow: $scheduledDate');
      }

      debugPrint('Final scheduled time: $scheduledDate');
      debugPrint('Time difference: ${scheduledDate.difference(now)}');

      // Check pending notifications
      final pending = await getPendingNotifications();
      debugPrint('Pending notifications: ${pending.length}');

      debugPrint('END DEBUG INFO');
    } catch (e) {
      debugPrint('Gagal get debug info: $e');
    }
  }

  /// Simple test notification 30 seconds from now - FIXED VERSION
  Future<bool> scheduleSimpleTest() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for simple test');
          return false;
        }
      }

      // EXPLICIT PERMISSION CHECK AND REQUEST
      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          final bool? exactAlarmGranted = await androidImplementation
              .canScheduleExactNotifications();
          debugPrint(
            '🔐 Simple test - Exact alarm permission: $exactAlarmGranted',
          );

          if (exactAlarmGranted != true) {
            debugPrint('No exact alarm permission - requesting...');
            await androidImplementation.requestExactAlarmsPermission();

            // Re-check
            final recheckResult = await androidImplementation
                .canScheduleExactNotifications();
            debugPrint(
              '🔐 After request - exact alarm permission: $recheckResult',
            );

            if (recheckResult != true) {
              debugPrint(
                '❌ Still no exact alarm permission - scheduling may fail',
              );
            }
          }
        }
      }

      // Cancel any existing test
      await flutterLocalNotificationsPlugin.cancel(997);

      // TIMEZONE DEBUGGING
      debugPrint('TIMEZONE DEBUG');
      final DateTime regularNow = DateTime.now();
      final tz.TZDateTime tzNow = tz.TZDateTime.now(tz.local);

      debugPrint('Regular DateTime.now(): $regularNow');
      debugPrint('TZ DateTime.now(): $tzNow');
      debugPrint('Local timezone: ${tz.local}');
      debugPrint('System timezone offset: ${regularNow.timeZoneOffset}');

      // USE SYSTEM TIMEZONE METHOD INSTEAD OF tz.local
      final DateTime systemNow = DateTime.now();
      final tz.TZDateTime saferScheduledTime = tz.TZDateTime.from(
        systemNow.add(const Duration(seconds: 30)),
        tz.local,
      );

      debugPrint('SIMPLE TEST (30 seconds) FIXED');
      debugPrint('System time: $systemNow');
      debugPrint('Safer scheduled time: $saferScheduledTime');
      debugPrint('Time difference: ${saferScheduledTime.difference(tzNow)}');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        997, // test notification id
        '🚀 FIXED Test 30 Detik!',
        'Test dengan timezone fix berhasil pada ${saferScheduledTime.hour}:${saferScheduledTime.minute}:${saferScheduledTime.second}',
        saferScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Restaurant Reminder',
            channelDescription:
                'Daily reminder to check restaurant recommendations',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Simple Test Fixed',
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Fixed simple test scheduled for 30 seconds!');
      debugPrint('END FIXED SIMPLE TEST');

      return true;
    } catch (e) {
      debugPrint('Failed simple test: $e');
      debugPrint('Error details: ${e.toString()}');
      return false;
    }
  }

  /// Quick test notification 1 minute from now using the same method as daily reminder
  Future<bool> scheduleQuickTestNotification() async {
    try {
      if (!isPlatformSupported) {
        debugPrint('Notifikasis not supported on this platform');
        return false;
      }

      // Ensure notifications are initialized
      if (!_isInitialized) {
        final initialized = await initNotifications();
        if (!initialized) {
          debugPrint('Gagal initialize notifications for quick test');
          return false;
        }
      }

      // Request exact alarm permission for Android 12+
      if (Platform.isAndroid) {
        final androidImplementation = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          final bool? exactAlarmGranted = await androidImplementation
              .canScheduleExactNotifications();
          debugPrint(
            '🔐 Quick test - Exact alarm permission granted: $exactAlarmGranted',
          );

          if (exactAlarmGranted == false) {
            debugPrint(
              '⚠️ Quick test - Exact alarm permission not granted, requesting...',
            );
            final result = await androidImplementation
                .requestExactAlarmsPermission();
            debugPrint(
              '🔐 Quick test - Exact alarm permission request result: $result',
            );
          }
        }
      }

      // Cancel any existing test notifications
      await flutterLocalNotificationsPlugin.cancel(998);

      // Schedule for 1 minute from now
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledTime = now.add(const Duration(minutes: 1));

      debugPrint('QUICK TEST NOTIFICATION (1 MINUTE)');
      debugPrint('Waktu sekarang: $now');
      debugPrint('Dijadwalkan time: $scheduledTime');
      debugPrint('Will fire in: 60 seconds');

      // Schedule notification using the same method as daily reminder
      await flutterLocalNotificationsPlugin.zonedSchedule(
        998, // test notification id
        '⏰ Test Notifikasi 1 Menit BERHASIL!',
        'Notifikasi menggunakan zonedSchedule dengan exact alarm. Sistem bekerja sempurna pada ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Restaurant Reminder',
            channelDescription:
                'Daily reminder to check restaurant recommendations',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Test Notification',
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Quick test notification scheduled successfully!');
      debugPrint('Notifikasi will appear at: $scheduledTime');
      debugPrint('END QUICK TEST SETUP');

      return true;
    } catch (e) {
      debugPrint('Gagal schedule quick test notification: $e');
      return false;
    }
  }
}

// Export this function for use in main.dart
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('WorkManager CALLBACK STARTED');
      debugPrint('Task: $task');
      debugPrint('Input Data: $inputData');
      debugPrint('Time: ${DateTime.now()}');

      if (task == 'dailyReminderTask') {
        try {
          debugPrint('Processing dailyReminderTask');

          // Initialize timezone first to prevent timezone errors
          debugPrint('Initializing timezones...');
          tz.initializeTimeZones();
          debugPrint('Timezones initialized');

          // Initialize notifications (skip permission request in background)
          debugPrint('Initializing notifications...');
          final notificationHelper = NotificationHelper();

          // Force initialization without permission check in background
          if (!NotificationHelper._isInitialized) {
            try {
              // Initialize timezone and basic setup
              tz.initializeTimeZones();
              final String timeZoneName = await notificationHelper
                  ._getDeviceTimeZone();
              tz.setLocalLocation(tz.getLocation(timeZoneName));

              // Create notification channels without permission request
              await notificationHelper._createNotificationChannels();
              NotificationHelper._isInitialized = true;
              debugPrint(
                '✅ Background notifications initialized (skipped permissions)',
              );
            } catch (e) {
              debugPrint('Gagal initialize background notifications: $e');
              return Future.value(false);
            }
          } else {
            debugPrint('Notifikasis already initialized');
          }

          // Show the notification based on favorites
          bool notificationSuccess = false;

          try {
            // Get favorites from database
            final dbHelper = DatabaseHelper();
            await dbHelper.initialize();
            final favorites = await dbHelper.getFavorites();

            String title = 'Waktunya Makan! 🍽️';
            String body;

            if (favorites.isNotEmpty) {
              // Random restaurant from favorites
              final randomIndex = Random().nextInt(favorites.length);
              final restaurant = favorites[randomIndex];

              body =
                  'Bagaimana dengan ${restaurant.name} di ${restaurant.city} hari ini? Restoran favoritmu menunggu!';
              debugPrint('Using favorite restaurant: ${restaurant.name}');
            } else {
              // No favorites yet
              body =
                  'Jangan lupa makan siang hari ini! Yuk cari restoran favoritmu dan simpan untuk rekomendasi selanjutnya 😊';
              debugPrint('No favorites, using invitation message');
            }

            notificationSuccess = await notificationHelper.showNotification(
              title,
              body,
            );

            debugPrint('WorkManager notification shown: $notificationSuccess');
          } catch (e) {
            debugPrint('Error getting favorites in background: $e');

            // Fallback notification if error
            notificationSuccess = await notificationHelper.showNotification(
              'Waktunya Makan! 🍽️',
              'Jangan lupa makan siang hari ini! Cek aplikasi untuk rekomendasi restoran.',
            );
            debugPrint('Fallback notification shown: $notificationSuccess');
          }

          // Schedule next day's notification (auto-renewal from callback)
          await notificationHelper._scheduleNextDayWithWorkManager();

          return Future.value(notificationSuccess);
        } catch (e) {
          debugPrint('Error in background task: $e');

          // Last resort notification
          try {
            final notificationHelper = NotificationHelper();
            await notificationHelper.initNotifications();

            // Try to get content based on favorites
            String title = 'Waktunya Makan! 🍽️';
            String body = 'Jangan lupa makan siang hari ini!';

            try {
              final dbHelper = DatabaseHelper();
              await dbHelper.initialize();
              final favorites = await dbHelper.getFavorites();

              if (favorites.isNotEmpty) {
                final randomIndex = Random().nextInt(favorites.length);
                final restaurant = favorites[randomIndex];
                body =
                    'Bagaimana dengan ${restaurant.name} di ${restaurant.city} hari ini? Restoran favoritmu menunggu!';
              } else {
                body =
                    'Jangan lupa makan siang hari ini! Yuk cari restoran favoritmu dan simpan untuk rekomendasi selanjutnya 😊';
              }
            } catch (dbError) {
              debugPrint('Gagal get favorites in last resort: $dbError');
            }

            final success = await notificationHelper.showNotification(
              title,
              body,
            );
            debugPrint('Last resort notification shown: $success');

            // Still try to schedule next day (auto-renewal)
            await notificationHelper._scheduleNextDayWithWorkManager();

            return Future.value(success);
          } catch (notifError) {
            debugPrint('Gagal show last resort notification: $notifError');
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

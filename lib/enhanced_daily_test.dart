import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'utils/notification_helper.dart';

class EnhancedDailyTestScreen extends StatefulWidget {
  const EnhancedDailyTestScreen({super.key});

  @override
  State<EnhancedDailyTestScreen> createState() => _EnhancedDailyTestScreenState();
}

class _EnhancedDailyTestScreenState extends State<EnhancedDailyTestScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
    });
    debugPrint(message);
  }

  Future<void> _testSeparateNotifications() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _addLog('🔵 Testing SEPARATE notifications (no conflict)...');
    try {
      final now = DateTime.now();
      final twoMinutesLater = now.add(const Duration(minutes: 2));

      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Target time: ${twoMinutesLater.toString().substring(11, 19)}');

      // Step 1: Test PRIMARY notification only
      _addLog('🟢 Step 1: Testing PRIMARY notification only');

      // Cancel everything first
      await _notificationHelper.cancelDailyReminder();
      await Workmanager().cancelAll();
      _addLog('🧹 Cancelled all existing notifications and tasks');

      // Create immediate test notification (PRIMARY channel)
      await _notificationHelper.showNotification(
        'TEST PRIMARY 🟢',
        'This is PRIMARY channel test at ${now.toString().substring(11, 19)}'
      );
      _addLog('✅ PRIMARY test notification sent immediately');

      await Future.delayed(const Duration(seconds: 2));

      // Step 2: Test WorkManager notification only
      _addLog('🔵 Step 2: Testing WorkManager notification in 30 seconds');

      await Workmanager().registerOneOffTask(
        'test_workmanager_only',
        'dailyReminderTask',
        initialDelay: const Duration(seconds: 30),
      );
      _addLog('✅ WorkManager test scheduled for 30 seconds');
      _addLog('📺 Watch for WORKMANAGER notification in 30 seconds');

      await Future.delayed(const Duration(seconds: 3));

      // Step 3: Test scheduled PRIMARY for 2 minutes
      _addLog('🟡 Step 3: Testing scheduled PRIMARY for 2 minutes');

      // Set time for 2 minutes later
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', twoMinutesLater.hour);
      await prefs.setInt('notification_minute', twoMinutesLater.minute);

      // Schedule only PRIMARY (no WorkManager)
      await _testPrimarySchedulingOnly(twoMinutesLater);
      _addLog('✅ PRIMARY scheduled for 2 minutes (no WorkManager conflict)');

    } catch (e) {
      _addLog('❌ Error in separate test: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _testPrimarySchedulingOnly(DateTime targetTime) async {
    try {
      // Cancel existing
      await _notificationHelper.initNotifications();

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.cancel(0);
      await flutterLocalNotificationsPlugin.cancel(1);

      // Schedule only PRIMARY
      final scheduledDate = tz.TZDateTime(
        tz.local,
        targetTime.year,
        targetTime.month,
        targetTime.day,
        targetTime.hour,
        targetTime.minute,
        0,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        2, // Different ID
        'SCHEDULED PRIMARY 🟡',
        'Scheduled PRIMARY at ${targetTime.toString().substring(11, 19)}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'primary_notification_channel',
            'Primary Notifications',
            channelDescription: 'Primary scheduled notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Scheduled Primary Test',
            showWhen: true,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            tag: 'test_primary_scheduled',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

    } catch (e) {
      _addLog('❌ Error in primary scheduling: $e');
    }
  }

  Future<void> _testRealDailyReminderFlow() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    _addLog('🔴 Testing REAL daily reminder flow (2 minutes)...');
    try {
      final now = DateTime.now();
      final twoMinutesLater = now.add(const Duration(minutes: 2));

      _addLog('⏰ Current: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Target: ${twoMinutesLater.toString().substring(11, 19)}');

      // Set notification time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', twoMinutesLater.hour);
      await prefs.setInt('notification_minute', twoMinutesLater.minute);
      _addLog('⚙️ Set notification time in preferences');

      // Cancel everything
      await _notificationHelper.cancelDailyReminder();
      await Workmanager().cancelAll();
      _addLog('🧹 Cancelled all existing notifications');

      // Use REAL daily reminder method
      await _notificationHelper.scheduleDailyReminder();
      _addLog('✅ Real scheduleDailyReminder() called');
      _addLog('📺 Should get PRIMARY and BACKUP notifications');
      _addLog('⏰ Wait 2 minutes for results...');

    } catch (e) {
      _addLog('❌ Error in real daily test: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _checkActiveNotifications() async {
    _addLog('🔍 Checking active notifications...');
    try {
      final activeNotifications = await _notificationHelper.getActiveNotifications();
      _addLog('📱 Found ${activeNotifications.length} active notifications');

      for (final notification in activeNotifications) {
        _addLog('📝 ID: ${notification.id}, Title: ${notification.title}');
      }

      if (activeNotifications.isEmpty) {
        _addLog('📭 No active notifications found');
      }

    } catch (e) {
      _addLog('❌ Error checking notifications: $e');
    }
  }

  Future<void> _forceCreateChannels() async {
    _addLog('📺 Force creating notification channels...');
    try {
      await _notificationHelper.initNotifications();
      _addLog('✅ Notification channels recreated');
    } catch (e) {
      _addLog('❌ Error creating channels: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Daily Test'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.withOpacity(0.1),
            child: Column(
              children: [
                const Text(
                  'Enhanced Daily Reminder Testing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRunning ? 'Test Running...' : 'Ready to Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isRunning ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Robust testing with separate channels and conflict detection',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _testSeparateNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Separate'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _testRealDailyReminderFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Real Flow'),
                ),
                ElevatedButton(
                  onPressed: _checkActiveNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Check Active'),
                ),
                ElevatedButton(
                  onPressed: _forceCreateChannels,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Force Channels'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enhanced Test Logs:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color textColor = Colors.black;
                          if (log.contains('✅')) textColor = Colors.green;
                          if (log.contains('❌')) textColor = Colors.red;
                          if (log.contains('🔵')) textColor = Colors.blue;
                          if (log.contains('🟢')) textColor = Colors.green;
                          if (log.contains('🟡')) textColor = Colors.orange;
                          if (log.contains('🔴')) textColor = Colors.red;
                          if (log.contains('⏰')) textColor = Colors.purple;
                          if (log.contains('📺')) textColor = Colors.indigo;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: textColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
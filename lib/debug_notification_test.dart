import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'utils/notification_helper.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _addLog('🟢 NotificationTestScreen initialized');
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
    });
    debugPrint(message);
  }

  Future<void> _testBasicNotification() async {
    _addLog('🔵 Testing basic notification...');
    try {
      final success = await _notificationHelper.showNotification(
        'Test Notification 🧪',
        'This is a test notification at ${DateTime.now().toString().substring(11, 19)}'
      );
      _addLog(success ? '✅ Basic notification sent successfully' : '❌ Failed to send basic notification');
    } catch (e) {
      _addLog('❌ Error sending basic notification: $e');
    }
  }

  Future<void> _testNotificationPermissions() async {
    _addLog('🔵 Testing notification permissions...');
    try {
      final hasPermission = await _notificationHelper.requestAllPermissions();
      _addLog(hasPermission ? '✅ Permissions granted' : '❌ Permissions denied');
    } catch (e) {
      _addLog('❌ Error checking permissions: $e');
    }
  }

  Future<void> _testNotificationInit() async {
    _addLog('🔵 Testing notification initialization...');
    try {
      final success = await _notificationHelper.initNotifications();
      _addLog(success ? '✅ Notifications initialized successfully' : '❌ Failed to initialize notifications');
    } catch (e) {
      _addLog('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _testDailyReminder() async {
    _addLog('🔵 Testing daily reminder scheduling...');
    try {
      await _notificationHelper.scheduleDailyReminder();
      _addLog('✅ Daily reminder scheduled successfully');
    } catch (e) {
      _addLog('❌ Error scheduling daily reminder: $e');
    }
  }

  Future<void> _testWorkManagerStatus() async {
    _addLog('🔵 Testing WorkManager status...');
    try {
      // We can't directly check WorkManager status, but we can try to cancel existing tasks
      await Workmanager().cancelByUniqueName('daily_reminder');
      _addLog('✅ WorkManager accessible - existing tasks cancelled');
    } catch (e) {
      _addLog('❌ Error accessing WorkManager: $e');
    }
  }

  Future<void> _testImmediateWorkManagerTask() async {
    _addLog('🔵 Testing immediate WorkManager task...');
    try {
      await Workmanager().registerOneOffTask(
        'test_task',
        'dailyReminderTask',
        initialDelay: const Duration(seconds: 5),
      );
      _addLog('✅ Immediate WorkManager task scheduled for 5 seconds');
      _addLog('⏰ Check logs in 5 seconds for task execution');
    } catch (e) {
      _addLog('❌ Error scheduling immediate WorkManager task: $e');
    }
  }

  Future<void> _runAllTests() async {
    _addLog('🟡 === STARTING COMPREHENSIVE NOTIFICATION TEST ===');
    await _testNotificationInit();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testNotificationPermissions();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testBasicNotification();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testWorkManagerStatus();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testImmediateWorkManagerTask();
    await Future.delayed(const Duration(milliseconds: 500));

    await _testDailyReminder();
    _addLog('🟡 === COMPREHENSIVE TEST COMPLETED ===');
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
        title: const Text('Notification Test'),
        backgroundColor: Colors.blue,
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
            child: Column(
              children: [
                const Text(
                  'Notification Debug Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _runAllTests,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Run All Tests'),
                    ),
                    ElevatedButton(
                      onPressed: _testBasicNotification,
                      child: const Text('Test Basic'),
                    ),
                    ElevatedButton(
                      onPressed: _testNotificationPermissions,
                      child: const Text('Test Permissions'),
                    ),
                    ElevatedButton(
                      onPressed: _testDailyReminder,
                      child: const Text('Schedule Daily'),
                    ),
                    ElevatedButton(
                      onPressed: _testImmediateWorkManagerTask,
                      child: const Text('Test WorkManager'),
                    ),
                  ],
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
                    'Debug Logs:',
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
                          if (log.contains('🟡')) textColor = Colors.orange;
                          if (log.contains('⏰')) textColor = Colors.purple;

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
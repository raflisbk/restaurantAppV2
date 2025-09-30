import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/notification_helper.dart';

class ImmediateNotificationTestScreen extends StatefulWidget {
  const ImmediateNotificationTestScreen({super.key});

  @override
  State<ImmediateNotificationTestScreen> createState() => _ImmediateNotificationTestScreenState();
}

class _ImmediateNotificationTestScreenState extends State<ImmediateNotificationTestScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  final List<String> _logs = [];

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
    });
    debugPrint(message);
  }

  Future<void> _testScheduleForLater() async {
    _addLog('🔵 Testing schedule for 1 minute from now...');

    try {
      // Get current time and add 1 minute
      final now = DateTime.now();
      final oneMinuteLater = now.add(const Duration(minutes: 1));

      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Will trigger at: ${oneMinuteLater.toString().substring(11, 19)}');

      // Cancel existing WorkManager tasks
      await _notificationHelper.cancelDailyReminder();

      // Use WorkManager to schedule for 1 minute later
      await Workmanager().registerOneOffTask(
        'test_immediate',
        'dailyReminderTask',
        initialDelay: const Duration(minutes: 1),
      );

      _addLog('✅ Notification scheduled for 1 minute from now');
      _addLog('⏰ Please wait 1 minute to see the notification');

    } catch (e) {
      _addLog('❌ Error scheduling notification: $e');
    }
  }

  Future<void> _testScheduleFor30Seconds() async {
    _addLog('🔵 Testing schedule for 30 seconds from now...');

    try {
      // Get current time and add 30 seconds
      final now = DateTime.now();
      final thirtySecondsLater = now.add(const Duration(seconds: 30));

      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Will trigger at: ${thirtySecondsLater.toString().substring(11, 19)}');

      // Cancel existing WorkManager tasks
      await _notificationHelper.cancelDailyReminder();

      // Use WorkManager to schedule for 30 seconds later
      await Workmanager().registerOneOffTask(
        'test_immediate',
        'dailyReminderTask',
        initialDelay: const Duration(seconds: 30),
      );

      _addLog('✅ Notification scheduled for 30 seconds from now');
      _addLog('⏰ Please wait 30 seconds to see the notification');

    } catch (e) {
      _addLog('❌ Error scheduling notification: $e');
    }
  }

  Future<void> _testScheduleForSpecificTime() async {
    _addLog('🔵 Testing schedule for specific time (current time + 2 minutes)...');

    try {
      final now = DateTime.now();
      final targetTime = now.add(const Duration(minutes: 2));

      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Target time: ${targetTime.toString().substring(11, 19)}');

      // Simulate setting notification time to 2 minutes from now
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', targetTime.hour);
      await prefs.setInt('notification_minute', targetTime.minute);

      _addLog('🔧 Set notification time to: ${targetTime.hour}:${targetTime.minute.toString().padLeft(2, '0')}');

      // Now schedule daily reminder (should schedule for the time we just set)
      await _notificationHelper.scheduleDailyReminder();

      _addLog('✅ Daily reminder scheduled');
      _addLog('⏰ Should trigger in 2 minutes');

    } catch (e) {
      _addLog('❌ Error: $e');
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
        title: const Text('Immediate Notification Test'),
        backgroundColor: Colors.orange,
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
                  'Test Notifications for Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'These tests will schedule notifications for today to verify the logic works correctly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _testScheduleFor30Seconds,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test 30s'),
                    ),
                    ElevatedButton(
                      onPressed: _testScheduleForLater,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test 1min'),
                    ),
                    ElevatedButton(
                      onPressed: _testScheduleForSpecificTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test 2min'),
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
                    'Test Logs:',
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
                          if (log.contains('⏰')) textColor = Colors.orange;
                          if (log.contains('🔧')) textColor = Colors.purple;

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
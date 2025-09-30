import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/notification_helper.dart';

class DailyReminderDebugScreen extends StatefulWidget {
  const DailyReminderDebugScreen({super.key});

  @override
  State<DailyReminderDebugScreen> createState() => _DailyReminderDebugScreenState();
}

class _DailyReminderDebugScreenState extends State<DailyReminderDebugScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  final List<String> _logs = [];

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
    });
    debugPrint(message);
  }

  Future<void> _testExactDailyReminderLogic() async {
    _addLog('🔵 Testing EXACT daily reminder logic...');
    try {
      // Cancel existing tasks
      await Workmanager().cancelByUniqueName('daily_reminder');
      _addLog('🧹 Cancelled existing daily_reminder tasks');

      // Call the actual scheduleDailyReminder method
      await _notificationHelper.scheduleDailyReminder();
      _addLog('✅ Daily reminder scheduled using actual method');

    } catch (e) {
      _addLog('❌ Error with daily reminder: $e');
    }
  }

  Future<void> _testLongDelayWorkManager() async {
    _addLog('🔵 Testing WorkManager with LONG delay (like daily reminder)...');
    try {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(minutes: 5)); // 5 minutes later
      final delay = futureTime.difference(now);

      _addLog('⏰ Current: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Target: ${futureTime.toString().substring(11, 19)}');
      _addLog('⏰ Delay: ${delay.inMinutes}m ${delay.inSeconds.remainder(60)}s');

      // Cancel existing
      await Workmanager().cancelByUniqueName('test_long_delay');

      // Test with SAME constraints as daily reminder
      await Workmanager().registerOneOffTask(
        'test_long_delay',
        'dailyReminderTask',
        initialDelay: delay,
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      _addLog('✅ Long delay WorkManager scheduled (with constraints)');
      _addLog('⏰ Will trigger in 5 minutes');

    } catch (e) {
      _addLog('❌ Error with long delay: $e');
    }
  }

  Future<void> _testLongDelayNoConstraints() async {
    _addLog('🔵 Testing WorkManager with LONG delay (NO constraints)...');
    try {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(minutes: 3)); // 3 minutes later
      final delay = futureTime.difference(now);

      _addLog('⏰ Current: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Target: ${futureTime.toString().substring(11, 19)}');
      _addLog('⏰ Delay: ${delay.inMinutes}m ${delay.inSeconds.remainder(60)}s');

      // Cancel existing
      await Workmanager().cancelByUniqueName('test_no_constraints');

      // Test WITHOUT constraints (like comprehensive test)
      await Workmanager().registerOneOffTask(
        'test_no_constraints',
        'dailyReminderTask',
        initialDelay: delay,
        // NO CONSTRAINTS!
      );

      _addLog('✅ Long delay WorkManager scheduled (NO constraints)');
      _addLog('⏰ Will trigger in 3 minutes');

    } catch (e) {
      _addLog('❌ Error with no constraints: $e');
    }
  }

  Future<void> _testCurrentTimeScheduling() async {
    _addLog('🔵 Testing scheduling with current user time...');
    try {
      final now = DateTime.now();
      final testTime = now.add(const Duration(minutes: 1)); // 1 minute from now

      _addLog('🔧 Setting notification time to 1 minute from now...');

      // Temporarily set notification time to 1 minute from now
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', testTime.hour);
      await prefs.setInt('notification_minute', testTime.minute);

      _addLog('⚙️ Set notification time: ${testTime.hour}:${testTime.minute.toString().padLeft(2, '0')}');

      // Now use the actual daily reminder logic
      await _notificationHelper.scheduleDailyReminder();

      _addLog('✅ Daily reminder scheduled with user time logic');
      _addLog('⏰ Should trigger in ~1 minute');

    } catch (e) {
      _addLog('❌ Error with user time scheduling: $e');
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
        title: const Text('Daily Reminder Debug'),
        backgroundColor: Colors.red,
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
                  'Debug Daily Reminder Issues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Test why daily reminder fails but comprehensive test succeeds',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _testExactDailyReminderLogic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test Actual Daily'),
                    ),
                    ElevatedButton(
                      onPressed: _testLongDelayWorkManager,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test Long+Constraints'),
                    ),
                    ElevatedButton(
                      onPressed: _testLongDelayNoConstraints,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test Long+NoConstraints'),
                    ),
                    ElevatedButton(
                      onPressed: _testCurrentTimeScheduling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test User Time'),
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
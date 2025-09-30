import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/notification_helper.dart';

class RealDailyReminderTestScreen extends StatefulWidget {
  const RealDailyReminderTestScreen({super.key});

  @override
  State<RealDailyReminderTestScreen> createState() => _RealDailyReminderTestScreenState();
}

class _RealDailyReminderTestScreenState extends State<RealDailyReminderTestScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  final List<String> _logs = [];
  TimeOfDay? _currentNotificationTime;

  @override
  void initState() {
    super.initState();
    _loadCurrentNotificationTime();
  }

  Future<void> _loadCurrentNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('notification_hour') ?? 12;
      final minute = prefs.getInt('notification_minute') ?? 0;
      setState(() {
        _currentNotificationTime = TimeOfDay(hour: hour, minute: minute);
      });
      _addLog('📋 Current notification time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      _addLog('❌ Error loading current time: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
    });
    debugPrint(message);
  }

  Future<void> _testTodayScheduling() async {
    _addLog('🔵 Testing daily reminder for TODAY (2 minutes from now)...');
    try {
      final now = DateTime.now();
      final twoMinutesLater = now.add(const Duration(minutes: 2));

      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Setting notification for: ${twoMinutesLater.toString().substring(11, 19)}');

      // Set notification time to 2 minutes from now
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', twoMinutesLater.hour);
      await prefs.setInt('notification_minute', twoMinutesLater.minute);

      setState(() {
        _currentNotificationTime = TimeOfDay(
          hour: twoMinutesLater.hour,
          minute: twoMinutesLater.minute
        );
      });

      _addLog('⚙️ Updated notification time in settings');

      // Cancel existing reminders
      await _notificationHelper.cancelDailyReminder();
      _addLog('🧹 Cancelled existing reminders');

      // Schedule daily reminder (should use TODAY logic)
      await _notificationHelper.scheduleDailyReminder();
      _addLog('✅ Daily reminder scheduled - should trigger TODAY in 2 minutes');
      _addLog('⏰ Watch for both PRIMARY and BACKUP notifications');

    } catch (e) {
      _addLog('❌ Error testing today scheduling: $e');
    }
  }

  Future<void> _testTomorrowScheduling() async {
    _addLog('🔵 Testing daily reminder for TOMORROW (past time)...');
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');
      _addLog('⏰ Setting notification for: ${oneHourAgo.toString().substring(11, 19)} (past time)');

      // Set notification time to 1 hour ago (should trigger tomorrow logic)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', oneHourAgo.hour);
      await prefs.setInt('notification_minute', oneHourAgo.minute);

      setState(() {
        _currentNotificationTime = TimeOfDay(
          hour: oneHourAgo.hour,
          minute: oneHourAgo.minute
        );
      });

      _addLog('⚙️ Updated notification time to past time');

      // Cancel existing reminders
      await _notificationHelper.cancelDailyReminder();
      _addLog('🧹 Cancelled existing reminders');

      // Schedule daily reminder (should use TOMORROW logic)
      await _notificationHelper.scheduleDailyReminder();
      _addLog('✅ Daily reminder scheduled - should trigger TOMORROW');

      // Calculate exact time for tomorrow
      final tomorrow = DateTime(
        now.year,
        now.month,
        now.day + 1,
        oneHourAgo.hour,
        oneHourAgo.minute,
      );
      final delay = tomorrow.difference(now);
      _addLog('📅 Will trigger in: ${delay.inHours}h ${delay.inMinutes.remainder(60)}m');

    } catch (e) {
      _addLog('❌ Error testing tomorrow scheduling: $e');
    }
  }

  Future<void> _testCurrentUserTime() async {
    _addLog('🔵 Testing with current user notification time...');
    try {
      final now = DateTime.now();
      _addLog('⏰ Current time: ${now.toString().substring(11, 19)}');

      if (_currentNotificationTime != null) {
        _addLog('⚙️ Using current user time: ${_currentNotificationTime!.hour.toString().padLeft(2, '0')}:${_currentNotificationTime!.minute.toString().padLeft(2, '0')}');

        // Check if current user time is today or tomorrow
        final userTimeToday = DateTime(
          now.year,
          now.month,
          now.day,
          _currentNotificationTime!.hour,
          _currentNotificationTime!.minute,
        );

        if (userTimeToday.isAfter(now)) {
          final delay = userTimeToday.difference(now);
          _addLog('📅 User time is TODAY - will trigger in: ${delay.inHours}h ${delay.inMinutes.remainder(60)}m');
        } else {
          final userTimeTomorrow = userTimeToday.add(const Duration(days: 1));
          final delay = userTimeTomorrow.difference(now);
          _addLog('📅 User time has passed - will trigger TOMORROW in: ${delay.inHours}h ${delay.inMinutes.remainder(60)}m');
        }

        // Cancel existing and reschedule
        await _notificationHelper.cancelDailyReminder();
        await _notificationHelper.scheduleDailyReminder();
        _addLog('✅ Daily reminder scheduled with current user time');

      } else {
        _addLog('❌ No current notification time found');
      }

    } catch (e) {
      _addLog('❌ Error testing current user time: $e');
    }
  }

  Future<void> _restoreOriginalTime() async {
    _addLog('🔧 Restoring original notification time...');
    try {
      // Restore to reasonable default (12:00)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', 12);
      await prefs.setInt('notification_minute', 0);

      setState(() {
        _currentNotificationTime = const TimeOfDay(hour: 12, minute: 0);
      });

      _addLog('✅ Restored to 12:00 PM');
      await _loadCurrentNotificationTime();

    } catch (e) {
      _addLog('❌ Error restoring time: $e');
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
        title: const Text('Real Daily Reminder Test'),
        backgroundColor: Colors.purple,
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
            color: Colors.purple.withOpacity(0.1),
            child: Column(
              children: [
                const Text(
                  'Real Daily Reminder Testing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_currentNotificationTime != null)
                  Text(
                    'Current Setting: ${_currentNotificationTime!.hour.toString().padLeft(2, '0')}:${_currentNotificationTime!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Test the actual daily reminder logic with real user scenarios',
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
                  onPressed: _testTodayScheduling,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Today (2min)'),
                ),
                ElevatedButton(
                  onPressed: _testTomorrowScheduling,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Tomorrow'),
                ),
                ElevatedButton(
                  onPressed: _testCurrentUserTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Current Setting'),
                ),
                ElevatedButton(
                  onPressed: _restoreOriginalTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Restore 12:00'),
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
                          if (log.contains('📅')) textColor = Colors.indigo;

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
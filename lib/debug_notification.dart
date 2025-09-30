import 'package:flutter/material.dart';
import 'utils/notification_helper.dart';

/// Debug screen for testing notifications
class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  String _debugOutput = '';

  void _addToDebug(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print(message); // Also print to console
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Notifikasi'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Test buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Checking permission status...');
                    final status = await _notificationHelper.checkPermissionStatus();
                    _addToDebug('Permission status: $status');
                  },
                  child: const Text('Check Permissions'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Requesting all permissions...');
                    final result = await _notificationHelper.requestAllPermissions();
                    _addToDebug('Permission request result: $result');
                  },
                  child: const Text('Request Permissions'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Checking battery optimization...');
                    final result = await _notificationHelper.requestBatteryOptimizationExemption();
                    _addToDebug('Battery optimization check: $result');
                  },
                  child: const Text('Battery Optimization'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Testing immediate notification...');
                    final result = await _notificationHelper.testImmediateNotification();
                    _addToDebug('Immediate test result: $result');
                  },
                  child: const Text('Test Immediate'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Testing 30-second ZonedSchedule...');
                    final result = await _notificationHelper.scheduleSimpleTest();
                    _addToDebug('30-second ZonedSchedule test: $result');
                  },
                  child: const Text('Test ZonedSchedule'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Testing 30-second Timer...');
                    final result = await _notificationHelper.scheduleTimerBasedTest();
                    _addToDebug('30-second Timer test: $result');
                  },
                  child: const Text('Test Timer'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    _addToDebug('🔥 LIVE TEST +2 MINUTES STARTING...');
                    _addToDebug('Current time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}');
                    _addToDebug('Target time: ${now.add(Duration(minutes: 2)).hour.toString().padLeft(2, '0')}:${now.add(Duration(minutes: 2)).minute.toString().padLeft(2, '0')}:${now.add(Duration(minutes: 2)).second.toString().padLeft(2, '0')}');

                    final result = await _notificationHelper.scheduleLiveTest2Minutes();
                    _addToDebug('Live test scheduled: $result');
                    _addToDebug('CLOSE APP AND WAIT 2 MINUTES!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🔥 LIVE TEST +2 MIN'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Testing 1-minute notification...');
                    final result = await _notificationHelper.scheduleQuickTestNotification();
                    _addToDebug('1-minute test scheduled: $result');
                  },
                  child: const Text('Test 1 Minute'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Getting debug info...');
                    await _notificationHelper.debugSchedulingInfo();
                    _addToDebug('Debug info printed to console');
                  },
                  child: const Text('Debug Info'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('🔍 INVESTIGATING NOTIFICATION DELIVERY...');

                    // Check channels existence
                    _addToDebug('Recreating notification channels...');
                    await _notificationHelper.recreateChannels();

                    // Check permissions again
                    final permissions = await _notificationHelper.checkPermissionStatus();
                    _addToDebug('Permissions: $permissions');

                    // Get active notifications
                    final activeNotifs = await _notificationHelper.getActiveNotifications();
                    _addToDebug('Active notifications: ${activeNotifs.length}');

                    // Get pending notifications
                    final pending = await _notificationHelper.getPendingNotifications();
                    _addToDebug('Pending notifications: ${pending.length}');

                    if (pending.isNotEmpty) {
                      for (var notif in pending) {
                        _addToDebug('- ID ${notif.id}: ${notif.title}');
                      }
                    }

                    _addToDebug('🔍 === INVESTIGATION COMPLETE ===');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🔍 INVESTIGATE'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Checking pending notifications...');
                    final pending = await _notificationHelper.getPendingNotifications();
                    _addToDebug('Pending notifications: ${pending.length}');
                  },
                  child: const Text('Check Pending'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Scheduling daily reminder...');
                    await _notificationHelper.scheduleDailyReminder();
                    _addToDebug('Daily reminder scheduled');
                  },
                  child: const Text('Schedule Daily'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    _addToDebug('Cancelling all notifications...');
                    await _notificationHelper.cancelDailyReminder();
                    await _notificationHelper.cancelTestNotifications();
                    _addToDebug('All notifications cancelled');
                  },
                  child: const Text('Cancel All'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    _addToDebug('🔄 TIMER FALLBACK TEST +30 SECONDS...');
                    _addToDebug('Current time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}');
                    _addToDebug('Target time: ${now.add(Duration(seconds: 30)).hour.toString().padLeft(2, '0')}:${now.add(Duration(seconds: 30)).minute.toString().padLeft(2, '0')}:${now.add(Duration(seconds: 30)).second.toString().padLeft(2, '0')}');

                    final result = await _notificationHelper.testTimerFallback();
                    _addToDebug('Timer fallback result: $result');
                    _addToDebug('KEEP APP OPEN TO TEST TIMER!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('🔄 TIMER FALLBACK'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Debug output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? 'Debug output akan muncul di sini...' : _debugOutput,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _debugOutput = '';
                });
              },
              child: const Text('Clear Log'),
            ),
          ],
        ),
      ),
    );
  }
}
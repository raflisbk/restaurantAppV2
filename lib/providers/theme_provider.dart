import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isDailyReminderEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isDailyReminderEnabled => _isDailyReminderEnabled;
  TimeOfDay get notificationTime => _notificationTime;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  static const String _themeKey = 'isDarkMode';
  static const String _reminderKey = 'isDailyReminderEnabled';
  static const String _notificationTimeKey = 'notificationTime';

  ThemeProvider() {
    // Load preferences asynchronously, don't block constructor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThemePreferences();
    });
  }

  Future<void> _loadThemePreferences() async {
    try {
      _setLoading(true);
      _clearError();

      final prefs = await SharedPreferences.getInstance();

      // Explicitly check if keys exist to ensure proper defaults
      final bool? storedDarkMode = prefs.getBool(_themeKey);
      final bool? storedReminder = prefs.getBool(_reminderKey);
      final String? storedTime = prefs.getString(_notificationTimeKey);

      _isDarkMode = storedDarkMode ?? false;
      _isDailyReminderEnabled = storedReminder ?? false;

      // Parse stored time or use default 11:00
      if (storedTime != null) {
        final timeParts = storedTime.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 11;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          _notificationTime = TimeOfDay(hour: hour, minute: minute);
        }
      }

      // Always ensure default is 11:00 for consistency
      if (_notificationTime.hour != 11 || _notificationTime.minute != 0) {
        _notificationTime = const TimeOfDay(hour: 11, minute: 0);
        await _saveNotificationTimePreference();
        debugPrint('Notification time reset to default 11:00');
      }

      debugPrint(
        'Theme preferences loaded - Dark: $_isDarkMode, Reminder: $_isDailyReminderEnabled, Time: ${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}',
      );

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat preferensi tema: $e');
      _setError('Gagal memuat preferensi: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemePreference();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _saveThemePreference();
    notifyListeners();
  }

  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Gagal menyimpan preferensi tema: $e');
    }
  }

  Future<void> toggleDailyReminder() async {
    _isDailyReminderEnabled = !_isDailyReminderEnabled;
    await _saveReminderPreference();
    notifyListeners();
  }

  Future<bool> setDailyReminder(bool value) async {
    try {
      _isDailyReminderEnabled = value;
      final success = await _saveReminderPreference();

      if (success) {
        debugPrint('Daily reminder set to: $value');
        notifyListeners();
        return true;
      } else {
        // Revert on failure
        _isDailyReminderEnabled = !value;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert on exception
      _isDailyReminderEnabled = !value;
      debugPrint('Failed to set daily reminder: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> _saveReminderPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(
        _reminderKey,
        _isDailyReminderEnabled,
      );
      return success;
    } catch (e) {
      debugPrint('Gagal menyimpan preferensi pengingat: $e');
      return false;
    }
  }

  Future<bool> setNotificationTime(TimeOfDay time) async {
    try {
      _notificationTime = time;
      final success = await _saveNotificationTimePreference();

      if (success) {
        debugPrint(
          'Notification time set to: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        );
        notifyListeners();
        return true;
      } else {
        // Revert on failure
        _notificationTime = const TimeOfDay(hour: 11, minute: 0);
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Revert on exception
      _notificationTime = const TimeOfDay(hour: 11, minute: 0);
      debugPrint('Failed to set notification time: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> _saveNotificationTimePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString =
          '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}';
      final success = await prefs.setString(_notificationTimeKey, timeString);
      return success;
    } catch (e) {
      debugPrint('Gagal menyimpan waktu notifikasi: $e');
      return false;
    }
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = '';
  }

  // Method to reset preferences (useful for testing)
  Future<void> resetPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.remove(_reminderKey);
      await prefs.remove(_notificationTimeKey);

      _isDarkMode = false;
      _isDailyReminderEnabled = false;
      _notificationTime = const TimeOfDay(hour: 11, minute: 0);

      notifyListeners();
      debugPrint('Preferences reset to defaults');
    } catch (e) {
      debugPrint('Failed to reset preferences: $e');
    }
  }
}

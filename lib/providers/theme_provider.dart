import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isDailyReminderEnabled = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isDailyReminderEnabled => _isDailyReminderEnabled;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  static const String _themeKey = 'isDarkMode';
  static const String _reminderKey = 'isDailyReminderEnabled';

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

      _isDarkMode = storedDarkMode ?? false;
      _isDailyReminderEnabled = storedReminder ?? false;

      debugPrint('Theme preferences loaded - Dark: $_isDarkMode, Reminder: $_isDailyReminderEnabled');

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
      final success = await prefs.setBool(_reminderKey, _isDailyReminderEnabled);
      return success;
    } catch (e) {
      debugPrint('Gagal menyimpan preferensi pengingat: $e');
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

      _isDarkMode = false;
      _isDailyReminderEnabled = false;

      notifyListeners();
      debugPrint('Preferences reset to defaults');
    } catch (e) {
      debugPrint('Failed to reset preferences: $e');
    }
  }
}

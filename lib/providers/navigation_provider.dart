import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void navigateToHome() => setSelectedIndex(0);
  void navigateToSearch() => setSelectedIndex(1);
  void navigateToFavorites() => setSelectedIndex(2);
  void navigateToSettings() => setSelectedIndex(3);
}

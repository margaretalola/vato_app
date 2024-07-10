import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  int _selectedIndex = 1;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int newIndex) {
    _selectedIndex = newIndex;
    notifyListeners();
  }

  void resetSelection() {
    _selectedIndex = -1;
    notifyListeners();
  }
}

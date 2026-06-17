import 'package:flutter/foundation.dart';

/// Global theme notifier for app-wide theme changes
class ThemeProvider extends ChangeNotifier {
  bool get isDarkMode => true; // Force dark mode as per user request

  void toggleTheme() {
    // Theme is permanently dark as per user request
    notifyListeners();
  }
}

final themeProvider = ThemeProvider();

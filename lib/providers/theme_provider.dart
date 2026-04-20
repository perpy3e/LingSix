import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingsix/services/firestore_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _lastTestCountKey = 'last_synced_test_count';
  static const String _defaultTheme = 'default';
  static const List<String> _themeRotation = ['default', 'summer', 'winter'];
  
  String _currentTheme = _defaultTheme;
  int _lastSyncedTestCount = 0;
  final FirestoreService _firestoreService = FirestoreService();
  late SharedPreferences _prefs;
  
  String get currentTheme => _currentTheme;

  ThemeProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _currentTheme = _prefs.getString(_themeKey) ?? _defaultTheme;
    _lastSyncedTestCount = _prefs.getInt(_lastTestCountKey) ?? 0;
    notifyListeners();
  }

  /// Get wallpaper path for a given page and theme
  String getWallpaperPath(String pageType) {
    return 'assets/themes/$_currentTheme/bg/$pageType.png';
  }

  /// Auto-rotate to next theme when 10 tests completed
  Future<void> syncThemeStatusFromFirestore(String uid) async {
    try {
      final userDoc = await _firestoreService.getUserByUid(uid);
      if (userDoc == null) return;

      final summary = await _firestoreService.getDashboardSummary(uid);
      final testCount = summary['totalQuestions'] as int? ?? 0;
      
      // Check if test count increased by 10 (rotation milestone)
      if (testCount > _lastSyncedTestCount && testCount % 10 == 0) {
        _rotateTheme();
      }
      
      // Update last synced count
      _lastSyncedTestCount = testCount;
      await _prefs.setInt(_lastTestCountKey, testCount);

      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing theme status: $e');
    }
  }

  /// Rotate to next theme in the sequence
  void _rotateTheme() async {
    final currentIndex = _themeRotation.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % _themeRotation.length;
    _currentTheme = _themeRotation[nextIndex];
    
    await _prefs.setString(_themeKey, _currentTheme);
    notifyListeners();
  }

  /// Get current test progress (0-10, then repeats)
  int getTestProgressInCycle() {
    return _lastSyncedTestCount % 10;
  }

  /// Get next theme that will be unlocked
  String getNextTheme() {
    final currentIndex = _themeRotation.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % _themeRotation.length;
    return _themeRotation[nextIndex];
  }
}

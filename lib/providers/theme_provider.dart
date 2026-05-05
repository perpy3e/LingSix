import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingsix/services/firestore_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _lastTestCountKey = 'last_synced_test_count';
  static const String _selectedCharacterKey = 'selected_character';
  static const String _defaultTheme = 'default';
  static const String _defaultCharacter = 'dino';
  static const List<String> _themeRotation = ['default', 'summer', 'winter'];
  static const List<String> _availableCharacters = ['dino', 'rabbit', 'cat'];
  //change mapping
static const Map<String, Map<String, String>> _themeBackgroundAliases = {
  'summer': {
    'home': 'home',
    'lesson': 'quiz',
    'quiz': 'quiz',
  },
};
  
  String _currentTheme = _defaultTheme;
  int _lastSyncedTestCount = 0;
  String _selectedCharacter = _defaultCharacter;
  final FirestoreService _firestoreService = FirestoreService();
  late SharedPreferences _prefs;
  
  String get currentTheme => _currentTheme;
  String get selectedCharacter => _selectedCharacter;
  List<String> get availableCharacters => _availableCharacters;

  ThemeProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
   
    _currentTheme = _prefs.getString(_themeKey) ?? _defaultTheme;
    _lastSyncedTestCount = _prefs.getInt(_lastTestCountKey) ?? 0;
    _selectedCharacter = _prefs.getString(_selectedCharacterKey) ?? _defaultCharacter;
    notifyListeners();
  }

  /// Get wallpaper path for a given page and theme
  String getWallpaperPath(String pageType) {
    final mappedPageType =
        _themeBackgroundAliases[_currentTheme]?[pageType] ?? pageType;
    return 'assets/themes/$_currentTheme/bg/$mappedPageType.png';
  }

  String getCharacterHeadPath(String character) {
    return 'assets/themes/$_currentTheme/characters/$character/head.png';
  }

  String getCharacterBodyPath(String character) {
    return 'assets/themes/$_currentTheme/characters/$character/body.png';
  }

  String getDefaultCharacterHeadPath(String character) {
    return 'assets/themes/default/characters/$character/head.png';
  }

  String getDefaultCharacterBodyPath(String character) {
    return 'assets/themes/default/characters/$character/body.png';
  }

  Future<void> setSelectedCharacter(String character) async {
    if (!_availableCharacters.contains(character)) return;
    _selectedCharacter = character;
    await _prefs.setString(_selectedCharacterKey, character);
    notifyListeners();
  }

  // Change theme count 
  Future<void> syncThemeStatusFromFirestore(String uid) async {
    try {
      final userDoc = await _firestoreService.getUserByUid(uid);
      if (userDoc == null) return;

      final summary = await _firestoreService.getDashboardSummary(uid);
      //final testCount = summary['totalQuestions'] as int? ?? 0;
      final testCount = summary['totalQuizzes'] as int? ?? 0; //totalquizzes from dashboard 
       if (testCount == 0) {
  _currentTheme = _defaultTheme;
  _lastSyncedTestCount = 0;

  await _prefs.setString(_themeKey, _currentTheme);
  await _prefs.setInt(_lastTestCountKey, 0);

  notifyListeners();
  return;
}
      
 int newThemeIndex = (testCount ~/ 10); // 0,1,2,...

if (newThemeIndex >= _themeRotation.length) {
  newThemeIndex = _themeRotation.length - 1;
}

final newTheme = _themeRotation[newThemeIndex];

/*
if (_currentTheme != newTheme) {
  _currentTheme = newTheme;
  await _prefs.setString(_themeKey, _currentTheme);
}
      
      
      _lastSyncedTestCount = testCount;
      await _prefs.setInt(_lastTestCountKey, testCount);

      notifyListeners();
      */

      bool hasChanged = false;

if (_currentTheme != newTheme) {
  _currentTheme = newTheme;
  await _prefs.setString(_themeKey, _currentTheme);
  hasChanged = true;
}

if (_lastSyncedTestCount != testCount) {
  _lastSyncedTestCount = testCount;
  await _prefs.setInt(_lastTestCountKey, testCount);
  hasChanged = true;
}

if (hasChanged) {
  notifyListeners();
}
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

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../models/habit.dart';

class LocalStorageService {
  static const String _themeKey = 'themePreference';
  static const String _habitsKey = 'habitsData';
  static const String _historyKey = 'historyData';
  static const String _pendingSyncQueueKey = 'pendingSyncQueue';
  static const String _streakFreezeKey = 'streakFreezesAvailable';
  static const String _totalPerfectDaysKey = 'totalPerfectDays';
  static const String _totalHabitsCreatedKey = 'totalHabitsCreated';
  static const String _versionKey = 'localStorageVersion';
  static const int _currentVersion = 1;

  late SharedPreferences _prefs;
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateData();
  }

  Future<void> _migrateData() async {
    final int storedVersion = _prefs.getInt(_versionKey) ?? 0;
    if (storedVersion < _currentVersion) {
      // Add migration logic here if needed in the future
      // For now, just update the version
      await _prefs.setInt(_versionKey, _currentVersion);
    }
  }

  // Theme Preference
  Future<void> saveThemePreference(String themeName) async {
    await _prefs.setString(_themeKey, themeName);
  }

  String? getThemePreference() {
    return _prefs.getString(_themeKey);
  }

  // Habit Card Data
  Future<void> saveHabits(List<Habit> habits) async {
    final String jsonString = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await _prefs.setString(_habitsKey, jsonString);
  }

  List<Habit> getHabits() {
    final String? jsonString = _prefs.getString(_habitsKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Habit.fromJson(json)).toList();
  }

  // History Data
  Future<void> saveHistory(Map<String, dynamic> historyData) async {
    final String jsonString = jsonEncode(historyData);
    await _prefs.setString(_historyKey, jsonString);
  }

  Map<String, dynamic> getHistory() {
    final String? jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) {
      return {};
    }
    return jsonDecode(jsonString);
  }

  // Pending Sync Queue Data
  Future<void> savePendingSyncQueue(List<Map<String, dynamic>> queue) async {
    final String jsonString = jsonEncode(queue);
    await _prefs.setString(_pendingSyncQueueKey, jsonString);
  }

  List<Map<String, dynamic>> getPendingSyncQueue() {
    final String? jsonString = _prefs.getString(_pendingSyncQueueKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => json as Map<String, dynamic>).toList();
  }

  // Streak Freeze Data
  Future<void> saveStreakFreezesAvailable(int freezes) async {
    await _prefs.setInt(_streakFreezeKey, freezes);
  }

  int getStreakFreezesAvailable() {
    return _prefs.getInt(_streakFreezeKey) ?? 3; // Default to 3 freezes
  }

  // Total Perfect Days
  Future<void> saveTotalPerfectDays(int count) async {
    await _prefs.setInt(_totalPerfectDaysKey, count);
  }

  int getTotalPerfectDays() {
    return _prefs.getInt(_totalPerfectDaysKey) ?? 0;
  }

  // Total Habits Created
  Future<void> saveTotalHabitsCreated(int count) async {
    await _prefs.setInt(_totalHabitsCreatedKey, count);
  }

  int getTotalHabitsCreated() {
    return _prefs.getInt(_totalHabitsCreatedKey) ?? 0;
  }

}

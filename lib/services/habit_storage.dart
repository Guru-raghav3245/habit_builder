import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_builder/models/habit.dart';

class HabitStorage {
  static const String _key = 'daily_habits_list';

  // Load all habits from device storage
  static Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Habit.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Save all habits to device storage
  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
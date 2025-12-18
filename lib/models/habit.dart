import 'package:flutter/material.dart';

class Habit {
  final String id;
  String name;
  TimeOfDay startTime;
  int durationMinutes;
  bool reminderEnabled;
  List<DateTime> completedDates;

  // PERFORMANCE: Pre-calculated values to prevent UI jank during builds
  final int currentStreak;
  final int longestStreak;

  Habit({
    required this.id,
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    this.reminderEnabled = true,
    List<DateTime>? completedDates,
  })  : completedDates = completedDates ?? [],
        currentStreak = _calculateCurrentStreak(completedDates ?? []),
        longestStreak = _calculateLongestStreak(completedDates ?? []);

  bool get isCompletedToday {
    if (completedDates.isEmpty) return false;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    return completedDates.any((date) =>
        date.year == todayNormalized.year &&
        date.month == todayNormalized.month &&
        date.day == todayNormalized.day);
  }

  static int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final sortedDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime? expectedDate = DateTime.now();

    for (final date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final normalizedExpected = DateTime(expectedDate!.year, expectedDate.month, expectedDate.day);

      if (normalizedDate.isAtSameMomentAs(normalizedExpected)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (normalizedDate.isBefore(normalizedExpected.subtract(const Duration(days: 1)))) {
        break;
      }
    }

    return streak;
  }

  static int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final uniqueDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    int maxStreak = 1;
    int current = 1;

    for (int i = 1; i < uniqueDates.length; i++) {
      if (uniqueDates[i].difference(uniqueDates[i - 1]).inDays == 1) {
        current++;
        maxStreak = current > maxStreak ? current : maxStreak;
      } else {
        current = 1;
      }
    }

    return maxStreak;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'durationMinutes': durationMinutes,
      'reminderEnabled': reminderEnabled,
      'completedDates': completedDates
          .map((d) => d.toIso8601String().substring(0, 10))
          .toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final List<DateTime> dates = (json['completedDates'] as List<dynamic>? ?? [])
          .map((d) => DateTime.parse(d as String))
          .toList();

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: TimeOfDay(
        hour: json['startTimeHour'] as int,
        minute: json['startTimeMinute'] as int,
      ),
      durationMinutes: json['durationMinutes'] as int,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      completedDates: dates,
    );
  }

  Habit copyWith({
    String? name,
    TimeOfDay? startTime,
    int? durationMinutes,
    bool? reminderEnabled,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      completedDates: completedDates ?? this.completedDates,
    );
  }
}
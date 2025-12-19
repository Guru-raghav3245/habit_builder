import 'package:flutter/material.dart';

class Habit {
  final String id;
  String name;
  TimeOfDay startTime;
  int durationMinutes;
  bool reminderEnabled;
  bool focusModeEnabled;
  List<DateTime> completedDates;

  final int currentStreak;
  final int longestStreak;

  Habit({
    required this.id,
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    this.reminderEnabled = true,
    this.focusModeEnabled = false,
    List<DateTime>? completedDates,
  })  : completedDates = _filterFutureDates(completedDates ?? []),
        currentStreak = _calculateCurrentStreak(_filterFutureDates(completedDates ?? [])),
        longestStreak = _calculateLongestStreak(_filterFutureDates(completedDates ?? []));

  // NEW: Checks if the current time is within the habit's window
  bool get isActiveNow {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final todayEnd = todayStart.add(Duration(minutes: durationMinutes));
    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  static List<DateTime> _filterFutureDates(List<DateTime> dates) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return dates.where((date) => date.isBefore(todayEnd) || date.isAtSameMomentAs(todayEnd)).toList();
  }

  static int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sortedDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort((a, b) => b.compareTo(a));
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
    final uniqueDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();
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

  bool get isCompletedToday {
    if (completedDates.isEmpty) return false;
    final today = DateTime.now();
    return completedDates.any((date) =>
        date.year == today.year && date.month == today.month && date.day == today.day);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'durationMinutes': durationMinutes,
      'reminderEnabled': reminderEnabled,
      'focusModeEnabled': focusModeEnabled,
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
      focusModeEnabled: json['focusModeEnabled'] as bool? ?? false,
      completedDates: dates,
    );
  }

  Habit copyWith({
    String? name,
    TimeOfDay? startTime,
    int? durationMinutes,
    bool? reminderEnabled,
    bool? focusModeEnabled,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      completedDates: completedDates ?? this.completedDates,
    );
  }
}
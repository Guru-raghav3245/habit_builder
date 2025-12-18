import 'package:flutter/material.dart';

class Habit {
  final String id;                    // Unique identifier
  String name;                        // e.g., "Meditation"
  TimeOfDay startTime;                // e.g., 9:00 AM
  int durationMinutes;                // e.g., 20
  bool reminderEnabled;               // true = daily notification
  List<DateTime> completedDates;      // List of completed days (midnight normalized)

  Habit({
    required this.id,
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    this.reminderEnabled = true,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? [];

  // Helper: Check if completed today (using device local date)
  bool get isCompletedToday {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    return completedDates.any((date) =>
        date.year == todayNormalized.year &&
        date.month == todayNormalized.month &&
        date.day == todayNormalized.day);
  }

  // Helper: Calculate current streak
  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    int streak = 0;
    DateTime? expectedDate = DateTime.now();

    for (final date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final normalizedExpected = DateTime(expectedDate!.year, expectedDate.month, expectedDate.day);

      if (normalizedDate.isAtSameMomentAs(normalizedExpected)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (normalizedDate.isBefore(normalizedExpected.subtract(const Duration(days: 1)))) {
        break; // Gap found
      }
    }

    return streak;
  }

  // Helper: Calculate longest streak
  int get longestStreak {
    if (completedDates.isEmpty) return 0;

    final uniqueDates = completedDates
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

  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'durationMinutes': durationMinutes,
      'reminderEnabled': reminderEnabled,
      'completedDates': completedDates
          .map((d) => d.toIso8601String().substring(0, 10)) // Store as YYYY-MM-DD
          .toList(),
    };
  }

  // Create from JSON
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: TimeOfDay(
        hour: json['startTimeHour'] as int,
        minute: json['startTimeMinute'] as int,
      ),
      durationMinutes: json['durationMinutes'] as int,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      completedDates: (json['completedDates'] as List<dynamic>? ?? [])
          .map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }

  // For updating (creates a copy with new values)
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
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
    this.focusModeEnabled = true, 
    List<DateTime>? completedDates,
  })  : completedDates = _filterFutureDates(completedDates ?? []),
        currentStreak = _calculateCurrentStreak(_filterFutureDates(completedDates ?? [])),
        longestStreak = _calculateLongestStreak(_filterFutureDates(completedDates ?? []));

  // Detects if the habit is currently in its scheduled time window
  bool get isActiveNow {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final todayEnd = todayStart.add(Duration(minutes: durationMinutes));
    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((date) =>
        date.year == today.year && date.month == today.month && date.day == today.day);
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
      if (DateTime(date.year, date.month, date.day).isAtSameMomentAs(DateTime(expectedDate!.year, expectedDate.month, expectedDate.day))) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(expectedDate.subtract(const Duration(days: 1)))) {
        break;
      }
    }
    return streak;
  }

  static int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final uniqueDates = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()..sort();
    int maxS = 1, curr = 1;
    for (int i = 1; i < uniqueDates.length; i++) {
      if (uniqueDates[i].difference(uniqueDates[i - 1]).inDays == 1) {
        curr++;
        if (curr > maxS) maxS = curr;
      } else { curr = 1; }
    }
    return maxS;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'startTimeHour': startTime.hour, 'startTimeMinute': startTime.minute,
    'durationMinutes': durationMinutes, 'reminderEnabled': reminderEnabled,
    'focusModeEnabled': focusModeEnabled, 'completedDates': completedDates.map((d) => d.toIso8601String().substring(0, 10)).toList(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'], name: json['name'], startTime: TimeOfDay(hour: json['startTimeHour'], minute: json['startTimeMinute']),
    durationMinutes: json['durationMinutes'], reminderEnabled: json['reminderEnabled'] ?? true,
    focusModeEnabled: json['focusModeEnabled'] ?? true,
    completedDates: (json['completedDates'] as List).map((d) => DateTime.parse(d)).toList(),
  );

  Habit copyWith({String? name, TimeOfDay? startTime, int? durationMinutes, bool? reminderEnabled, bool? focusModeEnabled, List<DateTime>? completedDates}) => Habit(
    id: id, name: name ?? this.name, startTime: startTime ?? this.startTime, durationMinutes: durationMinutes ?? this.durationMinutes,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled, focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled, completedDates: completedDates ?? this.completedDates,
  );
}
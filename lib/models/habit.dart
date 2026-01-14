import 'package:flutter/material.dart';

class Habit {
  final String id;
  String name;
  TimeOfDay startTime;
  int durationMinutes;
  bool reminderEnabled;
  bool focusModeEnabled;
  final List<DateTime> completedDates;
  final Set<String> _completedDatesSet;
  final DateTime startDate;
  final int targetDays;

  Habit({
    required this.id,
    required this.name,
    required this.startTime,
    required this.durationMinutes,
    required this.startDate,
    required this.targetDays,
    this.reminderEnabled = true,
    this.focusModeEnabled = true,
    List<DateTime>? completedDates,
  }) : completedDates = _filterFutureDates(completedDates ?? []),
       _completedDatesSet = _filterFutureDates(
         completedDates ?? [],
       ).map((d) => "${d.year}-${d.month}-${d.day}").toSet();

  bool get hasWindowPassedToday {
    final now = DateTime.now();
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    ).add(Duration(minutes: durationMinutes));

    return now.isAfter(endTime);
  }

  bool get isActiveNow {
    final now = DateTime.now();
    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    final todayEnd = todayStart.add(Duration(minutes: durationMinutes));
    return now.isAfter(todayStart) && now.isBefore(todayEnd);
  }

  bool isCompletedOn(DateTime date) {
    return _completedDatesSet.contains(
      "${date.year}-${date.month}-${date.day}",
    );
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  double get completionPercentage {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final daysElapsedTotal = today.difference(start).inDays + 1;
    if (daysElapsedTotal <= 0) return 0.0;
    final percentage = completedDates.length / daysElapsedTotal;
    return percentage > 1.0 ? 1.0 : percentage;
  }

  int get daysElapsed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = today.difference(start).inDays + 1;
    return diff < 0 ? 0 : diff;
  }

  bool get isArchived {
    final endDate = startDate.add(Duration(days: targetDays));
    return DateTime.now().isAfter(endDate);
  }

  static List<DateTime> _filterFutureDates(List<DateTime> dates) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return dates
        .where(
          (date) => date.isBefore(todayEnd) || date.isAtSameMomentAs(todayEnd),
        )
        .toList();
  }

  int get currentStreak => _calculateCurrentStreak(completedDates);
  int get longestStreak => _calculateLongestStreak(completedDates);

  static int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sorted =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime expected = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // If not completed today, check if it was completed yesterday to keep streak alive
    if (!sorted.any((d) => d.isAtSameMomentAs(expected))) {
      expected = expected.subtract(const Duration(days: 1));
    }

    for (final date in sorted) {
      if (date.isAtSameMomentAs(expected)) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (date.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  static int _calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final unique =
        dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
          ..sort();
    int maxS = 1, curr = 1;
    for (int i = 1; i < unique.length; i++) {
      if (unique[i].difference(unique[i - 1]).inDays == 1) {
        curr++;
        if (curr > maxS) maxS = curr;
      } else {
        curr = 1;
      }
    }
    return maxS;
  }

  Map<String, dynamic> toJson() => {
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
    'startDate': startDate.toIso8601String(),
    'targetDays': targetDays,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    startTime: TimeOfDay(
      hour: json['startTimeHour'],
      minute: json['startTimeMinute'],
    ),
    durationMinutes: json['durationMinutes'],
    reminderEnabled: json['reminderEnabled'] ?? true,
    focusModeEnabled: json['focusModeEnabled'] ?? true,
    completedDates: (json['completedDates'] as List)
        .map((d) => DateTime.parse(d))
        .toList(),
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'])
        : DateTime.now(),
    targetDays: json['targetDays'] ?? 30,
  );

  Habit copyWith({
    String? name,
    TimeOfDay? startTime,
    int? durationMinutes,
    List<DateTime>? completedDates,
    int? targetDays,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    startTime: startTime ?? this.startTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    completedDates: completedDates ?? this.completedDates,
    startDate: this.startDate,
    targetDays: targetDays ?? this.targetDays,
  );
}

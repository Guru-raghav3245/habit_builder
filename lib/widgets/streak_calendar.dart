import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:habit_builder/models/habit.dart';

class StreakCalendar extends StatelessWidget {
  final Habit habit;

  const StreakCalendar({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    // Convert completedDates to Map<DateTime, int> for the heatmap
    final Map<DateTime, int> datasets = {};
    for (final date in habit.completedDates) {
      final normalized = DateTime(date.year, date.month, date.day);
      datasets[normalized] = 1; // Any positive value = filled
    }

    return HeatMapCalendar(
      datasets: datasets,
      colorsets: const {
        1: Colors.green,
      },
      defaultColor: Colors.grey[200],
      textColor: Colors.black87,
      showColorTip: false,
      borderRadius: 12,
      size: 40,
      fontSize: 14,
      margin: const EdgeInsets.all(4),
      weekTextColor: Colors.deepPurple,
      monthFontSize: 18,
    );
  }
}
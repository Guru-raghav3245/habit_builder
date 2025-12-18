import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:habit_builder/models/habit.dart';

class StreakCalendar extends StatelessWidget {
  final Habit habit;

  const StreakCalendar({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    // Convert completed dates to dataset
    final Map<DateTime, int> datasets = {};
    for (final date in habit.completedDates) {
      final normalized = DateTime(date.year, date.month, date.day);
      datasets[normalized] = 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      child: HeatMapCalendar(
        datasets: datasets,
        colorsets: const {
          1: Colors.green,
        },
        defaultColor: Colors.grey[300],
        textColor: Colors.black87,
        showColorTip: false,
        size: 36,         // Reduced slightly to help fit more screens
        fontSize: 12,
        margin: const EdgeInsets.all(3),
        borderRadius: 8,
        weekTextColor: Colors.deepPurple,
        monthFontSize: 16,
      ),
    );
  }
}
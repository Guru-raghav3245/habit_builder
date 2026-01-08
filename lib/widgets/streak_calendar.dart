import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:habit_builder/models/habit.dart';

class StreakCalendar extends StatelessWidget {
  final Habit habit;

  const StreakCalendar({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define date boundaries
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
    final end = start.add(Duration(days: habit.targetDays - 1));

    final Map<DateTime, int> datasets = {};

    // 1. Mark the entire range from start to today as "Skipped" (Value: 1)
    // This provides a base layer for days that passed but weren't finished.
    for (int i = 0; i <= today.difference(start).inDays; i++) {
      final date = start.add(Duration(days: i));
      if (date.isBefore(today) || date.isAtSameMomentAs(today)) {
        datasets[date] = 1; 
      }
    }

    // 2. Mark completed dates (Value: 2)
    for (final date in habit.completedDates) {
      final normalized = DateTime(date.year, date.month, date.day);
      datasets[normalized] = 2;
    }

    // 3. Explicitly mark Start and End dates with high values for distinct colors (Values: 3, 4)
    datasets[start] = 3;
    datasets[end] = 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: HeatMapCalendar(
            datasets: datasets,
            colorsets: {
              1: Colors.redAccent.withOpacity(0.2), // Skipped/Missed
              2: Colors.green,                      // Completed
              3: colorScheme.primary,               // Start Date
              4: colorScheme.secondary,             // End Date (Target)
            },
            defaultColor: colorScheme.surfaceVariant.withOpacity(0.3),
            textColor: colorScheme.onSurface,
            weekTextColor: colorScheme.onSurfaceVariant, // Fixed the purple issue
            monthFontSize: 18,
            borderRadius: 6,
            size: 38,
            showColorTip: false,
          ),
        ),
        const SizedBox(height: 16),
        // Legend for clarity
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLegendItem('Start', colorScheme.primary),
            _buildLegendItem('End Goal', colorScheme.secondary),
            _buildLegendItem('Completed', Colors.green),
            _buildLegendItem('Skipped', Colors.redAccent.withOpacity(0.4)),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
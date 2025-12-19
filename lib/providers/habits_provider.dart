import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/services/habit_storage.dart';
import 'package:habit_builder/services/notification_service.dart';

final habitsProvider = StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  return HabitsNotifier();
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  // Helper to sort habits by time
  void _sortAndSetState(List<Habit> habits) {
    habits.sort((a, b) {
      if (a.startTime.hour != b.startTime.hour) {
        return a.startTime.hour.compareTo(b.startTime.hour);
      }
      return a.startTime.minute.compareTo(b.startTime.minute);
    });
    state = AsyncValue.data(habits);
  }

  Future<void> loadHabits() async {
    try {
      final habits = await HabitStorage.loadHabits();
      _sortAndSetState(habits);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleDoneToday(String habitId) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = currentHabits[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<DateTime> updatedDates = List.from(habit.completedDates);
    
    if (habit.isCompletedToday) {
      updatedDates.removeWhere((d) => d.year == today.year && d.month == today.month && d.day == today.day);
    } else {
      updatedDates.add(today);
    }

    final updatedHabit = habit.copyWith(completedDates: updatedDates);
    final updatedList = [...currentHabits]..[index] = updatedHabit;
    
    await HabitStorage.saveHabits(updatedList);
    _sortAndSetState(updatedList);
  }

  Future<void> addHabit({
    required String name,
    required TimeOfDay startTime,
    required int durationMinutes,
    bool reminderEnabled = true,
  }) async {
    final currentHabits = state.value ?? [];
    final newHabit = Habit(
      id: const Uuid().v4(),
      name: name,
      startTime: startTime,
      durationMinutes: durationMinutes,
      reminderEnabled: reminderEnabled,
    );
    final updatedList = [...currentHabits, newHabit];
    await HabitStorage.saveHabits(updatedList);
    _sortAndSetState(updatedList);
    if (reminderEnabled) await NotificationService.scheduleDailyReminder(newHabit, updatedList.length - 1);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index == -1) return;
    
    final updatedList = [...currentHabits]..[index] = updatedHabit;
    await HabitStorage.saveHabits(updatedList);
    _sortAndSetState(updatedList);
    await NotificationService.scheduleDailyReminder(updatedHabit, index);
  }

  Future<void> deleteHabit(String habitId) async {
    final currentHabits = state.value ?? [];
    final updatedList = currentHabits.where((h) => h.id != habitId).toList();
    await HabitStorage.saveHabits(updatedList);
    _sortAndSetState(updatedList);
  }
}
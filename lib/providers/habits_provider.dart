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

  Future<void> loadHabits() async {
    try {
      final habits = await HabitStorage.loadHabits();
      state = AsyncValue.data(habits);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // REVERSIBLE STATUS: Toggles the entry for today on or off
  Future<void> toggleDoneToday(String habitId) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = currentHabits[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<DateTime> updatedDates = List.from(habit.completedDates);
    
    if (habit.isCompletedToday) {
      // Remove today's entry (Undo)
      updatedDates.removeWhere((d) => d.year == today.year && d.month == today.month && d.day == today.day);
    } else {
      // Add today's entry
      updatedDates.add(today);
    }

    final updatedHabit = habit.copyWith(completedDates: updatedDates);
    final updatedHabits = [...currentHabits]..[index] = updatedHabit;
    
    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
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
    final updatedHabits = [...currentHabits, newHabit];
    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
    if (reminderEnabled) await NotificationService.scheduleDailyReminder(newHabit, currentHabits.length);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index == -1) return;
    final updatedHabits = [...currentHabits]..[index] = updatedHabit;
    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
    await NotificationService.scheduleDailyReminder(updatedHabit, index);
  }

  Future<void> deleteHabit(String habitId) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == habitId);
    final updatedHabits = currentHabits.where((h) => h.id != habitId).toList();
    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
    if (index != -1) await NotificationService.cancelReminder(index);
  }
}
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/services/habit_storage.dart';

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>((ref) {
  return HabitsNotifier();
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final habits = await HabitStorage.loadHabits();
      state = AsyncValue.data(habits);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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

    // Notifications will be scheduled in Phase 6
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == updatedHabit.id);
    if (index == -1) return;

    final updatedHabits = [...currentHabits]..[index] = updatedHabit;

    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
  }

  Future<void> deleteHabit(String habitId) async {
    final currentHabits = state.value ?? [];
    final updatedHabits = currentHabits.where((h) => h.id != habitId).toList();

    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
  }

  Future<void> markDoneToday(String habitId) async {
    final currentHabits = state.value ?? [];
    final index = currentHabits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = currentHabits[index];

    if (habit.isCompletedToday) return; // Already done today

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final updatedHabit = habit.copyWith(
      completedDates: [...habit.completedDates, today],
    );

    final updatedHabits = [...currentHabits]..[index] = updatedHabit;

    state = AsyncValue.data(updatedHabits);
    await HabitStorage.saveHabits(updatedHabits);
  }
}
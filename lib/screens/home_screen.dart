import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Detect system time/date changes
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // REFRESH LOGIC: Automatically reloads habits when returning from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(habitsProvider.notifier).loadHabits();
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.deepPurple,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('My Daily Habits', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.deepPurple, Colors.deepPurple.shade800],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.auto_graph_rounded, size: 80, color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ];
        },
        body: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (habits) {
            if (habits.isEmpty) return _buildEmptyState(context);

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isDoneToday = habit.isCompletedToday;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RepaintBoundary(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailScreen(habit: habit)),
                      ),
                      borderRadius: BorderRadius.circular(24),
                      child: Card(
                        elevation: isDoneToday ? 1 : 4,
                        color: isDoneToday ? Colors.green.shade50 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: isDoneToday ? BorderSide(color: Colors.green.shade200, width: 2) : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDoneToday ? Colors.green.shade100 : Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      isDoneToday ? Icons.check_circle : Icons.timer_outlined,
                                      color: isDoneToday ? Colors.green.shade700 : Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(habit.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('${_formatTime(habit.startTime)} • ${habit.durationMinutes}m', 
                                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  if (habit.currentStreak > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.whatshot, size: 16, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text('${habit.currentStreak}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  // UNDO FEATURE: Toggles status instead of only setting it to "Done"
                                  onPressed: () {
                                    ref.read(habitsProvider.notifier).toggleDoneToday(habit.id);
                                    if (!isDoneToday) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Great! Streak updated 🔥'),
                                          backgroundColor: Colors.green.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDoneToday ? Colors.green.shade600 : Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(isDoneToday ? 'Completed ✓ (Tap to Undo)' : 'Mark as Done'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditHabitScreen())),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(child: Text('No habits yet. Tap + to begin.'));
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.deepPurple,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'My Daily Habits',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
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
                    child: Icon(
                      Icons.auto_graph_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
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
            if (habits.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final streak = habit.currentStreak;
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
                        shadowColor: Colors.deepPurple.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: isDoneToday 
                              ? BorderSide(color: Colors.green.shade200, width: 2)
                              : BorderSide.none,
                        ),
                        color: isDoneToday ? Colors.green.shade50 : Colors.white,
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
                                        Text(
                                          habit.name,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_formatTime(habit.startTime)} • ${habit.durationMinutes}m',
                                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (streak > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.whatshot, size: 16, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text('$streak', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isDoneToday ? null : () {
                                    ref.read(habitsProvider.notifier).markDoneToday(habit.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDoneToday ? Colors.green.shade600 : Colors.deepPurple,
                                    disabledBackgroundColor: Colors.green.shade400,
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    isDoneToday ? 'Completed for Today' : 'Mark as Done',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
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
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditHabitScreen()));
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, size: 24),
        label: const Text('Add Habit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_graph_rounded, size: 80, color: Colors.deepPurple.shade200),
            ),
            const SizedBox(height: 32),
            const Text(
              'No habits yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your journey to a better you starts with a single habit. Tap the button below to begin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
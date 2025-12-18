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
      appBar: AppBar(
        title: const Text('My Daily Habits'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt_outlined, size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 32),
                    Text('No habits yet', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 16),
                    Text('Build unbreakable streaks.\nStart by adding your first daily habit.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              final streak = habit.currentStreak;
              final isDoneToday = habit.isCompletedToday;

              return GestureDetector(
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailScreen(habit: habit),
    ),
  );
},
                child: Card(
                  elevation: isDoneToday ? 2 : 6,
                  color: isDoneToday ? Colors.green.shade50 : Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: isDoneToday ? BorderSide(color: Colors.green.shade300, width: 2) : BorderSide.none,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(habit.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete habit?'),
                                    content: Text('Are you sure you want to delete "${habit.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () {
                                          ref.read(habitsProvider.notifier).deleteHabit(habit.id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(Icons.access_time, _formatTime(habit.startTime)),
                            const SizedBox(width: 12),
                            _buildInfoChip(Icons.timer, '${habit.durationMinutes} min'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.whatshot_outlined, size: 36, color: streak > 0 ? Colors.orangeAccent : Colors.grey[400]),
                            const SizedBox(width: 10),
                            Text(
                              streak == 0 ? 'Start your streak today' : 'Current streak: $streak day${streak == 1 ? "" : "s"}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: streak > 0 ? Colors.orange[800] : Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isDoneToday ? null : () {
                              ref.read(habitsProvider.notifier).markDoneToday(habit.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(children: const [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 12), Text('Great! Streak updated 🔥', style: TextStyle(fontSize: 16))]),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDoneToday ? Colors.green.shade600 : Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: isDoneToday ? 0 : 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isDoneToday ? Icons.check_circle : Icons.check_circle_outline, size: 28),
                                const SizedBox(width: 12),
                                Text(isDoneToday ? 'Done for today ✓' : 'Mark Done Today', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditHabitScreen()));
        },
        backgroundColor: Colors.deepPurple,
        tooltip: 'Add new habit',
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
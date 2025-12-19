import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/detail_screen.dart';
import 'package:habit_builder/screens/focus_timer_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(habitsProvider.notifier).loadHabits();
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
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
                title: const Text(
                  'My Daily Habits',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
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
                    color: isDoneToday ? Colors.green.shade50 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isDoneToday
                          ? BorderSide(color: Colors.green.shade300, width: 2)
                          : BorderSide.none,
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
                                child: Text(
                                  habit.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete habit?'),
                                      content: Text(
                                        'Are you sure you want to delete "${habit.name}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ref
                                                .read(habitsProvider.notifier)
                                                .deleteHabit(habit.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
                              _buildInfoChip(
                                Icons.access_time,
                                _formatTime(habit.startTime),
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                Icons.timer,
                                '${habit.durationMinutes} min',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.whatshot_outlined,
                                size: 36,
                                color: habit.currentStreak > 0
                                    ? Colors.orangeAccent
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                habit.currentStreak == 0
                                    ? 'Start your streak today'
                                    : 'Current streak: ${habit.currentStreak} day${habit.currentStreak == 1 ? "" : "s"}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: habit.currentStreak > 0
                                      ? Colors.orange[800]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                          if (habit.focusModeEnabled) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final startTime = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    habit.startTime.hour,
                                    habit.startTime.minute,
                                  );
                                  final endTime = startTime.add(Duration(minutes: habit.durationMinutes));

                                  int remainingSeconds;
                                  if (now.isBefore(startTime)) {
                                    // Start early? Give full duration.
                                    remainingSeconds = habit.durationMinutes * 60;
                                  } else if (now.isAfter(endTime)) {
                                    // Already passed.
                                    remainingSeconds = 0;
                                  } else {
                                    // Currently in progress (e.g., 1:43 PM for 1:41 PM start).
                                    remainingSeconds = endTime.difference(now).inSeconds;
                                  }

                                  if (remainingSeconds <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Focus window for this habit has already passed.')),
                                    );
                                    return;
                                  }

                                  final remaining = await Navigator.push<int>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FocusTimerScreen(
                                        habit: habit,
                                        initialSeconds: remainingSeconds,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  );

                                  if (remaining != null && remaining > 0 && mounted) {
                                    final resume = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Resume Focus Session?'),
                                        content: Text(
                                          'You have ${remaining ~/ 60} minute${remaining ~/ 60 == 1 ? "" : "s"} left. Continue?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (resume == true) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FocusTimerScreen(
                                            habit: habit,
                                            initialSeconds: remaining,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.lock_clock),
                                label: const Text(
                                  'Start Focus Session',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Colors.deepPurple,
                                    width: 2,
                                  ),
                                  foregroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(habitsProvider.notifier)
                                    .toggleDoneToday(habit.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          habit.isCompletedToday
                                              ? Icons.undo
                                              : Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          habit.isCompletedToday
                                              ? 'Marked as not done today'
                                              : 'Great! Streak updated 🔥',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: habit.isCompletedToday
                                        ? Colors.orange.shade600
                                        : Colors.green.shade600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                habit.isCompletedToday
                                    ? Icons.undo_rounded
                                    : Icons.check_circle_outline,
                                size: 28,
                              ),
                              label: Text(
                                habit.isCompletedToday
                                    ? 'Undo Completion'
                                    : 'Mark as Done',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: habit.isCompletedToday
                                    ? Colors.orange.shade600
                                    : Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        ),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Habit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
              child: Icon(
                Icons.auto_graph_rounded,
                size: 80,
                color: Colors.deepPurple.shade200,
              ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
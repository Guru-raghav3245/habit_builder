import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/detail_screen.dart';
import 'package:habit_builder/screens/focus_timer_screen.dart';
import 'package:habit_builder/models/habit.dart';

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
            if (habits.isEmpty) return _buildEmptyState(context);

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isDoneToday = habit.isCompletedToday;
                final isActive = habit.isActiveNow;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(habit: habit),
                        ),
                      );
                    },
                    child: Card(
                      elevation: isActive ? 12 : (isDoneToday ? 2 : 6),
                      color: isActive
                          ? Colors.deepPurple.shade50
                          : (isDoneToday ? Colors.green.shade50 : Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: isActive
                            ? const BorderSide(color: Colors.deepPurple, width: 2)
                            : (isDoneToday
                                ? BorderSide(
                                    color: Colors.green.shade300,
                                    width: 2,
                                  )
                                : BorderSide.none),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Hero(
                                    tag: 'habit_name_${habit.id}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        habit.name,
                                        style: Theme.of(context).textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    _showDeleteDialog(context, habit);
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
                            _buildStreakRow(habit),
                            if (isActive && !isDoneToday) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FocusTimerScreen(habit: habit),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.bolt_rounded),
                                  label: const Text(
                                    'ENTER FOCUS SESSION',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
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
                            const SizedBox(height: 16),
                            _buildMarkDoneButton(context, habit),
                          ],
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
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showDeleteDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
  }

  Widget _buildStreakRow(Habit habit) {
    return Row(
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
    );
  }

  Widget _buildMarkDoneButton(BuildContext context, Habit habit) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(habitsProvider.notifier).toggleDoneToday(habit.id);
        },
        icon: Icon(
          habit.isCompletedToday
              ? Icons.undo_rounded
              : Icons.check_circle_outline,
          size: 28,
        ),
        label: Text(
          habit.isCompletedToday ? 'Undo Completion' : 'Mark as Done',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: habit.isCompletedToday
              ? Colors.orange.shade600
              : Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        );
      },
      backgroundColor: Colors.deepPurple,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Add Habit',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
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
              'Your journey to a better you starts here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
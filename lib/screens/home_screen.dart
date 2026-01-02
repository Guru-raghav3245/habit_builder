import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/detail_screen.dart';
import 'package:habit_builder/screens/focus_timer_screen.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/widgets/mini_streak_grid.dart';

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
                ),
              ),
            ),
          ];
        },
        body: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (habits) {
            if (habits.isEmpty) return _buildEmptyState();

            final activeHabits = habits.where((h) => !h.isArchived).toList();
            final archivedHabits = habits.where((h) => h.isArchived).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (activeHabits.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'ACTIVE CHALLENGES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ...activeHabits.map((h) => _buildHabitCard(context, h)),
                ],
                if (archivedHabits.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 8),
                    child: Text(
                      'COMPLETED JOURNEYS 🏆',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ...archivedHabits.map(
                    (h) => _buildHabitCard(context, h, isArchived: true),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    Habit habit, {
    bool isArchived = false,
  }) {
    final isDoneToday = habit.isCompletedToday;
    final isActive = habit.isActiveNow && !isArchived;

    if (isArchived) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          dense: true,
          title: Text(
            habit.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          trailing: const Icon(Icons.stars, color: Colors.green, size: 20),
          subtitle: const Text('Goal Reached!'),
        ),
      );
    }

    return Card(
      elevation: isActive ? 8 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white, // Static white background as requested
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isActive
            ? const BorderSide(color: Colors.deepPurple, width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(habit: habit)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ROW 1: Name, Status Indicator, and Delete ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isDoneToday)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                  Expanded(
                    child: Hero(
                      tag: 'habit_name_${habit.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDoneToday ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    isDoneToday ? Icons.task_alt : Icons.access_time,
                    _formatTime(habit.startTime),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () => _showDeleteDialog(context, habit),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // --- ROW 2: Compact Progress Bar ---
              _buildCompactProgress(habit),

              const SizedBox(height: 12),

              // --- ROW 3: Journey Grid (Functionality Intact) ---
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MiniStreakGrid(habit: habit), //
              ),

              const SizedBox(height: 12),

              // --- ROW 4: Action Buttons and Streak ---
              Row(
                children: [
                  Icon(
                    Icons.whatshot,
                    size: 16,
                    color: habit.currentStreak > 0
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${habit.currentStreak}d streak',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: habit.currentStreak > 0
                          ? Colors.orange.shade900
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (isActive && !isDoneToday)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FocusTimerScreen(habit: habit), //
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('FOCUS'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(habitsProvider.notifier)
                            .toggleDoneToday(habit.id); //
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDoneToday
                            ? Colors.orange
                            : Colors.deepPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        isDoneToday ? 'UNDO' : 'DONE',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactProgress(Habit habit) {
    final percentage = habit.completionPercentage; //
    final displayPercent = (percentage * 100).toInt();
    final misses = habit.missDaysCount; //

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$displayPercent%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${habit.targetDays} day challenge',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (misses > 0)
              Text(
                '$misses missed',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
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

  Widget _buildInfoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );

  Widget _buildFab(BuildContext context) => FloatingActionButton.extended(
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
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_graph_rounded, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'No habits yet. Start your journey!',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

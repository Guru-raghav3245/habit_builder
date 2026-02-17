import 'package:flutter/material.dart';
import 'package:habitit/models/habit.dart';
import 'package:habitit/screens/add_edit_habit_screen.dart';
import 'package:habitit/screens/progress_screen.dart';

class DetailScreen extends StatefulWidget {
  final Habit habit;
  const DetailScreen({super.key, required this.habit});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight:
                  kToolbarHeight,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                widget.habit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            AddEditHabitScreen(habitToEdit: widget.habit, isEmbedded: true),
            ProgressScreen(habit: widget.habit),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Progress'),
            ],
          ),
        ),
      ),
    );
  }
}

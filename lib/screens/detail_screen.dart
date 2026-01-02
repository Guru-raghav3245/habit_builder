import 'package:flutter/material.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/progress_screen.dart';

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
              expandedHeight: 150.0,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.habit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
                    Tab(icon: Icon(Icons.insights_rounded), text: 'Progress'),
                  ],
                ),
                theme.colorScheme.surface,
              ),
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
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.bgColor);
  final TabBar _tabBar;
  final Color bgColor;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: bgColor, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

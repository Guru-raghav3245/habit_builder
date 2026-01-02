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
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150.0,
              pinned: true,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: innerBoxIsScrolled ? 4 : 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Hero(
                  tag: 'habit_name_${widget.habit.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      widget.habit.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                centerTitle: true,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.deepPurple,
                  indicatorWeight: 3,
                  // Smoothly animate to tab on click
                  onTap: (index) => _tabController.animateTo(index),
                  tabs: const [
                    Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
                    Tab(icon: Icon(Icons.insights_rounded), text: 'Progress'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(), // Makes swiping feel organic
          children: [
            _KeepAliveWrapper(
              child: AddEditHabitScreen(
                habitToEdit: widget.habit,
                isEmbedded: true,
              ),
            ),
            _KeepAliveWrapper(child: ProgressScreen(habit: widget.habit)),
          ],
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});
  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: Colors.white, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

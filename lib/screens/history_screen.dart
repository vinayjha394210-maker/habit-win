import 'package:flutter/material.dart';
import 'package:habit_win/widgets/history_tab_content.dart';
import 'package:habit_win/widgets/badges_tab_content.dart';
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon

class HistoryScreen extends StatefulWidget {
  final DateTime selectedDate;

  const HistoryScreen({super.key, required this.selectedDate});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withAlpha(179),
          labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: textTheme.titleSmall,
          tabs: <Widget>[
            Tab(
              icon: CustomIcon.material(Icons.analytics).toWidget(size: 20, defaultColor: _tabController.index == 0 ? colorScheme.onPrimary : colorScheme.onPrimary.withAlpha(179)),
              text: 'Stats',
            ),
            Tab(
              icon: CustomIcon.material(Icons.military_tech).toWidget(size: 20, defaultColor: _tabController.index == 1 ? colorScheme.onPrimary : colorScheme.onPrimary.withAlpha(179)),
              text: 'Badges',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const HistoryTabContent(),
          const BadgesTabContent(),
        ],
      ),
    );
  }
}

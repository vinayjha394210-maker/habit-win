import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:habit_win/screens/habit_list_screen.dart';
import 'package:habit_win/screens/history_screen.dart';
import 'package:habit_win/screens/settings_screen.dart';
import 'package:habit_win/models/habit.dart'; // Import TimeOfDayType
import 'package:habit_win/screens/add_habit_screen.dart'; // Import AddHabitScreen
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:habit_win/widgets/home_app_bar_content.dart'; // Import HomeAppBarContent
import 'package:habit_win/utils/date_utils.dart' as my_date_utils; // Import DateUtils with prefix
import 'package:provider/provider.dart'; // Import provider
import 'package:habit_win/services/habit_service.dart'; // Import HabitService
import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon
import 'package:habit_win/widgets/top_gradient_background.dart'; // Import TopGradientBackground

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _mainSelectedIndex = 0; // For bottom navigation bar (Habits, History, Settings)
  TimeOfDayType _selectedTimeOfDayFilter = TimeOfDayType.all; // For habit filtering
  DateTime _selectedDate = my_date_utils.DateUtils.startOfDay; // Track the selected date, normalized to start of day
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late AnimationController _lottieAnimationController; // New controller for Lottie animation

  final Debouncer _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _selectedDate = my_date_utils.DateUtils.normalizeDateTime(DateTime.now());
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.bounceIn,
      ),
    );
    _lottieAnimationController = AnimationController( // Initialize Lottie controller
      vsync: this,
      duration: const Duration(seconds: 3), // Adjust duration as needed
    )..repeat(); // Make it loop continuously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStreakFreezeUsage();
      context.read<HabitService>().addListener(_checkStreakFreezeUsage);
      if (_mainSelectedIndex == 0) {
        _fabAnimationController.forward();
      }
      _rescheduleAllHabitReminders(); // Call to reschedule notifications on app start
    });
  }

  Future<void> _rescheduleAllHabitReminders() async {
    final habitService = context.read<HabitService>();
    final notificationService = habitService.notificationService;
    await habitService.loadHabits(); // Ensure habits are loaded
    for (final habit in habitService.habits) {
      await notificationService.scheduleHabitReminders(habit);
    }
  }

  @override
  void dispose() {
    context.read<HabitService>().removeListener(_checkStreakFreezeUsage);
    _debouncer.dispose();
    _fabAnimationController.dispose();
    _lottieAnimationController.dispose(); // Dispose Lottie controller
    super.dispose();
  }

  void _checkStreakFreezeUsage() {
    final habitService = context.read<HabitService>();
    for (final habit in habitService.habits) {
      if (habit.lastFreezeDate != null) {
        final daysSinceLastFreeze = DateTime.now().difference(habit.lastFreezeDate!).inDays;
        if (daysSinceLastFreeze >= 0 && daysSinceLastFreeze <= 1) {
          _showStreakFreezePopup();
          // Reset lastFreezeDate to avoid showing the popup again for the same freeze
          habit.lastFreezeDate = null;
          habitService.updateHabit(habit);
          break;
        }
      }
    }
  }

  void _showStreakFreezePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return FadeTransition( // Added FadeTransition for smoother appearance
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOut,
            ),
          ),
          child: AlertDialog(
            title: const Text('Streak Freeze Used'),
            content: const Text('Your streak is protected by a Streak Freeze!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  // List of screens for the main bottom navigation
  // Using a getter to ensure the list is only created when accessed,
  // and the HabitListScreen is recreated with new keys when date/filter changes.
  List<Widget> _mainWidgetOptions(TimeOfDayType filter, DateTime selectedDate) {
    return <Widget>[
      HabitListScreen(
        key: ValueKey('$filter-$selectedDate'), // Unique key for each combination of filter and date
        timeOfDayFilter: filter,
        selectedDate: selectedDate,
      ),
      HistoryScreen(
        key: ValueKey('HistoryScreen-$selectedDate'), // Key for HistoryScreen
        selectedDate: selectedDate,
      ),
      const SettingsScreen(key: ValueKey('SettingsScreen')), // Key for SettingsScreen
    ];
  }

  void _onMainItemTapped(int index) {
    setState(() {
      _mainSelectedIndex = index;
      if (_mainSelectedIndex == 0) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _onTimeOfDayFilterTapped(TimeOfDayType filter) {
    setState(() {
      _selectedTimeOfDayFilter = filter;
      // Restart Lottie animation if visible
      if (_mainSelectedIndex == 0 && context.read<HabitService>().habits.isEmpty) {
        _lottieAnimationController.reset();
        _lottieAnimationController.forward();
      }
    });
  }

  // This method will be called to update the selected date, e.g., from a calendar widget
  void _onDateSelected(DateTime newDate) {
    setState(() {
      _selectedDate = my_date_utils.DateUtils.normalizeDateTime(newDate);
      // Restart Lottie animation if visible
      if (_mainSelectedIndex == 0 && context.read<HabitService>().habits.isEmpty) {
        _lottieAnimationController.reset();
        _lottieAnimationController.forward();
      }
    });
  }

  // No longer needed as TableCalendar handles month/week changes internally via onPageChanged
  // void _onMonthChanged(DateTime newMonth) {
  //   debugPrint('Month changed to: ${DateFormat.yMMMM().format(newMonth)}');
  // }

  // void _onWeekChanged(DateTime newWeek) {
  //   debugPrint('Week changed to: ${DateFormat.yMMMMd().format(newWeek)}');
  // }

  void _onGoToToday() {
    setState(() {
      _selectedDate = my_date_utils.DateUtils.normalizeDateTime(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format the selected date for display
    final String formattedDate = DateFormat('MMM d').format(_selectedDate);
    final DateTime now = DateTime.now();
    final bool isToday = my_date_utils.DateUtils.isSameDay(_selectedDate, now);
    final bool isTomorrow = my_date_utils.DateUtils.isSameDay(_selectedDate, now.add(const Duration(days: 1)));
    final bool isYesterday = my_date_utils.DateUtils.isSameDay(_selectedDate, now.subtract(const Duration(days: 1)));

    String dayLabel;
    if (isToday) {
      dayLabel = 'TODAY';
    } else if (isTomorrow) {
      dayLabel = 'TOMORROW';
    } else if (isYesterday) {
      dayLabel = 'YESTERDAY';
    } else {
      dayLabel = DateFormat('EEEE').format(_selectedDate).toUpperCase();
    }

    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Stack(
          children: [
            TopGradientBackground(),
            Scaffold(
              appBar: _mainSelectedIndex == 0
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(271.0),
                      child: AppBar(
                        toolbarHeight: 271.0,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        flexibleSpace: HomeAppBarContent(
                          selectedDate: _selectedDate,
                          onDateSelected: _onDateSelected,
                          timeOfDayFilter: _selectedTimeOfDayFilter,
                          onTimeOfDayFilterTapped: _onTimeOfDayFilterTapped,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          isToday: isToday,
                          dayLabel: dayLabel,
                          formattedDate: formattedDate,
                          debouncer: _debouncer,
                          onGoToToday: _onGoToToday,
                        ),
                      ),
                    )
                  : null,
              body: _mainSelectedIndex == 0 && habitService.habits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: AnimatedBuilder(
                              animation: _lottieAnimationController,
                              builder: (context, child) {
                                return Lottie.asset(
                                  key: ValueKey('noHabitsAnimation'),
                                  'assets/Meditation  Wait please.json',
                                  controller: _lottieAnimationController,
                                  width: 220,
                                  height: 220,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 15.0),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        _mainWidgetOptions(_selectedTimeOfDayFilter, _selectedDate)
                            .elementAt(_mainSelectedIndex),
                        if (habitService.isFetchingData)
                          Positioned.fill(
                            child: Container(
                              color: colorScheme.surface.withAlpha((255 * 0.5).round()),
                              child: Center(
                                child: RotationTransition(
                                  turns: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(_fabAnimationController),
                                  child: CircularProgressIndicator(
                                      color: colorScheme.primary),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
              bottomNavigationBar: BottomNavigationBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: CustomIcon.material(Icons.check_box_outlined).toWidget(defaultColor: _mainSelectedIndex == 0 ? colorScheme.primary : colorScheme.onSurface),
                    label: 'Habits',
                  ),
                  BottomNavigationBarItem(
                    icon: CustomIcon.material(Icons.history_toggle_off_outlined).toWidget(defaultColor: _mainSelectedIndex == 1 ? colorScheme.primary : colorScheme.onSurface),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: CustomIcon.material(Icons.settings_outlined).toWidget(defaultColor: _mainSelectedIndex == 2 ? colorScheme.primary : colorScheme.onSurface),
                    label: 'Settings',
                  ),
                ],
                currentIndex: _mainSelectedIndex,
                selectedItemColor: colorScheme.primary,
                unselectedItemColor: colorScheme.onSurface,
                onTap: (index) {
                  _debouncer.call(() => _onMainItemTapped(index));
                },
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                backgroundColor: colorScheme.surface,
                elevation: 6,
              ),
              floatingActionButton: _mainSelectedIndex == 0
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ScaleTransition(
                        scale: _fabScaleAnimation,
                        child: FloatingActionButton(
                          onPressed: () {
                            _debouncer.call(() {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const AddHabitScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;

                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            });
                          },
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          child: CustomIcon.material(Icons.add).toWidget(),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }
}

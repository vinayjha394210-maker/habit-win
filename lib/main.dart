import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/screens/home_screen.dart';
import 'package:habit_win/screens/splash_screen.dart'; // Import SplashScreen
import 'package:habit_win/services/notification_service.dart'; // Import NotificationService
import 'package:habit_win/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:habit_win/screens/habit_detail_screen.dart'; // Import HabitDetailScreen
import 'package:habit_win/utils/app_themes.dart'; // Import AppThemes
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final LocalStorageService localStorageService = LocalStorageService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationService notificationService = NotificationService();
  await notificationService.init(navigatorKey);
  await localStorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeNotifier(localStorageService),
        ),
        ChangeNotifierProvider(
          create: (context) => HabitService(localStorageService, notificationService),
        ),
      ],
      child: MyApp(notificationService: notificationService),
    ),
  );
}

class ThemeNotifier with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.dark;
  final LocalStorageService _localStorageService;

  ThemeNotifier(this._localStorageService) {
    _loadThemePreference();
  }

  AppTheme get currentTheme => _currentTheme;

  void _loadThemePreference() {
    final String? storedThemeString = _localStorageService.getThemePreference();
    if (storedThemeString != null) {
      try {
        _currentTheme = AppTheme.values.firstWhere(
          (e) => e.toString() == storedThemeString,
          orElse: () => AppTheme.dark,
        );
      } catch (e) {
        _currentTheme = AppTheme.dark;
      }
    } else {
      _currentTheme = AppTheme.dark;
    }
  }

  void setTheme(AppTheme theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      _localStorageService.saveThemePreference(theme.toString());
      notifyListeners();
    }
  }
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'HABIT NOW',
          theme: themeNotifier.currentTheme.themeData,
          themeMode: themeNotifier.currentTheme.themeData.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
          navigatorKey: navigatorKey,
          routes: {
            '/habitDetail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return HabitDetailScreen(habitId: args['habitId']);
            },
          },
          home: const AppStartScreen(), // Use AppStartScreen for initial routing
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  void _checkInitialRoute() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(); // Show splash screen while checking passcode status
  }
}

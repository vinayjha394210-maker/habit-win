import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/main.dart'; // Import the main.dart to access ThemeNotifier
import 'package:habit_win/services/notification_service.dart'; // Import NotificationService
import 'package:habit_win/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:habit_win/utils/app_themes.dart'; // Import AppThemes
import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer
import 'package:habit_win/widgets/theme_preview_card.dart'; // Import ThemePreviewCard
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon
import 'package:habit_win/utils/app_dimens.dart'; // Import AppDimens
import 'package:habit_win/widgets/top_gradient_background.dart'; // Import TopGradientBackground
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  final NotificationService _notificationService = NotificationService();
  final Debouncer _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _checkNotificationStatus() async {
    final bool enabled = await NotificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  void _toggleNotifications(bool value) async {
    _debouncer.call(() async {
      if (value) {
        // If enabling, request permissions
        await NotificationService.requestNotificationPermissions();
        final bool granted = await NotificationService.areNotificationsEnabled();
        if (!granted) {
          if (!mounted) return;
          // If permission is still not granted, show an alert
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Notification Permission Required'),
                content: const Text(
                    'Please enable notifications in your device settings to receive reminders.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      NotificationService.openAppSettingsPage();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              );
            },
          );
        }
        if (!mounted) return;
        setState(() {
          _notificationsEnabled = granted;
        });
      } else {
        // If disabling, cancel all scheduled notifications
        await _notificationService.cancelAllNotifications();
        setState(() {
          _notificationsEnabled = false;
        });
        // Optionally, you could also guide the user to app settings to revoke permission
        // if they truly want to disable them at the system level.
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Stack(
      children: [
        TopGradientBackground(),
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingSmall + 4),
                child: SwitchListTile(
                  title: Text('Notifications', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                  secondary: CustomIcon.material(Icons.notifications).toWidget(defaultColor: Theme.of(context).colorScheme.onSurface),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero, // Remove default padding
                ),
              ),
              // Theme selection card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingSmall),
                elevation: AppDimens.paddingSmall - 4, // Softened shadow
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadius)), // Rounded corners
                child: ListTile(
                  leading: CustomIcon.material(Icons.color_lens).toWidget(defaultColor: Theme.of(context).colorScheme.onSurface),
                  title: Text('Choose Theme', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                  trailing: Text(themeNotifier.currentTheme.name, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.primary)),
                  onTap: () => _debouncer.call(() => _showThemePickerDialog(context, themeNotifier)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _showThemePickerDialog(BuildContext context, ThemeNotifier themeNotifier) {
    showGeneralDialog( // Using showGeneralDialog for custom transitions
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: AlertDialog(
            title: Text(
              'Select Theme',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                    child: Text(
                      'Choose your preferred app theme:',
                      style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: AppDimens.paddingSmall + 2,
                      mainAxisSpacing: AppDimens.paddingSmall + 2,
                    ),
                    itemCount: AppTheme.values.length,
                    itemBuilder: (context, index) {
                      final theme = AppTheme.values[index];
                      return ThemePreviewCard(
                        theme: theme,
                        currentTheme: themeNotifier.currentTheme,
                        onChanged: (selectedTheme) {
                          _debouncer.call(() {
                            if (selectedTheme != null) {
                              if (!mounted) return;
                              themeNotifier.setTheme(selectedTheme);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Theme "${selectedTheme.name}" applied successfully.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadius)), // Rounded corners for dialog
          ),
        );
      },
    );
  }
}

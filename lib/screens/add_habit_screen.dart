import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_win/services/habit_service.dart';
import 'package:habit_win/services/notification_service.dart'; // Import NotificationService
import 'package:habit_win/models/habit.dart'; // Import RepeatType and TimeOfDayType
import 'package:intl/intl.dart'; // For date formatting
import 'package:habit_win/utils/string_extensions.dart'; // Import StringExtension
import 'package:habit_win/utils/custom_icons.dart'; // Import CustomIcon and availableMaterialIcons
import 'package:habit_win/utils/debounce_utils.dart'; // Import Debouncer
import 'package:habit_win/widgets/icon_picker_widget.dart'; // Import IconPickerWidget
import 'package:habit_win/widgets/color_picker_widget.dart'; // Import ColorPickerWidget
import 'package:habit_win/utils/app_dimens.dart'; // Import AppDimens
import 'package:habit_win/widgets/custom_radio_group.dart'; // Import CustomRadioGroup
import 'package:habit_win/widgets/top_gradient_background.dart'; // Import TopGradientBackground

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // Optional habit for editing

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  // Controllers for text fields
  final _habitNameController = TextEditingController();
  final _goalValueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // New state variable for loading indicator

  String? _selectedUnit; // New state variable for selected unit

  final Debouncer _debouncer = Debouncer();

  String _selectedColor = 'FF42A5F5'; // Default color (blue)
  CustomIcon _selectedIcon = CustomIcon.material(Icons.directions_run); // Default icon
  bool _goalEnabled = false;
  RepeatType _selectedRepeatType = RepeatType.daily;
  Set<int> _selectedRepeatDays = {}; // 1 for Monday, 7 for Sunday
  int _selectedRepeatDateOfMonth = 1; // For monthly habits
  DateTime? _oneTimeDate; // For one-time habits

  TimeOfDayType _selectedTimeOfDayType = TimeOfDayType.morning;
  DateTime _selectedStartDate = DateTime.now();
  List<TimeOfDay> _reminderTimes = [];

  // Use the comprehensive list of icons from custom_icons.dart
  // final List<CustomIcon> _availableIcons = availableMaterialIcons; // Removed as it's unused

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      // Editing existing habit
      _habitNameController.text = widget.habit!.name;
      _selectedColor = widget.habit!.color;
      _selectedIcon = widget.habit!.icon; // Habit model now returns CustomIcon directly
      _goalEnabled = widget.habit!.goalEnabled;
      if (widget.habit!.goalValue != null) {
        _goalValueController.text = widget.habit!.goalValue.toString();
      }
      _selectedUnit = widget.habit!.unit; // Initialize selected unit
      _selectedRepeatType = widget.habit!.repeatType;
      _selectedRepeatDays = widget.habit!.repeatDays.toSet();
      _selectedRepeatDateOfMonth = widget.habit!.repeatDateOfMonth;
      _selectedTimeOfDayType = widget.habit!.timeOfDayType;
      _selectedStartDate = widget.habit!.startDate;
      _reminderTimes = List.from(widget.habit!.reminderTimes);

      // For one-time habits, initialize _oneTimeDate from targetDate
      if (_selectedRepeatType == RepeatType.oneTime) {
        _oneTimeDate = widget.habit!.targetDate;
      }
    }
  }

  @override
  void dispose() {
    _habitNameController.dispose();
    _goalValueController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation for weekly habits
    if (_selectedRepeatType == RepeatType.weekly && _selectedRepeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day for weekly habits.')),
      );
      return;
    }

    // Validation for one-time habits
    if (_selectedRepeatType == RepeatType.oneTime && _oneTimeDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date for one-time habits.')),
      );
      return;
    }

    // Check notification permissions if reminder times are set
    if (_reminderTimes.isNotEmpty) {
      final bool notificationsGranted = await NotificationService.areNotificationsEnabled();
      if (!notificationsGranted) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Notification Permission Required'),
              content: const Text(
                  'To set reminders for your habits, please enable notifications in your device settings.'),
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
        // After the dialog, re-check if permissions were granted.
        // If not, prevent saving the habit with reminders.
        final bool recheckedPermissions = await NotificationService.areNotificationsEnabled();
        if (!recheckedPermissions) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission not granted. Habit reminders will not be set.')),
          );
          setState(() {
            _isLoading = false;
          });
          return; // Stop saving if permissions are not granted
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final habitService = Provider.of<HabitService>(context, listen: false);
      final String habitName = _habitNameController.text.trim();

      // Check for duplicate habit name only when adding a new habit
      if (widget.habit == null) {
        final existingHabits = habitService.habits;
        if (existingHabits.any((habit) => habit.name.toLowerCase() == habitName.toLowerCase())) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Habit "$habitName" already exists. Please choose a different name.')),
          );
          setState(() {
            _isLoading = false;
          });
          return; // Stop execution if duplicate
        }
      } else {
        // When editing, check for duplicate names excluding the current habit being edited
        final existingHabits = habitService.habits.where((h) => h.id != widget.habit!.id).toList();
        if (existingHabits.any((habit) => habit.name.toLowerCase() == habitName.toLowerCase())) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Habit "$habitName" already exists. Please choose a different name.')),
          );
          setState(() {
            _isLoading = false;
          });
          return; // Stop execution if duplicate
        }
      }

      int? goalValue = _goalEnabled ? int.tryParse(_goalValueController.text) : null;
      String? unit = _goalEnabled ? _selectedUnit : null; // Get selected unit
      String successMessage = '';

      if (widget.habit == null) {
        // Adding a new habit
        await habitService.addHabit(
          habitName,
          _selectedColor,
          _selectedIcon.toSavableString(),
          _goalEnabled,
          goalValue,
          unit, // Pass unit to addHabit
          _selectedRepeatType,
          _selectedRepeatDays.toList(),
          _selectedRepeatDateOfMonth,
          _oneTimeDate,
          _selectedTimeOfDayType,
          _selectedStartDate,
          _reminderTimes,
        );
        successMessage = 'Habit "$habitName" added successfully!';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      } else {
        // Updating an existing habit
        final updatedHabit = Habit(
          id: widget.habit!.id,
          name: habitName,
          color: _selectedColor,
          icon: _selectedIcon,
          goalEnabled: _goalEnabled,
          goalValue: goalValue,
          unit: unit, // Pass unit to updatedHabit
          repeatType: _selectedRepeatType,
          repeatDays: _selectedRepeatDays.toList(),
          repeatDateOfMonth: _selectedRepeatDateOfMonth,
          targetDate: _selectedRepeatType == RepeatType.oneTime ? _oneTimeDate : null,
          completionDates: widget.habit!.completionDates,
          streak: widget.habit!.streak,
          timeOfDayType: _selectedTimeOfDayType,
          startDate: _selectedStartDate,
          reminderTimes: _reminderTimes,
        );
        await habitService.updateHabit(updatedHabit);
        successMessage = 'Habit "$habitName" updated successfully!';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save habit: $e')),
      );
    } finally {
      _isLoading = false; // Update loading state regardless of mounted status
      if (mounted) {
        setState(() {}); // Only call setState if the widget is still mounted
      }
    }
  }

  void _pickColor() async {
    final selectedColor = await showDialog<String>(
      context: context,
      builder: (context) => ColorPickerWidget(initialColor: _selectedColor),
    );

    if (selectedColor != null) {
      setState(() {
        _selectedColor = selectedColor;
      });
    }
  }

  void _pickIcon() async {
    final selectedIcon = await showDialog<CustomIcon>(
      context: context,
      builder: (context) => IconPickerWidget(
        initialIcon: _selectedIcon,
        initialColor: Color(int.parse(_selectedColor, radix: 16)),
      ),
    );

    if (selectedIcon != null) {
      setState(() {
        _selectedIcon = selectedIcon;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TopGradientBackground(),
        Scaffold(
          appBar: AppBar(
            title: Text(widget.habit == null ? 'New Habit' : 'Edit Habit'),
            actions: [
              TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    _debouncer.call(_saveHabit);
                  }, // Disable button when loading
            child: _isLoading
                ? SizedBox(
                    width: AppDimens.paddingLarge,
                    height: AppDimens.paddingLarge,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: AppDimens.paddingMedium + 2),
                  ),
          ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding for the body
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _habitNameController,
                    decoration: InputDecoration(
                      labelText: 'Enter habit name',
                      labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.5).round()), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      errorStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.error),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    maxLines: 1,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Habit name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingLarge),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _debouncer.call(_pickColor);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                            decoration: BoxDecoration(
                              color: Color(int.parse(_selectedColor, radix: 16)),
                              borderRadius: BorderRadius.circular(AppDimens.borderRadius), // More rounded
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withAlpha(20), // Softened shadow
                                  blurRadius: AppDimens.elevation,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomIcon.material(Icons.color_lens).toWidget(defaultColor: Colors.white),
                                const SizedBox(width: AppDimens.paddingSmall + 2),
                                Text('Color', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.paddingSmall + 2),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _debouncer.call(_pickIcon);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppDimens.borderRadius), // More rounded
                              border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.5).round())),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.shadow.withAlpha(20), // Softened shadow
                                  blurRadius: AppDimens.elevation,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _selectedIcon.toWidget(
                                  size: 30,
                                  defaultColor: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: AppDimens.paddingSmall + 2),
                                Text('Icon', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.paddingLarge),
                  SwitchListTile(
                    title: Text('Set a Goal', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    subtitle: Text('Set your target in a day', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.7).round()))),
                    value: _goalEnabled,
                    onChanged: (value) {
                      _debouncer.call(() {
                        setState(() {
                          _goalEnabled = value;
                        });
                      });
                    },
                    activeTrackColor: Theme.of(context).colorScheme.primary, // Use activeTrackColor for the track
                    activeThumbColor: Theme.of(context).colorScheme.onPrimary, // Ensure switch thumb color adapts
                  ),
                  if (_goalEnabled)
                    _buildGoalInputWithUnitSelector(), // New widget for goal input and unit selector
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildTimeOfDaySelection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildStartDateSelection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildReminderSelection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  _buildRepeatFrequencySection(),
                  if (_selectedRepeatType == RepeatType.weekly) _buildWeeklyDaySelection(),
                  if (_selectedRepeatType == RepeatType.monthly) _buildMonthlyDateSelection(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  if (_selectedRepeatType == RepeatType.oneTime) _buildOneTimeDatePicker(),
                  const SizedBox(height: AppDimens.paddingLarge),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveHabit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                      textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: AppDimens.paddingMedium + 2, color: Theme.of(context).colorScheme.onPrimary),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadius)), // Rounded corners
                      elevation: AppDimens.elevation, // More prominent shadow
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: AppDimens.paddingLarge, // Larger indicator
                            height: AppDimens.paddingLarge,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5, // Thicker stroke
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(widget.habit == null ? 'Add Habit' : 'Update Habit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInputWithUnitSelector() {
    final List<String> units = [
      "steps", "km", "miles", "minutes", "hours", "pages", "reps", "sets",
      "ml", "liters", "calories", "kg", "grams", "tasks", "sessions", "rounds"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Goal',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _goalValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Goal Value',
                  labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  errorStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.error),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                validator: (value) {
                  if (_goalEnabled) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a value';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Must be a positive number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimens.paddingSmall + 2),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Unit',
                labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                ),
                errorStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.error),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: units.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit.capitalize(), style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  _debouncer.call(() {
                    setState(() {
                      _selectedUnit = newValue;
                    });
                  });
                },
                validator: (value) {
                  if (_goalEnabled && (value == null || value.isEmpty)) {
                    return 'Select a unit';
                  }
                  return null;
                },
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.onSurface),
                icon: CustomIcon.material(Icons.arrow_drop_down).toWidget(defaultColor: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeOfDaySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I will do it at this time of day',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: TimeOfDayType.values.where((type) => type != TimeOfDayType.all).map((type) {
            final isSelected = _selectedTimeOfDayType == type;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall - 4),
                child: ElevatedButton(
                  onPressed: () {
                    _debouncer.call(() {
                      setState(() {
                        _selectedTimeOfDayType = type;
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                    foregroundColor: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.borderRadius), // More rounded
                      side: BorderSide(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    elevation: isSelected ? 6 : 0, // More prominent shadow for selected
                    shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(38), // More prominent shadow
                    padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                  ),
                  child: Text(type.toString().split('.').last.capitalize()),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStartDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I will stick to this habit starting from',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        FormField<DateTime>(
          initialValue: _selectedStartDate,
          validator: (value) {
            if (value == null) {
              return 'Please select a start date';
            }
            return null;
          },
          builder: (FormFieldState<DateTime> state) {
            return GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedStartDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Theme.of(context).colorScheme.primary, // Header background color
                          onPrimary: Theme.of(context).colorScheme.onPrimary, // Header text color
                          onSurface: Theme.of(context).colorScheme.onSurface, // Body text color
                          surface: Theme.of(context).colorScheme.surface, // Dialog background color
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary, // Button text color
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedStartDate) {
                  setState(() {
                    _selectedStartDate = picked;
                    state.didChange(picked);
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: state.errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0),
                  ),
                  contentPadding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                child: Row(
                  children: [
                    CustomIcon.material(Icons.calendar_today).toWidget(defaultColor: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppDimens.paddingSmall + 2),
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedStartDate),
                      style: TextStyle(fontSize: AppDimens.paddingMedium, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Spacer(),
                    CustomIcon.material(Icons.arrow_forward_ios).toWidget(size: AppDimens.paddingMedium, defaultColor: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReminderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remind me at',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        ..._reminderTimes.map((time) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.paddingSmall),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow.withAlpha(25), // More prominent shadow
                            blurRadius: AppDimens.elevation + 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        time.format(context),
                        style: TextStyle(fontSize: AppDimens.paddingMedium, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: CustomIcon.material(Icons.remove_circle_outline).toWidget(defaultColor: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      _debouncer.call(() {
                        setState(() {
                          _reminderTimes.remove(time);
                        });
                      });
                    },
                  ),
                ],
              ),
            )),
        GestureDetector(
          onTap: () {
            _debouncer.call(() async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).colorScheme.primary, // Header background color
                        onPrimary: Theme.of(context).colorScheme.onPrimary, // Header text color
                        onSurface: Theme.of(context).colorScheme.onSurface, // Body text color
                        surface: Theme.of(context).colorScheme.surface, // Dialog background color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary, // Button text color
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && !_reminderTimes.contains(picked)) {
                setState(() {
                  _reminderTimes.add(picked);
                  _reminderTimes.sort((a, b) {
                    final aMinutes = a.hour * 60 + a.minute;
                    final bMinutes = b.hour * 60 + b.minute;
                    return aMinutes.compareTo(bMinutes);
                  });
                });
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withAlpha((255 * 0.1).round()), // More prominent shadow
                  blurRadius: AppDimens.elevation + 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CustomIcon.material(Icons.add).toWidget(defaultColor: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppDimens.paddingSmall + 2),
                Text(
                  'Add time',
                  style: TextStyle(fontSize: AppDimens.paddingMedium, color: Theme.of(context).colorScheme.onSurface),
                ),
                const Spacer(),
                CustomIcon.material(Icons.arrow_forward_ios).toWidget(size: AppDimens.paddingMedium, defaultColor: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat Frequency',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        CustomRadioGroup<RepeatType>(
          groupValue: _selectedRepeatType,
          onChanged: (value) {
            _debouncer.call(() {
              setState(() {
                _selectedRepeatType = value!;
                _selectedRepeatDays.clear();
                _oneTimeDate = null;
                _selectedRepeatDateOfMonth = (value == RepeatType.monthly) ? DateTime.now().day : 1;
              });
            });
          },
          options: [
            CustomRadioOption(label: 'Daily', value: RepeatType.daily),
            CustomRadioOption(label: 'Weekly', value: RepeatType.weekly),
            CustomRadioOption(label: 'Monthly', value: RepeatType.monthly),
            CustomRadioOption(label: 'One-Time', value: RepeatType.oneTime),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyDaySelection() {
    final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimens.paddingSmall + 2),
        Text(
          'Select Days',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppDimens.paddingSmall,
          runSpacing: AppDimens.paddingSmall,
          children: List.generate(7, (index) {
            final dayIndex = index + 1;
            final isSelected = _selectedRepeatDays.contains(dayIndex);
            return GestureDetector(
              onTap: () {
                _debouncer.call(() {
                  setState(() {
                    if (isSelected) {
                      _selectedRepeatDays.remove(dayIndex);
                    } else {
                      _selectedRepeatDays.add(dayIndex);
                    }
                  });
                });
              },
              child: CircleAvatar(
                radius: AppDimens.paddingLarge,
                backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  weekdays[index],
                  style: TextStyle(
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOneTimeDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        GestureDetector(
          onTap: () {
            _debouncer.call(() async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _oneTimeDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).colorScheme.primary,
                        onPrimary: Theme.of(context).colorScheme.onPrimary,
                        onSurface: Theme.of(context).colorScheme.onSurface,
                        surface: Theme.of(context).colorScheme.surface,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _oneTimeDate) {
                setState(() {
                  _oneTimeDate = picked;
                });
              }
            });
          },
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.borderRadius),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
              ),
              contentPadding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                CustomIcon.material(Icons.calendar_today).toWidget(defaultColor: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppDimens.paddingSmall + 2),
                Text(
                  _oneTimeDate == null
                      ? 'Pick a date'
                      : 'Date: ${DateFormat('EEEE, MMM d').format(_oneTimeDate!)}',
                  style: TextStyle(fontSize: AppDimens.paddingMedium, color: Theme.of(context).colorScheme.onSurface),
                ),
                const Spacer(),
                CustomIcon.material(Icons.arrow_forward_ios).toWidget(size: AppDimens.paddingMedium, defaultColor: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimens.paddingSmall + 2),
        Text(
          'Repeat on day of month',
          style: TextStyle(fontSize: AppDimens.paddingMedium, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: AppDimens.paddingSmall + 2),
        DropdownButtonFormField<int>(
          initialValue: _selectedRepeatDateOfMonth,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.borderRadius),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
            ),
            contentPadding: const EdgeInsets.all(AppDimens.paddingMedium), // Consistent padding
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          items: List.generate(31, (index) => index + 1)
              .map((date) => DropdownMenuItem(
                    value: date,
                    child: Text(date.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  ))
              .toList(),
          onChanged: (value) {
            _debouncer.call(() {
              setState(() {
                _selectedRepeatDateOfMonth = value!;
              });
            });
          },
          dropdownColor: Theme.of(context).colorScheme.surface, // Dropdown menu background color
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface), // Selected item text style
          icon: CustomIcon.material(Icons.arrow_drop_down).toWidget(defaultColor: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
        ),
      ],
    );
  }
}

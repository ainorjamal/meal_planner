import 'package:flutter/material.dart';
import '../services/firestore.dart';

// Custom color palette
class AppColors {
  static const Color primary = Color(0xFF6750A4);
  static const Color secondary = Color(0xFF9A82DB);
  static const Color lightPurple = Color(0xFFE6DFFF);
  static const Color darkPurple = Color(0xFF4A3880);
  static const Color background = Color(0xFFF8F5FF);
  static const Color darkBackground = Color(0xFF2D2D3A);
  static const Color textDark = Color(0xFF1D1B20);
  static const Color textLight = Color(0xFFF4EFF4);
  static const Color errorRed = Color(0xFFB3261E);
}

class AddMealScreen extends StatefulWidget {
  final Map<String, dynamic>? mealToEdit;
  final DateTime? preselectedDate;

  const AddMealScreen({super.key, this.mealToEdit, this.preselectedDate});

  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController mealNameController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  String? _selectedMealType;
  TimeOfDay? _selectedTime;
  DateTime _selectedDate = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();

    if (widget.preselectedDate != null) {
      _selectedDate = widget.preselectedDate!;
    }

    if (widget.mealToEdit != null) {
      mealNameController.text = widget.mealToEdit!['title'] ?? '';
      ingredientsController.text = widget.mealToEdit!['description'] ?? '';
      timeController.text = widget.mealToEdit!['time'] ?? '';
      _selectedMealType = widget.mealToEdit!['mealType'];

      if (widget.mealToEdit!['date'] != null) {
        _selectedDate = widget.mealToEdit!['date'].toDate();
      }

      if (widget.mealToEdit!['time'] != null &&
          widget.mealToEdit!['time'].isNotEmpty) {
        try {
          final timeParts = widget.mealToEdit!['time'].split(' ');
          if (timeParts.length == 2) {
            final hourMinute = timeParts[0].split(':');
            int hour = int.parse(hourMinute[0]);
            final int minute = int.parse(hourMinute[1]);
            final String amPm = timeParts[1].toUpperCase();

            if (amPm == 'PM' && hour < 12) {
              hour += 12;
            } else if (amPm == 'AM' && hour == 12) {
              hour = 0;
            }

            _selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        } catch (e) {
          _selectedTime = TimeOfDay.now();
        }
      }
    }

    _selectedTime ??= TimeOfDay.now();
    _updateTimeController();
    _updateDateController();
  }

  void _updateTimeController() {
    if (_selectedTime != null) {
      final String period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      final int hourIn12HourFormat =
          _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
      final String minute = _selectedTime!.minute.toString().padLeft(2, '0');
      timeController.text = '$hourIn12HourFormat:$minute $period';
    }
  }

  void _updateDateController() {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    dateController.text = '$month/$day/$year';
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Custom TimePickerTheme with high contrast colors
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: AppColors.primary.withOpacity(0.2),
              hourMinuteTextColor: AppColors.darkPurple,
              dayPeriodColor: AppColors.lightPurple,
              dayPeriodTextColor: AppColors.darkPurple,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.lightPurple.withOpacity(0.3),
              dialTextColor: Colors.black87,
              entryModeIconColor: AppColors.primary,
              hourMinuteTextStyle: TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        _updateTimeController();
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: isDarkMode ? AppColors.darkBackground : Colors.white,
              onSurface: isDarkMode ? AppColors.textLight : AppColors.textDark,
            ),
            dialogBackgroundColor:
                isDarkMode ? AppColors.darkBackground : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              weekdayStyle: TextStyle(
                color:
                    isDarkMode ? AppColors.lightPurple : AppColors.darkPurple,
                fontWeight: FontWeight.bold,
              ),
              dayStyle: TextStyle(
                color: isDarkMode ? AppColors.textLight : AppColors.textDark,
              ),
              dayBackgroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return AppColors.primary;
                }
                return isDarkMode ? Colors.transparent : Colors.transparent;
              }),
              todayBackgroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                return AppColors.secondary.withOpacity(0.3);
              }),
              todayForegroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                return AppColors.darkPurple;
              }),
              dayForegroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return isDarkMode ? AppColors.textLight : AppColors.textDark;
              }),
              surfaceTintColor: Colors.transparent,
              backgroundColor:
                  isDarkMode ? AppColors.darkBackground : Colors.white,
              yearBackgroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return AppColors.primary;
                }
                return isDarkMode ? Colors.grey[800]! : Colors.grey[100]!;
              }),
              yearForegroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return isDarkMode ? AppColors.textLight : AppColors.textDark;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _updateDateController();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.background;
    final cardColor = isDarkMode ? Color(0xFF3D3A4A) : Colors.white;
    final textColor = isDarkMode ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.mealToEdit == null ? 'Add Meal' : 'Edit Meal',
          style: TextStyle(
            color: isDarkMode ? AppColors.textLight : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [
                      AppColors.darkPurple.withOpacity(0.3),
                      AppColors.darkBackground,
                    ]
                    : [
                      AppColors.primary.withOpacity(0.05),
                      AppColors.background,
                    ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: mealNameController,
                        label: 'Meal Name',
                        icon: Icons.restaurant_menu,
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: ingredientsController,
                        label: 'Ingredients',
                        icon: Icons.inventory_2,
                        isDarkMode: isDarkMode,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time & Date',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildDateField(
                        controller: dateController,
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _selectTime(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: timeController,
                            label: 'Time',
                            icon: Icons.access_time,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meal Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildDropdown(isDarkMode),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              _buildSaveButton(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDarkMode
                    ? AppColors.lightPurple.withOpacity(0.4)
                    : AppColors.primary.withOpacity(0.4),
          ),
          color:
              isDarkMode
                  ? Colors.grey[800]!.withOpacity(0.5)
                  : Colors.grey[100]!.withOpacity(0.7),
        ),
        child: TextField(
          controller: controller,
          enabled: false,
          style: TextStyle(
            color: isDarkMode ? AppColors.textLight : AppColors.textDark,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: 'Date',
            labelStyle: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.lightPurple
                      : AppColors.primary.withOpacity(0.8),
            ),
            prefixIcon: Icon(
              Icons.calendar_today,
              color: isDarkMode ? AppColors.lightPurple : AppColors.primary,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: isDarkMode ? AppColors.lightPurple : AppColors.primary,
              size: 28,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDarkMode ? AppColors.textLight : AppColors.textDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:
              isDarkMode
                  ? AppColors.lightPurple
                  : AppColors.primary.withOpacity(0.8),
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? AppColors.lightPurple : AppColors.primary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDarkMode
                    ? AppColors.lightPurple.withOpacity(0.4)
                    : AppColors.primary.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor:
            isDarkMode
                ? Colors.grey[800]!.withOpacity(0.5)
                : Colors.grey[100]!.withOpacity(0.7),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 0,
        ),
      ),
    );
  }

  Widget _buildDropdown(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkMode
                  ? AppColors.lightPurple.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.4),
        ),
        color:
            isDarkMode
                ? Colors.grey[800]!.withOpacity(0.5)
                : Colors.grey[100]!.withOpacity(0.7),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Select meal type',
          labelStyle: TextStyle(
            color:
                isDarkMode
                    ? AppColors.lightPurple
                    : AppColors.primary.withOpacity(0.8),
          ),
          prefixIcon: Icon(
            Icons.category,
            color: isDarkMode ? AppColors.lightPurple : AppColors.primary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDarkMode ? AppColors.lightPurple : AppColors.primary,
        ),
        style: TextStyle(
          color: isDarkMode ? AppColors.textLight : AppColors.textDark,
          fontSize: 16,
        ),
        value: _selectedMealType,
        items:
            <String>['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((
              String value,
            ) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedMealType = newValue;
          });
        },
      ),
    );
  }

  Widget _buildSaveButton(bool isDarkMode) {
    return ElevatedButton(
      onPressed: () async {
        String title = mealNameController.text.trim();
        String description = ingredientsController.text.trim();
        String time = timeController.text.trim();
        String? mealType = _selectedMealType;

        if (title.isNotEmpty &&
            description.isNotEmpty &&
            time.isNotEmpty &&
            mealType != null &&
            mealType.isNotEmpty) {
          if (widget.mealToEdit == null) {
            await _firestoreService.addMeal(
              title: title,
              description: description,
              time: time,
              date: _selectedDate,
              mealType: mealType,
            );
          } else {
            await _firestoreService.updateMeal(
              mealId: widget.mealToEdit!['id'],
              title: title,
              description: description,
              time: time,
              date: _selectedDate,
              mealType: mealType,
              logged: widget.mealToEdit!['logged'] ?? false,
            );
          }
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please fill all required fields',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.mealToEdit == null ? Icons.add_circle : Icons.save),
          SizedBox(width: 8),
          Text(
            widget.mealToEdit == null ? 'Add Meal' : 'Save Changes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

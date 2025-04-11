import 'package:flutter/material.dart';
import '../services/firestore.dart'; // Import your FirestoreService

class AddMealScreen extends StatefulWidget {
  final Map<String, dynamic>? mealToEdit;

  const AddMealScreen({super.key, this.mealToEdit});

  @override
  // ignore: library_private_types_in_public_api
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
    // Populate the text fields if we are editing a meal
    if (widget.mealToEdit != null) {
      mealNameController.text = widget.mealToEdit!['title'] ?? '';
      ingredientsController.text = widget.mealToEdit!['description'] ?? '';
      timeController.text = widget.mealToEdit!['time'] ?? '';
      _selectedMealType = widget.mealToEdit!['mealType'];

      // Parse the date if it exists
      if (widget.mealToEdit!['date'] != null) {
        // The date is stored as a Timestamp in Firestore
        _selectedDate = widget.mealToEdit!['date'].toDate();
      }

      // Parse the time string if it exists
      if (widget.mealToEdit!['time'] != null &&
          widget.mealToEdit!['time'].isNotEmpty) {
        try {
          // Try to parse time in format like "8:00 AM"
          final timeParts = widget.mealToEdit!['time'].split(' ');
          if (timeParts.length == 2) {
            final hourMinute = timeParts[0].split(':');
            int hour = int.parse(hourMinute[0]);
            final int minute = int.parse(hourMinute[1]);
            final String amPm = timeParts[1].toUpperCase();

            // Convert to 24-hour format if PM
            if (amPm == 'PM' && hour < 12) {
              hour += 12;
            } else if (amPm == 'AM' && hour == 12) {
              hour = 0;
            }

            _selectedTime = TimeOfDay(hour: hour, minute: minute);
          }
        } catch (e) {
          // If parsing fails, default to current time
          _selectedTime = TimeOfDay.now();
        }
      }
    }

    // If no time was loaded or parsing failed, use current time
    _selectedTime ??= TimeOfDay.now();

    // Update the text controllers
    _updateTimeController();
    _updateDateController();
  }

  // Format time to display in the text field
  void _updateTimeController() {
    if (_selectedTime != null) {
      final String period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      final int hourIn12HourFormat =
          _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
      final String minute = _selectedTime!.minute.toString().padLeft(2, '0');
      timeController.text = '$hourIn12HourFormat:$minute $period';
    }
  }

  // Format date to display in the text field
  void _updateDateController() {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    dateController.text = '$month/$day/$year';
  }

  // Show time picker dialog
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodTextColor: Theme.of(context).primaryColor,
            ),
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
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

  // Show date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onSurface:
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mealToEdit == null ? 'Add Meal' : 'Edit Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: mealNameController,
              decoration: InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(
                labelText: 'Ingredients',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
              maxLines: 3, // Allow multiple lines for ingredients
            ),
            SizedBox(height: 16),
            // Date field with picker
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Time field with picker
            GestureDetector(
              onTap: () => _selectTime(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
              value: _selectedMealType,
              items:
                  <String>['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMealType = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a meal type';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
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
                    // Add new meal
                    await _firestoreService.addMeal(
                      title: title,
                      description: description,
                      time: time,
                      date: _selectedDate, // Pass the selected date
                      mealType: mealType,
                    );
                  } else {
                    // Update existing meal
                    await _firestoreService.updateMeal(
                      mealId: widget.mealToEdit!['id'],
                      title: title,
                      description: description,
                      time: time,
                      date: _selectedDate, // Pass the selected date
                      mealType: mealType,
                      logged: widget.mealToEdit!['logged'] ?? false,
                    );
                  }
                  Navigator.pop(context); // Go back to the previous screen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Meal Name, Ingredients, Time, and Meal Type cannot be empty',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.mealToEdit == null ? 'Add Meal' : 'Save Changes',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

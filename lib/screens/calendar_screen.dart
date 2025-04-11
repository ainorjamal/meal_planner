import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../screens/recipes_screen.dart';
import '../screens/user_profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _currentIndex = 1; // Set to 1 for Calendar tab
  bool _isDarkMode = false;
  Color primaryColor = Colors.green;

  // Example meal data mapped by date
  final Map<DateTime, List<MealEvent>> _mealEvents = {
    DateTime.now(): [
      MealEvent('Breakfast', 'Oatmeal', '8:00 AM'),
      MealEvent('Lunch', 'Grilled Chicken Salad', '12:30 PM'),
      MealEvent('Dinner', 'Pasta with Tomato Sauce', '7:00 PM'),
    ],
    DateTime.now().add(Duration(days: 1)): [
      MealEvent('Breakfast', 'Scrambled Eggs', '8:30 AM'),
      MealEvent('Lunch', 'Vegetable Soup', '1:00 PM'),
      MealEvent('Dinner', 'Grilled Salmon', '6:30 PM'),
    ],
    DateTime.now().add(Duration(days: 2)): [
      MealEvent('Breakfast', 'Pancakes', '9:00 AM'),
      MealEvent('Lunch', 'Caesar Salad', '12:00 PM'),
      MealEvent('Dinner', 'Beef Stir Fry', '7:30 PM'),
    ],
  };

  List<MealEvent> _getEventsForDay(DateTime day) {
    // Normalize date to remove time part for comparison
    final normalizedDay = DateTime(day.year, day.month, day.day);

    return _mealEvents.entries
        .where(
          (entry) =>
              entry.key.year == normalizedDay.year &&
              entry.key.month == normalizedDay.month &&
              entry.key.day == normalizedDay.day,
        )
        .expand((entry) => entry.value)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Calendar'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            // Add event markers
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(child: _buildEventList()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor:
            _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            // Home tab
            Navigator.pop(context);
          } else if (index == 1) {
            // Current Calendar tab - do nothing
          } else if (index == 2) {
            // Recipes tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipesScreen()),
            );
          } else if (index == 3) {
            // Profile tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new meal event for selected day
          _showAddMealDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_meals, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No meals planned for this day',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            TextButton.icon(
              icon: Icon(Icons.add),
              label: Text('Add Meal'),
              onPressed: () => _showAddMealDialog(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _getMealIcon(event.type),
            title: Text(event.mealName),
            subtitle: Text(event.type),
            trailing: Text(event.time),
            onTap: () {
              // Navigate to meal details
            },
          ),
        );
      },
    );
  }

  Widget _getMealIcon(String mealType) {
    IconData iconData;
    Color iconColor;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        iconData = Icons.wb_sunny;
        iconColor = Colors.orange;
        break;
      case 'lunch':
        iconData = Icons.restaurant;
        iconColor = Colors.green;
        break;
      case 'dinner':
        iconData = Icons.nightlight;
        iconColor = Colors.indigo;
        break;
      default:
        iconData = Icons.fastfood;
        iconColor = Colors.brown;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }

  void _showAddMealDialog() {
    // Implement a dialog to add a new meal
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Meal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Meal Type'),
                  items:
                      ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                          .map(
                            (label) => DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {},
                ),
                TextField(decoration: InputDecoration(labelText: 'Meal Name')),
                TextField(decoration: InputDecoration(labelText: 'Time')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Add'),
              ),
            ],
          ),
    );
  }
}

// Model class for meal events
class MealEvent {
  final String type;
  final String mealName;
  final String time;

  MealEvent(this.type, this.mealName, this.time);
}
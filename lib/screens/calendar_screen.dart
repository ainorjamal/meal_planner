// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:meal_planner/pages/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/recipes_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/add_meal_screen.dart';
import '../services/firestore.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final int _currentIndex = 1; // Set to 1 for Calendar tab
  bool _isDarkMode = false;
  Color primaryColor = Colors.green;
  FirestoreService _firestoreService = FirestoreService();
  Map<DateTime, List<MealEvent>> _mealEvents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMeals();
  }

  // Load meals from Firestore
  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Listen to meals collection stream
      _firestoreService.getMeals().listen((mealsSnapshot) {
        final Map<DateTime, List<MealEvent>> newEvents = {};

        for (var doc in mealsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;
          data['id'] = id; // Add document ID to the data

          if (data['date'] != null) {
            // Convert Firestore Timestamp to DateTime
            final DateTime mealDate = (data['date'] as Timestamp).toDate();
            // Normalize date by removing time part
            final DateTime normalizedDate = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
            );

            // Create a MealEvent from Firestore data
            final MealEvent event = MealEvent(
              data['mealType'] ?? 'Unknown',
              data['title'] ?? 'Unnamed Meal',
              data['time'] ?? '--:--',
              data, // Store the full data for later use
            );

            // Add to events map
            if (newEvents[normalizedDate] == null) {
              newEvents[normalizedDate] = [];
            }
            newEvents[normalizedDate]!.add(event);
          }
        }

        // Update state with new events
        setState(() {
          _mealEvents = newEvents;
          _isLoading = false;
        });
      });
    } catch (e) {
      print('Error loading meals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<MealEvent> _getEventsForDay(DateTime day) {
    // Normalize date to remove time part for comparison
    final normalizedDay = DateTime(day.year, day.month, day.day);

    return _mealEvents.entries
        .where((entry) {
          final eventDay = entry.key;
          return eventDay.year == normalizedDay.year &&
              eventDay.month == normalizedDay.month &&
              eventDay.day == normalizedDay.day;
        })
        .expand((entry) => entry.value)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Calendar'),
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
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

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
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
          // Navigate to AddMealScreen with selected date
          _navigateToAddMeal();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Navigate to AddMealScreen with preselected date
  void _navigateToAddMeal([Map<String, dynamic>? mealToEdit]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddMealScreen(
              mealToEdit: mealToEdit,
              preselectedDate: _selectedDay,
            ),
      ),
    );

    // If meal was added or updated, no need to explicitly reload
    // as we're using a stream that will update automatically
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
              onPressed: () => _navigateToAddMeal(),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.time),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToAddMeal(event.data);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(event.data['id']);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ],
            ),
            onTap: () {
              // Navigate to meal details
              _navigateToAddMeal(event.data);
            },
          ),
        );
      },
    );
  }

  // Show confirmation dialog before deleting a meal
  void _showDeleteConfirmation(String mealId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Meal'),
            content: Text('Are you sure you want to delete this meal?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _firestoreService.deleteMeal(mealId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Meal deleted')));
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
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
}

// Updated model class for meal events
class MealEvent {
  final String type;
  final String mealName;
  final String time;
  final Map<String, dynamic> data; // Store full document data

  MealEvent(this.type, this.mealName, this.time, this.data);
}

// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:meal_planner/pages/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/recipes_screen.dart';
import '../screens/user_profile_screen.dart';
import '../services/firestore.dart';
import '../screens/add_meal_screen.dart';

// Custom color palette
class AppColors {
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color secondaryPurple = Color(0xFF9A82DB);
  static const Color lightPurple = Color(0xFFE6DFFF);
  static const Color darkPurple = Color(0xFF4A3880);
  static const Color accentColor = Color(0xFFB69DF8);

  // Meal type colors
  static const Color breakfastColor = Color(0xFFFFA726);
  static const Color lunchColor = Color(0xFF66BB6A);
  static const Color dinnerColor = Color(0xFF5C6BC0);
  static const Color snackColor = Color(0xFFBF8C6D);
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final int _currentIndex = 1; // Set to 1 for Calendar tab
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meal Calendar',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? AppColors.darkPurple : AppColors.lightPurple,
              isDarkMode ? Colors.black : Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple,
                    ),
                  ),
                )
                : Column(
                  children: [
                    Card(
                      margin: EdgeInsets.all(8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TableCalendar(
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
                          // Customize calendar style
                          calendarStyle: CalendarStyle(
                            markersMaxCount: 3,
                            markerDecoration: BoxDecoration(
                              color: AppColors.accentColor,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.secondaryPurple.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle: TextStyle(
                              color: AppColors.secondaryPurple,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              color: AppColors.lightPurple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            formatButtonTextStyle: TextStyle(
                              color: AppColors.darkPurple,
                              fontWeight: FontWeight.bold,
                            ),
                            titleTextStyle: TextStyle(
                              color: AppColors.darkPurple,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Meals for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color:
                                  isDarkMode
                                      ? Colors.white
                                      : AppColors.darkPurple,
                            ),
                          ),
                          Spacer(),
                          OutlinedButton.icon(
                            icon: Icon(Icons.add, size: 16),
                            label: Text("Add"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              side: BorderSide(color: AppColors.primaryPurple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => _navigateToAddMeal(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildEventList(isDarkMode)),
                  ],
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor:
            isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            activeIcon: Icon(Icons.food_bank),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Navigate to AddMealScreen with preselected date
  // Replace the empty _navigateToAddMeal() method in your _CalendarScreenState class with this:
  void _navigateToAddMeal([Map<String, dynamic>? mealToEdit]) async {
    // Navigate to the existing AddMealScreen
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

    // If we got a positive result (meal added/updated), show a confirmation
    if (result == true) {
      // No need to call _loadMeals() since we have a listener in initState
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mealToEdit != null ? 'Meal updated' : 'Meal added'),
          backgroundColor: AppColors.primaryPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Add this import at the top of the calendar_screen.dart file:
  // import 'package:meal_planner/screens/add_meal_screen.dart';

  Widget _buildEventList(bool isDarkMode) {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_meals,
              size: 80,
              color:
                  isDarkMode
                      ? AppColors.lightPurple
                      : AppColors.secondaryPurple.withOpacity(0.7),
            ),
            SizedBox(height: 16),
            Text(
              'No meals planned for this day',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Add Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => _navigateToAddMeal(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getMealColor(event.type).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
              leading: _getMealIcon(event.type),
              title: Text(
                event.mealName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: _getMealColor(event.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.type,
                      style: TextStyle(
                        color: _getMealColor(event.type),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.time,
                      style: TextStyle(
                        color: AppColors.darkPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppColors.primaryPurple),
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
                              leading: Icon(
                                Icons.edit,
                                color: AppColors.primaryPurple,
                                size: 20,
                              ),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              title: Text('Delete'),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  _firestoreService.deleteMeal(mealId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Meal deleted'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  Color _getMealColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return AppColors.breakfastColor;
      case 'lunch':
        return AppColors.lunchColor;
      case 'dinner':
        return AppColors.dinnerColor;
      default:
        return AppColors.snackColor;
    }
  }

  Widget _getMealIcon(String mealType) {
    IconData iconData;
    Color iconColor;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        iconData = Icons.wb_sunny;
        iconColor = AppColors.breakfastColor;
        break;
      case 'lunch':
        iconData = Icons.restaurant;
        iconColor = AppColors.lunchColor;
        break;
      case 'dinner':
        iconData = Icons.nightlight;
        iconColor = AppColors.dinnerColor;
        break;
      default:
        iconData = Icons.fastfood;
        iconColor = AppColors.snackColor;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }
}

// Model class for meal events
class MealEvent {
  final String type;
  final String mealName;
  final String time;
  final Map<String, dynamic> data; // Store full document data

  MealEvent(this.type, this.mealName, this.time, this.data);
}

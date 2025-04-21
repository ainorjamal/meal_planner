// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

// Enhanced color palette
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
  
  // New enhanced colors
  static const Color backgroundGradientStart = Color(0xFF8265CD);
  static const Color backgroundGradientEnd = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFAFAFA);
}

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final String userId;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
    required this.userId,
  }) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String selectedMealType = 'Lunch'; // Default value
  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  // Function to show success notification
  void _showSuccessNotification(BuildContext context) {
    // Create an overlay entry
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.green,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Added to Meal Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Insert the overlay
    overlayState.insert(overlayEntry);
    
    // Automatically remove after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Function to add the recipe to Firestore favorites
  void _addToFavorites(BuildContext context) async {
    final favRef = FirebaseFirestore.instance.collection('favorites');
    
    // Check if the recipe is already in favorites
    final snapshot = await favRef
        .where('user_id', isEqualTo: widget.userId)
        .where('recipe_id', isEqualTo: widget.recipe.id)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // 🟡 Already in favorites
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.recipe.name} is already in Favorites'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // 🟢 Add to favorites
      favRef.add({
        'user_id': widget.userId,
        'recipe_id': widget.recipe.id,
        'recipe_name': widget.recipe.name,
        'image_url': widget.recipe.imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        // Clearer success feedback
        final snackBar = SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Success!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Added to Favorites',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 51, 38, 88),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 3),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to Favorites'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      });
    }
  }

  // Function to show the dialog for adding the meal schedule
  void _showAddToMealDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Reset selections
    setState(() {
      selectedDate = DateTime.now();
      selectedTime = TimeOfDay.now();
      selectedMealType = 'Lunch';
    });

    // Function to pick date
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime.now().subtract(Duration(days: 365)),
        lastDate: DateTime.now().add(Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryPurple,
                onPrimary: Colors.white,
                onSurface: AppColors.darkPurple,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null)
        setState(() {
          selectedDate = picked;
        });
    }

    // Function to pick time
    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryPurple,
                onPrimary: Colors.white,
                onSurface: AppColors.darkPurple,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null)
        setState(() {
          selectedTime = picked;
        });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add to Meal Schedule',
            style: TextStyle(
              color: AppColors.darkPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe preview
                  Center(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.recipe.imageUrl,
                            height: 120,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.recipe.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.darkPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Meal Type Selector
                  Text(
                    'Meal Type:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.darkPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondaryPurple.withOpacity(0.5),
                      ),
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMealType,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primaryPurple,
                        ),
                        items: mealTypes.map((String mealType) {
                          return DropdownMenuItem<String>(
                            value: mealType,
                            child: Text(mealType),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedMealType = newValue;
                            });
                            Navigator.pop(context);
                            _showAddToMealDialog(context);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Date picker
                  Text(
                    'Date:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.darkPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.secondaryPurple.withOpacity(0.5),
                        ),
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? 'Select Date'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: AppColors.primaryPurple,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Time picker
                  Text(
                    'Time:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.darkPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectTime(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.secondaryPurple.withOpacity(0.5),
                        ),
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime == null
                                ? 'Select Time'
                                : selectedTime!.format(context),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            color: AppColors.primaryPurple,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedDate != null && selectedTime != null) {
                  // Combine the selected date and time into a single DateTime object
                  DateTime scheduleDateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  // Add to meals collection in Firestore
                  FirebaseFirestore.instance.collection('meals').add({
                    'user_id': widget.userId,
                    'recipe_id': widget.recipe.id,
                    'recipe_name': widget.recipe.name,
                    'date': Timestamp.fromDate(scheduleDateTime),
                    'time': '${selectedTime!.format(context)}',
                    'mealType': selectedMealType,
                    'title': widget.recipe.name,
                    'image_url': widget.recipe.imageUrl,
                    'created_at': FieldValue.serverTimestamp(),
                  }).then((_) {
                    // Close the dialog first
                    Navigator.pop(context);
                    
                    // Show a more prominent notification at the top
                    _showSuccessNotification(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add to Meal Plan'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select both date and time'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text('Add to Plan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      // Enhanced AppBar with proper colors and white back arrow
      appBar: AppBar(
        title: Text(
          widget.recipe.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        // White back button as requested
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () => _addToFavorites(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? AppColors.darkPurple : AppColors.backgroundGradientStart,
              isDarkMode ? Colors.black : AppColors.backgroundGradientEnd,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced recipe image with rounded corners and better shadow
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Hero(
                    tag: 'recipe-${widget.recipe.id}',
                    child: Image.network(
                      widget.recipe.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPurple,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Enhanced recipe details card
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isDarkMode ? Color(0xFF282828) : AppColors.cardBackground,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe category with enhanced styling
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppColors.darkPurple : AppColors.lightPurple,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryPurple.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.recipe.category,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : AppColors.darkPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Spacer(),
                          // Enhanced rating stars
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < 4 ? Icons.star : Icons.star_border,
                                color: AppColors.breakfastColor,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // Recipe ingredients section with enhanced styling
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            color: AppColors.secondaryPurple,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.darkPurple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Display ingredients with enhanced styling
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIngredientItem('2 cups flour'),
                          _buildIngredientItem('1 cup sugar'),
                          _buildIngredientItem('2 eggs'),
                          _buildIngredientItem('1/2 cup milk'),
                          _buildIngredientItem('1 tsp vanilla extract'),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Recipe instructions section with enhanced styling
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: AppColors.secondaryPurple,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.darkPurple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        widget.recipe.instructions
                          .trim()
                          .split('\n')
                          .map((paragraph) => '\t$paragraph')
                          .join('\n\n'), // adds space between paragraphs
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontFamily: 'Poppins', 
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Enhanced action buttons
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text(
                    'Add to Meal Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primaryPurple.withOpacity(0.5),
                  ),
                  onPressed: () => _showAddToMealDialog(context),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  // Enhanced helper method to build ingredient item
  Widget _buildIngredientItem(String ingredient) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.secondaryPurple,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Text(
            ingredient,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Extend this design style to other screens as needed
class MealHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meal History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        centerTitle: true,
        // White back button as in the reference image
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh functionality
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Meal history header card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.primaryPurple,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal History',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You have 16 meals in your history',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Month header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightPurple,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'April 2025',
                style: TextStyle(
                  color: AppColors.darkPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Meal item
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lightPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: AppColors.darkPurple,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Migas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Uncategorized',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'April 12, 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryPurple,
                ),
                onTap: () {
                  // Navigate to meal details
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
                      

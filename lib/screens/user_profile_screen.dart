// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isDarkMode = false;

  Future<String?> _showPasswordPrompt(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Confirm Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Enter your password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(passwordController.text.trim()),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: _buildProfileContent(),
    );
  }

  // Profile content with user details
  Widget _buildProfileContent() {
    // Get current user from Firebase Auth
    final User? currentUser = authService.value.currentUser;

    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'User not logged in',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authService.value.signOut();
              },
              child: Text('Return to Login'),
            ),
          ],
        ),
      );
    }

    // Get user email from Firebase Auth
    final String userEmail = currentUser.email ?? 'No email available';
    final String userId = currentUser.uid;

    // Return the profile UI with Firestore data
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading profile: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // Get user data from Firestore
        Map<String, dynamic>? userData =
            snapshot.data?.data() as Map<String, dynamic>?;

        // Default username if not set in Firestore
        String userName = userData?['displayName'] ?? 'User';
        String photoUrl = userData?['photoUrl'] ?? '';

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile picture
              photoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(photoUrl),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
              SizedBox(height: 16),

              // User name
              Text(
                userName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // User email
              Text(userEmail, style: TextStyle(color: Colors.grey)),
              SizedBox(height: 32),

              // Edit profile button
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                onPressed: () {
                  _showEditProfileDialog(context, userName);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
              SizedBox(height: 24),

              // Divider
              Divider(),

              // Settings and options
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  // Navigate to settings screen
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite),
                title: Text('Favorite Recipes'),
                onTap: () {
                  // Navigate to favorites screen
                },
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text('Meal History'),
                onTap: () {
                  // Navigate to meal history screen
                },
              ),
              ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Support'),
                onTap: () {
                  // Navigate to help screen
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Logout'),
                          content: Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Logout'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (confirm) {
                    // Sign out the user
                    await authService.value.signOut();

                    // Redirect to login screen
                    Navigator.pushReplacementNamed(context, '/login'); // Make sure to set up your route for login
                  }
                },
              ),

              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Delete Account', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  bool confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text('Delete Account'),
                              content: Text(
                                  'Are you sure you want to delete your account? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                      ) ??
                      false;

                  if (confirmDelete) {
                    final user = authService.value.currentUser;
                    if (user != null) {
                      try {
                        // Delete user data in Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .delete();

                        // Delete Firebase user account
                        await user.delete();

                        // Navigate to login screen
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting account: $e')),
                        );
                      }
                    }
                  }
                },
              ),

              // Add statistics section
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),

              Text(
                'Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // User stats cards
              Row(
                children: [
                  _buildStatCard('Total Meals', '42', Icons.restaurant),
                  SizedBox(width: 12),
                  _buildStatCard('Favorites', '7', Icons.favorite),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('This Week', '12', Icons.calendar_today),
                  SizedBox(width: 12),
                  _buildStatCard(
                    'Streak',
                    '5 days',
                    Icons.local_fire_department,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build stat cards
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Theme.of(context).primaryColor),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show the edit profile dialog
  void _showEditProfileDialog(BuildContext context, String currentName) {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display name field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // New password field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Confirm new password field
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),

              // Password requirements info (optional, can be styled further)
              Text(
                'Password must be at least 8 characters long, and contain a number and a letter.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Get the current user ID
              final User? user = authService.value.currentUser;
              if (user != null) {
                String displayName = nameController.text.trim();
                String newPassword = passwordController.text.trim();
                String confirmPassword = confirmPasswordController.text.trim();

                // Validate display name and password
                if (displayName.isNotEmpty) {
                  try {
                    // Update display name in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({
                      'displayName': displayName,
                      // Keep other fields that might exist in the document
                    }, SetOptions(merge: true));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating profile: $e')),
                    );
                    return;
                  }
                }

                if (newPassword.isNotEmpty && newPassword == confirmPassword) {
                  try {
                    // Re-authenticate the user to change password
                    final AuthCredential credential =
                        EmailAuthProvider.credential(
                            email: user.email!, password: "CurrentPassword"); // Replace with current password

                    await user.reauthenticateWithCredential(credential);

                    // Change password
                    await user.updatePassword(newPassword);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password updated successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error changing password: $e')),
                    );
                  }
                }

                Navigator.of(context).pop();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

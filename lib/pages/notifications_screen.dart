import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isNotificationsEnabled = true;
  bool _isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load the saved notification and sound preferences
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationsEnabled = prefs.getBool('isNotificationsEnabled') ?? true;
      _isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
    });
  }

  // Save the preferences to SharedPreferences
  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationsEnabled', _isNotificationsEnabled);
    await prefs.setBool('isSoundEnabled', _isSoundEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // Notification toggle
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _isNotificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _isNotificationsEnabled = value;
              });
              _saveSettings(); // Save the new value
            },
          ),
          const SizedBox(height: 10),
          // Sound toggle
          SwitchListTile(
            title: const Text('Enable Sound'),
            value: _isSoundEnabled,
            onChanged: (bool value) {
              setState(() {
                _isSoundEnabled = value;
              });
              _saveSettings(); // Save the new value
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PreferencesSettingsPage extends StatefulWidget {
  const PreferencesSettingsPage({super.key});

  @override
  State<PreferencesSettingsPage> createState() => _PreferencesSettingsPageState();
}

class _PreferencesSettingsPageState extends State<PreferencesSettingsPage> {
  String _selectedLanguage = 'English';
  String _selectedTimezone = 'GMT+8 (Philippines)';

  final List<String> languages = ['English', 'Filipino'];
  final List<String> timezones = [
    'GMT-5 (New York)',
    'GMT+0 (London)',
    'GMT+8 (Philippines)',
    'GMT+9 (Japan)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _selectedLanguage,
            items: languages.map((String lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(lang),
              );
            }).toList(),
            onChanged: (String? newLang) {
              setState(() {
                _selectedLanguage = newLang!;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language set to $_selectedLanguage')),
              );
            },
          ),
          const SizedBox(height: 20),

          const Text('Timezone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: _selectedTimezone,
            items: timezones.map((String tz) {
              return DropdownMenuItem<String>(
                value: tz,
                child: Text(tz),
              );
            }).toList(),
            onChanged: (String? newTz) {
              setState(() {
                _selectedTimezone = newTz!;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Timezone set to $_selectedTimezone')),
              );
            },
          ),
        ],
      ),
    );
  }
}

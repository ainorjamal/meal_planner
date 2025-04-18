import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _feedbackController = TextEditingController();

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hershey.doria@carsu.edu.ph',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  void _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback.')),
      );
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hershey.doria@carsu.edu.ph',
      queryParameters: {
        'subject': 'App Feedback',
        'body': feedback,
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqItems = [
      {
        'question': 'How do I reset my password?',
        'answer':
            'You can reset your password by going to the login screen and tapping "Forgot Password", or by going to Edit Profile in your Profile Page.'
      },
      {
        'question': 'How can I contact support?',
        'answer':
            'You can email us at hershey.doria@carsu.edu.ph. You may also call during working hours for urgent concerns.'
      },
      {
        'question': 'Is there a tutorial for using the app?',
        'answer':
            'We are currently working on in-app tutorials. For now, please reach out to support if you need help navigating the app.'
      },
      {
        'question': 'My app is not working correctly. What should I do?',
        'answer':
            'Try restarting the app and checking your internet connection. If the problem persists, contact support with a detailed description.'
      },
      {
        'question': 'Can I update my personal information?',
        'answer':
            'Yes. Go to your Profile Page and tap Edit Profile to update your information.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...faqItems.map((item) => ExpansionTile(
                  title: Text(item['question']!),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(item['answer']!),
                    ),
                    const SizedBox(height: 8),
                  ],
                )),
            const SizedBox(height: 32),
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.email),
              label: const Text('Email Us at hershey.doria@carsu.edu.ph'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Support'),
              subtitle: const Text('+63 912 345 6789'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calling feature not yet implemented.'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Support Hours'),
              subtitle: const Text('Monday to Friday, 9:00 AM - 5:00 PM'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Send Feedback',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your feedback here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _submitFeedback,
              icon: const Icon(Icons.send),
              label: const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}

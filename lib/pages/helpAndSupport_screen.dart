import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> with SingleTickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Enhanced color palette - can be used selectively for dark or light themes
  final Color primaryPurple = const Color(0xFF6750A4);
  final Color secondaryPurple = const Color(0xFF9A82DB);
  final Color lightPurple = const Color(0xFFE6DFFF);
  final Color darkPurple = const Color(0xFF4A3880);
  final Color accentPurple = const Color(0xFFB69DF8);
  final Color subtlePurple = const Color(0xFFF6F2FF);

  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  Color get _backgroundColor => _isDarkTheme ? Colors.black : Colors.white;
  Color get _textColor => _isDarkTheme ? Colors.white : Colors.black87;
  Color get _inputFillColor => _isDarkTheme ? Colors.grey[900]! : Colors.grey[200]!;
  Color get _snackBarColor => _isDarkTheme ? darkPurple : primaryPurple;
  Color get _buttonColor => _isDarkTheme ? accentPurple : primaryPurple;

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hershey.doria@carsu.edu.ph',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      _showSnackBar('Could not open email app.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: _snackBarColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _submitFeedback() async {
    HapticFeedback.mediumImpact();

    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      _showSnackBar('Please enter your feedback.');
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
      _feedbackController.clear();
    } else {
      _showSnackBar('Could not open email app.');
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _animationController.dispose();
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
    backgroundColor: _backgroundColor, // use dynamic background color
    appBar: AppBar(
      backgroundColor: _buttonColor, // use dynamic primary color
      elevation: 0,
      title: Text(
        'Help & Support',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _textColor,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: _textColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: _textColor),
          tooltip: 'Refresh',
          onPressed: () {
            HapticFeedback.lightImpact();
            _showSnackBar('Refreshed');
          },
        ),
      ],
      shape: RoundedRectangleBorder(),
    ),
    body: FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkTheme
                ? [Colors.grey[900]!, Colors.black]
                : [subtlePurple, Colors.white],
            stops: const [0.0, 0.6],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // Stylish Header Section
            Container(
              margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? [darkPurple, primaryPurple]
                      : [secondaryPurple, primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _isDarkTheme
                        ? primaryPurple.withOpacity(0.8)
                        : secondaryPurple.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_isDarkTheme ? 0.1 : 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(_isDarkTheme ? 0.3 : 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Help & Support',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We\'re here to help you with any issue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // FAQ Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer_rounded,
                    color: _buttonColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // FAQ list container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _inputFillColor,
                boxShadow: [
                  BoxShadow(
                    color: _isDarkTheme
                        ? Colors.black.withOpacity(0.9)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: faqItems.length,
                  separatorBuilder: (context, index) => Divider(
                    color: _isDarkTheme ? Colors.grey[800] : lightPurple,
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        colorScheme: ColorScheme.light(
                          primary: primaryPurple,
                        ),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(
                          faqItems[index]['question']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        collapsedIconColor: _buttonColor,
                        iconColor: accentPurple,
                        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        expandedAlignment: Alignment.topLeft,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isDarkTheme ? Colors.grey[850] : subtlePurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              faqItems[index]['answer']!,
                              style: TextStyle(
                                color: _isDarkTheme ? Colors.grey[300] : Colors.grey[800],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Contact Support Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.contact_support_rounded,
                    color: _buttonColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Contact cards container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _inputFillColor,
                boxShadow: [
                  BoxShadow(
                    color: _isDarkTheme
                        ? Colors.black.withOpacity(0.9)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ContactTile(
                    icon: Icons.email_rounded,
                    title: 'Email Us',
                    subtitle: 'hershey.doria@carsu.edu.ph',
                    iconBgColor: _isDarkTheme ? darkPurple : lightPurple,
                    iconColor: _isDarkTheme ? accentPurple : primaryPurple,
                    onTap: _launchEmail,
                    textColor: _textColor,
                  ),
                  _buildDivider(color: _isDarkTheme ? Colors.grey[800]! : lightPurple),
                  ContactTile(
                    icon: Icons.phone_rounded,
                    title: 'Call Support',
                    subtitle: '+63 912 345 6789',
                    iconBgColor: _isDarkTheme ? darkPurple : lightPurple,
                    iconColor: _isDarkTheme ? accentPurple : primaryPurple,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showSnackBar('Calling feature not yet implemented.');
                    },
                    textColor: _textColor,
                  ),
                  _buildDivider(color: _isDarkTheme ? Colors.grey[800]! : lightPurple),
                  ContactTile(
                    icon: Icons.chat_rounded,
                    title: 'Chat with Us',
                    subtitle: 'Open live chat support',
                    iconBgColor: _isDarkTheme ? darkPurple : lightPurple,
                    iconColor: _isDarkTheme ? accentPurple : primaryPurple,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showSnackBar('Chat support is currently offline.');
                    },
                    textColor: _textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

          // Feedback section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.feedback_rounded, color: _buttonColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Send Feedback',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                minLines: 3,
                style: TextStyle(color: _textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _inputFillColor,
                  hintText: 'Enter your feedback here...',
                  hintStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitFeedback,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Email Us',
                    icon: Icon(Icons.email_rounded, color: _buttonColor),
                    onPressed: _launchEmail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

Divider _buildDivider({required Color color}) => Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: color,
    );

class ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final Function()? onTap;
  final Color? textColor;

  const ContactTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    this.textColor, 
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A3880),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF9A82DB),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
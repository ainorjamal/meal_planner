import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  final introKey = GlobalKey<IntroductionScreenState>();

  OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A148C),
              Color(0xFF6A1B9A),
              Colors.white
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                IntroductionScreen(
                  key: introKey,
                  globalBackgroundColor: Colors.transparent,
                  pages: [
                    _animatedPage(
                      title: "Welcome",
                      body: "Plan meals, track favorites, and manage your health easily.",
                      imagePath: 'assets/images/Meal Planner (4).png',
                    ),
                    _animatedPage(
                      title: "Notifications",
                      body: "Stay on schedule with meal reminders.",
                      imagePath: 'assets/images/notifications.png',
                    ),
                    _animatedPage(
                      title: "Customize",
                      body: "Adjust settings and personalize your preferences.",
                      imagePath: 'assets/images/customize.png',
                    ),
                  ],
                  onDone: () => _onIntroEnd(context),
                  onSkip: () => _onIntroEnd(context),
                  showSkipButton: true,
                  skip: const Text("Skip", style: TextStyle(color: Colors.deepPurple)),
                  next: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
                  done: const Text("Done", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                  dotsDecorator: getDotDecoration(),
                ),

                // Top Floating Icons
                PositionedFloatingIcon(icon: Icons.restaurant_menu, left: 20, top: 60, size: 40, durationMs: 3000),
                PositionedFloatingIcon(icon: Icons.local_pizza, left: 120, top: 40, size: 45, durationMs: 3500),
                PositionedFloatingIcon(icon: Icons.fastfood, right: 50, top: 70, size: 38, durationMs: 2800),

                // Bottom Floating Icons
                PositionedFloatingIcon(icon: Icons.ramen_dining, left: 10, bottom: 100, size: 40, durationMs: 4000),
                PositionedFloatingIcon(icon: Icons.icecream, left: 80, bottom: 200, size: 42, durationMs: 3500),
                PositionedFloatingIcon(icon: Icons.cake, left: 130, bottom: 300, size: 38, durationMs: 3200),
                PositionedFloatingIcon(icon: Icons.local_cafe, right: 150, bottom: 300, size: 45, durationMs: 3700),
                PositionedFloatingIcon(icon: Icons.set_meal, right: 40, bottom: 250, size: 50, durationMs: 4000),
                PositionedFloatingIcon(icon: Icons.restaurant_menu, right: 10, bottom: 150, size: 35, durationMs: 2800),
              ],
            );
          },
        ),
      ),
    );
  }

  PageViewModel _animatedPage({required String title, required String body, required String imagePath}) {
    return PageViewModel(
      titleWidget: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Padding(
            padding: EdgeInsets.only(top: (1 - value) * 20), // smoother entrance
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
      ),
      bodyWidget: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Padding(
            padding: EdgeInsets.only(top: value * 10),
            child: Text(
              body,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontFamily: 'OpenSans',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      image: Image.asset(imagePath, height: 250),
      decoration: getPageDecoration(),
    );
  }

  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.of(context).pushReplacementNamed('/login');
  }

  PageDecoration getPageDecoration() => const PageDecoration(
        imagePadding: EdgeInsets.all(24),
        pageColor: Colors.transparent,
      );

  DotsDecorator getDotDecoration() => const DotsDecorator(
        activeColor: Colors.deepPurple,
        color: Colors.deepPurple,
        size: Size(10, 10),
        activeSize: Size(22, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      );
}

// Move this class outside OnboardingScreen:
class PositionedFloatingIcon extends StatefulWidget {
  final IconData icon;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final int durationMs;

  const PositionedFloatingIcon({
    super.key,
    required this.icon,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.size = 40,
    this.durationMs = 3000,
  });

  @override
  _PositionedFloatingIconState createState() => _PositionedFloatingIconState();
}

class _PositionedFloatingIconState extends State<PositionedFloatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 15).animate(
    CurvedAnimation(parent: _controller, curve: Curves.bounceInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: widget.left,
          right: widget.right,
          top: widget.top != null ? widget.top! + _animation.value : null,
          bottom: widget.bottom != null ? widget.bottom! + _animation.value : null,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: Colors.white.withOpacity(0.7),
          ),
        );
      },
    );
  }
}

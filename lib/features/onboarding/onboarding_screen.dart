import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: "HABESHA EXCELLENCE",
      subtitle: "Join the most exclusive community of high-achieving Habesha professionals.",
      icon: Icons.auto_awesome,
      color: AppColors.gold,
    ),
    OnboardingData(
      title: "SMART MATCHING",
      subtitle: "Our AI-driven algorithm matches you based on values, heritage, and goals.",
      icon: Icons.psychology,
      color: AppColors.gold,
    ),
    OnboardingData(
      title: "NEARBY DISCOVERY",
      subtitle: "Find elite connections just around the corner with precise location-based discovery.",
      icon: Icons.near_me,
      color: AppColors.gold,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) => OnboardingPage(data: _onboardingData[index]),
          ),
          
          // TOP NAVIGATION
          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: const Text("Skip", style: TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          ),

          // BOTTOM CONTROLS
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.gold : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Button
                _currentPage == _onboardingData.length - 1
                    ? ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text("GET STARTED"),
                      )
                    : IconButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.arrow_forward_ios, color: AppColors.gold),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  final OnboardingData data;
  const OnboardingPage({required this.data, super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.data.color.withValues(alpha: 0.1),
                ),
                child: Icon(widget.data.icon, size: 100, color: widget.data.color),
              ),
            ),
          ),
          const SizedBox(height: 60),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    widget.data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.data.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  OnboardingData({required this.title, required this.subtitle, required this.icon, required this.color});
}

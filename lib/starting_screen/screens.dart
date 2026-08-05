import 'package:flutter/material.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/starting_screen/models/onboarding_model.dart';
import 'package:mecha_connect/starting_screen/widgets/onboarding_button.dart';
import 'package:mecha_connect/starting_screen/widgets/onboarding_indicator.dart';
import 'package:mecha_connect/starting_screen/widgets/onboarding_page.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color _lightBg = Color(0xFFFEF7FF);

  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slides = OnboardingModel.slides;
    final currentAccent = slides[_currentPage].accent;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : _lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.grey500,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    slide: slides[index],
                    isDark: isDark,
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: Column(
                children: [
                  // Page indicator dots
                  OnboardingIndicator(
                    count: slides.length,
                    currentIndex: _currentPage,
                    activeColor: currentAccent,
                  ),
                  const SizedBox(height: 28),

                  // Get Started / Next button
                  OnboardingButton(
                    label: _currentPage == slides.length - 1
                        ? 'Get Started'
                        : 'Next',
                    color: currentAccent,
                    onPressed: () {
                      if (_currentPage < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _navigateToLogin();
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Continue as Guest (last page only)
                  if (_currentPage == slides.length - 1)
                    TextButton(
                      onPressed: _navigateToLogin,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                      ),
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grey500,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

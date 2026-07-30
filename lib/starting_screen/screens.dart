import 'package:flutter/material.dart';
import 'package:mecha_connect/auth/login_screen.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color _accentLightBg = Color(0xFFFEF7FF);

  final List<_SlideData> _slides = const [
    _SlideData(
      title: 'Your Smart Vehicle Companion',
      description:
          'Track, maintain, and manage your vehicle effortlessly.\nEverything you need, right at your fingertips.',
      accent: AppColors.brandOrange,
      icons: [
        _IconData(Icons.smart_toy_rounded, AppColors.brandOrange),
        _IconData(Icons.speed_rounded, AppColors.brandOrangeLight),
        _IconData(Icons.electric_rickshaw_rounded, AppColors.brandOrange),
      ],
    ),
    _SlideData(
      title: 'Roadside Help in Minutes',
      description:
          'Breakdown, flat tyre, or battery dead?\nGet instant help from nearby mechanics.',
      accent: AppColors.brandBlue,
      icons: [
        _IconData(Icons.build_rounded, AppColors.brandBlue),
        _IconData(Icons.support_agent_rounded, AppColors.brandBlueLight),
        _IconData(Icons.two_wheeler_rounded, AppColors.brandBlue),
      ],
    ),
    _SlideData(
      title: 'Everything Your Vehicle Needs',
      description:
          'Fuel delivery, spare parts, servicing, and AI diagnostics —\none app for all your vehicle needs.',
      accent: AppColors.success,
      icons: [
        _IconData(Icons.local_gas_station_rounded, AppColors.success),
        _IconData(Icons.settings_suggest_rounded, AppColors.success),
        _IconData(Icons.precision_manufacturing_rounded, AppColors.success),
      ],
    ),
    _SlideData(
      title: 'Ready to Drive Smarter?',
      description:
          'Join thousands of vehicle owners who trust Mecha Connect\nfor smarter, faster vehicle care.',
      accent: AppColors.grey500,
      icons: [
        _IconData(Icons.rocket_launch_rounded, AppColors.brandOrange),
        _IconData(Icons.auto_awesome_rounded, AppColors.grey500),
        _IconData(Icons.map_rounded, AppColors.grey500),
      ],
    ),
  ];

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
    final bgColor = isDark ? AppColors.darkBg : _accentLightBg;

    return Scaffold(
      backgroundColor: bgColor,
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
                itemCount: _slides.length,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    slide: _slides[index],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = _currentPage == index;
                      final accent = _slides[_currentPage].accent;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: isActive ? 32 : 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? accent
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.grey200),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Get Started / Next button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage].accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToLogin();
                        }
                      },
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue as Guest (last page only)
                  if (_currentPage == _slides.length - 1)
                    TextButton(
                      onPressed: _navigateToLogin,
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

class _SlideData {
  final String title;
  final String description;
  final Color accent;
  final List<_IconData> icons;

  const _SlideData({
    required this.title,
    required this.description,
    required this.accent,
    required this.icons,
  });
}

class _IconData {
  final IconData icon;
  final Color color;

  const _IconData(this.icon, this.color);
}

class _OnboardingPage extends StatelessWidget {
  final _SlideData slide;
  final bool isDark;

  const _OnboardingPage({
    required this.slide,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.textPrimary;
    final subTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ConstrainedContent(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon cluster
            SizedBox(
              height: AppResponsive.scale(context, 180),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Bottom-left icon
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: _buildIconCircle(
                      context,
                      slide.icons[0].icon,
                      slide.icons[0].color,
                      60,
                    ),
                  ),
                  // Top-right icon
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _buildIconCircle(
                      context,
                      slide.icons[1].icon,
                      slide.icons[1].color,
                      60,
                    ),
                  ),
                  // Center main icon (larger)
                  _buildIconCircle(
                    context,
                    slide.icons[2].icon,
                    slide.accent,
                    80,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Title
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: AppResponsive.scaleFont(context, 26),
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppResponsive.scaleFont(context, 15),
                fontWeight: FontWeight.w400,
                color: subTextColor,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle(
    BuildContext context,
    IconData icon,
    Color color,
    double size,
  ) {
    final containerSize = AppResponsive.scale(context, size);
    final iconSize = AppResponsive.scaleIcon(context, size * 0.45);

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

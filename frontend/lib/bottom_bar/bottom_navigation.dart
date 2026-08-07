import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mecha_connect/bottom_bar/order_screen.dart';
import 'package:mecha_connect/features/ai/screens/ai_home_screen.dart';
import 'package:mecha_connect/features/home/screens/home_screen.dart';
import 'package:mecha_connect/features/profile/screens/profile_screen.dart';
import 'package:mecha_connect/starting_screen/home.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  late final List<Widget> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = [
      const HomeDashboard(),
      const ServiceSelectionScreen(),
      Orderscreen(onExploreServices: () => _switchToTab(1)),
      const AiHomeScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _navItems),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border(top: BorderSide(color: context.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: GNav(
              gap: 4,
              activeColor: context.accent,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              duration: const Duration(milliseconds: 250),
              tabBackgroundColor: context.accent.withValues(alpha: 0.08),
              tabBorderRadius: 12,
              color: context.textTertiary,
              selectedIndex: _currentIndex,
              onTabChange: (value) {
                if (_currentIndex != value) {
                  setState(() => _currentIndex = value);
                }
              },
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GButton(
                  icon: Icons.build_rounded,
                  text: 'Services',
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GButton(
                  icon: Icons.receipt_long_rounded,
                  text: 'Orders',
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GButton(
                  icon: Icons.auto_awesome_rounded,
                  text: 'AI',
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GButton(
                  icon: Icons.person_rounded,
                  text: 'Profile',
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

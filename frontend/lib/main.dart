import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mecha_connect/starting_screen/screens.dart';
import 'package:mecha_connect/features/auth/screens/login_screen.dart';
import 'package:mecha_connect/bottom_bar/bottom_navigation.dart';
import 'package:mecha_connect/theme/app_theme.dart';
import 'package:mecha_connect/theme/theme_provider.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/features/fuel_delivery/providers/fuel_provider.dart';
import 'package:mecha_connect/features/marketplace/providers/marketplace_provider.dart';
import 'package:mecha_connect/app_wiring.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("ENV LOAD FAILED: $e");
  }

  final locationProvider = LocationProvider();
  final fuelProvider = FuelProvider(locationProvider: locationProvider);
  final marketplaceProvider = MarketplaceProvider();

  runApp(
    MultiProvider(
      providers: buildRootProviders(
        locationProvider: locationProvider,
        fuelProvider: fuelProvider,
        marketplaceProvider: marketplaceProvider,
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.enableDevicePreview = kDebugMode,
    this.navigatorObservers = const [],
  });

  final bool enableDevicePreview;
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return DevicePreview(
      enabled: enableDevicePreview,
      builder:
          (context) => MaterialApp(
            // ignore: deprecated_member_use — required by DevicePreview
            useInheritedMediaQuery: true,
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            debugShowCheckedModeBanner: false,
            title: 'Mecha Connect',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            navigatorObservers: navigatorObservers,
            initialRoute: '/',
            routes: {'/': (context) => const SplashScreen()},
          ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SPLASH SCREEN — Sprint 1.1 FINAL (Locked v0.6.1)
// Logo only. No text. No circle. No texture. No particles.
// Premium layered surface. Natural ambient light.
// The permanent Mecha Connect brand introduction.
// ══════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _glowController;

  late final Animation<double> _bgFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _bgFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeOut));

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _startAnimationSequence();
  }

  // ── Animation Timeline (v0.6.2 — Optimized) ────────────────────
  //
  // First Launch (≈2.5 seconds — max):
  // 0.0s — Background fades in (300ms)
  // 0.1s — Logo fades in + scales 0.94→1.0 (500ms)
  // 0.6s — Logo visible, glow starts breathing (2000ms cycle)
  // 0.6s — Hold (1450ms)
  // 2.05s — Fade transition (450ms)
  // 2.5s — Next screen visible
  //
  // Returning User (≈2.0 seconds):
  // 0.0s — Background fades in (300ms)
  // 0.1s — Logo fades in (500ms)
  // 0.6s — Logo visible, hold (950ms)
  // 1.55s — Fade transition (450ms)
  // 2.0s — Next screen visible
  //
  Future<void> _startAnimationSequence() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    _bgController.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    _glowController.repeat(reverse: true);

    final Duration holdDuration =
        onboardingCompleted
            ? const Duration(milliseconds: 950)
            : const Duration(milliseconds: 1450);

    await Future.delayed(holdDuration);

    if (mounted) {
      _navigateToNext();
    }
  }

  Future<void> _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!mounted) return;

    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    final Widget target =
        isLoggedIn
            ? const BottomNavigation()
            : onboardingCompleted
            ? const LoginScreen()
            : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD — Logo Only. No Text. No Circle. No Texture.
  // Premium layered surface. Natural ambient light.
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final logoSize = AppResponsive.responsive<double>(
      context,
      mobile: screenHeight * 0.33,
      tablet: screenHeight * 0.30,
      desktop: screenHeight * 0.24,
    );

    final glowOpacity = 0.02 + (_glowController.value * 0.03);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _logoController,
          _glowController,
        ]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFAF8F5),
                  Color(0xFFF6F2EC),
                  Color(0xFFEFE9E0),
                  Color(0xFFE8E0D5),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                _buildRadialLight(screenWidth, screenHeight),
                _buildAmbientGlow(screenWidth, screenHeight, glowOpacity),
                SafeArea(
                  child: Center(
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Image.asset(
                          'assets/no_bg.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Radial Light — subtle center warmth in background ───────────
  Widget _buildRadialLight(double screenWidth, double screenHeight) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Opacity(
        opacity: _bgFade.value,
        child: CustomPaint(
          painter: const _RadialLightPainter(),
          size: Size(screenWidth, screenHeight),
        ),
      ),
    );
  }

  // ── Ambient Glow — natural sunlight behind logo, breathing ──────
  Widget _buildAmbientGlow(
    double screenWidth,
    double screenHeight,
    double opacity,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Opacity(
        opacity: _bgFade.value,
        child: CustomPaint(
          painter: _AmbientGlowPainter(opacity: opacity),
          size: Size(screenWidth, screenHeight),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Radial Light Painter — premium layered background lighting
// A very soft warm radial that adds depth to the surface
// ══════════════════════════════════════════════════════════════════════

class _RadialLightPainter extends CustomPainter {
  const _RadialLightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final radius = size.height * 0.55;

    final paint =
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x0AFFFFFF), Color(0x00FFFFFF)],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════
// Ambient Glow Painter — natural sunlight behind logo
// Soft, blurred, extends ~45% of screen height
// Breathing: 2%→5% opacity (subconscious warmth)
// No visible edges. No obvious circle.
// ══════════════════════════════════════════════════════════════════════

class _AmbientGlowPainter extends CustomPainter {
  final double opacity;

  _AmbientGlowPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.40);
    final radius = size.height * 0.45;

    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFF15A22).withValues(alpha: opacity),
              const Color(0xFFF15A22).withValues(alpha: opacity * 0.4),
              const Color(0xFFF15A22).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.3, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

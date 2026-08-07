import 'package:flutter/material.dart';
import 'package:mecha_connect/auth/auth_divider.dart';
import 'package:mecha_connect/auth/auth_header.dart';
import 'package:mecha_connect/auth/auth_scaffold.dart';
import 'package:mecha_connect/auth/auth_text_field.dart';
import 'package:mecha_connect/auth/bottom_link.dart';
import 'package:mecha_connect/auth/password_field.dart';
import 'package:mecha_connect/auth/primary_button.dart';
import 'package:mecha_connect/auth/social_button.dart';
import 'package:mecha_connect/features/auth/screens/sign_up_screen.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/auth/screens/forgot_password_screen.dart';
import 'package:mecha_connect/bottom_bar/bottom_navigation.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.savedEmail != null) {
      _emailController.text = auth.savedEmail!;
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      auth.login(_emailController.text.trim(), _passwordController.text).then((success) {
        if (!mounted) return;
        if (success) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BottomNavigation()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? 'Login failed'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const SignUpScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const ForgotPasswordScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BottomNavigation()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScaffold(
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: AppResponsive.scale(context, 72)),
                const AuthHeader(
                  title: 'Welcome to Mecha!',
                  subtitle: 'Sign in to your account',
                ),
                SizedBox(height: AppResponsive.scale(context, 34)),
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email or Username',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => auth.validateEmail(v),
                ),
                SizedBox(height: AppResponsive.scale(context, 12)),
                PasswordField(
                  controller: _passwordController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                SizedBox(height: AppResponsive.scale(context, 8)),
                Row(
                  children: [
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: Checkbox(
                        value: auth.rememberMe,
                        onChanged: (v) => auth.setRememberMe(v ?? false),
                        activeColor: AppColors.brandOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Remember Me',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _navigateToForgotPassword,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.brandOrange,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: AppResponsive.scaleFont(context, 13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.scale(context, 8)),
                PrimaryButton(
                  text: 'Login',
                  isLoading: auth.isLoading,
                  onPressed: _handleLogin,
                ),
                SizedBox(height: AppResponsive.scale(context, 8)),
                TextButton(
                  onPressed: _continueAsGuest,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.grey500,
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: AppResponsive.scaleFont(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: AppResponsive.scale(context, 20)),
                const AuthDivider(),
                SizedBox(height: AppResponsive.scale(context, 12)),
                SocialButton(
                  text: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  iconColor: const Color(0xFF4285F4),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Google Sign-In coming in Sprint 2'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                  SizedBox(height: AppResponsive.scale(context, 8)),
                  SocialButton(
                    text: 'Continue with Apple',
                    icon: Icons.apple_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Apple Sign-In coming in Sprint 2'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
                SizedBox(height: AppResponsive.scale(context, 26)),
                BottomLink(
                  prefix: "Don't have an account?",
                  linkText: 'Sign Up',
                  onTap: _navigateToSignUp,
                ),
                SizedBox(height: AppResponsive.scale(context, 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

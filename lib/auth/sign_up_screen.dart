import 'package:flutter/material.dart';
import 'package:mecha_connect/auth/auth_divider.dart';
import 'package:mecha_connect/auth/auth_header.dart';

import 'package:mecha_connect/auth/auth_scaffold.dart';
import 'package:mecha_connect/auth/auth_text_field.dart';
import 'package:mecha_connect/auth/bottom_link.dart';
import 'package:mecha_connect/auth/password_field.dart';
import 'package:mecha_connect/auth/password_strength.dart';
import 'package:mecha_connect/auth/primary_button.dart';
import 'package:mecha_connect/auth/social_button.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading = false;
  PasswordStrength _passwordStrength = PasswordStrength.empty;

  void _updatePasswordStrength(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordStrength = PasswordStrength.empty;
      } else if (value.length < 6) {
        _passwordStrength = PasswordStrength.weak;
      } else if (value.length < 8) {
        _passwordStrength = PasswordStrength.fair;
      } else if (value.length < 12 || !RegExp(r'[A-Z]').hasMatch(value)) {
        _passwordStrength = PasswordStrength.good;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      onBack: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: AppResponsive.scale(context, 72)),
            const AuthHeader(
              title: 'Create Account',
              subtitle: 'Join thousands of drivers using Mecha Connect',
            ),
            SizedBox(height: AppResponsive.scale(context, 36)),
            AuthTextField(
              controller: _nameController,
              hintText: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
            ),
            SizedBox(height: AppResponsive.scale(context, 14)),
            AuthTextField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            SizedBox(height: AppResponsive.scale(context, 14)),
            AuthTextField(
              controller: _phoneController,
              hintText: 'Phone Number (optional)',
              prefixIcon: Icons.phone_outlined,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: AppResponsive.scale(context, 14)),
            PasswordField(
              controller: _passwordController,
              hintText: 'Password',
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _updatePasswordStrength(_passwordController.text),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter a password';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            SizedBox(height: AppResponsive.scale(context, 6)),
            PasswordStrengthWidget(strength: _passwordStrength),
            SizedBox(height: AppResponsive.scale(context, 14)),
            PasswordField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            SizedBox(height: AppResponsive.scale(context, 16)),
            Row(
              children: [
                SizedBox(
                  height: 44,
                  width: 44,
                  child: Checkbox(
                    value: _agreeToTerms,
                    onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                    activeColor: AppColors.brandOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I agree to the Terms & Conditions and Privacy Policy',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppResponsive.scale(context, 24)),
            PrimaryButton(
              text: 'Create Account',
              isLoading: _isLoading,
              onPressed: _handleSignUp,
            ),
            SizedBox(height: AppResponsive.scale(context, 24)),
            const AuthDivider(text: 'or sign up with'),
            SizedBox(height: AppResponsive.scale(context, 16)),
            SocialButton(
              text: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              iconColor: const Color(0xFF4285F4),
            ),
            if (Theme.of(context).platform == TargetPlatform.iOS) ...[
              SizedBox(height: AppResponsive.scale(context, 12)),
              SocialButton(
                text: 'Continue with Apple',
                icon: Icons.apple_rounded,
              ),
            ],
            SizedBox(height: AppResponsive.scale(context, 32)),
            BottomLink(
              prefix: 'Already have an account?',
              linkText: 'Sign In',
              onTap: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: AppResponsive.scale(context, 16)),
          ],
        ),
      ),
    );
  }
}

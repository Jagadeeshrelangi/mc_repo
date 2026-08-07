import 'package:flutter/material.dart';
import 'package:mecha_connect/auth/auth_divider.dart';
import 'package:mecha_connect/auth/auth_header.dart';
import 'package:mecha_connect/auth/auth_scaffold.dart';
import 'package:mecha_connect/auth/auth_text_field.dart';
import 'package:mecha_connect/auth/bottom_link.dart';
import 'package:mecha_connect/auth/password_field.dart';
import 'package:mecha_connect/auth/primary_button.dart';
import 'package:mecha_connect/auth/social_button.dart';
import 'package:mecha_connect/features/auth/providers/auth_provider.dart';
import 'package:mecha_connect/features/auth/widgets/password_strength.dart';
import 'package:mecha_connect/bottom_bar/bottom_navigation.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:provider/provider.dart';

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
  final _vehicleNameController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleRegController = TextEditingController();

  bool _agreeToTerms = false;
  bool _showVehicleInfo = false;
  PasswordStrength _passwordStrength = PasswordStrength.empty;

  void _updatePasswordStrength(String value) {
    final auth = context.read<AuthProvider>();
    setState(() {
      _passwordStrength = auth.evaluatePasswordStrength(value);
    });
  }

  Future<void> _handleSignUp() async {
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

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleNameController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleRegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScaffold(
      showBack: true,
      onBack: () => Navigator.of(context).pop(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 4),
                const AuthHeader(
                  title: 'Create Account',
                  subtitle: 'Join thousands of drivers using Mecha Connect',
                ),
                SizedBox(height: AppResponsive.scale(context, 32)),
                AuthTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => auth.validateName(v),
                ),
                SizedBox(height: AppResponsive.scale(context, 14)),
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => auth.validateEmail(v),
                ),
                SizedBox(height: AppResponsive.scale(context, 14)),
                AuthTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number (optional)',
                  prefixIcon: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  validator: (v) => auth.validatePhone(v),
                ),
                SizedBox(height: AppResponsive.scale(context, 14)),
                PasswordField(
                  controller: _passwordController,
                  hintText: 'Password',
                  textInputAction: TextInputAction.next,
                  onChanged: _updatePasswordStrength,
                  validator: (v) => auth.validatePassword(v),
                ),
                SizedBox(height: AppResponsive.scale(context, 6)),
                PasswordStrengthWidget(strength: _passwordStrength),
                SizedBox(height: AppResponsive.scale(context, 14)),
                PasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignUp(),
                  validator: (v) => auth.validateConfirmPassword(v, _passwordController.text),
                ),
                SizedBox(height: AppResponsive.scale(context, 12)),
                // Remember Me
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
                  ],
                ),
                // Terms & Conditions
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'I agree to the Terms & Conditions and Privacy Policy',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.scale(context, 4)),
                // Vehicle Information (optional, collapsible)
                _buildVehicleToggle(isDark),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildVehicleFields(),
                  crossFadeState: _showVehicleInfo
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                SizedBox(height: AppResponsive.scale(context, 8)),
                PrimaryButton(
                  text: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: _handleSignUp,
                ),
                SizedBox(height: AppResponsive.scale(context, 20)),
                const AuthDivider(text: 'or sign up with'),
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
                  SizedBox(height: AppResponsive.scale(context, 12)),
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
                SizedBox(height: AppResponsive.scale(context, 28)),
                BottomLink(
                  prefix: 'Already have an account?',
                  linkText: 'Sign In',
                  onTap: () => Navigator.of(context).pop(),
                ),
                SizedBox(height: AppResponsive.scale(context, 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleToggle(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _showVehicleInfo = !_showVehicleInfo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.directions_car_rounded,
              size: 20,
              color: AppColors.brandOrange,
            ),
            const SizedBox(width: 10),
            Text(
              'Vehicle Information (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _showVehicleInfo ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more_rounded,
                size: 22,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          AuthTextField(
            controller: _vehicleNameController,
            hintText: 'Vehicle Name (e.g. Honda Activa)',
            prefixIcon: Icons.directions_car_rounded,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppResponsive.scale(context, 12)),
          AuthTextField(
            controller: _vehicleBrandController,
            hintText: 'Brand',
            prefixIcon: Icons.business_rounded,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppResponsive.scale(context, 12)),
          AuthTextField(
            controller: _vehicleModelController,
            hintText: 'Model',
            prefixIcon: Icons.model_training_rounded,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppResponsive.scale(context, 12)),
          AuthTextField(
            controller: _vehicleRegController,
            hintText: 'Registration Number',
            prefixIcon: Icons.confirmation_number_rounded,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

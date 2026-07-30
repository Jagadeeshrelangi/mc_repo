import 'package:flutter/material.dart';
import 'package:mecha_connect/auth/auth_header.dart';

import 'package:mecha_connect/auth/auth_scaffold.dart';
import 'package:mecha_connect/auth/auth_text_field.dart';
import 'package:mecha_connect/auth/primary_button.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSent = false;

  void _handleSend() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSent = true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      onBack: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _isSent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      children: [
        SizedBox(height: AppResponsive.scale(context, 72)),
        const AuthHeader(
          title: 'Forgot Password',
          subtitle: 'Enter your email address and we\'ll send you a reset link.',
        ),
        SizedBox(height: AppResponsive.scale(context, 34)),
        AuthTextField(
          controller: _emailController,
          hintText: 'Email',
          prefixIcon: Icons.email_outlined,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => _handleSend(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        SizedBox(height: AppResponsive.scale(context, 20)),
        PrimaryButton(
          text: 'Send Reset Link',
          onPressed: _handleSend,
        ),
        SizedBox(height: AppResponsive.scale(context, 12)),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      children: [
        SizedBox(height: AppResponsive.scale(context, 72)),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successLight,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 40,
            color: AppColors.success,
          ),
        ),
        SizedBox(height: AppResponsive.scale(context, 20)),
        const AuthHeader(
          title: 'Check Your Email',
          subtitle: 'We\'ve sent a password reset link to your email address. It may take a few minutes to arrive.',
        ),
        SizedBox(height: AppResponsive.scale(context, 34)),
        PrimaryButton(
          text: 'Back to Login',
          onPressed: () => Navigator.of(context).pop(),
        ),
        SizedBox(height: AppResponsive.scale(context, 12)),
      ],
    );
  }
}

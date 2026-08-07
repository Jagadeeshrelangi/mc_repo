import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF1A1612),
                    Color(0xFF1F1A15),
                    Color(0xFF251F19),
                  ]
                : const [
                    Color(0xFFFAF8F5),
                    Color(0xFFF6F2EC),
                    Color(0xFFEFE9E0),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppResponsive.responsive(context, mobile: 24.0, tablet: 48.0, desktop: 0.0),
                0,
                AppResponsive.responsive(context, mobile: 24.0, tablet: 48.0, desktop: 0.0),
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: AppResponsive.isDesktop(context)
                  ? SizedBox(width: 480, child: _buildBody(context, isDark))
                  : _buildBody(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton(
                onPressed: onBack ?? () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: isDark
                      ? const Color(0xFFC4B6A8).withValues(alpha: 0.82)
                      : const Color(0xFF7A6B60).withValues(alpha: 0.82),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 22),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

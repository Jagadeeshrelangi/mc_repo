import 'package:flutter/material.dart';
import 'package:mecha_connect/starting_screen/models/onboarding_model.dart';
import 'package:mecha_connect/starting_screen/widgets/floating_icon_cluster.dart';
import 'package:mecha_connect/starting_screen/widgets/glow_background.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel slide;
  final bool isDark;

  const OnboardingPage({
    super.key,
    required this.slide,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.textPrimary;
    final subTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final isLogoSlide = slide.icons.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: ConstrainedContent(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glow background + icon cluster or logo
            SizedBox(
              height: AppResponsive.scale(context, isLogoSlide ? 160 : 220),
              child: isLogoSlide ? _buildLogo(context) : _buildIconCluster(context),
            ),
            SizedBox(height: isLogoSlide ? 36 : 48),

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

  Widget _buildIconCluster(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GlowBackground(
          color: slide.glowColor,
          size: AppResponsive.scale(context, 260),
        ),
        FloatingIconCluster(
          icons: slide.icons,
          accent: slide.accent,
          containerSize: 200,
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.white;
    final size = AppResponsive.scale(context, 140);

    return Stack(
      alignment: Alignment.center,
      children: [
        GlowBackground(
          color: slide.glowColor,
          size: AppResponsive.scale(context, 200),
        ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandOrange.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.settings_suggest_rounded,
            size: AppResponsive.scaleIcon(context, 56),
            color: AppColors.brandOrange,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppAvatarSize { xs, sm, md, lg, xl, xxl }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AppAvatarSize size;
  final Color? backgroundColor;
  final IconData? icon;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppAvatarSize.md,
    this.backgroundColor,
    this.icon,
  });

  double get _dimensions {
    switch (size) {
      case AppAvatarSize.xs: return 24;
      case AppAvatarSize.sm: return 32;
      case AppAvatarSize.md: return 40;
      case AppAvatarSize.lg: return 56;
      case AppAvatarSize.xl: return 80;
      case AppAvatarSize.xxl: return 120;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppAvatarSize.xs: return 10;
      case AppAvatarSize.sm: return 12;
      case AppAvatarSize.md: return 14;
      case AppAvatarSize.lg: return 18;
      case AppAvatarSize.xl: return 24;
      case AppAvatarSize.xxl: return 32;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dimensions,
      height: _dimensions,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl == null ? const LinearGradient(colors: [AppColors.brandOrange, AppColors.brandOrangeDark]) : null,
        image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
      ),
      child: imageUrl == null
          ? Center(
              child: icon != null
                  ? Icon(icon, size: _fontSize + 8, color: AppColors.white)
                  : Text(
                      initials ?? '?',
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
            )
          : null,
    );
  }
}

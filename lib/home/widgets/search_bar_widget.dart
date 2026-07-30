import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

class HomeSearchBar extends StatelessWidget {
  final String hintText;

  const HomeSearchBar({
    super.key,
    this.hintText = 'What do you need today?',
  });

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Search'),
          ),
          body: Center(
            child: Text(
              'Search coming soon!',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        left: AppResponsive.horizontalPadding(context),
        right: AppResponsive.horizontalPadding(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: () => _navigateToSearch(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: isDark ? null : AppElevation.shadowLow,
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  hintText,
                  style: TextStyle(
                    fontSize: AppResponsive.scaleFont(context, 15),
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
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

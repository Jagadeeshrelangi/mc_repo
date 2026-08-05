import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/widgets/location_picker_sheet.dart';

class LocationHeader extends StatelessWidget {
  const LocationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.select<LocationProvider,
        ({String address, bool isLoading, bool isFetching, LocationPermissionState permission})>(
      (l) => (
        address: l.selectedAddress,
        isLoading: l.isLoadingLocation,
        isFetching: l.isFetchingAddress,
        permission: l.permissionState,
      ),
    );
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => _showLocationPicker(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grey200,
            width: 0.5,
          ),
          boxShadow: isDark ? AppElevation.shadowDarkLow : AppElevation.shadowLow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppColors.brandOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildAddressText(location, isDark),
                ],
              ),
            ),
            if (location.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandOrange,
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: isDark ? AppColors.darkTextSecondary : AppColors.grey500,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressText(
    ({String address, bool isLoading, bool isFetching, LocationPermissionState permission}) location,
    bool isDark,
  ) {
    final address = location.address;

    if (location.isFetching && address.isEmpty) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.brandOrange.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Detecting location...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    if (location.permission == LocationPermissionState.denied ||
        location.permission == LocationPermissionState.deniedForever) {
      return Row(
        children: [
          Icon(Icons.location_off_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Location access needed — tap to set manually',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (address.isEmpty) {
      return Text(
        'Tap to set delivery location',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      );
    }

    return Row(
      children: [
        Flexible(
          child: Text(
            address,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showLocationPicker(BuildContext context) {
    showLocationPickerSheet(context);
  }
}

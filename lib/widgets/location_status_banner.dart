import 'package:flutter/material.dart';
import 'package:mecha_connect/services/location_service.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// ONE banner widget for GPS location detection, shared by every screen that
/// collects an address (Fuel, Mechanic, Marketplace checkout, …).
///
/// Renders the right visual for each [LocationBannerState] inside a reserved,
/// constant-height box so the surrounding layout (text fields, Continue
/// button) never jumps between states. All copy and actions are identical
/// across screens — there is exactly one implementation of the detection UI.
class LocationStatusBanner extends StatelessWidget {
  const LocationStatusBanner({
    super.key,
    required this.state,
    required this.isDetecting,
    required this.onDetect,
    required this.onEnterManually,
    this.onOpenSettings,
    this.onEnableServices,
  });

  /// Current detection state; drives which banner is shown.
  final LocationBannerState state;

  /// True while a detection run is in flight (disables the retry/refresh
  /// actions and lets screens disable their address fields).
  final bool isDetecting;

  /// Re-runs the GPS-first detection pipeline.
  final VoidCallback onDetect;

  /// Switches the screen to manual address entry.
  final VoidCallback onEnterManually;

  /// Deep-links the user into app settings (deniedForever state).
  final VoidCallback? onOpenSettings;

  /// Re-checks/requests location services (serviceDisabled state).
  final VoidCallback? onEnableServices;

  /// Reserved height for the status area — never changes, so the layout below
  /// (fields, Continue) is pinned across all states.
  static const double reservedHeight = 108;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('location_status_area'),
      width: double.infinity,
      height: reservedHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.loose,
          clipBehavior: Clip.hardEdge,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: KeyedSubtree(
          key: ValueKey(state),
          child: LayoutBuilder(
            builder: (context, constraints) => OverflowBox(
              alignment: Alignment.topCenter,
              minWidth: 0,
              maxWidth: constraints.maxWidth,
              minHeight: 0,
              maxHeight: double.infinity,
              child: switch (state) {
                LocationBannerState.loading => _loading(context),
                LocationBannerState.success => _success(context),
                LocationBannerState.denied => _error(
                    context,
                    'Location permission denied.',
                    onRetry: onDetect,
                  ),
                LocationBannerState.deniedForever => _error(
                    context,
                    'Location permission blocked.',
                    onRetry: onOpenSettings,
                    retryLabel: 'Open Settings',
                  ),
                LocationBannerState.serviceDisabled => _error(
                    context,
                    'Location services are off.',
                    onRetry: onEnableServices,
                    retryLabel: 'Enable Services',
                  ),
                LocationBannerState.error => _error(
                    context,
                    'Unable to determine your location.',
                    onRetry: onDetect,
                  ),
                LocationBannerState.idle => _idle(context),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _loading(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Loading current location...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: 8,
        overflowSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location_rounded,
                  size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '📍 Current Location Detected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: isDetecting ? null : onDetect,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Use Current Location'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _idle(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: isDetecting ? null : onDetect,
        icon: const Icon(Icons.my_location_rounded, size: 16),
        label: const Text('Use Current Location'),
        style: TextButton.styleFrom(foregroundColor: AppColors.brandBlue),
      ),
    );
  }

  Widget _error(
    BuildContext context,
    String message, {
    required VoidCallback? onRetry,
    String retryLabel = 'Retry',
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_off_rounded,
                  size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton(
                onPressed: isDetecting ? null : onRetry,
                child: Text(retryLabel),
              ),
              TextButton(
                onPressed: onEnterManually,
                child: const Text('Enter Manually'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

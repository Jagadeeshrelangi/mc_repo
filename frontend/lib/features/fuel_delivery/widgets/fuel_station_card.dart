import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import '../models/fuel_station.dart';
import '../utils/location_utils.dart';

class FuelStationCard extends StatelessWidget {
  final FuelStation station;
  final bool isSelected;
  final VoidCallback onTap;

  const FuelStationCard({
    super.key,
    required this.station,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectable = station.isSelectable;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: selectable,
      label: '${station.brand}, ${station.name}, '
          '${station.rating.toStringAsFixed(1)} rating, '
          '${formatDistance(station.distanceKm)} away, '
          '₹${station.pricePerLitre.toStringAsFixed(1)} per litre, '
          '${selectable ? 'available' : 'unavailable'}',
      child: GestureDetector(
        onTap: selectable ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _brandColor(station.brand).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _brandInitials(station.brand),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _brandColor(station.brand),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          station.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(theme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _info(theme, Icons.star_rounded,
                            station.rating.toStringAsFixed(1),
                            color: AppColors.warning),
                        _info(theme, Icons.location_on_rounded,
                            formatDistance(station.distanceKm)),
                        _info(theme, Icons.schedule_rounded,
                            '${station.etaMinutes} min'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${station.pricePerLitre.toStringAsFixed(1)}/L',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${station.ratingCount} ratings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(ThemeData theme) {
    final Color color;
    final String label;
    if (!station.isOpen) {
      color = AppColors.error;
      label = 'Closed';
    } else if (station.availability == FuelAvailability.outOfStock) {
      color = AppColors.error;
      label = 'Out of Stock';
    } else if (station.availability == FuelAvailability.low) {
      color = AppColors.warning;
      label = 'Low Fuel';
    } else {
      color = AppColors.success;
      label = 'Open';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _info(ThemeData theme, IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Color _brandColor(String brand) {
    switch (brand) {
      case 'Indian Oil':
        return AppColors.brandBlue;
      case 'Bharat Petroleum':
        return AppColors.brandOrange;
      case 'Shell':
        return AppColors.error;
      case 'Nayara Energy':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _brandInitials(String brand) {
    final parts = brand.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isEmpty ? '?' : brand.substring(0, 2).toUpperCase();
  }
}

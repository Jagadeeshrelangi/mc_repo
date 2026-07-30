import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SeverityLevel { critical, high, medium, low, maintenance }

class SeverityBadge extends StatelessWidget {
  final SeverityLevel level;
  final bool showLabel;
  final double? fontSize;

  const SeverityBadge({
    super.key,
    required this.level,
    this.showLabel = true,
    this.fontSize,
  });

  factory SeverityBadge.fromString({required String severity, bool showLabel = true}) {
    return SeverityBadge(
      level: _fromString(severity),
      showLabel: showLabel,
    );
  }

  static SeverityLevel _fromString(String s) {
    switch (s.toLowerCase()) {
      case 'critical': return SeverityLevel.critical;
      case 'high': return SeverityLevel.high;
      case 'medium': return SeverityLevel.medium;
      case 'low': return SeverityLevel.low;
      case 'maintenance': return SeverityLevel.maintenance;
      default: return SeverityLevel.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(
                fontSize: fontSize ?? 11,
                fontWeight: FontWeight.w700,
                color: _textColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _bgColor {
    switch (level) {
      case SeverityLevel.critical: return AppColors.errorLight;
      case SeverityLevel.high: return const Color(0xFFFFEDD5);
      case SeverityLevel.medium: return AppColors.warningLight;
      case SeverityLevel.low: return AppColors.infoLight;
      case SeverityLevel.maintenance: return AppColors.successLight;
    }
  }

  Color get _dotColor {
    switch (level) {
      case SeverityLevel.critical: return AppColors.error;
      case SeverityLevel.high: return const Color(0xFFF97316);
      case SeverityLevel.medium: return AppColors.warning;
      case SeverityLevel.low: return AppColors.info;
      case SeverityLevel.maintenance: return AppColors.success;
    }
  }

  Color get _textColor {
    switch (level) {
      case SeverityLevel.critical: return AppColors.error;
      case SeverityLevel.high: return const Color(0xFFC2410C);
      case SeverityLevel.medium: return const Color(0xFFB45309);
      case SeverityLevel.low: return const Color(0xFF1D4ED8);
      case SeverityLevel.maintenance: return const Color(0xFF047857);
    }
  }

  String get _label {
    switch (level) {
      case SeverityLevel.critical: return 'CRITICAL';
      case SeverityLevel.high: return 'HIGH';
      case SeverityLevel.medium: return 'MEDIUM';
      case SeverityLevel.low: return 'LOW';
      case SeverityLevel.maintenance: return 'MAINTENANCE';
    }
  }
}

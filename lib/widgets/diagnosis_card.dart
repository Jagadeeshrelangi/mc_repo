import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_helpers.dart';
import 'severity_badge.dart';

class DiagnosisCard extends StatelessWidget {
  final String fault;
  final String? severity;
  final String? confidence;
  final String? estimatedCost;
  final String? repairTime;
  final String? safetyAdvice;
  final bool isSafeToDrive;
  final VoidCallback? onRequestMechanic;
  final VoidCallback? onOrderParts;
  final VoidCallback? onDownloadReport;
  final VoidCallback? onShareReport;

  const DiagnosisCard({
    super.key,
    required this.fault,
    this.severity,
    this.confidence,
    this.estimatedCost,
    this.repairTime,
    this.safetyAdvice,
    this.isSafeToDrive = true,
    this.onRequestMechanic,
    this.onOrderParts,
    this.onDownloadReport,
    this.onShareReport,
  });

  double get _confidenceValue {
    if (confidence == null || confidence!.isEmpty) return 0.95;
    return double.tryParse(confidence!) ?? 0.95;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandBlue, AppColors.brandBlueDark],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'AI DIAGNOSTIC REPORT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (severity != null)
                  SeverityBadge.fromString(severity: severity!, showLabel: true),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fault
                _buildRow(
                  context: context,
                  icon: Icons.error_outline_rounded,
                  title: 'Identified Fault',
                  value: fault,
                  iconColor: AppColors.error,
                ),
                const SizedBox(height: 12),
                // Safety
                if (safetyAdvice != null && safetyAdvice!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSafeToDrive ? AppColors.successLight : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSafeToDrive ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          size: 18,
                          color: isSafeToDrive ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            safetyAdvice!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSafeToDrive ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Cost & Time row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        context: context,
                        icon: Icons.payments_outlined,
                        title: 'Est. Cost',
                        value: estimatedCost != null ? '₹$estimatedCost' : 'N/A',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoTile(
                        context: context,
                        icon: Icons.schedule_rounded,
                        title: 'Repair Time',
                        value: repairTime ?? 'N/A',
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Confidence
                _buildConfidenceBar(context),
                const SizedBox(height: 14),
                // Divider
                Divider(color: context.borderSoft),
                const SizedBox(height: 10),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Find Mechanic',
                        icon: Icons.build_rounded,
                        isPrimary: true,
                        onTap: onRequestMechanic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Order Parts',
                        icon: Icons.shopping_cart_outlined,
                        isPrimary: false,
                        onTap: onOrderParts,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Download',
                        icon: Icons.download_rounded,
                        isPrimary: false,
                        onTap: onDownloadReport,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Share',
                        icon: Icons.share_rounded,
                        isPrimary: false,
                        onTap: onShareReport,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.bgTertiary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, color: context.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Space Grotesk',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _confidenceValue,
                strokeWidth: 4,
                backgroundColor: context.borderSoft,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _confidenceValue >= 0.85 ? AppColors.success : AppColors.warning,
                ),
              ),
              Text(
                '${(_confidenceValue * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
            Text(
              _confidenceValue >= 0.85 ? 'High probability' : 'Moderate probability',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.brandOrange : context.bgTertiary,
          borderRadius: BorderRadius.circular(10),
          border: isPrimary ? null : Border.all(color: context.borderSoft, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : context.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

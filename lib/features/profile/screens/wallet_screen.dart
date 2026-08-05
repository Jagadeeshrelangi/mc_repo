import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/profile_loading.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Wallet balance, transactions, coupons and saved payment methods.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final wallet = provider.wallet;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Wallet',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      body: wallet == null
          ? const ProfileLoadingState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                _balanceCard(context, wallet),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(context, 'Recent activity'),
                for (final tx in wallet.transactions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _transactionTile(context, tx),
                  ),
                if (wallet.coupons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Coupons'),
                  for (final coupon in wallet.coupons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _couponTile(context, coupon),
                    ),
                ],
                if (wallet.paymentMethods.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _sectionTitle(context, 'Saved payment methods'),
                  for (final method in wallet.paymentMethods)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _methodTile(context, method),
                    ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }

  Widget _balanceCard(BuildContext context, WalletData wallet) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '₹${wallet.balance.toStringAsFixed(2)}',
            style: AppTypography.displayLg.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded,
                  color: Colors.white.withValues(alpha: 0.85), size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${wallet.rewardPoints} reward points',
                style: AppTypography.bodySm.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.headlineMd.copyWith(color: context.textPrimary),
      ),
    );
  }

  Widget _transactionTile(BuildContext context, WalletTransaction tx) {
    final color =
        tx.type == WalletTransactionType.credit ? AppColors.success : AppColors.error;
    final sign = tx.type == WalletTransactionType.credit ? '+' : '−';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              tx.icon ??
                  (tx.type == WalletTransactionType.credit
                      ? Icons.add_circle_rounded
                      : Icons.remove_circle_rounded),
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.subtitle,
                  style: AppTypography.bodySm
                      .copyWith(color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.date,
                  style: AppTypography.labelSm
                      .copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$sign₹${tx.amount.toStringAsFixed(0)}',
            style: AppTypography.titleLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _couponTile(BuildContext context, Coupon coupon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: coupon.isActive ? context.accent.withValues(alpha: 0.5) : context.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.local_offer_rounded,
                size: 22, color: AppColors.brandOrange),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.title,
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  coupon.discount,
                  style: AppTypography.bodySm.copyWith(color: context.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Valid until ${coupon.validUntil}',
                  style: AppTypography.labelSm
                      .copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          if (coupon.isActive)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: coupon.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coupon ${coupon.code} copied')),
                );
              },
              child: Text(
                coupon.code,
                style: AppTypography.titleSm
                    .copyWith(color: AppColors.brandOrange),
              ),
            )
          else
            Text(
              'Expired',
              style: AppTypography.labelSm.copyWith(color: context.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _methodTile(BuildContext context, PaymentMethod method) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(method.icon, size: 22, color: context.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.name,
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  method.details,
                  style: AppTypography.bodySm
                      .copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

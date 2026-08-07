import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// FAQs, contact options and a feedback form.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _feedbackController = TextEditingController();

  static const _faqs = [
    (
      q: 'How do I change my default vehicle?',
      a: 'Open My Vehicles, tap Set Default on the vehicle card you want '
          'to make primary.',
    ),
    (
      q: 'How do I cancel an order?',
      a: 'Orders can be cancelled from the Orders tab before the service '
          'starts. A refund is processed within 3-5 working days.',
    ),
    (
      q: 'How do reward points work?',
      a: 'You earn points on every order. Redeemable points appear in '
          'Rewards and can be applied at checkout.',
    ),
    (
      q: 'Where does my pickup address come from?',
      a: 'Saved Addresses are reused across parts, mechanic and fuel '
          'pickups. GPS auto-detection fills the current location.',
    ),
    (
      q: 'How do I report a problem with a workshop?',
      a: 'Use the feedback form below or email support. Our team reviews '
          'every report within 24 hours.',
    ),
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _copyText(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  void _submitFeedback() {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a few words before sending.')),
      );
      return;
    }
    _feedbackController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks! We have received your feedback.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Support',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          _sectionTitle(context, 'Frequently asked questions'),
          for (final faq in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: context.border, width: 1),
              ),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(
                  faq.q,
                  style: AppTypography.titleSm.copyWith(
                      color: context.textPrimary),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.a,
                      style: AppTypography.bodySm
                          .copyWith(color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Contact us'),
          _contactTile(
            context,
            Icons.phone_outlined,
            'Call support',
            '+91 98765 43210',
            '9 AM - 9 PM, all days',
            () => _copyText(context, '+91 98765 43210', 'Number'),
          ),
          _contactTile(
            context,
            Icons.mail_outline_rounded,
            'Email support',
            'support@mechaconnect.ai',
            'Replies within 24 hours',
            () => _copyText(context, 'support@mechaconnect.ai', 'Email'),
          ),
          _contactTile(
            context,
            Icons.chat_bubble_outline_rounded,
            'WhatsApp',
            '+91 98765 43210',
            'Chat with a real agent',
            () => _copyText(context, '+91 98765 43210', 'Number'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _sectionTitle(context, 'Feedback'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: AppTypography.bodyMd
                      .copyWith(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tell us how we can improve Mecha Connect…',
                    filled: true,
                    fillColor: context.bgSecondary,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.brandOrange, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
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

  Widget _contactTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String subtitle,
    VoidCallback onAction,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            child: Icon(icon, size: 22, color: context.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMd.copyWith(color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySm
                      .copyWith(color: context.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelSm
                      .copyWith(color: context.textTertiary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAction,
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: AppColors.brandOrange,
            tooltip: 'Copy $title',
          ),
        ],
      ),
    );
  }
}

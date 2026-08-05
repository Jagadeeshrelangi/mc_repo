import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/navigation.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/ai/widgets/widgets.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/mechanic_home_screen.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// AI Assistant landing tab: greeting, search entry, quick actions, recent
/// conversations, recent diagnoses, vehicle health and daily tips. Every card
/// and CTA navigates — there are no dead sections.
class AiHomeScreen extends StatefulWidget {
  const AiHomeScreen({super.key});

  @override
  State<AiHomeScreen> createState() => _AiHomeScreenState();
}

class _AiHomeScreenState extends State<AiHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AiProvider>();
      if (provider.state == AiScreenState.initial ||
          provider.state == AiScreenState.error) {
        provider.loadHome();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();

    switch (provider.state) {
      case AiScreenState.initial:
      case AiScreenState.loading:
        return const Scaffold(body: AiLoadingState());
      case AiScreenState.error:
        return Scaffold(
          body: AiErrorState(
            message: provider.errorMessage ?? 'Unable to load your assistant.',
            onRetry: provider.loadHome,
          ),
        );
      case AiScreenState.ready:
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: provider.refreshHome,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverPadding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: _HomeContent(provider: provider),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppResponsive.horizontalPadding(context),
          right: AppResponsive.horizontalPadding(context),
          top: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mecha AI',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: AppResponsive.scaleFont(context, 24),
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                _IconAction(
                  icon: Icons.history_rounded,
                  tooltip: 'Conversation history',
                  onTap: () => openAiHistory(context),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _greeting(),
              style: AppTypography.bodyMd.copyWith(
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            _SearchEntry(onTap: () => openAiChat(context)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning! How can I help with your ride today?';
    if (hour < 17) {
      return 'Good afternoon! How can I help with your ride today?';
    }
    return 'Good evening! How can I help with your ride today?';
  }
}

class _SearchEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask Mecha AI anything about your vehicle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 20, color: context.textTertiary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ask me anything about your vehicle…',
                  style: AppTypography.bodySm.copyWith(
                    color: context.textTertiary,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final AiProvider provider;

  const _HomeContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(context);
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Quick actions',
            actionLabel: null,
            onAction: null,
          ),
          _QuickActionsGrid(provider: provider),
          const SizedBox(height: AppSpacing.xl),
          _buildHealthCard(context),
          const SizedBox(height: AppSpacing.xl),
          _buildDiagnoses(context),
          const SizedBox(height: AppSpacing.xl),
          _buildRecentConversations(context),
          const SizedBox(height: AppSpacing.xl),
          _buildSuggestions(context),
          const SizedBox(height: AppSpacing.xl),
          _buildTips(context),
        ],
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context) {
    final health = AiProvider.vehicleHealth;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandOrange, AppColors.brandOrangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: context.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Vehicle health',
                style: AppTypography.labelLg.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Text(
                '${health.score}',
                style: AppTypography.headlineLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            health.vehicleName,
            style: AppTypography.titleLg.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            '${health.statusLabel} • ${health.nextService}',
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              Expanded(
                child: _HealthChip(
                  icon: Icons.build_rounded,
                  label: 'Book mechanic',
                  onTap:
                      () => Navigator.of(
                        context,
                      ).push(aiFadeRoute(const MechanicHomeScreen())),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HealthChip(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel advice',
                  onTap:
                      () => Navigator.of(
                        context,
                      ).push(aiFadeRoute(const FuelHomeScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnoses(BuildContext context) {
    final diagnoses = provider.recentDiagnoses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent diagnoses',
          actionLabel: 'Diagnose',
          onAction: () => openAiDiagnosis(context),
        ),
        if (diagnoses.isEmpty)
          _InlinePromptCard(
            icon: Icons.monitor_heart_rounded,
            title: 'No diagnoses yet',
            message: 'Run a guided symptom check to spot issues early.',
            actionLabel: 'Start diagnosis',
            onAction: () => openAiDiagnosis(context),
          )
        else
          Column(
            children: [
              for (
                var i = 0;
                i < (diagnoses.length > 2 ? 2 : diagnoses.length);
                i++
              )
                _RecentDiagnosisTile(
                  diagnosis: diagnoses[i],
                  onTap: () => openAiDiagnosis(context),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentConversations(BuildContext context) {
    final recent = provider.recentConversations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent conversations',
          actionLabel: 'See all',
          onAction: () => openAiHistory(context),
        ),
        if (recent.isEmpty)
          _InlinePromptCard(
            icon: Icons.forum_rounded,
            title: 'Start a conversation',
            message: 'Ask anything — repairs, parts, fuel or maintenance.',
            actionLabel: 'New chat',
            onAction: () => openAiChat(context),
          )
        else
          Column(
            children: [
              for (final conversation in recent.take(3))
                ConversationTile(
                  conversation: conversation,
                  onTap:
                      () => openAiConversationDetail(context, conversation.id),
                  onPinToggle: () => provider.togglePin(conversation.id),
                  onRename: provider.renameConversation,
                  onDelete: provider.deleteConversation,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Ask about', actionLabel: null, onAction: null),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final suggestion in AiProvider.suggestions.take(6))
              SuggestionChip(
                label: suggestion.text,
                onTap: () => openAiChat(context, prompt: suggestion.text),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Daily tips', actionLabel: null, onAction: null),
        for (var i = 0; i < AiProvider.tips.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: context.cardBgAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.brandOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      size: 14,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AiProvider.tips[i],
                      style: AppTypography.bodySm.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final AiProvider provider;

  const _QuickActionsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final actions = provider.quickActions;
    return Column(
      children: [
        for (var row = 0; row < (actions.length / 2).ceil(); row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: col == 0 ? AppSpacing.sm : 0,
                      ),
                      child: _buildSlot(context, actions, row * 2 + col),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSlot(
    BuildContext context,
    List<QuickAction> actions,
    int index,
  ) {
    if (index >= actions.length) return const SizedBox.shrink();
    final action = actions[index];
    return _QuickActionSlot(
      action: action,
      onTap: () => _handleQuickAction(context, action),
    );
  }

  void _handleQuickAction(BuildContext context, QuickAction action) {
    switch (action.destination) {
      case QuickActionDestination.diagnosis:
        openAiDiagnosis(context);
      case QuickActionDestination.mechanic:
        Navigator.of(context).push(aiFadeRoute(const MechanicHomeScreen()));
      case QuickActionDestination.fuel:
        Navigator.of(context).push(aiFadeRoute(const FuelHomeScreen()));
      case QuickActionDestination.marketplace:
        Navigator.of(context).push(aiFadeRoute(const MarketplaceHomeScreen()));
      case QuickActionDestination.chat:
        openAiChat(context, prompt: action.prompt);
      case QuickActionDestination.emergency:
        _showEmergencySheet(context);
    }
  }

  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency help',
                  style: AppTypography.headlineMd.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'In an emergency, first make sure you are safe and off the road.',
                  style: AppTypography.bodySm.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _EmergencyRow(
                  icon: Icons.local_police_rounded,
                  title: 'Police',
                  number: '100',
                ),
                const SizedBox(height: AppSpacing.md),
                _EmergencyRow(
                  icon: Icons.emergency_rounded,
                  title: 'Ambulance',
                  number: '108',
                ),
                const SizedBox(height: AppSpacing.md),
                _EmergencyRow(
                  icon: Icons.car_crash_rounded,
                  title: 'Roadside assistance',
                  number: 'Call your insurer hotline',
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('I\'m safe'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _QuickActionSlot extends StatelessWidget {
  final QuickAction? action;
  final VoidCallback onTap;

  const _QuickActionSlot({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (action == null) {
      return const SizedBox.shrink();
    }
    return AiQuickActionCard(action: action!, onTap: onTap);
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, color: context.textPrimary),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSm.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTypography.labelMd.copyWith(
                  color: context.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlinePromptCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlinePromptCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBgAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: context.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSm.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: context.accent,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HealthChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDiagnosisTile extends StatelessWidget {
  final Diagnosis diagnosis;
  final VoidCallback onTap;

  const _RecentDiagnosisTile({required this.diagnosis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnosis.severity) {
      SeverityLevel.low => AppColors.success,
      SeverityLevel.medium => AppColors.warning,
      SeverityLevel.high => AppColors.error,
      SeverityLevel.critical => AppColors.error,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label: 'Diagnosis for ${diagnosis.vehicleName}: ${diagnosis.problem}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: context.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    size: 20,
                    color: context.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnosis.problem,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd.copyWith(
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${diagnosis.vehicleName} • ₹${diagnosis.estimatedCost.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(diagnosis.severity.icon, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        diagnosis.severity.label,
                        style: AppTypography.labelSm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _EmergencyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String number;

  const _EmergencyRow({
    required this.icon,
    required this.title,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 20, color: AppColors.error),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleSm.copyWith(color: context.textPrimary),
          ),
        ),
        Text(
          number,
          style: AppTypography.titleMd.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

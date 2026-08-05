import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/mock_data.dart';
import 'package:mecha_connect/mechanic/widgets/primary_action_button.dart';
import 'package:mecha_connect/mechanic/screens/booking_summary_screen.dart';

class SelectServiceScreen extends StatefulWidget {
  final MechanicInfo mechanic;

  const SelectServiceScreen({super.key, required this.mechanic});

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {
  int? _selectedIndex;

  List<MechanicService> get _services {
    return widget.mechanic.services.isNotEmpty ? widget.mechanic.services : generalServices;
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Select Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
      ),
      body: ConstrainedContent(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
                itemCount: services.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == services.length) {
                    return _buildCustomIssueCard(context);
                  }
                  return _buildServiceCard(context, services[index], index);
                },
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, MechanicService service, int index) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.brandOrange : context.borderSoft,
              width: isSelected ? 1.5 : 0.5,
            ),
            boxShadow: isSelected ? AppElevation.shadowBrandLight : context.shadowLow,
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandOrangeSoft : context.bgTertiary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(service.icon, size: 24, color: isSelected ? AppColors.brandOrange : context.textSecondary),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    SizedBox(height: 2),
                    Text('${service.estimatedMinutes} mins', style: TextStyle(fontSize: 12, color: context.textTertiary)),
                  ],
                ),
              ),
              Text('₹${service.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomIssueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.borderSoft, width: 0.5, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: context.bgTertiary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.edit_note_rounded, size: 24, color: context.textSecondary),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Custom Issue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
                SizedBox(height: 2),
                Text('Describe your problem', style: TextStyle(fontSize: 12, color: context.textTertiary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: context.textTertiary),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppResponsive.horizontalPadding(context), AppSpacing.base, AppResponsive.horizontalPadding(context), MediaQuery.of(context).padding.bottom + AppSpacing.base),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        border: Border(top: BorderSide(color: context.divider)),
      ),
      child: PrimaryActionButton(
        label: _selectedIndex != null ? 'Continue' : 'Select a Service',
        onPressed: _selectedIndex != null
            ? () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BookingSummaryScreen(
                    mechanic: widget.mechanic,
                    service: _services[_selectedIndex!],
                  ),
                ));
              }
            : null,
      ),
    );
  }
}

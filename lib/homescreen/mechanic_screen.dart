import 'package:flutter/material.dart';
import 'package:mecha_connect/services/ai_repository.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/mechanic/screens/mechanic_home_screen.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key});

  @override
  _VehicleFormPageState createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  String? selectedVehicle;
  String? selectedBrand;
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  bool _isEmergency = false;
  final AIRepository _aiRepository = AIRepository();

  final List<String> _vehicles = ['Bike', 'Car', 'Truck', 'Van'];
  final List<String> _brands = ['Honda', 'Toyota', 'Maruti Suzuki', 'Hyundai', 'Tata', 'Bajaj', 'Hero', 'TVS', 'Royal Enfield', 'KTM', 'Yamaha', 'Suzuki', 'Mahindra', 'Ashok Leyland', 'Other'];

  @override
  void dispose() {
    _problemController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
      return;
    }

    final String problem = _problemController.text.trim();
    if (problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your problem')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.brandOrange),
              ),
              const SizedBox(height: 16),
              const Text(
                'Analyzing with AI...',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Diagnosing your $selectedVehicle issue',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final diagnosis = await _aiRepository.diagnoseVehicle(
        vehicleType: selectedVehicle!,
        symptoms: [problem],
        mileage: 75000,
      );

      if (!mounted) return;
      Navigator.pop(context);
      _showDiagnosticDetails(diagnosis, problem);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MechanicHomeScreen(),
        ),
      );
    }
  }

  void _showDiagnosticDetails(Map<String, dynamic> diag, String problem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(color: context.textTertiary, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_rounded, size: 22, color: AppColors.brandBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Diagnostic Report', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
                          Text('Powered by Mecha AI', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Predicted Fault', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                            Text(diag['predicted_fault'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.currency_rupee,
                        label: 'Est. Cost',
                        value: '₹${diag['estimated_cost']}',
                        color: AppColors.brandOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.schedule,
                        label: 'Duration',
                        value: diag['repair_time'],
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Safety Advice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
                            const SizedBox(height: 2),
                            Text(diag['safety_advice'], style: TextStyle(fontSize: 13, color: context.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MechanicHomeScreen(),
                        ),
                      );
                    },
                    child: const Text('Find Nearby Mechanics'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: context.textSecondary)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        title: const Text('Vehicle Service Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isEmergency ? AppColors.brandOrange.withValues(alpha: 0.08) : context.cardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: _isEmergency ? AppColors.brandOrange : context.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emergency_rounded,
                    size: 22,
                    color: _isEmergency ? AppColors.brandOrange : (isDark ? AppColors.darkTextSecondary : AppColors.grey500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isEmergency ? AppColors.brandOrange : context.textPrimary,
                          ),
                        ),
                        Text(
                          'Priority matching for urgent issues',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEmergency,
                    onChanged: (v) => setState(() => _isEmergency = v),
                    activeColor: AppColors.brandOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Vehicle Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _vehicles.map((v) {
                final isSelected = selectedVehicle == v;
                return GestureDetector(
                  onTap: () => setState(() => selectedVehicle = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandOrange : context.cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isSelected ? AppColors.brandOrange : context.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      v,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : context.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text('Brand', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 8),
            Text('Tap to select — search coming soon', style: TextStyle(fontSize: 11, color: context.textTertiary)),
            const SizedBox(height: 8),
              SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _brands.map((b) {
                final isSelected = selectedBrand == b;
                return GestureDetector(
                  onTap: () => setState(() => selectedBrand = b),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brandBlue : context.cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isSelected ? AppColors.brandBlue : context.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Text('Describe the Problem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _problemController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'e.g., Engine overheating, flat tire, brake noise...',
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: context.border, width: 1.5, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Camera opened'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.brandOrangeSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.brandOrange),
                              SizedBox(width: 8),
                              Text('Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandOrange)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.base),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gallery opened'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlueSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined, size: 20, color: AppColors.brandBlue),
                              SizedBox(width: 8),
                              Text('Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandBlue)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text('Add photos to help the mechanic prepare better', style: TextStyle(fontSize: 11, color: context.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Find Nearby Mechanics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

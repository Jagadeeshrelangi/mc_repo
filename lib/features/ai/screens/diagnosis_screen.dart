import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/ai/models/models.dart';
import 'package:mecha_connect/features/ai/navigation.dart';
import 'package:mecha_connect/features/ai/providers/ai_provider.dart';
import 'package:mecha_connect/features/ai/widgets/widgets.dart';
import 'package:mecha_connect/features/fuel_delivery/screens/fuel_home_screen.dart';
import 'package:mecha_connect/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:mecha_connect/features/mechanic/screens/mechanic_home_screen.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Guided vehicle diagnosis: vehicle → problem → symptoms → result card.
/// Every outcome has a real CTA (book mechanic / search parts / fuel advice).
class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

enum _DiagnosisStep { vehicle, problem, symptoms, result }

class _VehicleOption {
  final String label;
  final String vehicleName;
  final IconData icon;

  const _VehicleOption({
    required this.label,
    required this.vehicleName,
    required this.icon,
  });
}

const List<_VehicleOption> _vehicleOptions = [
  _VehicleOption(
    label: 'Scooter',
    vehicleName: 'Honda Activa 6G',
    icon: Icons.electric_moped_rounded,
  ),
  _VehicleOption(
    label: 'Bike',
    vehicleName: 'TVS Apache RTR 160',
    icon: Icons.motorcycle_rounded,
  ),
  _VehicleOption(
    label: 'Car',
    vehicleName: 'Maruti Alto 800',
    icon: Icons.directions_car_rounded,
  ),
  _VehicleOption(
    label: 'Electric',
    vehicleName: 'Ola S1',
    icon: Icons.bolt_rounded,
  ),
];

const List<String> _problems = [
  'Engine won\'t start',
  'Engine overheating',
  'Brake noise',
  'Battery not holding charge',
  'Poor fuel efficiency',
  'Oil leak',
  'Flat tyre',
];

const List<String> _symptoms = [
  'Clicking sound',
  'Vibration',
  'Smoke / odour',
  'Warning light',
  'Unusual noise',
  'Loss of power',
  'Fluid leak',
];

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  _DiagnosisStep _step = _DiagnosisStep.vehicle;
  _VehicleOption? _selectedVehicle;
  String? _selectedProblem;
  final Set<String> _selectedSymptoms = <String>{};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Diagnosis')),
      body: SafeArea(top: false, child: _buildBody(context, provider)),
    );
  }

  Widget _buildBody(BuildContext context, AiProvider provider) {
    if (provider.isDiagnosing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AiActivityIndicator(),
            SizedBox(height: AppSpacing.lg),
            Text('Diagnosing your vehicle…'),
          ],
        ),
      );
    }

    if (_step == _DiagnosisStep.result && provider.diagnosisError != null) {
      return AiErrorState(
        message: provider.diagnosisError!,
        onRetry: _generate,
      );
    }

    if (_step == _DiagnosisStep.result && provider.lastDiagnosis != null) {
      return _buildResult(context, provider.lastDiagnosis!);
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_step.index + 1) / 3,
                minHeight: 6,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                color: context.accent,
                backgroundColor: context.cardBgAlt,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _stepTitle(),
                style: AppTypography.headlineMd.copyWith(
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _stepSubtitle(),
                style: AppTypography.bodySm.copyWith(
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              switch (_step) {
                _DiagnosisStep.vehicle => _buildVehicleStep(context),
                _DiagnosisStep.problem => _buildProblemStep(context),
                _DiagnosisStep.symptoms => _buildSymptomsStep(context),
                _DiagnosisStep.result => const SizedBox.shrink(),
              },
            ],
          ),
        ),
        _buildStepNav(context),
      ],
    );
  }

  String _stepTitle() {
    switch (_step) {
      case _DiagnosisStep.vehicle:
        return 'Which vehicle?';
      case _DiagnosisStep.problem:
        return 'What seems wrong?';
      case _DiagnosisStep.symptoms:
        return 'What do you notice?';
      case _DiagnosisStep.result:
        return 'Diagnosis complete';
    }
  }

  String _stepSubtitle() {
    switch (_step) {
      case _DiagnosisStep.vehicle:
        return 'Choose the vehicle you need to diagnose.';
      case _DiagnosisStep.problem:
        return 'Pick the issue you are facing right now.';
      case _DiagnosisStep.symptoms:
        return 'Select all the symptoms you have noticed.';
      case _DiagnosisStep.result:
        return 'Here is what we found and what to do next.';
    }
  }

  Widget _buildVehicleStep(BuildContext context) {
    return Column(
      children: [
        for (final option in _vehicleOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SelectCard(
              selected: _selectedVehicle == option,
              leading: option.icon,
              title: option.label,
              subtitle: option.vehicleName,
              onTap: () => setState(() => _selectedVehicle = option),
            ),
          ),
      ],
    );
  }

  Widget _buildProblemStep(BuildContext context) {
    return Column(
      children: [
        for (final problem in _problems)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SelectCard(
              selected: _selectedProblem == problem,
              leading: Icons.build_rounded,
              title: problem,
              subtitle: null,
              onTap: () => setState(() => _selectedProblem = problem),
            ),
          ),
      ],
    );
  }

  Widget _buildSymptomsStep(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final symptom in _symptoms)
          FilterChip(
            label: Text(symptom),
            selected: _selectedSymptoms.contains(symptom),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedSymptoms.add(symptom);
                } else {
                  _selectedSymptoms.remove(symptom);
                }
              });
            },
            selectedColor: context.accent.withValues(alpha: 0.15),
            checkmarkColor: context.accent,
            labelStyle: AppTypography.labelMd.copyWith(
              color: context.textPrimary,
            ),
            side: BorderSide(
              color:
                  _selectedSymptoms.contains(symptom)
                      ? context.accent
                      : context.border,
            ),
          ),
      ],
    );
  }

  Widget _buildStepNav(BuildContext context) {
    final canContinue = switch (_step) {
      _DiagnosisStep.vehicle => _selectedVehicle != null,
      _DiagnosisStep.problem => _selectedProblem != null,
      _DiagnosisStep.symptoms => _selectedSymptoms.isNotEmpty,
      _DiagnosisStep.result => false,
    };

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          border: Border(top: BorderSide(color: context.border, width: 1)),
        ),
        child: Row(
          children: [
            if (_step != _DiagnosisStep.vehicle) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = _previousStep()),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: canContinue ? _continue : null,
                child: Text(
                  _step == _DiagnosisStep.symptoms
                      ? 'Generate report'
                      : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DiagnosisStep _previousStep() {
    switch (_step) {
      case _DiagnosisStep.vehicle:
        return _DiagnosisStep.vehicle;
      case _DiagnosisStep.problem:
        return _DiagnosisStep.vehicle;
      case _DiagnosisStep.symptoms:
        return _DiagnosisStep.problem;
      case _DiagnosisStep.result:
        return _DiagnosisStep.symptoms;
    }
  }

  void _continue() {
    switch (_step) {
      case _DiagnosisStep.vehicle:
        setState(() => _step = _DiagnosisStep.problem);
      case _DiagnosisStep.problem:
        setState(() => _step = _DiagnosisStep.symptoms);
      case _DiagnosisStep.symptoms:
        _generate();
      case _DiagnosisStep.result:
        break;
    }
  }

  Future<void> _generate() async {
    final vehicle = _selectedVehicle;
    final problem = _selectedProblem;
    if (vehicle == null || problem == null) return;

    setState(() => _step = _DiagnosisStep.result);
    final diagnosis = await context.read<AiProvider>().startDiagnosis(
      vehicleName: vehicle.vehicleName,
      vehicleType: vehicle.label,
      problem: problem,
      symptoms: _selectedSymptoms.toList(),
    );
    if (!mounted) return;
    if (diagnosis == null) {
      setState(() {});
    }
  }

  Widget _buildResult(BuildContext context, Diagnosis diagnosis) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        DiagnosisCard(
          diagnosis: diagnosis,
          onBookMechanic:
              () => Navigator.of(
                context,
              ).push(aiFadeRoute(const MechanicHomeScreen())),
          onSearchParts:
              () => Navigator.of(
                context,
              ).push(aiFadeRoute(const MarketplaceHomeScreen())),
          onFuelRecommendation:
              () => Navigator.of(
                context,
              ).push(aiFadeRoute(const FuelHomeScreen())),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('New diagnosis'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => openAiChat(context, prompt: diagnosis.problem),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('Ask Mecha AI'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _reset() {
    setState(() {
      _step = _DiagnosisStep.vehicle;
      _selectedVehicle = null;
      _selectedProblem = null;
      _selectedSymptoms.clear();
    });
  }
}

class _SelectCard extends StatelessWidget {
  final bool selected;
  final IconData leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SelectCard({
    required this.selected,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color:
                selected
                    ? context.accent.withValues(alpha: 0.08)
                    : context.cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? context.accent : context.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? context.accent.withValues(alpha: 0.15)
                          : context.cardBgAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  leading,
                  size: 22,
                  color: selected ? context.accent : context.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMd.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySm.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? context.accent : context.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

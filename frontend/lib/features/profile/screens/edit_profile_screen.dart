import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/features/profile/models/models.dart';
import 'package:mecha_connect/features/profile/providers/profile_provider.dart';
import 'package:mecha_connect/features/profile/widgets/profile_header.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/theme/app_typography.dart';

/// Form screen for editing account details and the emergency contact.
///
/// Local field state lives in this widget; the payload is written only through
/// [ProfileProvider.updateProfile] (single source of truth).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyRelationController;
  late final TextEditingController _emergencyPhoneController;

  DateTime? _dateOfBirth;
  String? _gender;
  String? _avatarUrl;
  bool _hasEmergencyContact = true;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    final emergency = profile?.emergencyContact;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _emergencyNameController = TextEditingController(
      text: emergency?.name ?? '',
    );
    _emergencyRelationController = TextEditingController(
      text: emergency?.relation ?? 'Family',
    );
    _emergencyPhoneController = TextEditingController(
      text: emergency?.phone ?? '',
    );
    _dateOfBirth = profile?.dateOfBirth;
    _gender = profile?.gender;
    _avatarUrl = profile?.avatarUrl;
    _hasEmergencyContact = emergency != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = provider.validateProfileForm(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      emergencyContact:
          _hasEmergencyContact
              ? EmergencyContact(
                name: _emergencyNameController.text,
                relation: _emergencyRelationController.text,
                phone: _emergencyPhoneController.text,
              )
              : null,
    );
    if (error != null) {
      _showError(error);
      return;
    }

    final draft = provider.profile!.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      avatarUrl: _avatarUrl,
      emergencyContact:
          _hasEmergencyContact
              ? EmergencyContact(
                name: _emergencyNameController.text.trim(),
                relation: _emergencyRelationController.text.trim(),
                phone: _emergencyPhoneController.text.trim(),
              )
              : null,
      clearEmergencyContact: !_hasEmergencyContact,
    );

    final saved = await provider.updateProfile(draft);
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } else {
      _showError(provider.operationError ?? 'Unable to save your profile.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAvatar() async {
    final current = _avatarUrl;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose an avatar',
                    style: AppTypography.headlineLg.copyWith(
                      color: ctx.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _avatarChoice(
                        ctx,
                        'avatar-person',
                        Icons.person_rounded,
                        current,
                      ),
                      _avatarChoice(
                        ctx,
                        'avatar-bike',
                        Icons.two_wheeler_rounded,
                        current,
                      ),
                      _avatarChoice(
                        ctx,
                        'avatar-car',
                        Icons.directions_car_rounded,
                        current,
                      ),
                      _avatarChoice(
                        ctx,
                        'avatar-helmet',
                        Icons.sports_motorsports_rounded,
                        current,
                      ),
                      _avatarChoice(
                        ctx,
                        'avatar-tools',
                        Icons.build_rounded,
                        current,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (selected != null) {
      setState(() => _avatarUrl = selected);
    }
  }

  Widget _avatarChoice(
    BuildContext context,
    String key,
    IconData icon,
    String? current,
  ) {
    final isSelected = key == current;
    final label = 'Choose ${key.replaceAll('avatar-', '')} avatar';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () => Navigator.pop(context, key),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? context.accent.withValues(alpha: 0.15)
                      : context.bgTertiary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? context.accent : context.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: isSelected ? context.accent : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1995, 1, 1),
      firstDate: DateTime(now.year - 90),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: AppTypography.titleLg.copyWith(color: context.textPrimary),
        ),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: TextButton(
              onPressed: provider.isSavingProfile ? null : _save,
              child:
                  provider.isSavingProfile
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        'Save',
                        style: AppTypography.titleSm.copyWith(
                          color: AppColors.brandOrange,
                        ),
                      ),
            ),
          ),
        ],
      ),
      body:
          profile == null
              ? const SizedBox.shrink()
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandOrange,
                                  AppColors.brandOrangeDark,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              profileAvatarIcon(_avatarUrl),
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: _pickAvatar,
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                            ),
                            label: const Text('Change Photo'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionLabel(context, 'Account'),
                    _buildField(
                      controller: _nameController,
                      label: 'Full name',
                      icon: Icons.person_outline_rounded,
                      validator: provider.validateFullName,
                    ),
                    _buildField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: provider.validateEmail,
                    ),
                    _buildField(
                      controller: _phoneController,
                      label: 'Mobile number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: provider.validatePhone,
                    ),
                    _dateField(context, provider),
                    _genderField(context, provider),
                    const SizedBox(height: AppSpacing.lg),
                    _sectionLabel(context, 'Emergency contact'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable emergency contact'),
                      value: _hasEmergencyContact,
                      activeTrackColor: AppColors.brandOrange,
                      onChanged:
                          (v) => setState(() => _hasEmergencyContact = v),
                    ),
                    if (_hasEmergencyContact) ...[
                      _buildField(
                        controller: _emergencyNameController,
                        label: 'Contact name',
                        icon: Icons.badge_outlined,
                        validator: provider.validateFullName,
                      ),
                      _buildField(
                        controller: _emergencyRelationController,
                        label: 'Relation',
                        icon: Icons.family_restroom_rounded,
                      ),
                      _buildField(
                        controller: _emergencyPhoneController,
                        label: 'Contact number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: provider.validatePhone,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: provider.isSavingProfile ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accent,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                      ),
                      child:
                          provider.isSavingProfile
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Save Changes'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.titleLg.copyWith(
          color: context.accent,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTypography.bodyMd.copyWith(color: context.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: context.textSecondary, size: 20),
          filled: true,
          fillColor: context.bgSecondary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.brandOrange,
              width: 1.6,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context, ProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: _pickDateOfBirth,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of birth',
            prefixIcon: const Icon(
              Icons.cake_outlined,
              color: AppColors.brandOrange,
              size: 20,
            ),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            filled: true,
            fillColor: context.bgSecondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: context.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: context.border),
            ),
          ),
          child: Text(
            _dateOfBirth == null
                ? 'Select date'
                : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
            style:
                _dateOfBirth == null
                    ? AppTypography.bodyMd.copyWith(color: context.textTertiary)
                    : AppTypography.bodyMd.copyWith(color: context.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _genderField(BuildContext context, ProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: const Icon(
            Icons.wc_outlined,
            color: AppColors.brandOrange,
            size: 20,
          ),
          filled: true,
          fillColor: context.bgSecondary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(color: context.border),
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
          DropdownMenuItem(
            value: 'Prefer not to say',
            child: Text('Prefer not to say'),
          ),
        ],
        onChanged: (v) => setState(() => _gender = v),
      ),
    );
  }
}

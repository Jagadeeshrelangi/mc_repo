import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/services/location_provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';

/// Opens the shared location picker above the app's root [LocationProvider].
/// Used by every screen that lets the user choose/set the delivery location
/// (Home, header bar, …) so there is exactly one picker implementation.
void showLocationPickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => ChangeNotifierProvider.value(
          value: context.read<LocationProvider>(),
          child: const LocationPickerSheet(),
        ),
  );
}

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _addLabelController = TextEditingController();
  final _addAddressController = TextEditingController();
  Timer? _debounce;
  bool _showAddForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    _addLabelController.dispose();
    _addAddressController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, LocationProvider location) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      location.searchLocations(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final isDark = context.isDark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              _buildHandle(isDark),
              _buildHeader(isDark),
              _buildSearchBar(location, isDark),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (_searchController.text.isEmpty) ...[
                      _buildUseCurrentLocation(location, isDark),
                      if (location.savedAddresses.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSavedAddressesSection(location, isDark),
                      ],
                      const SizedBox(height: 20),
                      _buildPermissionSection(location, isDark),
                    ],
                    if (_searchController.text.isNotEmpty &&
                        location.searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSearchResults(location, isDark),
                    ],
                    if (_searchController.text.isNotEmpty &&
                        location.searchResults.isEmpty &&
                        _searchController.text.length >= 3) ...[
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'No results found. Try a different search.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                    if (_showAddForm) ...[
                      const SizedBox(height: 16),
                      _buildAddAddressForm(location, isDark),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBorder : AppColors.grey300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select Location',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showAddForm = !_showAddForm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brandOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showAddForm ? Icons.close_rounded : Icons.add_rounded,
                    size: 16,
                    color: AppColors.brandOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAddForm ? 'Cancel' : 'Add New',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(LocationProvider location, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grey50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grey200,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (q) => _onSearchChanged(q, location),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkText : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search area, street, or landmark...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      tooltip: 'Clear search',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color:
                            isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.grey400,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        location.clearSearch();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUseCurrentLocation(LocationProvider location, bool isDark) {
    final isUsing =
        location.hasSelection &&
        location.selectedLatLng != null &&
        location.currentLatLng != null &&
        location.selectedLatLng!.latitude == location.currentLatLng!.latitude;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: () {
          if (location.permissionState == LocationPermissionState.granted) {
            location.useCurrentLocation();
            Navigator.pop(context);
          } else {
            location.getCurrentLocation();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isUsing
                    ? AppColors.brandOrange.withValues(alpha: 0.08)
                    : (isDark ? AppColors.darkSurface : AppColors.grey50),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color:
                  isUsing
                      ? AppColors.brandOrange.withValues(alpha: 0.3)
                      : (isDark ? AppColors.darkBorder : AppColors.grey200),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 20,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use current location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.darkText : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.currentAddress.isNotEmpty
                          ? location.currentAddress
                          : 'Tap to detect your position',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUsing)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.brandOrange,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddressesSection(LocationProvider location, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Addresses',
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(location.savedAddresses.length, (index) {
          final addr = location.savedAddresses[index];
          final isSelected = location.selectedAddress.contains(addr.label);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                location.selectSavedAddress(index);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.brandOrange.withValues(alpha: 0.08)
                          : (isDark ? AppColors.darkSurface : AppColors.grey50),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.brandOrange.withValues(alpha: 0.3)
                            : (isDark
                                ? AppColors.darkBorderLight
                                : AppColors.grey100),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (addr.label == 'Home'
                                ? AppColors.brandOrange
                                : addr.label == 'Work'
                                ? AppColors.brandBlue
                                : AppColors.success)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        addr.label == 'Home'
                            ? Icons.home_rounded
                            : addr.label == 'Work'
                            ? Icons.work_rounded
                            : Icons.place_rounded,
                        size: 18,
                        color:
                            addr.label == 'Home'
                                ? AppColors.brandOrange
                                : addr.label == 'Work'
                                ? AppColors.brandBlue
                                : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addr.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? AppColors.darkText
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addr.address,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.brandOrange,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults(LocationProvider location, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Search Results',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ...location.searchResults.map((result) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                location.selectSearchResult(result);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorderLight : AppColors.grey100,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppColors.brandOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${result['shortName'] ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? AppColors.darkText
                                  : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPermissionSection(LocationProvider location, bool isDark) {
    if (location.permissionState == LocationPermissionState.granted ||
        location.permissionState == LocationPermissionState.initial) {
      return const SizedBox.shrink();
    }

    String title;
    String description;
    String actionLabel;
    VoidCallback? action;

    switch (location.permissionState) {
      case LocationPermissionState.denied:
        title = 'Location Access Needed';
        description =
            'Mecha Connect uses your location to find nearby services and mechanics.';
        actionLabel = 'Grant Access';
        action = () => location.checkAndRequestPermission();
        break;
      case LocationPermissionState.deniedForever:
        title = 'Location Permission Blocked';
        description =
            'Please enable location access in your device settings to use this feature.';
        actionLabel = 'Open Settings';
        action = () => location.openSettings();
        break;
      case LocationPermissionState.serviceDisabled:
        title = 'Location Services Off';
        description =
            'Turn on location services in your device settings to find nearby mechanics and fuel.';
        actionLabel = 'Enable Services';
        action = () => location.checkAndRequestPermission();
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: action,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAddressForm(LocationProvider location, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grey200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save New Address',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addLabelController,
            hint: 'Label (e.g., Home, Work, Gym)',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addAddressController,
            hint: 'Full address',
            isDark: isDark,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                if (_addLabelController.text.isEmpty ||
                    _addAddressController.text.isEmpty) {
                  return;
                }
                if (location.selectedLatLng == null) return;
                location.addSavedAddress(
                  SavedAddress(
                    label: _addLabelController.text.trim(),
                    address: _addAddressController.text.trim(),
                    latitude: location.selectedLatLng!.latitude,
                    longitude: location.selectedLatLng!.longitude,
                  ),
                );
                _addLabelController.clear();
                _addAddressController.clear();
                setState(() => _showAddForm = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save Address',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppColors.darkText : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.darkTextTertiary : AppColors.grey400,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grey200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grey200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.brandOrange,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

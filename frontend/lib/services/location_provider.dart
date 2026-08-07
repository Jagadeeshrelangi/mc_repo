import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/services/geocoding_service.dart';

enum LocationPermissionState { initial, granted, denied, deniedForever, serviceDisabled }

class SavedAddress {
  final String label;
  final String address;
  final double latitude;
  final double longitude;

  const SavedAddress({
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    label: json['label'] as String,
    address: json['address'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

class LocationProvider extends ChangeNotifier {
  LocationPermissionState _permissionState = LocationPermissionState.initial;
  LatLng? _currentLatLng;
  LatLng? _selectedLatLng;
  String _currentAddress = '';
  String _selectedAddress = '';
  GeocodingResult? _currentAddressDetails;
  GeocodingResult? _selectedAddressDetails;
  bool _isLoadingLocation = false;
  bool _isFetchingAddress = false;
  bool _isInitializing = false;
  List<SavedAddress> _savedAddresses = [];
  List<Map<String, dynamic>> _searchResults = [];

  static const _savedAddressesKey = 'saved_addresses';
  static const _selectedLatKey = 'selected_lat';
  static const _selectedLngKey = 'selected_lng';
  static const _selectedAddressKey = 'selected_address';

  LocationPermissionState get permissionState => _permissionState;
  LatLng? get currentLatLng => _currentLatLng;
  LatLng? get selectedLatLng => _selectedLatLng ?? _currentLatLng;
  String get currentAddress => _currentAddress;
  String get selectedAddress => _selectedAddress.isNotEmpty ? _selectedAddress : _currentAddress;
  GeocodingResult? get currentAddressDetails => _currentAddressDetails;
  GeocodingResult? get selectedAddressDetails => _selectedAddressDetails;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get isFetchingAddress => _isFetchingAddress;
  List<SavedAddress> get savedAddresses => List.unmodifiable(_savedAddresses);
  List<Map<String, dynamic>> get searchResults => List.unmodifiable(_searchResults);
  bool get hasLocation => _currentLatLng != null;
  bool get hasSelection => _selectedLatLng != null;

  LocationProvider() {
    _loadSavedState();
    _initLocation();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final addressesJson = prefs.getStringList(_savedAddressesKey);
      if (addressesJson != null) {
        _savedAddresses = addressesJson
            .map((json) => SavedAddress.fromJson(jsonDecode(json)))
            .toList();
      }

      final savedLat = prefs.getDouble(_selectedLatKey);
      final savedLng = prefs.getDouble(_selectedLngKey);
      final savedAddress = prefs.getString(_selectedAddressKey);
      if (savedLat != null && savedLng != null) {
        _selectedLatLng = LatLng(savedLat, savedLng);
        _selectedAddress = savedAddress ?? '';
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved location: $e');
    }
  }

  Future<void> _saveSelectionToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedLatLng != null) {
        await prefs.setDouble(_selectedLatKey, _selectedLatLng!.latitude);
        await prefs.setDouble(_selectedLngKey, _selectedLatLng!.longitude);
        await prefs.setString(_selectedAddressKey, _selectedAddress);
      }
    } catch (e) {
      debugPrint('Error saving selection: $e');
    }
  }

  Future<void> _initLocation() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await checkAndRequestPermission();
      if (_permissionState == LocationPermissionState.granted) {
        await getCurrentLocation();
      }
    } catch (_) {
      // Startup detection must never throw an unhandled async error (e.g. when
      // the geolocation plugin is unavailable on the current platform/webview).
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> checkAndRequestPermission() async {
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        _permissionState = LocationPermissionState.serviceDisabled;
        notifyListeners();
        return;
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }

      if (permission == geo.LocationPermission.denied) {
        _permissionState = LocationPermissionState.denied;
      } else if (permission == geo.LocationPermission.deniedForever) {
        _permissionState = LocationPermissionState.deniedForever;
      } else {
        _permissionState = LocationPermissionState.granted;
      }
      notifyListeners();
    } catch (_) {
      // Geolocation unavailable (unsupported platform, blocked webview/iframe,
      // non-HTTPS web origin, plugin missing in tests). Surface as a resolvable
      // state instead of throwing out of the constructor-triggered detection.
      _permissionState = LocationPermissionState.serviceDisabled;
      notifyListeners();
    }
  }

  Future<bool> getCurrentLocation() async {
    if (_permissionState != LocationPermissionState.granted) return false;
    if (_isLoadingLocation) return false;

    _isLoadingLocation = true;
    notifyListeners();

    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      _currentLatLng = LatLng(position.latitude, position.longitude);

      if (!hasSelection) {
        _selectedLatLng = _currentLatLng;
      }

      await _getAddressFromLatLng(_currentLatLng!, isCurrent: true);

      if (_selectedAddress.isEmpty && _currentAddress.isNotEmpty) {
        _selectedAddress = _currentAddress;
        await _saveSelectionToPrefs();
      }

      _isLoadingLocation = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error getting location: $e');
      _isLoadingLocation = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location, {bool isCurrent = false}) async {
    _isFetchingAddress = true;
    notifyListeners();

    final details = await GeocodingService().reverseGeocode(location);

    if (isCurrent) {
      _currentAddressDetails = details;
      _currentAddress = details?.shortAddress ?? _shortenAddress(details?.displayName ?? '');
    } else {
      _selectedAddressDetails = details;
      _selectedAddress = details?.shortAddress ?? _shortenAddress(details?.displayName ?? '');
    }

    _isFetchingAddress = false;
    notifyListeners();
  }

  String _shortenAddress(String fullAddress) {
    final parts = fullAddress.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 3) {
      return parts.take(3).join(', ');
    }
    return fullAddress;
  }

  Future<void> searchLocations(String query) async {
    if (query.trim().length < 3) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _searchResults = await GeocodingService().searchLocations(query);
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> selectLocation(LatLng point, {String? address}) async {
    _selectedLatLng = point;
    _selectedAddress = address ?? '';

    if (_selectedAddress.isEmpty) {
      await _getAddressFromLatLng(point, isCurrent: false);
    }

    await _saveSelectionToPrefs();
    notifyListeners();
  }

  Future<void> selectSearchResult(Map<String, dynamic> result) async {
    final point = LatLng(result['lat'] as double, result['lng'] as double);
    await selectLocation(point, address: result['shortName'] as String);
  }

  void useCurrentLocation() {
    if (_currentLatLng != null) {
      _selectedLatLng = _currentLatLng;
      _selectedAddress = _currentAddress;
      _saveSelectionToPrefs();
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
    await checkAndRequestPermission();
    if (_permissionState == LocationPermissionState.granted) {
      await getCurrentLocation();
    }
  }

  void _saveAddressToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedAddresses.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList(_savedAddressesKey, jsonList);
    } catch (e) {
      debugPrint('Error saving addresses: $e');
    }
  }

  Future<void> addSavedAddress(SavedAddress address) async {
    _savedAddresses.add(address);
    _saveAddressToPrefs();
    notifyListeners();
  }

  Future<void> removeSavedAddress(int index) async {
    if (index >= 0 && index < _savedAddresses.length) {
      _savedAddresses.removeAt(index);
      _saveAddressToPrefs();
      notifyListeners();
    }
  }

  void selectSavedAddress(int index) {
    if (index >= 0 && index < _savedAddresses.length) {
      final addr = _savedAddresses[index];
      selectLocation(
        LatLng(addr.latitude, addr.longitude),
        address: '${addr.label} — ${addr.address}',
      );
    }
  }
}

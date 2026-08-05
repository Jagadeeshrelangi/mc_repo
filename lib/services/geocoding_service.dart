import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Structured address returned by [GeocodingService.reverseGeocode].
///
/// Shared across the app (LocationProvider, VehicleFormScreen, etc.) so the
/// same Nominatim reverse-geocoding logic is never duplicated.
class GeocodingResult {
  final String street;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final String displayName;

  const GeocodingResult({
    this.street = '',
    this.locality = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.displayName = '',
  });

  bool get isEmpty =>
      street.isEmpty &&
      locality.isEmpty &&
      city.isEmpty &&
      state.isEmpty &&
      pincode.isEmpty &&
      displayName.isEmpty;

  List<String> get _parts => [
    if (street.isNotEmpty) street,
    if (locality.isNotEmpty) locality,
    if (city.isNotEmpty) city,
    if (state.isNotEmpty) state,
    if (pincode.isNotEmpty) pincode,
  ];

  /// Full readable address: street, locality, city, state, pincode.
  String get fullAddress => _parts.join(', ');

  /// Compact address (first 3 parts) for short labels / previews.
  String get shortAddress => _parts.take(3).join(', ');
}

class GeocodingService {
  static const String _userAgent = 'MechaConnect/1.0';
  static const Duration _timeout = Duration(seconds: 10);

  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Reverse-geocodes [location] into a structured [GeocodingResult].
  ///
  /// Returns `null` on any failure (network error, non-200, empty payload,
  /// timeout) so a slow/hung Nominatim call can never keep a location screen
  /// stuck on "Detecting…".
  Future<GeocodingResult?> reverseGeocode(LatLng location) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse'
              '?format=json&addressdetails=1'
              '&lat=${location.latitude}&lon=${location.longitude}',
            ),
            headers: {'User-Agent': _userAgent},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;

      final address = (data['address'] as Map<String, dynamic>?) ?? {};
      final result = GeocodingResult(
        street: _firstNonEmpty(address, ['road', 'pedestrian', 'footway', 'path']),
        locality: _firstNonEmpty(address, ['neighbourhood', 'suburb', 'quarter', 'hamlet']),
        city: _firstNonEmpty(address, ['city', 'town', 'village', 'municipality', 'county']),
        state: _firstNonEmpty(address, ['state', 'state_district']),
        pincode: _firstNonEmpty(address, ['postcode']),
        displayName: data['display_name'] as String? ?? '',
      );

      if (result.isEmpty) return null;
      return result;
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Forward-geocodes [query] into a list of candidate places.
  ///
  /// Returns an empty list on failure. Each item maps to:
  /// `name`, `shortName`, `lat`, `lng`.
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/search'
              '?q=${Uri.encodeComponent(query)}&format=json&limit=8&countrycodes=in',
            ),
            headers: {'User-Agent': _userAgent},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      return data.map<Map<String, dynamic>>((item) {
        final displayName = item['display_name'] as String? ?? '';
        final shortName = _shorten(displayName);
        return {
          'name': displayName,
          'shortName': shortName,
          'lat': double.parse(item['lat'] as String),
          'lng': double.parse(item['lon'] as String),
        };
      }).toList();
    } catch (e) {
      debugPrint('Location search error: $e');
      return [];
    }
  }

  String _shorten(String fullAddress) {
    final parts = fullAddress.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 3) {
      return parts.take(3).join(', ');
    }
    return fullAddress;
  }

  String _firstNonEmpty(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return '';
  }
}

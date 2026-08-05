import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:mecha_connect/services/geocoding_service.dart';
import 'package:mecha_connect/services/location_provider.dart';

/// Banner states shown by every address/location screen during GPS detection.
///
/// ONE enum shared by Fuel, Mechanic and Marketplace checkout so all screens
/// behave identically: no screen re-defines its own loading/success/denied
/// vocabulary.
enum LocationBannerState {
  idle,
  loading,
  success,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

/// The outcome of a successful detection run. [address] is always a readable
/// address (full geocode result or the provider's fallback), never null when
/// detection reported success.
class DetectedLocation {
  final LatLng? latLng;
  final GeocodingResult? details;
  final String? address;

  const DetectedLocation({this.latLng, this.details, this.address});
}

/// Thrown when the GPS-first pipeline cannot resolve a location. [state]
/// maps 1:1 to the banner a screen must render, so screens never guess how to
/// present a failure.
class LocationDetectException implements Exception {
  final LocationBannerState state;
  final String message;

  const LocationDetectException(this.state, this.message);

  @override
  String toString() => message;
}

/// THE single implementation of the app-wide "GPS first" location flow:
///
/// 1. Reuse coordinates already resolved by [LocationProvider] (fast path).
/// 2. Otherwise request permission — denied / deniedForever / serviceDisabled
///    surface as distinct banner states instead of one generic "denied".
/// 3. Acquire the current position (with a timeout) and reverse-geocode it.
///
/// Every address/location screen (Fuel, Mechanic, Marketplace checkout, Home)
/// funnels through this one service. No screen re-implements the
/// permission → GPS → geocode pipeline.
class LocationService {
  LocationService({GeocodingService? geocoding})
      : _geocoding = geocoding ?? GeocodingService();

  final GeocodingService _geocoding;

  static const Duration gpsTimeout = Duration(seconds: 10);

  Future<DetectedLocation> detect({required LocationProvider provider}) async {
    if (provider.hasLocation) {
      // Fast path: the app already resolved coordinates at startup. Only
      // reverse-geocode if no structured result is cached yet. The geocode is
      // bounded so a hung Nominatim call can never hang the screen.
      final latLng = provider.currentLatLng;
      var details = provider.currentAddressDetails;
      if (details == null && latLng != null) {
        try {
          details = await _geocoding
              .reverseGeocode(latLng)
              .timeout(gpsTimeout);
        } on TimeoutException {
          details = null;
        }
      }
      return DetectedLocation(
        latLng: latLng,
        details: details,
        address: _readableAddress(details, fallback: provider.currentAddress),
      );
    }

    try {
      await provider.checkAndRequestPermission().timeout(gpsTimeout);
    } catch (_) {
      // A throwing OR hanging permission request (rare platform edge, pending
      // browser/OS prompt) must surface as a resolvable error, never hang the
      // screen on "loading".
      throw const LocationDetectException(
          LocationBannerState.error, 'Unable to determine your location.');
    }

    switch (provider.permissionState) {
      case LocationPermissionState.denied:
        throw const LocationDetectException(
            LocationBannerState.denied, 'Location permission denied.');
      case LocationPermissionState.deniedForever:
        throw const LocationDetectException(
            LocationBannerState.deniedForever, 'Location permission blocked.');
      case LocationPermissionState.serviceDisabled:
        throw const LocationDetectException(
            LocationBannerState.serviceDisabled, 'Location services are off.');
      case LocationPermissionState.granted:
      case LocationPermissionState.initial:
        break;
    }

    try {
      final ok =
          await provider.getCurrentLocation().timeout(gpsTimeout);
      if (!ok) {
        throw const LocationDetectException(
            LocationBannerState.error, 'Unable to determine your location.');
      }
    } on TimeoutException {
      throw const LocationDetectException(
          LocationBannerState.error, 'Unable to determine your location.');
    }

    final latLng = provider.currentLatLng;
    final details = provider.currentAddressDetails;
    final address = _readableAddress(details, fallback: provider.currentAddress);
    if (address == null || address.isEmpty) {
      // GPS reported success but reverse geocoding produced nothing readable —
      // never report "success" next to empty fields.
      throw const LocationDetectException(
          LocationBannerState.error, 'Unable to determine your location.');
    }
    return DetectedLocation(latLng: latLng, details: details, address: address);
  }

  String? _readableAddress(GeocodingResult? details, {required String fallback}) {
    if (details != null && details.fullAddress.isNotEmpty) {
      return details.fullAddress;
    }
    return fallback.isNotEmpty ? fallback : null;
  }
}

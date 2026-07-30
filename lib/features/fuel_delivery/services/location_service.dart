import 'dart:math';

import '../models/delivery_location.dart';

class LocationService {
  DeliveryLocation getDefaultLocation() {
    return const DeliveryLocation(
      latitude: 12.9716,
      longitude: 77.5946,
      address: 'Bengaluru, Karnataka',
      label: 'Current Location',
    );
  }

  Future<DeliveryLocation> searchLocation(String query) async {
    return DeliveryLocation(
      latitude: 12.9716,
      longitude: 77.5946,
      address: query,
      label: 'Searched Location',
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}

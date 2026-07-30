import 'dart:math';
import '../models/tracking_info.dart';
import '../models/order_status.dart';

class MockTrackingService {
  final Random _random = Random();

  TrackingInfo getMockTracking({
    required double customerLat,
    required double customerLon,
    OrderStatus status = OrderStatus.enRoute,
  }) {
    final distanceRemaining = 0.5 + _random.nextDouble() * 4;
    final etaMinutes = (distanceRemaining / 0.5).round().clamp(2, 30);

    return TrackingInfo(
      partnerLatitude: customerLat + 0.005 + _random.nextDouble() * 0.01,
      partnerLongitude: customerLon + 0.003 + _random.nextDouble() * 0.01,
      customerLatitude: customerLat,
      customerLongitude: customerLon,
      distanceRemaining: distanceRemaining,
      etaMinutes: etaMinutes,
      status: status,
      statusLabel: status.label,
    );
  }
}

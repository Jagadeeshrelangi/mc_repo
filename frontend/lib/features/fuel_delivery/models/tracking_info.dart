import 'order_status.dart';

class TrackingInfo {
  final double partnerLatitude;
  final double partnerLongitude;
  final double customerLatitude;
  final double customerLongitude;
  final double distanceRemaining;
  final int etaMinutes;
  final OrderStatus status;
  final String statusLabel;

  const TrackingInfo({
    required this.partnerLatitude,
    required this.partnerLongitude,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.distanceRemaining,
    required this.etaMinutes,
    required this.status,
    required this.statusLabel,
  });
}

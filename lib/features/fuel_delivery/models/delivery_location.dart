class DeliveryLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String label;

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.label = '',
  });
}

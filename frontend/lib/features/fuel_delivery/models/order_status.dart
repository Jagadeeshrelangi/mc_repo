enum OrderStatus {
  requested('Requested'),
  accepted('Accepted'),
  fuelPacked('Fuel Packed'),
  partnerAssigned('Delivery Partner Assigned'),
  enRoute('En Route'),
  arrived('Arrived'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const OrderStatus(this.label);

  bool get isTerminal => this == delivered || this == cancelled;

  int get stepIndex {
    if (this == cancelled) return 0;
    return index;
  }
}

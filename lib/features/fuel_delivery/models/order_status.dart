enum OrderStatus {
  created('Created'),
  searching('Searching'),
  partnerAssigned('Partner Assigned'),
  accepted('Accepted'),
  headingToStation('Heading to Station'),
  fuelPicked('Fuel Picked'),
  enRoute('En Route'),
  arrived('Arrived'),
  delivered('Delivered'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const OrderStatus(this.label);
}

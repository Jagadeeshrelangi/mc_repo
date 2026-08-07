/// A snapshot of one cart line at checkout time. The marketplace keeps a typed
/// record for the checkout/success flow while the shared Orders tab renders
/// from its own lightweight entries (see `parts/order_data.dart`).
class OrderItem {
  final String productId;
  final String name;
  final String brand;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;
}

/// Delivery details captured on the checkout form.
class CheckoutAddress {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;

  const CheckoutAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
  });

  String get fullAddress => '$address, $city, $state - $pincode';
}

/// A marketplace order created at checkout. One order per cart line so each
/// line maps 1:1 onto the shared Orders tab card list.
class MarketplaceOrder {
  final String id;
  final OrderItem item;
  final String address;
  final String paymentMethod;
  final double total;
  final DateTime createdAt;
  final String status;

  const MarketplaceOrder({
    required this.id,
    required this.item,
    required this.address,
    required this.paymentMethod,
    required this.total,
    required this.createdAt,
    this.status = 'Pending',
  });
}

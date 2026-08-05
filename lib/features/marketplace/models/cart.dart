import 'product.dart';

/// A product plus the quantity the user intends to buy.
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  double get lineTotal => product.price * quantity;
  double get lineMrp => product.mrp * quantity;
}

/// A saved-for-later product.
class WishlistItem {
  final Product product;
  final DateTime addedAt;

  const WishlistItem({required this.product, required this.addedAt});
}

/// Fully computed order totals. Single source of truth for every price the
/// cart/checkout renders — produced by `CartService`, never hand-rolled in UI.
class PriceSummary {
  final double itemsTotal;
  final double mrpTotal;
  final double gst;
  final double deliveryFee;
  final double couponDiscount;
  final double grandTotal;

  const PriceSummary({
    required this.itemsTotal,
    required this.mrpTotal,
    required this.gst,
    required this.deliveryFee,
    required this.couponDiscount,
    required this.grandTotal,
  });

  double get savings => mrpTotal - itemsTotal;
}

/// How a coupon discounts the cart total.
enum CouponType {
  /// Percentage discount, capped at [maxDiscount].
  percent,

  /// Flat rupee discount.
  flat,

  /// Waives the delivery fee.
  freeDelivery,
}

/// A promotional code. Sprint 2: validated by the backend; the mock list here
/// keeps the coupon UX fully functional in this sprint.
class Coupon {
  final String id;
  final String code;
  final String title;
  final String description;
  final CouponType type;
  final double value;
  final double? maxDiscount;
  final double minOrderValue;

  const Coupon({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    this.value = 0,
    this.maxDiscount,
    this.minOrderValue = 0,
  });
}

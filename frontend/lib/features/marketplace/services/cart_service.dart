import '../models/cart.dart';
import '../models/coupon.dart';

/// Pricing engine for the marketplace cart. Every price shown on the cart and
/// checkout screens is computed here — the UI never re-implements GST,
/// delivery or coupon math, so all totals are always consistent.
class CartService {
  static const double gstRate = 0.18;
  static const double deliveryFee = 49.0;
  static const double freeDeliveryThreshold = 999.0;

  /// Builds the full [PriceSummary] for [items], applying [coupon] when valid.
  PriceSummary calculate(List<CartItem> items, {Coupon? coupon}) {
    final itemsTotal = items.fold<double>(0, (sum, c) => sum + c.lineTotal);
    final mrpTotal = items.fold<double>(0, (sum, c) => sum + c.lineMrp);

    final gst = itemsTotal * gstRate;

    var fee =
        itemsTotal >= freeDeliveryThreshold || itemsTotal == 0 ? 0.0 : deliveryFee;

    var couponDiscount = 0.0;
    if (coupon != null && itemsTotal >= coupon.minOrderValue) {
      switch (coupon.type) {
        case CouponType.freeDelivery:
          fee = 0;
          break;
        case CouponType.percent:
          couponDiscount = itemsTotal * coupon.value / 100;
          final max = coupon.maxDiscount;
          if (max != null && couponDiscount > max) couponDiscount = max;
          break;
        case CouponType.flat:
          couponDiscount = coupon.value;
          break;
      }
      if (couponDiscount > itemsTotal) couponDiscount = itemsTotal;
    }

    final grandTotal =
        (itemsTotal + gst + fee - couponDiscount).clamp(0.0, double.infinity);

    return PriceSummary(
      itemsTotal: itemsTotal,
      mrpTotal: mrpTotal,
      gst: gst,
      deliveryFee: fee,
      couponDiscount: couponDiscount,
      grandTotal: grandTotal,
    );
  }
}

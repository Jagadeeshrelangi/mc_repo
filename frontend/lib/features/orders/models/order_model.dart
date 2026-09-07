import 'package:mecha_connect/widgets/order_card.dart';

/// Unified cross-domain order model supporting Parts, Fuel, Mechanic, and AI activities.
class UnifiedOrder {
  final String id;
  final String name;
  final String brand;
  final int quantity;
  final double price;
  final String? image;
  final String type; // 'parts', 'mechanic', 'fuel', 'aiReport'
  final String status; // 'Pending', 'In Progress', 'Delivered', 'Completed', 'Cancelled'
  final String date;
  final DateTime? occurredAt;
  final String? source;

  const UnifiedOrder({
    required this.id,
    required this.name,
    required this.brand,
    this.quantity = 1,
    required this.price,
    this.image,
    required this.type,
    required this.status,
    required this.date,
    this.occurredAt,
    this.source,
  });

  OrderType get orderType {
    switch (type.toLowerCase()) {
      case 'mechanic':
        return OrderType.mechanic;
      case 'fuel':
        return OrderType.fuel;
      case 'aireport':
      case 'ai':
        return OrderType.aiReport;
      case 'parts':
      default:
        return OrderType.parts;
    }
  }

  factory UnifiedOrder.fromJson(Map<String, dynamic> json) {
    final rawDate = json['occurred_at'] ?? json['created_at'] ?? json['date'];
    DateTime? dt;
    String displayDate = 'Recent';

    if (rawDate != null) {
      if (rawDate is DateTime) {
        dt = rawDate;
      } else {
        dt = DateTime.tryParse(rawDate.toString());
      }
    }

    if (dt != null) {
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        displayDate = 'Today';
      } else if (diff.inDays == 1) {
        displayDate = 'Yesterday';
      } else if (diff.inDays < 7) {
        displayDate = '${diff.inDays} days ago';
      } else {
        displayDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } else if (json['date'] != null) {
      displayDate = json['date'].toString();
    }

    return UnifiedOrder(
      id: (json['id'] ?? json['external_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'Order').toString(),
      brand: (json['brand'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      image: json['image'] as String? ?? json['image_url'] as String?,
      type: (json['type'] ?? 'parts').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      date: displayDate,
      occurredAt: dt,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'price': price.round(),
      'image': image,
      'type': type,
      'status': status,
      'date': date,
      if (occurredAt != null) 'occurred_at': occurredAt!.toIso8601String(),
      if (source != null) 'source': source,
    };
  }

  UnifiedOrder copyWith({
    String? id,
    String? name,
    String? brand,
    int? quantity,
    double? price,
    String? image,
    String? type,
    String? status,
    String? date,
    DateTime? occurredAt,
    String? source,
  }) {
    return UnifiedOrder(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      image: image ?? this.image,
      type: type ?? this.type,
      status: status ?? this.status,
      date: date ?? this.date,
      occurredAt: occurredAt ?? this.occurredAt,
      source: source ?? this.source,
    );
  }
}

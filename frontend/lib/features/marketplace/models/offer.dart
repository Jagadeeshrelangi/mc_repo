import 'package:flutter/material.dart';

/// Offer model representing a marketplace promotional offer.
/// Supports deserialization from backend JSON response and static mock fallback.
class Offer {
  final String id;
  final String title;
  final String subtitle;
  final String code;
  final Color gradientStart;
  final Color gradientEnd;
  final String? categoryId;

  const Offer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.code,
    required this.gradientStart,
    required this.gradientEnd,
    this.categoryId,
  });

  static Color _parseColor(dynamic raw, Color fallback) {
    if (raw == null) return fallback;
    var s = raw.toString().trim().replaceAll('#', '').replaceAll('0x', '');
    if (s.length == 6) {
      s = 'FF$s';
    }
    final val = int.tryParse(s, radix: 16);
    if (val == null) return fallback;
    return Color(val);
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      gradientStart: _parseColor(
        json['gradientStart'] ?? json['gradient_start'],
        const Color(0xFFF15A22),
      ),
      gradientEnd: _parseColor(
        json['gradientEnd'] ?? json['gradient_end'],
        const Color(0xFFD44A15),
      ),
      categoryId: (json['categoryId'] ?? json['category_id']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'code': code,
    'gradientStart':
        '#${(gradientStart.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
    'gradientEnd':
        '#${(gradientEnd.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
    'categoryId': categoryId,
  };

  @override
  String toString() => 'Offer{id: $id, title: $title, code: $code}';
}

import 'package:flutter/material.dart';

/// A marketplace promotional banner. [categoryId] links the banner to a browse
/// category so tapping it navigates (never a silent button).
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
}

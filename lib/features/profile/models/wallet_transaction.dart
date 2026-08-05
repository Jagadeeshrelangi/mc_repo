import 'package:flutter/material.dart';

/// Direction of a wallet movement.
enum WalletTransactionType {
  credit,
  debit;

  bool get isCredit => this == WalletTransactionType.credit;
}

/// One wallet movement (recharge, order payment, cashback, refund).
class WalletTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final WalletTransactionType type;
  final String date;
  final IconData? icon;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.date,
    this.icon,
  });
}

/// A promotional coupon visible in the wallet.
class Coupon {
  final String code;
  final String title;
  final String discount;
  final String validUntil;
  final bool isActive;

  const Coupon({
    required this.code,
    required this.title,
    required this.discount,
    required this.validUntil,
    this.isActive = true,
  });
}

/// A saved payment method (mock data only).
class PaymentMethod {
  final String id;
  final String name;
  final String details;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.details,
    required this.icon,
  });
}

/// Snapshot of the wallet state returned by the mock backend.
class WalletData {
  final double balance;
  final int rewardPoints;
  final List<WalletTransaction> transactions;
  final List<Coupon> coupons;
  final List<PaymentMethod> paymentMethods;

  const WalletData({
    required this.balance,
    required this.rewardPoints,
    required this.transactions,
    required this.coupons,
    required this.paymentMethods,
  });
}

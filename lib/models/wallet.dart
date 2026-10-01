import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 2)
class Wallet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type; // 'cash', 'bank', 'credit', 'savings', 'other'

  @HiveField(3)
  final double initialBalance;

  @HiveField(4)
  final String icon;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final bool isDefault;

  @HiveField(7)
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.colorValue,
    this.isDefault = false,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  IconData get iconData {
    return switch (icon) {
      'cash' || 'payments' => Icons.payments_outlined,
      'bank' || 'account_balance' => Icons.account_balance_outlined,
      'credit' || 'credit_card' => Icons.credit_card_outlined,
      'savings' => Icons.savings_outlined,
      'wallet' => Icons.account_balance_wallet_outlined,
      'shopping' => Icons.shopping_bag_outlined,
      'work' => Icons.work_outline,
      _ => Icons.account_balance_wallet_outlined,
    };
  }

  Wallet copyWith({
    String? id,
    String? name,
    String? type,
    double? initialBalance,
    String? icon,
    int? colorValue,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initialBalance': initialBalance,
      'icon': icon,
      'colorValue': colorValue,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      initialBalance: (json['initialBalance'] as num).toDouble(),
      icon: json['icon'],
      colorValue: json['colorValue'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

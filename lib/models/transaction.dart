import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String type; // 'income', 'expense', or 'transfer'

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final String? walletId; // Source wallet (or primary wallet)

  @HiveField(8)
  final String? toWalletId; // Destination wallet (for transfer)

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.notes,
    this.walletId,
    this.toWalletId,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? type,
    String? notes,
    String? walletId,
    String? toWalletId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'type': type,
      'notes': notes,
      'walletId': walletId,
      'toWalletId': toWalletId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      notes: json['notes'],
      walletId: json['walletId'],
      toWalletId: json['toWalletId'],
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/wallet.dart';

void main() {
  group('Wallet Model Tests', () {
    test('Wallet creation and properties', () {
      final now = DateTime.now();
      final wallet = Wallet(
        id: 'w1',
        name: 'Ví tiền mặt',
        type: 'cash',
        initialBalance: 500000,
        icon: 'cash',
        colorValue: 0xFF2E7D32,
        isDefault: true,
        createdAt: now,
      );

      expect(wallet.id, 'w1');
      expect(wallet.name, 'Ví tiền mặt');
      expect(wallet.type, 'cash');
      expect(wallet.initialBalance, 500000);
      expect(wallet.isDefault, isTrue);
    });

    test('Wallet copyWith works correctly', () {
      final now = DateTime.now();
      final wallet = Wallet(
        id: 'w1',
        name: 'Ví tiền mặt',
        type: 'cash',
        initialBalance: 500000,
        icon: 'cash',
        colorValue: 0xFF2E7D32,
        isDefault: true,
        createdAt: now,
      );

      final updated = wallet.copyWith(name: 'Tiền mặt đã đổi', initialBalance: 1000000);
      expect(updated.id, 'w1');
      expect(updated.name, 'Tiền mặt đã đổi');
      expect(updated.initialBalance, 1000000);
      expect(updated.isDefault, isTrue);
    });

    test('Wallet toJson and fromJson', () {
      final now = DateTime.now();
      final wallet = Wallet(
        id: 'w2',
        name: 'Vietcombank',
        type: 'bank',
        initialBalance: 2000000,
        icon: 'bank',
        colorValue: 0xFF1565C0,
        isDefault: false,
        createdAt: now,
      );

      final json = wallet.toJson();
      final fromJson = Wallet.fromJson(json);

      expect(fromJson.id, wallet.id);
      expect(fromJson.name, wallet.name);
      expect(fromJson.type, wallet.type);
      expect(fromJson.initialBalance, wallet.initialBalance);
      expect(fromJson.isDefault, wallet.isDefault);
    });
  });
}

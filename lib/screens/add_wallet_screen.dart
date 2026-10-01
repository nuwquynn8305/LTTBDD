import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/wallet.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;

  const AddWalletScreen({super.key, this.wallet});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedType = 'cash';
  String _selectedIcon = 'cash';
  int _selectedColor = 0xFF2E7D32;
  bool _isDefault = false;

  final List<String> _walletTypes = ['cash', 'bank', 'credit', 'savings', 'other'];

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'cash', 'icon': Icons.payments_outlined},
    {'name': 'bank', 'icon': Icons.account_balance_outlined},
    {'name': 'credit', 'icon': Icons.credit_card_outlined},
    {'name': 'savings', 'icon': Icons.savings_outlined},
    {'name': 'wallet', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'work', 'icon': Icons.work_outline},
  ];

  final List<int> _availableColors = [
    0xFF2E7D32, // Green
    0xFF1565C0, // Blue
    0xFFD84315, // Deep Orange
    0xFFF57F17, // Amber
    0xFF6A1B9A, // Purple
    0xFF00838F, // Teal
    0xFFC2185B, // Pink
    0xFF37474F, // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    if (widget.wallet != null) {
      final w = widget.wallet!;
      _nameController.text = w.name;
      _balanceController.text = w.initialBalance % 1 == 0
          ? w.initialBalance.toInt().toString()
          : w.initialBalance.toString();
      _selectedType = w.type;
      _selectedIcon = w.icon;
      _selectedColor = w.colorValue;
      _isDefault = w.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    final initialBalance = _balanceController.text.trim().isEmpty
        ? 0.0
        : double.parse(
            _balanceController.text.replaceAll(' ', '').replaceAll(',', '.'),
          );

    final wallet = Wallet(
      id: widget.wallet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: initialBalance,
      icon: _selectedIcon,
      colorValue: _selectedColor,
      isDefault: _isDefault,
      createdAt: widget.wallet?.createdAt ?? DateTime.now(),
    );

    if (widget.wallet == null) {
      await ref.read(walletNotifierProvider.notifier).addWallet(wallet);
    } else {
      await ref.read(walletNotifierProvider.notifier).updateWallet(wallet);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.wallet != null;
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? strings.editWallet : strings.addWallet),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: strings.walletName,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return strings.walletNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: strings.walletType,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: _walletTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(strings.getWalletTypeName(type)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _selectedIcon = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: strings.initialBalance,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: currency.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final clean = val.replaceAll(' ', '').replaceAll(',', '.');
                    if (double.tryParse(clean) == null) {
                      return strings.amountInvalid;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Icon selector
              Text(
                'Biểu tượng / Icon',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _availableIcons.map((item) {
                  final name = item['name'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = _selectedIcon == name;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = name),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Color selector
              Text(
                'Màu sắc / Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _availableColors.map((col) {
                  final isSelected = _selectedColor == col;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = col),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(col),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(col).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.isDefaultWallet),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveWallet,
                icon: const Icon(Icons.check),
                label: Text(isEditing ? strings.saveChanges : strings.addWallet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

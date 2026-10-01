import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import 'add_wallet_screen.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? initialFromWalletId;
  final String? initialToWalletId;

  const TransferScreen({
    super.key,
    this.initialFromWalletId,
    this.initialToWalletId,
  });

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String? _fromWalletId;
  String? _toWalletId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fromWalletId = widget.initialFromWalletId;
    _toWalletId = widget.initialToWalletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _executeTransfer(List<Wallet> wallets, AppStrings strings) async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromWalletId == null || _toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.selectWallet)),
      );
      return;
    }

    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.sameWalletError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final fromWallet = wallets.firstWhere((w) => w.id == _fromWalletId);
    final toWallet = wallets.firstWhere((w) => w.id == _toWalletId);

    final cleanAmount = _amountController.text
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    final amount = double.parse(cleanAmount);

    final title = _titleController.text.trim().isEmpty
        ? '${strings.transferPrefix}: ${fromWallet.name} ➔ ${toWallet.name}'
        : _titleController.text.trim();

    final transferTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: 'Chuyển tiền',
      date: _selectedDate,
      type: 'transfer',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      walletId: _fromWalletId,
      toWalletId: _toWalletId,
    );

    await ref
        .read(transactionNotifierProvider.notifier)
        .addTransaction(transferTx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.transferSuccess)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final colorScheme = Theme.of(context).colorScheme;

    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
        : DateFormat('EEEE, MMM dd, yyyy', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.transferBetweenWallets),
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Cần ít nhất 2 ví để thực hiện chuyển tiền.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddWalletScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(strings.addWallet),
                    ),
                  ],
                ),
              ),
            );
          }

          _fromWalletId ??= wallets.first.id;
          _toWalletId ??= wallets.length > 1 ? wallets[1].id : wallets.first.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transfer visual card
                  Card(
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _fromWalletId,
                            decoration: InputDecoration(
                              labelText: strings.fromWallet,
                              prefixIcon: const Icon(Icons.outbox_rounded),
                              border: const OutlineInputBorder(),
                            ),
                            items: wallets.map((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Row(
                                  children: [
                                    Icon(w.iconData, color: w.color, size: 18),
                                    const SizedBox(width: 8),
                                    Text(w.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _fromWalletId = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            icon: const Icon(Icons.swap_vert, size: 28),
                            onPressed: () {
                              setState(() {
                                final temp = _fromWalletId;
                                _fromWalletId = _toWalletId;
                                _toWalletId = temp;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _toWalletId,
                            decoration: InputDecoration(
                              labelText: strings.toWallet,
                              prefixIcon: const Icon(Icons.move_to_inbox_rounded),
                              border: const OutlineInputBorder(),
                            ),
                            items: wallets.map((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Row(
                                  children: [
                                    Icon(w.iconData, color: w.color, size: 18),
                                    const SizedBox(width: 8),
                                    Text(w.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _toWalletId = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: strings.amountLabel,
                      prefixIcon: const Icon(Icons.payments_outlined),
                      suffixText: currency.symbol,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return strings.amountRequired;
                      }
                      final clean =
                          val.replaceAll(' ', '').replaceAll(',', '.');
                      final parsed = double.tryParse(clean);
                      if (parsed == null || parsed <= 0) {
                        return strings.amountInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: strings.titleLabel,
                      hintText: 'Ví dụ: Nạp tiền ngân hàng, Rút tiền mặt...',
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: strings.dateLabel,
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(dateFormat.format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: strings.notesLabel,
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => _executeTransfer(wallets, strings),
                    icon: const Icon(Icons.send_rounded),
                    label: Text(strings.transfer),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(strings.errorLoading('$err'))),
      ),
    );
  }
}

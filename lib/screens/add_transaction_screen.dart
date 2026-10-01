import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/categories.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = Categories.expenseCategories[0];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _titleController.text = t.title;
      _amountController.text = t.amount % 1 == 0
          ? t.amount.toInt().toString()
          : t.amount.toString();
      _notesController.text = t.notes ?? '';
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final transaction = Transaction(
      id:
          widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: double.parse(
        _amountController.text.replaceAll(' ', '').replaceAll(',', '.'),
      ),
      category: _selectedCategory,
      date: _selectedDate,
      type: _selectedType,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (widget.transaction == null) {
      await ref
          .read(transactionNotifierProvider.notifier)
          .addTransaction(transaction);
    } else {
      await ref
          .read(transactionNotifierProvider.notifier)
          .updateTransaction(transaction);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    final locale = ref.watch(localeNotifierProvider);
    final currency = ref.watch(currencyNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
        : DateFormat('EEEE, MMM dd, yyyy', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? strings.editTransaction : strings.addTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'expense',
                    label: Text(strings.tabExpenses),
                    icon: const Icon(Icons.south_west),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text(strings.tabIncome),
                    icon: const Icon(Icons.north_east),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _selectedCategory = _selectedType == 'expense'
                        ? Categories.expenseCategories[0]
                        : Categories.incomeCategories[0];
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.titleLabel,
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.titleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: strings.amountLabel,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: currency.symbol,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return strings.amountRequired;
                  }
                  final cleanValue =
                      value.replaceAll(' ', '').replaceAll(',', '.');
                  final parsed = double.tryParse(cleanValue);
                  if (parsed == null || parsed <= 0) {
                    return strings.amountInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('$_selectedType-$_selectedCategory'),
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: strings.categoryLabel,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items:
                    (_selectedType == 'expense'
                            ? Categories.expenseCategories
                            : Categories.incomeCategories)
                        .map((category) {
                          final localizedCategory = Categories.getLocalizedName(
                            category,
                            locale.languageCode,
                          );
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(Categories.getMaterialIcon(category)),
                                const SizedBox(width: 12),
                                Text(localizedCategory),
                              ],
                            ),
                          );
                        })
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: strings.dateLabel,
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    dateFormat.format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: strings.notesLabel,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.check),
                label: Text(isEditing ? strings.saveChanges : strings.addTransaction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

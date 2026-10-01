import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../utils/categories.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _selectedCategory = Categories.expenseCategories[0];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      final b = widget.budget!;
      _amountController.text = b.limit.toStringAsFixed(0);
      _selectedCategory = b.category;
      _selectedMonth = b.month;
      _selectedYear = b.year;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectMonthYear() async {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedMonth = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn tháng'),
        content: SizedBox(
          width: 300,
          height: 280,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = month == _selectedMonth;

              return Padding(
                padding: const EdgeInsets.all(4),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('$month'),
                  onSelected: (_) => Navigator.pop(context, month),
                  selectedColor: colorScheme.secondaryContainer,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedMonth == null || !mounted) return;

    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn năm'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            selectedDate: DateTime(_selectedYear, selectedMonth),
            onChanged: (date) {
              Navigator.pop(context, date.year);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedYear != null) {
      setState(() {
        _selectedMonth = selectedMonth;
        _selectedYear = selectedYear;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final budget = Budget(
      id:
          widget.budget?.id ??
          '${_selectedCategory}_${_selectedMonth}_$_selectedYear',
      category: _selectedCategory,
      limit: double.parse(
        _amountController.text.replaceAll('.', '').replaceAll(',', ''),
      ),
      month: _selectedMonth,
      year: _selectedYear,
    );

    if (widget.budget == null) {
      await ref.read(budgetNotifierProvider.notifier).addBudget(budget);
    } else {
      await ref.read(budgetNotifierProvider.notifier).updateBudget(budget);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budget != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa ngân sách' : 'Thêm ngân sách'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: Categories.expenseCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(Categories.getMaterialIcon(category)),
                        const SizedBox(width: 12),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Giới hạn ngân sách',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: '₫',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giới hạn ngân sách';
                  }
                  final cleanValue = value
                      .replaceAll('.', '')
                      .replaceAll(',', '');
                  if (double.tryParse(cleanValue) == null ||
                      double.parse(cleanValue) <= 0) {
                    return 'Vui lòng nhập số tiền hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectMonthYear,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tháng & năm',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text('Tháng $_selectedMonth/$_selectedYear'),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveBudget,
                icon: const Icon(Icons.check),
                label: Text(isEditing ? 'Lưu thay đổi' : 'Thêm ngân sách'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

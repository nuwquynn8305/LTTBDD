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
import '../utils/categories.dart';
import '../widgets/empty_state.dart';
import '../widgets/theme_action_button.dart';
import 'add_transaction_screen.dart';

// ── Filter State ──

class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryFilter;
  final String? walletFilter;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.categoryFilter,
    this.walletFilter,
  });

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryFilter,
    String? walletFilter,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCategory = false,
    bool clearWallet = false,
  }) {
    return TransactionFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      walletFilter: clearWallet ? null : (walletFilter ?? this.walletFilter),
    );
  }

  bool get hasAnyFilter =>
      startDate != null ||
      endDate != null ||
      categoryFilter != null ||
      walletFilter != null;

  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (categoryFilter != null) count++;
    if (walletFilter != null) count++;
    return count;
  }

  static const TransactionFilter empty = TransactionFilter();
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.empty);

// ── Main Screen ──

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.navTransactions),
          actions: [
            // Filter button with badge
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    filter.hasAnyFilter
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                  ),
                  tooltip: strings.filterTransactions,
                  onPressed: () => _showFilterSheet(context, ref),
                ),
                if (filter.hasAnyFilter)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${filter.activeFilterCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const ThemeActionButton(),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                  text: strings.tabExpenses,
                  icon: const Icon(Icons.south_west)),
              Tab(
                  text: strings.tabIncome,
                  icon: const Icon(Icons.north_east)),
              Tab(
                  text: strings.tabTransfer,
                  icon: const Icon(Icons.sync_alt)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Active filter summary bar
            if (filter.hasAnyFilter)
              _ActiveFilterBar(filter: filter, strings: strings),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // Apply all filters
                  final filtered =
                      _applyFilters(transactions, filter, walletsAsync);

                  if (filtered.isEmpty && filter.hasAnyFilter) {
                    return EmptyState(
                      icon: Icons.search_off_outlined,
                      title: strings.noMatchingTransactions,
                      message: strings.noMatchingTransactionsDesc,
                      actionLabel: strings.clearFilters,
                      onAction: () => ref
                          .read(transactionFilterProvider.notifier)
                          .state = TransactionFilter.empty,
                    );
                  }

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: strings.noTransactions,
                      message: strings.noTransactionsDesc,
                      actionLabel: strings.addTransaction,
                      onAction: () => _openEditor(context),
                    );
                  }

                  final expenseTransactions = filtered
                      .where((t) => t.type == 'expense')
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  final incomeTransactions = filtered
                      .where((t) => t.type == 'income')
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  final transferTransactions = filtered
                      .where((t) => t.type == 'transfer')
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

                  return TabBarView(
                    children: [
                      _TransactionList(transactions: expenseTransactions),
                      _TransactionList(transactions: incomeTransactions),
                      _TransactionList(transactions: transferTransactions),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text(strings.errorLoading('$error'))),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add),
          label: Text(strings.addTransaction),
        ),
      ),
    );
  }

  List<Transaction> _applyFilters(
    List<Transaction> transactions,
    TransactionFilter filter,
    AsyncValue<List<Wallet>> walletsAsync,
  ) {
    var result = transactions;

    // Date range filter
    if (filter.startDate != null) {
      final start = DateTime(filter.startDate!.year, filter.startDate!.month,
          filter.startDate!.day);
      result = result.where((t) => !t.date.isBefore(start)).toList();
    }
    if (filter.endDate != null) {
      final end = DateTime(filter.endDate!.year, filter.endDate!.month,
          filter.endDate!.day, 23, 59, 59);
      result = result.where((t) => !t.date.isAfter(end)).toList();
    }

    // Category filter
    if (filter.categoryFilter != null) {
      result =
          result.where((t) => t.category == filter.categoryFilter).toList();
    }

    // Wallet filter
    if (filter.walletFilter != null) {
      result = result
          .where((t) =>
              t.walletId == filter.walletFilter ||
              t.toWalletId == filter.walletFilter)
          .toList();
    }

    return result;
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _FilterBottomSheet(parentRef: ref),
    );
  }

  void _openEditor(BuildContext context, {Transaction? transaction}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );
  }
}

// ── Active Filter Bar ──

class _ActiveFilterBar extends ConsumerWidget {
  final TransactionFilter filter;
  final AppStrings strings;

  const _ActiveFilterBar({required this.filter, required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('dd/MM/yyyy', 'vi_VN')
        : DateFormat('MMM dd, yyyy', 'en_US');

    return Container(
      width: double.infinity,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (filter.startDate != null || filter.endDate != null)
                    _chipTag(
                      context,
                      Icons.date_range,
                      _dateRangeLabel(
                          filter.startDate, filter.endDate, dateFormat),
                      () => ref.read(transactionFilterProvider.notifier).state =
                          filter.copyWith(
                              clearStartDate: true, clearEndDate: true),
                    ),
                  if (filter.categoryFilter != null)
                    _chipTag(
                      context,
                      Categories.getMaterialIcon(filter.categoryFilter!),
                      Categories.getLocalizedName(
                          filter.categoryFilter!, locale.languageCode),
                      () => ref.read(transactionFilterProvider.notifier).state =
                          filter.copyWith(clearCategory: true),
                    ),
                  if (filter.walletFilter != null)
                    walletsAsync.when(
                      data: (wallets) {
                        final w = wallets
                            .where((w) => w.id == filter.walletFilter)
                            .firstOrNull;
                        return _chipTag(
                          context,
                          w?.iconData ?? Icons.wallet,
                          w?.name ?? '?',
                          () => ref
                              .read(transactionFilterProvider.notifier)
                              .state = filter.copyWith(clearWallet: true),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => ref.read(transactionFilterProvider.notifier).state =
                TransactionFilter.empty,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRangeLabel(
      DateTime? start, DateTime? end, DateFormat dateFormat) {
    if (start != null && end != null) {
      return '${dateFormat.format(start)} – ${dateFormat.format(end)}';
    } else if (start != null) {
      return '${strings.fromDate} ${dateFormat.format(start)}';
    } else if (end != null) {
      return '${strings.toDate} ${dateFormat.format(end)}';
    }
    return '';
  }

  Widget _chipTag(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onRemove,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        avatar: Icon(icon, size: 14, color: colorScheme.primary),
        label: Text(label,
            style: TextStyle(fontSize: 12, color: colorScheme.primary)),
        deleteIcon: Icon(Icons.close, size: 14, color: colorScheme.primary),
        onDeleted: onRemove,
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}

// ── Filter Bottom Sheet ──

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;

  const _FilterBottomSheet({required this.parentRef});

  @override
  ConsumerState<_FilterBottomSheet> createState() =>
      _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late String? _categoryFilter;
  late String? _walletFilter;

  @override
  void initState() {
    super.initState();
    final current = widget.parentRef.read(transactionFilterProvider);
    _startDate = current.startDate;
    _endDate = current.endDate;
    _categoryFilter = current.categoryFilter;
    _walletFilter = current.walletFilter;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final walletsAsync = ref.watch(walletsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('dd/MM/yyyy', 'vi_VN')
        : DateFormat('MMM dd, yyyy', 'en_US');

    final allCategories = [
      ...Categories.expenseCategories,
      ...Categories.incomeCategories
          .where((c) => !Categories.expenseCategories.contains(c)),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title row
              Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    strings.filterTransactions,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_hasAnyFilter)
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: Text(strings.clearFilters),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Date Range Section ──
              _sectionTitle(context, Icons.date_range, strings.dateRange),
              const SizedBox(height: 8),

              // Quick date presets
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _datePresetChip(strings.today, _todayRange),
                  _datePresetChip(strings.thisWeek, _thisWeekRange),
                  _datePresetChip(strings.thisMonth, _thisMonthRange),
                  _datePresetChip(strings.last30Days, _last30DaysRange),
                  _datePresetChip(strings.last90Days, _last90DaysRange),
                ],
              ),
              const SizedBox(height: 10),

              // Custom date picker row
              Row(
                children: [
                  Expanded(
                    child: _dateTile(
                      context,
                      label: strings.fromDate,
                      date: _startDate,
                      dateFormat: dateFormat,
                      hint: strings.pickStartDate,
                      onTap: () => _pickDate(isStart: true),
                      onClear: _startDate != null
                          ? () => setState(() => _startDate = null)
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        size: 18, color: colorScheme.outline),
                  ),
                  Expanded(
                    child: _dateTile(
                      context,
                      label: strings.toDate,
                      date: _endDate,
                      dateFormat: dateFormat,
                      hint: strings.pickEndDate,
                      onTap: () => _pickDate(isStart: false),
                      onClear: _endDate != null
                          ? () => setState(() => _endDate = null)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Category Section ──
              _sectionTitle(
                  context, Icons.category_outlined, strings.filterByCategory),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  FilterChip(
                    selected: _categoryFilter == null,
                    label: Text(strings.allCategories),
                    onSelected: (_) =>
                        setState(() => _categoryFilter = null),
                  ),
                  ...allCategories.map((cat) {
                    final isSelected = _categoryFilter == cat;
                    final localizedName = Categories.getLocalizedName(
                        cat, locale.languageCode);
                    return FilterChip(
                      avatar: Icon(Categories.getMaterialIcon(cat),
                          size: 16,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : Categories.getMaterialColor(cat)),
                      selected: isSelected,
                      label: Text(localizedName),
                      onSelected: (_) {
                        setState(
                            () => _categoryFilter = isSelected ? null : cat);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // ── Wallet Section ──
              _sectionTitle(context, Icons.wallet, strings.filterByWallet),
              const SizedBox(height: 8),
              walletsAsync.when(
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      FilterChip(
                        selected: _walletFilter == null,
                        label: Text(strings.allWallets),
                        onSelected: (_) =>
                            setState(() => _walletFilter = null),
                      ),
                      ...wallets.map((w) {
                        final isSelected = _walletFilter == w.id;
                        return FilterChip(
                          avatar:
                              Icon(w.iconData, size: 16, color: w.color),
                          selected: isSelected,
                          label: Text(w.name),
                          onSelected: (_) {
                            setState(() =>
                                _walletFilter = isSelected ? null : w.id);
                          },
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_all),
                      label: Text(strings.clearFilters),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check),
                      label: Text(strings.applyFilters),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ──

  bool get _hasAnyFilter =>
      _startDate != null ||
      _endDate != null ||
      _categoryFilter != null ||
      _walletFilter != null;

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _datePresetChip(
      String label, ({DateTime start, DateTime end}) Function() rangeFn) {
    final range = rangeFn();
    final isActive = _startDate != null &&
        _endDate != null &&
        _isSameDay(_startDate!, range.start) &&
        _isSameDay(_endDate!, range.end);

    return ChoiceChip(
      selected: isActive,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      onSelected: (_) {
        setState(() {
          if (isActive) {
            _startDate = null;
            _endDate = null;
          } else {
            _startDate = range.start;
            _endDate = range.end;
          }
        });
      },
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required String hint,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: date != null
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? dateFormat.format(date) : hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null
                          ? colorScheme.onSurface
                          : colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: colorScheme.outline),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto-adjust end if needed
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          // Auto-adjust start if needed
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  void _clearAll() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _categoryFilter = null;
      _walletFilter = null;
    });
  }

  void _apply() {
    widget.parentRef.read(transactionFilterProvider.notifier).state =
        TransactionFilter(
      startDate: _startDate,
      endDate: _endDate,
      categoryFilter: _categoryFilter,
      walletFilter: _walletFilter,
    );
    Navigator.pop(context);
  }

  // ── Date Range Presets ──

  ({DateTime start, DateTime end}) _todayRange() {
    final now = DateTime.now();
    return (start: DateTime(now.year, now.month, now.day), end: now);
  }

  ({DateTime start, DateTime end}) _thisWeekRange() {
    final now = DateTime.now();
    final weekDay = now.weekday; // 1 = Monday
    final start = now.subtract(Duration(days: weekDay - 1));
    return (
      start: DateTime(start.year, start.month, start.day),
      end: now,
    );
  }

  ({DateTime start, DateTime end}) _thisMonthRange() {
    final now = DateTime.now();
    return (start: DateTime(now.year, now.month, 1), end: now);
  }

  ({DateTime start, DateTime end}) _last30DaysRange() {
    final now = DateTime.now();
    return (start: now.subtract(const Duration(days: 30)), end: now);
  }

  ({DateTime start, DateTime end}) _last90DaysRange() {
    final now = DateTime.now();
    return (start: now.subtract(const Duration(days: 90)), end: now);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Transaction List ──

class _TransactionList extends ConsumerWidget {
  final List<Transaction> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final strings = AppStrings.fromLocale(locale);

    if (transactions.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off_outlined,
        title: strings.noItemsInTab,
        message: strings.noItemsInTabDesc,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyNotifierProvider);

    final dateFormat = locale.languageCode == 'vi'
        ? DateFormat('dd/MM/yyyy HH:mm', 'vi_VN')
        : DateFormat('MMM dd, yyyy HH:mm', 'en_US');

    final walletsMap = <String, Wallet>{};
    walletsAsync.whenData((wallets) {
      for (var w in wallets) {
        walletsMap[w.id] = w;
      }
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isIncome = transaction.type == 'income';
        final isTransfer = transaction.type == 'transfer';

        final amountColor = isTransfer
            ? colorScheme.primary
            : (isIncome ? colorScheme.tertiary : colorScheme.error);

        final categoryColor = isTransfer
            ? colorScheme.primary
            : Categories.getMaterialColor(transaction.category);

        final localizedCategory = isTransfer
            ? strings.transfer
            : Categories.getLocalizedName(
                transaction.category,
                locale.languageCode,
              );

        final fromWallet = walletsMap[transaction.walletId];
        final toWallet = walletsMap[transaction.toWalletId];

        String subtitleText =
            '${dateFormat.format(transaction.date)} • $localizedCategory';

        if (isTransfer && fromWallet != null && toWallet != null) {
          subtitleText += '\n${fromWallet.name} ➔ ${toWallet.name}';
        } else if (fromWallet != null) {
          subtitleText += ' (${fromWallet.name})';
        }

        return Dismissible(
          key: Key(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete_outline,
                color: colorScheme.onErrorContainer),
          ),
          confirmDismiss: (direction) => _confirmDelete(context, strings),
          onDismissed: (direction) {
            ref
                .read(transactionNotifierProvider.notifier)
                .deleteTransaction(transaction.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.transactionDeleted)),
            );
          },
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: categoryColor.withValues(alpha: 0.16),
                foregroundColor: categoryColor,
                child: Icon(
                  isTransfer
                      ? Icons.sync_alt
                      : Categories.getMaterialIcon(transaction.category),
                ),
              ),
              title: Text(
                transaction.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(subtitleText),
              isThreeLine: isTransfer || fromWallet != null,
              trailing: Text(
                isTransfer
                    ? currency.format(transaction.amount)
                    : currency.formatWithSign(
                        transaction.amount,
                        isIncome: isIncome,
                      ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddTransactionScreen(transaction: transaction),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppStrings strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(strings.deleteTransactionConfirmTitle),
        content: Text(strings.deleteTransactionConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

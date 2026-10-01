import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/expense_chart.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/theme_action_button.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({super.key, this.onViewAllTransactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navDashboard),
        actions: const [ThemeActionButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const BalanceCard(),
          const SizedBox(height: 8),
          const ExpenseChart(),
          const SizedBox(height: 8),
          RecentTransactionsWidget(onViewAll: onViewAllTransactions),
        ],
      ),
    );
  }
}

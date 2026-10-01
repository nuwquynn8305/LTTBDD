import 'package:flutter/material.dart';
import '../widgets/balance_card.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/expense_chart.dart';
import '../widgets/theme_action_button.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({super.key, this.onViewAllTransactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
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

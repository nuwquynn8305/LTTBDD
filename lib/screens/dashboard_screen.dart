import 'package:flutter/material.dart';
import '../widgets/balance_card.dart';
import '../widgets/recent_transactions_widget.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onViewAllTransactions;

  const DashboardScreen({super.key, this.onViewAllTransactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BalanceCard(),
              const SizedBox(height: 16),
              RecentTransactionsWidget(
                onViewAll: onViewAllTransactions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/budgets_screen.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initApp();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initApp() async {
  await initializeDateFormatting('vi_VN');
  final storageService = StorageService();
  await storageService.init();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final lightTheme = ref.read(lightThemeProvider);
    final darkTheme = ref.read(darkThemeProvider);

    return MaterialApp(
      title: 'Quản lý chi tiêu',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _switchToTransactions() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onViewAllTransactions: _switchToTransactions),
          const TransactionsScreen(),
          const BudgetsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Ngân sách',
          ),
        ],
      ),
    );
  }
}

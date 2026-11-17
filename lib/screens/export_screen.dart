import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../models/app_currency.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/export_service.dart';

// For web download
import 'dart:html' as html;

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;
  String? _lastExportMessage;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeNotifierProvider);
    final strings = AppStrings.fromLocale(locale);
    final colorScheme = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.isVi ? 'Xuất dữ liệu' : 'Export Data'),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_download_off_outlined,
                      size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    strings.noTransactions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.isVi
                        ? 'Cần có giao dịch để xuất dữ liệu.'
                        : 'Need transactions to export data.',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          // Count by type
          final incomeCount =
              transactions.where((t) => t.type == 'income').length;
          final expenseCount =
              transactions.where((t) => t.type == 'expense').length;
          final transferCount =
              transactions.where((t) => t.type == 'transfer').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics_outlined,
                              color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            strings.isVi
                                ? 'Tổng quan dữ liệu'
                                : 'Data Summary',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _summaryRow(
                        context,
                        Icons.south_west,
                        colorScheme.error,
                        strings.tabExpenses,
                        '$expenseCount ${strings.isVi ? 'giao dịch' : 'transactions'}',
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        context,
                        Icons.north_east,
                        colorScheme.tertiary,
                        strings.tabIncome,
                        '$incomeCount ${strings.isVi ? 'giao dịch' : 'transactions'}',
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        context,
                        Icons.sync_alt,
                        colorScheme.primary,
                        strings.tabTransfer,
                        '$transferCount ${strings.isVi ? 'giao dịch' : 'transactions'}',
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 16, color: colorScheme.outline),
                          const SizedBox(width: 6),
                          Text(
                            strings.isVi
                                ? 'Tổng: ${transactions.length} giao dịch'
                                : 'Total: ${transactions.length} transactions',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Export Options Title
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  strings.isVi
                      ? 'Chọn định dạng xuất'
                      : 'Choose export format',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),

              // CSV Export Card
              _ExportOptionCard(
                icon: Icons.table_chart_outlined,
                iconColor: Colors.green.shade700,
                bgColor: Colors.green.shade50,
                title: strings.isVi
                    ? 'Xuất file CSV (Excel)'
                    : 'Export CSV (Excel)',
                description: strings.isVi
                    ? 'File bảng tính có thể mở bằng Excel, Google Sheets. Dễ chỉnh sửa và phân tích thêm.'
                    : 'Spreadsheet file that can be opened in Excel, Google Sheets. Easy to edit and analyze.',
                chips: ['Excel', 'Google Sheets', 'Numbers'],
                isExporting: _isExporting,
                onDownload: () => _exportCsv(transactions, download: true),
                onShare: () => _exportCsv(transactions, download: false),
                downloadLabel: strings.isVi ? 'Tải xuống' : 'Download',
                shareLabel: strings.isVi ? 'Chia sẻ' : 'Share',
              ),

              const SizedBox(height: 12),

              // PDF Export Card
              _ExportOptionCard(
                icon: Icons.picture_as_pdf_outlined,
                iconColor: Colors.red.shade700,
                bgColor: Colors.red.shade50,
                title: strings.isVi ? 'Xuất file PDF' : 'Export PDF',
                description: strings.isVi
                    ? 'File báo cáo chuyên nghiệp, có tổng kết. Gửi qua Zalo, Email dễ dàng.'
                    : 'Professional report with summary. Easy to share via email or chat.',
                chips: ['Zalo', 'Email', 'Print'],
                isExporting: _isExporting,
                onDownload: () => _exportPdf(transactions, download: true),
                onShare: () => _exportPdf(transactions, download: false),
                downloadLabel: strings.isVi ? 'Tải / Xem' : 'Download / View',
                shareLabel: strings.isVi ? 'Chia sẻ' : 'Share',
              ),

              // Status message
              if (_lastExportMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: colorScheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastExportMessage!,
                            style: TextStyle(
                                color: colorScheme.onTertiaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_isExporting) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(strings.errorLoading('$error'))),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Map<String, Wallet> _getWalletsMap() {
    final walletsAsync = ref.read(walletsProvider);
    final map = <String, Wallet>{};
    walletsAsync.whenData((wallets) {
      for (final w in wallets) {
        map[w.id] = w;
      }
    });
    return map;
  }

  AppStrings get _strings =>
      AppStrings.fromLocale(ref.read(localeNotifierProvider));
  AppCurrency get _currency => ref.read(currencyNotifierProvider);

  Future<void> _exportCsv(List<Transaction> transactions,
      {required bool download}) async {
    setState(() {
      _isExporting = true;
      _lastExportMessage = null;
    });

    try {
      final csv = ExportService.generateCsv(
        transactions: transactions,
        walletsMap: _getWalletsMap(),
        strings: _strings,
        currency: _currency,
      );

      final fileName = ExportService.fileName('csv');

      if (download || kIsWeb) {
        // Web: trigger browser download
        _downloadFileWeb(
          content: utf8.encode(csv),
          fileName: fileName,
          mimeType: 'text/csv',
        );
        setState(() {
          _lastExportMessage = _strings.isVi
              ? 'Đã tải file $fileName thành công!'
              : 'Downloaded $fileName successfully!';
        });
      } else {
        // Mobile: share via share_plus
        await Share.share(
          csv,
          subject: fileName,
        );
        setState(() {
          _lastExportMessage = _strings.isVi
              ? 'Đã chia sẻ file CSV!'
              : 'CSV file shared!';
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf(List<Transaction> transactions,
      {required bool download}) async {
    setState(() {
      _isExporting = true;
      _lastExportMessage = null;
    });

    try {
      final pdfBytes = await ExportService.generatePdf(
        transactions: transactions,
        walletsMap: _getWalletsMap(),
        strings: _strings,
        currency: _currency,
      );

      final fileName = ExportService.fileName('pdf');

      if (download) {
        if (kIsWeb) {
          // Web: trigger browser download
          _downloadFileWeb(
            content: pdfBytes,
            fileName: fileName,
            mimeType: 'application/pdf',
          );
        } else {
          // Mobile: use printing package to preview/print
          await Printing.layoutPdf(
            onLayout: (_) async => pdfBytes,
            name: fileName,
          );
        }

        setState(() {
          _lastExportMessage = _strings.isVi
              ? 'Đã tải file $fileName thành công!'
              : 'Downloaded $fileName successfully!';
        });
      } else {
        if (kIsWeb) {
          // Web: download is the only option
          _downloadFileWeb(
            content: pdfBytes,
            fileName: fileName,
            mimeType: 'application/pdf',
          );
        } else {
          // Mobile: share via printing
          await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        }
        setState(() {
          _lastExportMessage = _strings.isVi
              ? 'Đã chia sẻ file PDF!'
              : 'PDF file shared!';
        });
      }
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _downloadFileWeb({
    required List<int> content,
    required String fileName,
    required String mimeType,
  }) {
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showError(Object e) {
    setState(() {
      _lastExportMessage = _strings.isVi
          ? 'Lỗi: $e'
          : 'Error: $e';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_strings.errorGeneric}: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ── Export Option Card Widget ──

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String description;
  final List<String> chips;
  final bool isExporting;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final String downloadLabel;
  final String shareLabel;

  const _ExportOptionCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.description,
    required this.chips,
    required this.isExporting,
    required this.onDownload,
    required this.onShare,
    required this.downloadLabel,
    required this.shareLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Compatible with chips
            Wrap(
              spacing: 6,
              children: chips
                  .map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                            color:
                                colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isExporting ? null : onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(downloadLabel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isExporting ? null : onShare,
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(shareLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../l10n/app_strings.dart';
import '../models/app_currency.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class ExportService {
  // ── CSV Export ──

  static String generateCsv({
    required List<Transaction> transactions,
    required Map<String, Wallet> walletsMap,
    required AppStrings strings,
    required AppCurrency currency,
  }) {
    final headers = [
      strings.dateLabel,
      strings.titleLabel,
      strings.categoryLabel,
      strings.isVi ? 'Loại' : 'Type',
      strings.amountLabel,
      strings.isVi ? 'Ví' : 'Wallet',
      strings.isVi ? 'Ví nhận' : 'To Wallet',
      strings.notesLabel,
    ];

    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final rows = <List<dynamic>>[headers];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (final t in sorted) {
      final walletName = walletsMap[t.walletId]?.name ?? '';
      final toWalletName = walletsMap[t.toWalletId]?.name ?? '';

      String typeLabel;
      if (t.type == 'income') {
        typeLabel = strings.tabIncome;
      } else if (t.type == 'expense') {
        typeLabel = strings.tabExpenses;
      } else {
        typeLabel = strings.transfer;
      }

      rows.add([
        dateFormat.format(t.date),
        t.title,
        t.category,
        typeLabel,
        t.amount,
        walletName,
        toWalletName,
        t.notes ?? '',
      ]);
    }

    // Summary row
    final totalIncome = sorted
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = sorted
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    rows.add([]); // blank row
    rows.add(['', strings.totalIncome, '', '', totalIncome, '', '', '']);
    rows.add(['', strings.totalExpenses, '', '', totalExpense, '', '', '']);
    rows.add([
      '',
      strings.currentBalance,
      '',
      '',
      totalIncome - totalExpense,
      '',
      '',
      '',
    ]);

    return Csv(addBom: true).encode(rows);
  }

  // ── PDF Export ──

  static Future<Uint8List> generatePdf({
    required List<Transaction> transactions,
    required Map<String, Wallet> walletsMap,
    required AppStrings strings,
    required AppCurrency currency,
  }) async {
    final pdf = pw.Document();

    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final shortDateFormat = DateFormat('dd/MM/yyyy');

    // Summaries
    final totalIncome = sorted
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = sorted
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;
    final totalTransfer = sorted
        .where((t) => t.type == 'transfer')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Date range info
    String dateRangeText = '';
    if (sorted.isNotEmpty) {
      final earliest = sorted.last.date;
      final latest = sorted.first.date;
      dateRangeText =
          '${shortDateFormat.format(earliest)} - ${shortDateFormat.format(latest)}';
    }

    final exportDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Split transactions into pages of 20
    const pageSize = 20;
    final pageCount = (sorted.length / pageSize).ceil().clamp(1, 100);

    for (int page = 0; page < pageCount; page++) {
      final startIdx = page * pageSize;
      final endIdx = (startIdx + pageSize).clamp(0, sorted.length);
      final pageTransactions = sorted.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => _pdfHeader(
            strings: strings,
            dateRangeText: dateRangeText,
            exportDate: exportDate,
            isFirstPage: page == 0,
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '${strings.isVi ? 'Trang' : 'Page'} ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          build: (context) {
            final widgets = <pw.Widget>[];

            // Summary cards on first page
            if (page == 0) {
              widgets.add(_pdfSummaryRow(
                strings: strings,
                currency: currency,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                balance: balance,
                totalTransfer: totalTransfer,
                transactionCount: sorted.length,
              ));
              widgets.add(pw.SizedBox(height: 16));
            }

            // Table header
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.0), // Date
                  1: const pw.FlexColumnWidth(2.5), // Title
                  2: const pw.FlexColumnWidth(1.8), // Category
                  3: const pw.FlexColumnWidth(1.2), // Type
                  4: const pw.FlexColumnWidth(1.8), // Amount
                  5: const pw.FlexColumnWidth(1.8), // Wallet
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _pdfHeaderCell(strings.dateLabel),
                      _pdfHeaderCell(strings.titleLabel),
                      _pdfHeaderCell(strings.categoryLabel),
                      _pdfHeaderCell(strings.isVi ? 'Loai' : 'Type'),
                      _pdfHeaderCell(strings.amountLabel),
                      _pdfHeaderCell(strings.isVi ? 'Vi' : 'Wallet'),
                    ],
                  ),
                  // Data rows
                  ...pageTransactions.map((t) {
                    String typeLabel;
                    PdfColor typeColor;
                    if (t.type == 'income') {
                      typeLabel = strings.isVi ? 'Thu' : 'Income';
                      typeColor = PdfColors.green700;
                    } else if (t.type == 'expense') {
                      typeLabel = strings.isVi ? 'Chi' : 'Expense';
                      typeColor = PdfColors.red700;
                    } else {
                      typeLabel = strings.isVi ? 'Chuyen' : 'Transfer';
                      typeColor = PdfColors.blue700;
                    }

                    final walletName = walletsMap[t.walletId]?.name ?? '';
                    final toWalletName = walletsMap[t.toWalletId]?.name ?? '';
                    final walletDisplay = t.type == 'transfer' && toWalletName.isNotEmpty
                        ? '$walletName -> $toWalletName'
                        : walletName;

                    return pw.TableRow(
                      children: [
                        _pdfCell(dateFormat.format(t.date)),
                        _pdfCell(t.title),
                        _pdfCell(t.category),
                        _pdfCell(typeLabel, color: typeColor),
                        _pdfCell(
                          currency.format(t.amount),
                          alignment: pw.Alignment.centerRight,
                          color: typeColor,
                        ),
                        _pdfCell(walletDisplay),
                      ],
                    );
                  }),
                ],
              ),
            );

            // Summary footer on last page
            if (page == pageCount - 1) {
              widgets.add(pw.SizedBox(height: 12));
              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _pdfSummaryItem(
                          strings.totalIncome, currency.format(totalIncome),
                          color: PdfColors.green700),
                      _pdfSummaryItem(
                          strings.totalExpenses, currency.format(totalExpense),
                          color: PdfColors.red700),
                      _pdfSummaryItem(
                          strings.currentBalance, currency.format(balance),
                          color: PdfColors.blue800,
                          bold: true),
                    ],
                  ),
                ),
              );
            }

            return widgets;
          },
        ),
      );
    }

    return pdf.save();
  }

  // ── PDF Helper Widgets ──

  static pw.Widget _pdfHeader({
    required AppStrings strings,
    required String dateRangeText,
    required String exportDate,
    required bool isFirstPage,
  }) {
    if (!isFirstPage) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          strings.appTitle,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue200, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            strings.appTitle,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                strings.isVi
                    ? 'Bao cao lich su giao dich'
                    : 'Transaction History Report',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                dateRangeText,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${strings.isVi ? 'Xuat ngay' : 'Exported'}: $exportDate',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSummaryRow({
    required AppStrings strings,
    required AppCurrency currency,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required double totalTransfer,
    required int transactionCount,
  }) {
    return pw.Row(
      children: [
        _pdfSummaryCard(
          strings.totalIncome,
          currency.format(totalIncome),
          PdfColors.green50,
          PdfColors.green700,
        ),
        pw.SizedBox(width: 8),
        _pdfSummaryCard(
          strings.totalExpenses,
          currency.format(totalExpense),
          PdfColors.red50,
          PdfColors.red700,
        ),
        pw.SizedBox(width: 8),
        _pdfSummaryCard(
          strings.currentBalance,
          currency.format(balance),
          PdfColors.blue50,
          PdfColors.blue800,
        ),
        pw.SizedBox(width: 8),
        _pdfSummaryCard(
          strings.isVi ? 'Giao dich' : 'Transactions',
          '$transactionCount',
          PdfColors.amber50,
          PdfColors.amber800,
        ),
      ],
    );
  }

  static pw.Widget _pdfSummaryCard(
    String label,
    String value,
    PdfColor bgColor,
    PdfColor textColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: textColor.shade(0.3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: textColor)),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: color ?? PdfColors.grey800,
        ),
        maxLines: 2,
      ),
    );
  }

  static pw.Widget _pdfSummaryItem(String label, String value,
      {PdfColor color = PdfColors.grey800, bool bold = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── File name helper ──

  static String fileName(String extension) {
    final now = DateTime.now();
    final date = DateFormat('yyyyMMdd_HHmmss').format(now);
    return 'expense_tracker_$date.$extension';
  }
}

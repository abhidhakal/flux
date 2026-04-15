import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import '../models/transaction_model.dart';
import 'currency_service.dart';

/// Service for exporting user financial data to CSV or PDF formats.
class DataExportService {
  final CurrencyService _currencyService = CurrencyService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd');

  // Brand Colors
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF2563EB); // Blue 600
  static const PdfColor _secondaryColor = PdfColor.fromInt(0xFF1E293B); // Slate 800
  static const PdfColor _accentColor = PdfColor.fromInt(0xFFF1F5F9); // Slate 100
  static const PdfColor _textGrey = PdfColor.fromInt(0xFF64748B); // Slate 500

  static pw.MemoryImage? _cachedLogoImage;
  static pw.Font? _cachedFontRegular;
  static pw.Font? _cachedFontBold;

  /// Generates CSV content from unified transaction data.
  String generateCsv(List<Transaction> transactions) {
    final List<List<dynamic>> rows = [];

    rows.add(['=== TRANSACTIONS ===']);
    rows.add(['Date', 'Title', 'Category', 'Amount', 'Type', 'Essential']);
    
    for (final t in transactions) {
      rows.add([
        _dateFormat.format(t.date),
        t.title,
        t.category,
        t.amount.toStringAsFixed(2),
        t.type.name,
        t.isEssential ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a PDF document from unified transaction data.
  Future<Uint8List> generatePdf(
    List<Transaction> transactions,
    String userName,
    {
    String? reportScope,
    String? reportRange,
  }
  ) async {
    final pdf = pw.Document();
    final currencySymbol = _currencyService.symbol;

    pw.MemoryImage? logoImage = _cachedLogoImage;
    if (logoImage == null) {
      try {
        logoImage = pw.MemoryImage(
          (await rootBundle.load('assets/images/flux_logo.png'))
              .buffer
              .asUint8List(),
        );
        _cachedLogoImage = logoImage;
      } catch (_) {
        logoImage = null;
      }
    }

    pw.Font? fontRegular = _cachedFontRegular;
    pw.Font? fontBold = _cachedFontBold;
    if (fontRegular == null || fontBold == null) {
      try {
        fontRegular = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Satoshi/Satoshi-Regular.ttf'),
        );
        fontBold = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Satoshi/Satoshi-Bold.ttf'),
        );
        _cachedFontRegular = fontRegular;
        _cachedFontBold = fontBold;
      } catch (_) {
        fontRegular = null;
        fontBold = null;
      }
    }

    // Calculate totals
    final expenseTransactions = transactions.where((t) => t.isExpense).toList();
    final incomes = transactions.where((t) => t.isIncome).toList();
    final totalIncome = incomes.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpenses =
        expenseTransactions.fold<double>(0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpenses;

    final pageTheme = (fontRegular != null && fontBold != null)
        ? pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            theme: pw.ThemeData.withFont(
              base: fontRegular,
              bold: fontBold,
            ),
          )
        : pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
          );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) =>
            _buildPdfHeader(logoImage, userName, reportScope, reportRange),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary Section
          pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _secondaryColor)),
          pw.SizedBox(height: 12),
          _buildSummarySection(totalIncome, totalExpenses, netBalance, currencySymbol),
          pw.SizedBox(height: 32),

          // Category Summary
          _buildSectionTitle('Spending by Category'),
          pw.SizedBox(height: 12),
          _buildCategorySummary(transactions, currencySymbol),
          pw.SizedBox(height: 32),
          
          // Transactions Table
          _buildSectionTitle('Transaction History'),
          pw.SizedBox(height: 6),
          _buildSectionMeta(
            leftLabel: 'Entries',
            leftValue: expenseTransactions.length.toString(),
            rightLabel: 'Total Expenses',
            rightValue: _formatCurrency(totalExpenses, currencySymbol),
          ),
          pw.SizedBox(height: 12),
          _buildTransactionsTable(expenseTransactions, currencySymbol),
          pw.SizedBox(height: 32),
          
          // Income Table
          _buildSectionTitle('Income Record'),
          pw.SizedBox(height: 6),
          _buildSectionMeta(
            leftLabel: 'Entries',
            leftValue: incomes.length.toString(),
            rightLabel: 'Total Income',
            rightValue: _formatCurrency(totalIncome, currencySymbol),
          ),
          pw.SizedBox(height: 12),
          _buildIncomeTable(incomes, currencySymbol),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(
    pw.MemoryImage? logo,
    String userName,
    String? reportScope,
    String? reportRange,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accentColor, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: _accentColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: logo != null
                    ? pw.Image(logo)
                    : pw.Center(
                        child: pw.Text(
                          'F',
                          style: pw.TextStyle(
                            color: _primaryColor,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Flux',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _secondaryColor,
                    ),
                  ),
                  pw.Text(
                    'Financial Statement',
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      color: _textGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                userName,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _secondaryColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Issued: ${_dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: _textGrey,
                ),
              ),
              if (reportScope != null && reportScope.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  reportScope,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _textGrey,
                  ),
                ),
              ],
              if (reportRange != null && reportRange.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  reportRange,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _textGrey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionMeta({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$leftLabel: $leftValue',
          style: const pw.TextStyle(fontSize: 9, color: _textGrey),
        ),
        pw.Text(
          '$rightLabel: $rightValue',
          style: const pw.TextStyle(fontSize: 9, color: _textGrey),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 24),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Flux',
            style: const pw.TextStyle(fontSize: 8, color: _textGrey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _textGrey),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(
    double totalIncome,
    double totalExpenses,
    double netBalance,
    String currencySymbol,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard('Total Income', totalIncome, currencySymbol, PdfColors.green600, true),
        pw.SizedBox(width: 16),
        _buildSummaryCard('Total Expenses', totalExpenses, currencySymbol, PdfColors.red600, false),
        pw.SizedBox(width: 16),
        _buildSummaryCard(
          'Net Balance', 
          netBalance, 
          currencySymbol, 
          netBalance >= 0 ? _primaryColor : PdfColors.red600, 
          true
        ),
      ],
    );
  }

  pw.Widget _buildSummaryCard(String label, double amount, String symbol, PdfColor color, bool isPositive) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: _accentColor, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(fontSize: 9.5, color: _textGrey, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              _formatCurrency(amount, symbol),
              style: pw.TextStyle(
                fontSize: 19,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _primaryColor, width: 4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16.5,
          fontWeight: pw.FontWeight.bold,
          color: _secondaryColor,
        ),
      ),
    );
  }

  pw.Widget _buildTransactionsTable(List<Transaction> transactions, String currencySymbol) {
    if (transactions.isEmpty) {
      return pw.Text('No transactions available for this period.', style: const pw.TextStyle(color: _textGrey, fontSize: 10));
    }

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _accentColor, width: 0.5),
        bottom: pw.BorderSide(color: _accentColor, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _accentColor),
          children: [
            _buildHeaderCell('DATE'),
            _buildHeaderCell('TITLE'),
            _buildHeaderCell('CATEGORY'),
            _buildHeaderCell('AMOUNT', alignRight: true),
          ],
        ),
        ...List.generate(transactions.length, (index) {
          final t = transactions[index];
          final isExpense = t.type == TransactionType.expense;
          final amountColor = isExpense ? PdfColors.red600 : PdfColors.green600;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven
                  ? PdfColors.white
                  : const PdfColor.fromInt(0xFFF8FAFC),
            ),
            children: [
              _buildBodyCell(_dateFormat.format(t.date)),
              _buildBodyCell(
                t.title.length > 30 ? '${t.title.substring(0, 30)}...' : t.title,
              ),
              _buildBodyCell(t.category),
              _buildBodyCell(
                _formatCurrency(
                  t.amount,
                  currencySymbol,
                  showSign: true,
                  isNegative: isExpense,
                ),
                alignRight: true,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: amountColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildIncomeTable(List<Transaction> incomes, String currencySymbol) {
    if (incomes.isEmpty) {
      return pw.Text('No income records available for this period.', style: const pw.TextStyle(color: _textGrey, fontSize: 10));
    }

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _accentColor, width: 0.5),
        bottom: pw.BorderSide(color: _accentColor, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.7),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(2.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _accentColor),
          children: [
            _buildHeaderCell('DATE'),
            _buildHeaderCell('CATEGORY'),
            _buildHeaderCell('AMOUNT', alignRight: true),
            _buildHeaderCell('NOTES'),
          ],
        ),
        ...List.generate(incomes.length, (index) {
          final i = incomes[index];
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven
                  ? PdfColors.white
                  : const PdfColor.fromInt(0xFFF8FAFC),
            ),
            children: [
              _buildBodyCell(_dateFormat.format(i.date)),
              _buildBodyCell(i.category),
              _buildBodyCell(
                _formatCurrency(i.amount, currencySymbol, showSign: true),
                alignRight: true,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.green600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              _buildBodyCell(
                i.description.length > 25
                    ? '${i.description.substring(0, 25)}...'
                    : (i.description.isEmpty ? '-' : i.description),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildCategorySummary(
    List<Transaction> transactions,
    String currencySymbol,
  ) {
    final expenseTotals = <String, double>{};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      expenseTotals.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    if (expenseTotals.isEmpty) {
      return pw.Text(
        'No expense categories available for this period.',
        style: const pw.TextStyle(color: _textGrey, fontSize: 10),
      );
    }

    final sortedEntries = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();
    final total = sortedEntries.fold<double>(0, (sum, e) => sum + e.value);

    return pw.Column(
      children: topEntries.map((entry) {
        final share = total > 0 ? (entry.value / total) * 100 : 0;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _accentColor, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    entry.key,
                    style: pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _secondaryColor,
                    ),
                  ),
                ),
                pw.Text(
                  '${share.toStringAsFixed(1)}%',
                  style: const pw.TextStyle(fontSize: 9, color: _textGrey),
                ),
                pw.SizedBox(width: 12),
                pw.Text(
                  _formatCurrency(entry.value, currencySymbol),
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    color: PdfColors.red600,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: _secondaryColor,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildBodyCell(
    String text, {
    bool alignRight = false,
    pw.TextStyle? style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: style ?? const pw.TextStyle(fontSize: 9, color: _secondaryColor),
        ),
      ),
    );
  }

  String _formatCurrency(
    double amount,
    String symbol, {
    bool showSign = false,
    bool isNegative = false,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    final formatted = formatter.format(amount.abs());
    if (!showSign) return formatted;
    return '${isNegative ? '-' : '+'} $formatted';
  }

  /// Generates the file and returns it.
  Future<File> generateFile(Uint8List bytes, String extension) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'flux_export_${_fileNameDateFormat.format(DateTime.now())}.$extension';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Shares an existing file.
  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Flux Financial Data Export',
      ),
    );
  }

  /// Saves a file to the device's downloads or documents directory.
  /// Returns the path where it was saved.
  Future<String> saveToDownloads(File tempFile) async {
    Directory? downloadsDir;
    try {
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
    } catch (e) {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    if (downloadsDir == null) {
      throw Exception('Could not access storage directory');
    }

    String newPath = '${downloadsDir.path}/${tempFile.uri.pathSegments.last}';
    
    // Check for duplicates and append suffix if needed
    int counter = 1;
    String fileNameWithoutExt = tempFile.uri.pathSegments.last.replaceAll(RegExp(r'\.(pdf|csv)$'), '');
    String extension = tempFile.uri.pathSegments.last.split('.').last;
    
    while (File(newPath).existsSync()) {
      newPath = '${downloadsDir.path}/$fileNameWithoutExt ($counter).$extension';
      counter++;
    }

    await tempFile.copy(newPath);
    return newPath;
  }
}

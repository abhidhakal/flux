import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import '../models/transaction_model.dart';
import 'currency_service.dart';

/// Service for exporting user financial data to CSV or PDF formats.
class DataExportService {
  final CurrencyService _currencyService = CurrencyService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _fileNameDateFormat = DateFormat('yyyy-MM-dd');

  // Statement palette — kept deliberately small: ink for all figures/body
  // text, grey for labels and hairline rules, one accent used only on the
  // letterhead. No red/green row coloring — direction is conveyed by the
  // +/- sign already in the figures, the way a real bank statement does it.
  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _hairline = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _accent = PdfColor.fromInt(0xFF2563EB);

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
    String userName, {
    String? reportScope,
    String? reportRange,
    bool isBudgetScoped = false,
  }) async {
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
        header: (context) => _buildPdfHeader(logoImage, userName),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          if (reportScope != null || reportRange != null) ...[
            _buildMetaStrip(reportScope, reportRange),
            pw.SizedBox(height: 20),
          ],

          // Summary
          _buildSectionTitle('Summary'),
          pw.SizedBox(height: 10),
          _buildSummaryBlock(
              totalIncome, totalExpenses, netBalance, currencySymbol),
          pw.SizedBox(height: 28),

          // Category Summary — a per-budget export is already scoped to
          // ~1 category, so the breakdown is close to 100% one line; only
          // meaningful for time-range exports spanning multiple categories.
          if (!isBudgetScoped) ...[
            _buildSectionTitle('Spending by Category'),
            pw.SizedBox(height: 10),
            _buildCategorySummary(transactions, currencySymbol),
            pw.SizedBox(height: 28),
          ],

          // Transactions Table
          _buildSectionTitle('Transaction History'),
          pw.SizedBox(height: 6),
          _buildSectionMeta(
            leftLabel: 'Entries',
            leftValue: expenseTransactions.length.toString(),
            rightLabel: 'Total Expenses',
            rightValue: _formatCurrency(totalExpenses, currencySymbol),
          ),
          pw.SizedBox(height: 10),
          _buildTransactionsTable(expenseTransactions, currencySymbol),
          pw.SizedBox(height: 28),

          // Income Table
          _buildSectionTitle('Income Record'),
          pw.SizedBox(height: 6),
          _buildSectionMeta(
            leftLabel: 'Entries',
            leftValue: incomes.length.toString(),
            rightLabel: 'Total Income',
            rightValue: _formatCurrency(totalIncome, currencySymbol),
          ),
          pw.SizedBox(height: 10),
          _buildIncomeTable(incomes, currencySymbol),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(
    pw.MemoryImage? logo,
    String userName,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 36,
                height: 36,
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: logo != null
                    ? pw.Image(logo)
                    : pw.Center(
                        child: pw.Text(
                          'F',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
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
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.Text(
                    'Financial Statement',
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      color: _grey,
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
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Issued: ${_dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: _grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Full-width strip below the letterhead for the export's scope/range —
  /// more visible than tucked into a corner of the header.
  pw.Widget _buildMetaStrip(String? reportScope, String? reportRange) {
    final parts = [reportScope, reportRange]
        .where((s) => s != null && s.isNotEmpty)
        .join('   •   ');
    if (parts.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFEFF4FF),
        border:
            const pw.Border(left: pw.BorderSide(color: _accent, width: 2.5)),
      ),
      child: pw.Text(
        parts,
        style: pw.TextStyle(
            fontSize: 9.5, color: _ink, fontWeight: pw.FontWeight.bold),
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
          style: const pw.TextStyle(fontSize: 9, color: _grey),
        ),
        pw.Text(
          '$rightLabel: $rightValue',
          style: const pw.TextStyle(fontSize: 9, color: _grey),
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
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ],
      ),
    );
  }

  /// One ruled block with three columns, in place of three separate cards —
  /// reads like a statement's opening/credits/debits/closing line rather
  /// than a dashboard.
  pw.Widget _buildSummaryBlock(
    double totalIncome,
    double totalExpenses,
    double netBalance,
    String currencySymbol,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _hairline, width: 1),
      ),
      child: pw.Row(
        children: [
          _buildSummaryColumn(
              'Total Income', _formatCurrency(totalIncome, currencySymbol),
              first: true),
          _buildSummaryColumn('Total Expenses',
              '-${_formatCurrency(totalExpenses, currencySymbol)}'),
          _buildSummaryColumn('Net Balance',
              '${netBalance < 0 ? '-' : ''}${_formatCurrency(netBalance, currencySymbol)}',
              bold: true),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryColumn(String label, String value,
      {bool first = false, bool bold = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: first
              ? null
              : const pw.Border(
                  left: pw.BorderSide(color: _hairline, width: 1)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style:
                  pw.TextStyle(fontSize: 8.5, color: _grey, letterSpacing: 0.5),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: bold ? _accent : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _accent,
      ),
    );
  }

  pw.Widget _buildTransactionsTable(
      List<Transaction> transactions, String currencySymbol) {
    if (transactions.isEmpty) {
      return pw.Text('No transactions available for this period.',
          style: const pw.TextStyle(color: _grey, fontSize: 10));
    }

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _hairline, width: 0.5),
        bottom: pw.BorderSide(color: _hairline, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
          ),
          children: [
            _buildHeaderCell('DATE'),
            _buildHeaderCell('TITLE'),
            _buildHeaderCell('CATEGORY'),
            _buildHeaderCell('AMOUNT', alignRight: true),
          ],
        ),
        ...transactions.map((t) {
          return pw.TableRow(
            children: [
              _buildBodyCell(_dateFormat.format(t.date)),
              _buildBodyCell(
                t.title.length > 30
                    ? '${t.title.substring(0, 30)}...'
                    : t.title,
              ),
              _buildBodyCell(t.category),
              _buildBodyCell(
                '-${_formatCurrency(t.amount, currencySymbol)}',
                alignRight: true,
              ),
            ],
          );
        }),
        _buildTotalRow(
          cells: [
            pw.SizedBox(),
            _buildBodyCell('TOTAL',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(),
            _buildBodyCell(
              '-${_formatCurrency(transactions.fold<double>(0, (sum, t) => sum + t.amount), currencySymbol)}',
              alignRight: true,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent),
            ),
          ],
        ),
      ],
    );
  }

  /// Bold, top-ruled closing row for a table — the running total a reader
  /// would otherwise have to add up by hand across a long, multi-page list.
  pw.TableRow _buildTotalRow({required List<pw.Widget> cells}) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _ink, width: 1)),
      ),
      children: cells,
    );
  }

  pw.Widget _buildIncomeTable(
      List<Transaction> incomes, String currencySymbol) {
    if (incomes.isEmpty) {
      return pw.Text('No income records available for this period.',
          style: const pw.TextStyle(color: _grey, fontSize: 10));
    }

    // Most manually-logged income has no description — drop the column
    // entirely rather than rendering a mostly-empty "-" column.
    final showNotes = incomes.any((i) => i.description.trim().isNotEmpty);

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _hairline, width: 0.5),
        bottom: pw.BorderSide(color: _hairline, width: 0.5),
      ),
      columnWidths: showNotes
          ? const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(1.7),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(2.4),
            }
          : const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(1.7),
              2: pw.FlexColumnWidth(1.3),
            },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
          ),
          children: [
            _buildHeaderCell('DATE'),
            _buildHeaderCell('CATEGORY'),
            _buildHeaderCell('AMOUNT', alignRight: true),
            if (showNotes) _buildHeaderCell('NOTES'),
          ],
        ),
        ...incomes.map((i) {
          return pw.TableRow(
            children: [
              _buildBodyCell(_dateFormat.format(i.date)),
              _buildBodyCell(i.category),
              _buildBodyCell(
                '+${_formatCurrency(i.amount, currencySymbol)}',
                alignRight: true,
              ),
              if (showNotes)
                _buildBodyCell(
                  i.description.length > 25
                      ? '${i.description.substring(0, 25)}...'
                      : (i.description.isEmpty ? '-' : i.description),
                ),
            ],
          );
        }),
        _buildTotalRow(
          cells: [
            pw.SizedBox(),
            _buildBodyCell('TOTAL',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink)),
            _buildBodyCell(
              '+${_formatCurrency(incomes.fold<double>(0, (sum, i) => sum + i.amount), currencySymbol)}',
              alignRight: true,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent),
            ),
            if (showNotes) pw.SizedBox(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCategorySummary(
    List<Transaction> transactions,
    String currencySymbol,
  ) {
    final expenseTotals = <String, double>{};
    for (final t in transactions.where((t) => t.isExpense)) {
      expenseTotals.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    if (expenseTotals.isEmpty) {
      return pw.Text(
        'No expense categories available for this period.',
        style: const pw.TextStyle(color: _grey, fontSize: 10),
      );
    }

    final sortedEntries = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5).toList();
    final total = sortedEntries.fold<double>(0, (sum, e) => sum + e.value);

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _hairline, width: 0.5),
        bottom: pw.BorderSide(color: _hairline, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: _accent, width: 1.5)),
          ),
          children: [
            _buildHeaderCell('CATEGORY'),
            _buildHeaderCell('SHARE', alignRight: true),
            _buildHeaderCell('AMOUNT', alignRight: true),
          ],
        ),
        ...topEntries.map((entry) {
          final share = total > 0 ? (entry.value / total) * 100 : 0;
          return pw.TableRow(
            children: [
              _buildBodyCell(entry.key),
              _buildBodyCell('${share.toStringAsFixed(1)}%', alignRight: true),
              _buildBodyCell(
                '-${_formatCurrency(entry.value, currencySymbol)}',
                alignRight: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: _ink,
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
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: style ?? const pw.TextStyle(fontSize: 9, color: _ink),
        ),
      ),
    );
  }

  String _formatCurrency(double amount, String symbol) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount.abs());
  }

  /// Generates the file and returns it.
  Future<File> generateFile(Uint8List bytes, String extension) async {
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'flux_export_${_fileNameDateFormat.format(DateTime.now())}.$extension';
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

  static const _downloadsChannel =
      MethodChannel('com.klivostudios.flux/downloads');

  /// Saves a file to the device's public Downloads folder (Android) or lets
  /// the user pick a destination (iOS/desktop). Throws on failure — never
  /// returns a path unless the file is actually there, so callers can trust
  /// a non-throwing return.
  Future<String> saveToDownloads(File tempFile) async {
    final fileName = tempFile.uri.pathSegments.last;
    final extension = fileName.split('.').last;
    final bytes = await tempFile.readAsBytes();

    if (Platform.isAndroid) {
      // file_saver's Android saveFile() writes to the app's private
      // external-files dir (not the public Downloads folder) and swallows
      // native errors as a fake "success" path — use a real MediaStore
      // insert via a platform channel instead.
      try {
        final path =
            await _downloadsChannel.invokeMethod<String>('saveToDownloads', {
          'fileName': fileName,
          'mimeType': extension == 'pdf' ? 'application/pdf' : 'text/csv',
          'bytes': bytes,
        });
        if (path == null || path.isEmpty) {
          throw Exception('Save returned no path');
        }
        return path;
      } on PlatformException catch (e) {
        throw Exception(e.message ?? 'Failed to save to Downloads');
      }
    }

    final nameWithoutExt =
        fileName.substring(0, fileName.length - extension.length - 1);
    final savedPath = await FileSaver.instance.saveFile(
      name: nameWithoutExt,
      bytes: bytes,
      fileExtension: extension,
      mimeType: extension == 'pdf' ? MimeType.pdf : MimeType.csv,
    );
    return savedPath;
  }
}

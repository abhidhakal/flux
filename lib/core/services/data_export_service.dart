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
import '../models/income_model.dart';
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

  /// Generates CSV content from transactions and income data.
  String generateCsv(List<Transaction> transactions, List<Income> incomes) {
    final List<List<dynamic>> rows = [];

    // Transactions section
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

    rows.add([]); // Empty row separator

    // Income section
    rows.add(['=== INCOME ===']);
    rows.add(['Date', 'Category', 'Amount', 'Notes']);
    
    for (final i in incomes) {
      rows.add([
        _dateFormat.format(i.date),
        i.category,
        i.amount.toStringAsFixed(2),
        i.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a PDF document from transactions and income data.
  Future<Uint8List> generatePdf(
    List<Transaction> transactions,
    List<Income> incomes,
    String userName,
  ) async {
    final pdf = pw.Document();
    final currencySymbol = _currencyService.symbol;
    
    // Load Assets
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/flux_logo.png')).buffer.asUint8List(),
    );
    
    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Bold.ttf'),
    );

    // Calculate totals
    final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
        ),
        header: (context) => _buildPdfHeader(logoImage, userName),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          // Summary Section
          pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _secondaryColor)),
          pw.SizedBox(height: 12),
          _buildSummarySection(totalIncome, totalExpenses, netBalance, currencySymbol),
          pw.SizedBox(height: 32),
          
          // Transactions Table
          _buildSectionTitle('Transaction History'),
          pw.SizedBox(height: 12),
          _buildTransactionsTable(transactions, currencySymbol),
          pw.SizedBox(height: 32),
          
          // Income Table
          _buildSectionTitle('Income Record'),
          pw.SizedBox(height: 12),
          _buildIncomeTable(incomes, currencySymbol),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logo, String userName) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _accentColor, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 40,
                height: 40,
                child: pw.Image(logo),
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
                      fontSize: 10,
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
            ],
          ),
        ],
      ),
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
        padding: const pw.EdgeInsets.all(16),
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
              style: pw.TextStyle(fontSize: 9, color: _textGrey, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '$symbol${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 18,
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
          fontSize: 16,
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

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _secondaryColor),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
      headerDecoration: const pw.BoxDecoration(color: _accentColor),
      cellHeight: 32,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
      headers: ['DATE', 'TITLE', 'CATEGORY', 'AMOUNT'],
      data: transactions.map((t) => [
        _dateFormat.format(t.date),
        t.title.length > 30 ? '${t.title.substring(0, 30)}...' : t.title,
        t.category,
        '${t.type == TransactionType.expense ? '-' : '+'} $currencySymbol${t.amount.toStringAsFixed(2)}',
      ]).toList(),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _accentColor, width: 0.5),
        bottom: pw.BorderSide(color: _accentColor, width: 0.5),
      ),
    );
  }

  pw.Widget _buildIncomeTable(List<Income> incomes, String currencySymbol) {
    if (incomes.isEmpty) {
      return pw.Text('No income records available for this period.', style: const pw.TextStyle(color: _textGrey, fontSize: 10));
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _secondaryColor),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _secondaryColor),
      headerDecoration: const pw.BoxDecoration(color: _accentColor),
      cellHeight: 32,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
      },
      headers: ['DATE', 'CATEGORY', 'AMOUNT', 'NOTES'],
      data: incomes.map((i) => [
        _dateFormat.format(i.date),
        i.category,
        '+ $currencySymbol${i.amount.toStringAsFixed(2)}',
        (i.notes?.length ?? 0) > 25 ? '${i.notes!.substring(0, 25)}...' : (i.notes ?? '-'),
      ]).toList(),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _accentColor, width: 0.5),
        bottom: pw.BorderSide(color: _accentColor, width: 0.5),
      ),
    );
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
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Flux Financial Data Export',
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

    final newPath = '${downloadsDir.path}/${tempFile.uri.pathSegments.last}';
    await tempFile.copy(newPath);
    return newPath;
  }
}

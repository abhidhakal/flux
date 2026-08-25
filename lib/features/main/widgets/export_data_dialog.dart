import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/data_export_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/auth_bloc.dart';
import '../../budget/budget_bloc.dart';
import '../../transaction/transaction_bloc.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void showExportFormatDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  // filterMode: 'time' or 'budget'
  String filterMode = 'time';
  int selectedDays = 30; // Used only in 'time' mode
  Budget? selectedBudget; // Used only in 'budget' mode
  String selectedFormat = 'pdf'; // Default: PDF

  AppBottomSheet.show(
    context,
    radius: 24,
    builder: (dialogContext) => StatefulBuilder(
      // Named to avoid shadowing the outer `context` — that outer one is
      // tied to the long-lived screen that opened this sheet and must be
      // what _performExport receives, or its context.mounted checks go
      // stale the instant this sheet closes (this was a real bug: export
      // silently never dismissed its loading spinner).
      builder: (sheetContext, setModalState) {
        final budgetState = sheetContext.read<BudgetBloc>().state;
        final budgetsLoading = budgetState is BudgetLoading;
        final budgets =
            budgetState is BudgetLoaded ? budgetState.budgets : <Budget>[];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.download,
                      color: colorScheme.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Data',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Choose what you want to take with you',
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
            const SizedBox(height: 24),

            // 1. Filter Mode Toggle
            Text(
              'Filter By',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setModalState(() {
                      filterMode = 'time';
                      selectedBudget = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: filterMode == 'time'
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: filterMode == 'time'
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            color: filterMode == 'time'
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time Range',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: filterMode == 'time'
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: budgets.isEmpty
                        ? null
                        : () => setModalState(() {
                              filterMode = 'budget';
                              selectedDays = 30;
                            }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: budgets.isEmpty
                            ? colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2)
                            : filterMode == 'budget'
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: budgets.isEmpty
                              ? colorScheme.outline.withValues(alpha: 0.1)
                              : filterMode == 'budget'
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.coins,
                            color: budgets.isEmpty
                                ? colorScheme.onSurface.withValues(alpha: 0.3)
                                : filterMode == 'budget'
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            budgetsLoading
                                ? 'Budget (loading…)'
                                : budgets.isEmpty
                                    ? 'Budget (none)'
                                    : 'Budget',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: budgets.isEmpty
                                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                                  : filterMode == 'budget'
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2a. Time Range Selector (shown only in 'time' mode)
            if (filterMode == 'time') ...[
              Text(
                'Time Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedDays,
                    isExpanded: true,
                    icon: Icon(LucideIcons.chevronDown,
                        color: colorScheme.onSurface),
                    dropdownColor: colorScheme.surface,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                      DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                      DropdownMenuItem(value: 90, child: Text('Last 3 months')),
                      DropdownMenuItem(value: 365, child: Text('Last 1 year')),
                      DropdownMenuItem(value: -1, child: Text('All time')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedDays = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 2b. Budget Selector (shown only in 'budget' mode)
            if (filterMode == 'budget' && budgets.isNotEmpty) ...[
              Text(
                'Select Budget',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Budget?>(
                    value: selectedBudget,
                    isExpanded: true,
                    icon: Icon(LucideIcons.chevronDown,
                        color: colorScheme.onSurface),
                    dropdownColor: colorScheme.surface,
                    hint: const Text('Choose a budget'),
                    items: budgets
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setModalState(() => selectedBudget = value),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3. Format Selector
            Text(
              'Format',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    'PDF',
                    LucideIcons.fileText,
                    selectedFormat == 'pdf',
                    () => setModalState(() => selectedFormat = 'pdf'),
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormatOption(
                    'CSV',
                    LucideIcons.table,
                    selectedFormat == 'csv',
                    () => setModalState(() => selectedFormat = 'csv'),
                    colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _performExport(
                    context,
                    format: selectedFormat,
                    // In budget mode pass days=-1 so no date cutoff is applied
                    days: filterMode == 'budget' ? -1 : selectedDays,
                    budget: filterMode == 'budget' ? selectedBudget : null,
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Generate Export',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    ),
  );
}

Widget _buildFormatOption(String label, IconData icon, bool isSelected,
    VoidCallback onTap, ColorScheme colorScheme) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _performExport(BuildContext context,
    {required String format, required int days, Budget? budget}) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final exportService = DataExportService();

    // Get transactions
    final transactionState = context.read<TransactionBloc>().state;
    List<Transaction> filteredTransactions =
        (transactionState is TransactionLoaded
                ? transactionState.transactions
                : <Transaction>[])
            .cast<Transaction>();

    if (budget != null) {
      // BUDGET MODE: export all transactions for the chosen budget, ignore date range
      final budgetId = budget.id;

      filteredTransactions =
          filteredTransactions.where((t) => t.budgetId == budgetId).toList();
    } else {
      // TIME MODE: export transactions within the selected time range, no budget filter
      final DateTime? cutoffDate =
          days > 0 ? DateTime.now().subtract(Duration(days: days)) : null;

      if (cutoffDate != null) {
        filteredTransactions = filteredTransactions
            .where((t) => t.date.isAfter(cutoffDate))
            .toList();
      }
    }

    // Get user name for PDF
    final authState = context.read<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? (authState.user.displayName ?? 'User')
        : 'User';

    final now = DateTime.now();
    final todayIso = now.toIso8601String().split('T').first;
    final reportScope =
        budget != null ? 'Scope: Budget - ${budget.name}' : 'Scope: Time Range';
    final reportRange = budget != null
        ? 'Range: All records for selected budget'
        : (days > 0
            ? 'Range: ${now.subtract(Duration(days: days)).toIso8601String().split('T').first} to $todayIso'
            : 'Range: All time');

    File generatedFile;
    if (format == 'csv') {
      final csvContent = exportService.generateCsv(filteredTransactions);
      generatedFile = await exportService.generateFile(
        Uint8List.fromList(csvContent.codeUnits),
        'csv',
      );
    } else {
      final pdfBytes = await exportService.generatePdf(
        filteredTransactions,
        userName,
        reportScope: reportScope,
        reportRange: reportRange,
        isBudgetScoped: budget != null,
      );
      generatedFile = await exportService.generateFile(
        pdfBytes,
        'pdf',
      );
    }

    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Show action dialog (Share vs Download)
    if (context.mounted) {
      _showExportActionDialog(context, generatedFile, exportService);
    }
  } catch (e) {
    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (context.mounted) {
      AppSnackbar.showError(context, message: 'Export failed: $e');
    }
  }
}

void _showExportActionDialog(
    BuildContext context, File file, DataExportService exportService) {
  final colorScheme = Theme.of(context).colorScheme;
  AppBottomSheet.show(
    context,
    radius: 24,
    builder: (dialogContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Export Ready',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What would you like to do with the file?',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: LucideIcons.download,
                label: 'Save',
                colorScheme: colorScheme,
                onTap: () async {
                  Navigator.pop(dialogContext);
                  try {
                    final path = await exportService.saveToDownloads(file);
                    if (context.mounted) {
                      AppSnackbar.showSuccess(
                        context,
                        message: 'Saved to $path',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackbar.showError(
                        context,
                        message: 'Failed to save: $e',
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: LucideIcons.share2,
                label: 'Share',
                colorScheme: colorScheme,
                isPrimary: true,
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await exportService.shareFile(file);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    ),
  );
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required ColorScheme colorScheme,
  required VoidCallback onTap,
  bool isPrimary = false,
}) {
  return Material(
    color: isPrimary ? colorScheme.primary : colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isPrimary
              ? null
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

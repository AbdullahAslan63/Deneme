import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../buildings/data/buildings_store.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expenses_provider.dart';
import '../utils/expense_labels.dart';
import '../widgets/expense_form_sheet.dart';

class ManagerExpensesScreen extends ConsumerStatefulWidget {
  const ManagerExpensesScreen({super.key});

  @override
  ConsumerState<ManagerExpensesScreen> createState() =>
      _ManagerExpensesScreenState();
}

class _ManagerExpensesScreenState extends ConsumerState<ManagerExpensesScreen> {
  String? _buildingId;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  void _load() {
    final id = _buildingId;
    if (id == null) return;
    ref.read(expensesNotifierProvider.notifier).load(id, month: _month, year: _year);
  }

  Future<void> _openForm({ExpenseEntity? expense}) async {
    final id = _buildingId;
    if (id == null) return;
    final ok = await ExpenseFormSheet.show(
      context,
      buildingId: id,
      expense: expense,
    );
    if (ok == true && mounted) _load();
  }

  Future<void> _confirmDelete(ExpenseEntity expense) async {
    final t = context.t.features.expenses;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteTitle),
        content: Text(t.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref
        .read(expensesNotifierProvider.notifier)
        .delete(expense.id);
    if (!mounted) return;
    if (ok) {
      ref.read(toastProvider.notifier).show(
            t.deleteSuccess,
            type: ToastType.success,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildings = ref.watch(buildingsStoreProvider).value ?? [];
    final state = ref.watch(expensesNotifierProvider);
    final t = context.t.features.expenses;
    final years = List.generate(6, (i) => DateTime.now().year - i);

    if (_buildingId == null && buildings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _buildingId = buildings.first.id);
        _load();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _buildingId == null ? null : () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (buildings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spacingM,
                AppSizes.spacingM,
                AppSizes.spacingM,
                0,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _buildingId,
                decoration: InputDecoration(
                  labelText: context.t.common.buildingName,
                  border: const OutlineInputBorder(),
                ),
                items: buildings
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _buildingId = id);
                  _load();
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: InputDecoration(
                      labelText: t.fieldMonth,
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (m) {
                      if (m == null) return;
                      setState(() => _month = m);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: InputDecoration(
                      labelText: t.fieldYear,
                      border: const OutlineInputBorder(),
                    ),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                    onChanged: (y) {
                      if (y == null) return;
                      setState(() => _year = y);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (state.summary != null) _SummaryCard(summary: state.summary!),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: _buildList(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ExpensesState state) {
    final t = context.t.features.expenses;

    if (state.isLoading && state.expenses.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.error != null && state.expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
          Center(
            child: Padding(
              padding: AppSizes.screenBodyScrollPadding,
              child: Column(
                children: [
                  Text(state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSizes.spacingM),
                  FilledButton(
                    onPressed: _load,
                    child: Text(context.t.common.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (state.expenses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: t.emptyTitle,
            subtitle: t.emptySubtitle,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSizes.screenBodyScrollPadding,
      itemCount: state.expenses.length,
      itemBuilder: (context, i) {
        final e = state.expenses[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
          child: _ExpenseCard(
            expense: e,
            onEdit: () => _openForm(expense: e),
            onDelete: () => _confirmDelete(e),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ExpenseSummaryEntity summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = context.t.features.expenses;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.total}: ${summary.totalAmount.toStringAsFixed(2)} ${summary.currency}',
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),
            if (summary.byCategory.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingS),
              Wrap(
                spacing: AppSizes.spacingS,
                runSpacing: AppSizes.spacingXS,
                children: summary.byCategory.map((c) {
                  return Chip(
                    label: Text(
                      '${c.category.label(context)}: ${c.amount.toStringAsFixed(0)} ₺ (${c.count})',
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        '${expense.date.day}.${expense.date.month}.${expense.date.year}';
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  '${expense.category.label(context)} · $date',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (expense.note != null && expense.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.spacingXS),
                    child: Text(
                      expense.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${expense.amount.toStringAsFixed(2)} ₺',
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(context.t.features.expenses.editAction),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(context.t.features.expenses.deleteAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

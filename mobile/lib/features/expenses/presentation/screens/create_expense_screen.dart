import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expenses_provider.dart';
import '../utils/expense_labels.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  final String buildingId;

  const CreateExpenseScreen({super.key, required this.buildingId});

  @override
  ConsumerState<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.features.expenses;
    return Scaffold(
      appBar: AppBar(title: Text(t.createTitle), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSizes.screenBodyScrollPadding,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: t.fieldTitle),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t.fieldAmount),
              validator: (v) {
                final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                if (n == null || n <= 0) return t.amountInvalid;
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spacingM),
            DropdownButtonFormField<ExpenseCategory>(
              value: _category,
              decoration: InputDecoration(labelText: t.fieldCategory),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label(context)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(labelText: t.fieldNote),
            ),
            const SizedBox(height: AppSizes.spacingXL),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.submit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final amount =
        double.parse(_amountController.text.trim().replaceAll(',', '.'));
    final ok = await ref.read(expensesNotifierProvider.notifier).create(
          buildingId: widget.buildingId,
          title: _titleController.text,
          amount: amount,
          category: _category,
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ref.read(toastProvider.notifier).show(
            context.t.features.expenses.createSuccess,
            type: ToastType.success,
          );
      context.pop(true);
    }
  }
}

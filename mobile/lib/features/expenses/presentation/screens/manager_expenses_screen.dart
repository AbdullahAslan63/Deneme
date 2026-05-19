import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_sizes.dart';
import '../../../../l10n/strings.g.dart';
import '../../../buildings/data/buildings_store.dart';
import '../providers/expenses_provider.dart';
import '../utils/expense_labels.dart';

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

  @override
  Widget build(BuildContext context) {
    final buildings = ref.watch(buildingsStoreProvider).value ?? [];
    final state = ref.watch(expensesNotifierProvider);

    if (_buildingId == null && buildings.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _buildingId = buildings.first.id);
        _load();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.features.expenses.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _buildingId == null
                ? null
                : () => context.push(
                      '/expenses/new',
                      extra: _buildingId,
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (buildings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: DropdownButtonFormField<String>(
                value: _buildingId,
                decoration: InputDecoration(
                  labelText: context.t.common.buildingName,
                  border: const OutlineInputBorder(),
                ),
                items: buildings
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _buildingId = id);
                  _load();
                },
              ),
            ),
          if (state.summary != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
              child: Text(
                '${context.t.features.expenses.total}: ${state.summary!.totalAmount.toStringAsFixed(2)} ${state.summary!.currency}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _load(),
              child: state.isLoading && state.expenses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: state.expenses.length,
                      itemBuilder: (context, i) {
                        final e = state.expenses[i];
                        return ListTile(
                          title: Text(e.title),
                          subtitle: Text(e.category.label(context)),
                          trailing: Text('${e.amount.toStringAsFixed(2)} ₺'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

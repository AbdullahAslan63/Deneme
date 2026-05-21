import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/expense_form_sheet.dart';

/// `/expenses/new` — form bottom sheet ile açılır (B4).
class CreateExpenseScreen extends StatefulWidget {
  final String buildingId;

  const CreateExpenseScreen({super.key, required this.buildingId});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ok = await ExpenseFormSheet.show(
        context,
        buildingId: widget.buildingId,
      );
      if (!mounted) return;
      context.pop(ok == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

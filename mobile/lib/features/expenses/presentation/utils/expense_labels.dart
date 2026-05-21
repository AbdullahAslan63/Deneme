import 'package:flutter/widgets.dart';

import '../../../../l10n/strings.g.dart';
import '../../domain/entities/expense_entity.dart';

extension ExpenseCategoryLabels on ExpenseCategory {
  String label(BuildContext context) {
    final t = context.t.features.expenses;
    switch (this) {
      case ExpenseCategory.cleaning:
        return t.categoryCleaning;
      case ExpenseCategory.elevator:
        return t.categoryElevator;
      case ExpenseCategory.electricity:
        return t.categoryElectricity;
      case ExpenseCategory.water:
        return t.categoryWater;
      case ExpenseCategory.insurance:
        return t.categoryInsurance;
      case ExpenseCategory.repair:
        return t.categoryRepair;
      case ExpenseCategory.garden:
        return t.categoryGarden;
      case ExpenseCategory.other:
        return t.categoryOther;
    }
  }
}

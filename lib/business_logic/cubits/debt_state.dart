import 'package:smart_pharmacy_system/data/models/debt.dart';

abstract class DebtState {}

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtLoaded extends DebtState {
  final List<Debt> debts;
  final double totalDebt;

  DebtLoaded(this.debts)
    : totalDebt = debts.fold(0.0, (sum, item) => sum + item.remainingAmount);
}

class DebtError extends DebtState {
  final String message;
  DebtError(this.message);
}

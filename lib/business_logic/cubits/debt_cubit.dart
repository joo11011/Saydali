import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/debt_state.dart';
import 'package:smart_pharmacy_system/data/models/debt.dart';
import 'package:smart_pharmacy_system/data/repositories/debt_repository.dart';

class DebtCubit extends Cubit<DebtState> {
  final DebtRepository _repository;

  DebtCubit(this._repository) : super(DebtInitial());

  Future<void> loadDebts() async {
    try {
      emit(DebtLoading());
      final debts = await _repository.getDebts();
      emit(DebtLoaded(debts));
    } catch (e) {
      emit(DebtError("فشل تحميل الديون: $e"));
    }
  }

  Future<void> addDebt(Debt debt) async {
    try {
      await _repository.addDebt(debt);
      await loadDebts();
    } catch (e) {
      emit(DebtError("فشل إضافة الدين: $e"));
    }
  }

  Future<void> payDebt(String id, double amount) async {
    try {
      final box = await _repository.getDebts();
      final debt = box.firstWhere((d) => d.id == id);

      final updatedDebt = debt.copyWith(paidAmount: debt.paidAmount + amount);

      if (updatedDebt.remainingAmount <= 0) {
        // If fully paid, delete the debt
        _repository.deleteDebt(id);
      }

      await _repository.updateDebt(updatedDebt);
      await loadDebts();
    } catch (e) {
      emit(DebtError("فشل تسجيل الدفع :  $e"));
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _repository.deleteDebt(id);
      await loadDebts();
    } catch (e) {
      emit(DebtError("فشل حذف الدين: $e"));
    }
  }
}

import 'package:hive/hive.dart';
import 'package:smart_pharmacy_system/data/models/debt.dart';

class DebtRepository {
  static const String _boxName = 'debts';
  Future<Box<Debt>> get _box async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox<Debt>(_boxName);
  }

  Future<List<Debt>> getDebts() async {
    final box = await _box;
    final debts = box.values.toList();
    debts.sort((a, b) => b.date.compareTo(a.date));
    return debts;
  }

  Future<void> addDebt(Debt debt) async {
    final box = await _box;
    await box.put(debt.id, debt);
  }

  Future<void> updateDebt(Debt debt) async {
    final box = await _box;
    await box.put(debt.id, debt);
  }

  Future<void> deleteDebt(String id) async {
    final box = await _box;
    await box.delete(id);
  }
}

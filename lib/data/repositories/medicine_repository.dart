import 'package:hive/hive.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';

class MedicineRepository {
  static const String _boxName = 'medicines';
  Future<Box<Medicine>> get _box async =>
      await Hive.openBox<Medicine>(_boxName);

  // Get all medicines sorted by name
  Future<List<Medicine>> getAllMedicines() async {
    final box = await _box;
    final medicines = box.values.toList();
    medicines.sort((a, b) => a.name.compareTo(b.name));
    return medicines;
  }

  // Get paginated medicines rather than all at once
  Future<List<Medicine>> getPaginatedMedicines({
    int limit = 20,
    int offset = 0,
  }) async {
    final box = await _box;
    final medicines = box.values.toList();
    medicines.sort((a, b) => a.name.compareTo(b.name));

    if (offset >= medicines.length) return [];

    int end = offset + limit;
    if (end > medicines.length) end = medicines.length;

    return medicines.sublist(offset, end);
  }

  Future<void> addMedicine(Medicine medicine) async {
    final box = await _box;
    await box.put(medicine.id, medicine);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final box = await _box;
    await box.put(medicine.id, medicine);
  }

  Future<void> deleteMedicine(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  // Get medicine by name
  Future<Medicine?> getMedicineByName(String name) async {
    final box = await _box;
    return box.values.firstWhere(
      (medicine) => medicine.name.toLowerCase() == name.toLowerCase(),
      orElse: () => throw Exception('Medicine not found'),
    );
  }

  // Check if medicine exists
  Future<bool> medicineExists(String name) async {
    final box = await _box;
    try {
      box.values.firstWhere(
        (medicine) => medicine.name.toLowerCase() == name.toLowerCase(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update medicine quantity
  Future<void> updateMedicineQuantity(String name, int newQuantity) async {
    final box = await _box;
    final medicine = box.values.firstWhere(
      (m) => m.name.toLowerCase() == name.toLowerCase(),
    );
    final updatedMedicine = medicine.copyWith(quantity: newQuantity);
    await box.put(medicine.id, updatedMedicine);
  }

  // Get low stock medicines for notifications or dashboard indicators
  Future<List<Medicine>> getLowStockMedicines() async {
    final box = await _box;
    return box.values.where((medicine) => medicine.isLowStock).toList();
  }
}

import 'package:hive/hive.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';

class MissingMedicineRepository {
  static const String _boxName = 'missing_medicines';
  Future<Box<MissingMedicine>> get _box async =>
      await Hive.openBox<MissingMedicine>(_boxName);
  // Get all missing medicines sorted by reported date
  Future<List<MissingMedicine>> getAllMissingMedicines() async {
    final box = await _box;
    final medicines = box.values.toList();
    medicines.sort((a, b) => b.reportedDate.compareTo(a.reportedDate));
    return medicines;
  }

  // Get paginated missing medicines rather than all at once
  Future<List<MissingMedicine>> getPaginatedMissingMedicines({
    int limit = 20,
    int offset = 0,
  }) async {
    final box = await _box;
    final medicines = box.values.toList();
    medicines.sort((a, b) => b.reportedDate.compareTo(a.reportedDate));

    if (offset >= medicines.length) return [];

    int end = offset + limit;
    if (end > medicines.length) end = medicines.length;

    return medicines.sublist(offset, end);
  }

  // Add missing medicine
  Future<void> addMissingMedicine(MissingMedicine medicine) async {
    final box = await _box;
    await box.put(medicine.id, medicine);
  }

  // Update missing medicine (for adding alternative)
  Future<void> updateMissingMedicine(MissingMedicine medicine) async {
    final box = await _box;
    await box.put(medicine.id, medicine);
  }

  // Delete missing medicine
  Future<void> deleteMissingMedicine(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  // Check if medicine is already in missing list
  Future<bool> isMedicineInMissingList(String medicineName) async {
    final box = await _box;
    try {
      box.values.firstWhere(
        (m) => m.medicineName.toLowerCase() == medicineName.toLowerCase(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get missing medicine by name
  Future<MissingMedicine?> getMissingMedicineByName(String name) async {
    final box = await _box;
    try {
      return box.values.firstWhere(
        (m) => m.medicineName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Increment request count
  Future<void> incrementRequestCount(String medicineName) async {
    final medicine = await getMissingMedicineByName(medicineName);
    if (medicine != null) {
      final updated = medicine.copyWith(
        requestCount: medicine.requestCount + 1,
      );
      await updateMissingMedicine(updated);
    }
  }

  // Clear missing medicines before a specific date
  Future<void> clearMissingBefore(DateTime date) async {
    final box = await _box;
    final keysToDelete = box.keys.where((key) {
      final m = box.get(key);
      return m != null && m.reportedDate.isBefore(date);
    }).toList();

    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }
}

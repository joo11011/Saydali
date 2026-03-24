import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_state.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';
import 'package:smart_pharmacy_system/data/repositories/medicine_repository.dart';

class MedicineCubit extends Cubit<MedicineState> {
  final MedicineRepository _repository;
  MedicineCubit(this._repository) : super(MedicineInitial());
  int _currentPage = 0;
  static const int _pageSize = 20;
  Future<void> loadMedicines() async {
    try {
      emit(MedicineLoading());
      _currentPage = 0;

      // Verification log
      print('--- DEPATIVE DIAGNOSIS: Loading medicines from repository ---');

      final medicines = await _repository.getPaginatedMedicines(
        limit: _pageSize,
        offset: 0,
      );
      final lowStockMedicines = await _repository.getLowStockMedicines();

      print('--- DIAGNOSIS RESULT: Found ${medicines.length} items in box ---');

      final expiredMedicines = medicines.where((m) => m.isExpired).toList();
      final expiringSoonMedicines = medicines
          .where((m) => m.isExpiringSoon && !m.isExpired)
          .toList();

      emit(
        MedicineLoaded(
          medicines: medicines,
          lowStockMedicines: lowStockMedicines,
          expiredMedicines: expiredMedicines,
          expiringSoonMedicines: expiringSoonMedicines,
          hasMore: medicines.length == _pageSize,
        ),
      );
    } catch (e, stack) {
      print('--- ERROR IN LOAD_MEDICINES: $e');
      print(stack);
      emit(MedicineError('فشل في تحميل الأدوية: ${e.toString()}'));
    }
  }

  Future<void> loadMoreMedicines() async {
    final currentState = state;
    if (currentState is! MedicineLoaded || !currentState.hasMore) return;

    try {
      _currentPage++;
      final moreMedicines = await _repository.getPaginatedMedicines(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      final nextMedicines = [...currentState.medicines, ...moreMedicines];
      final nextExpired = nextMedicines.where((m) => m.isExpired).toList();
      final nextSoon = nextMedicines
          .where((m) => m.isExpiringSoon && !m.isExpired)
          .toList();

      emit(
        currentState.copyWith(
          medicines: nextMedicines,
          expiredMedicines: nextExpired,
          expiringSoonMedicines: nextSoon,
          hasMore: moreMedicines.length == _pageSize,
        ),
      );
    } catch (e) {}
  }

  Future<void> addMedicine(Medicine medicine) async {
    try {
      await _repository.addMedicine(medicine);
      emit(MedicineSuccess('تمت إضافة الدواء بنجاح'));
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('فشل في إضافة الدواء: ${e.toString()}'));
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    try {
      await _repository.updateMedicine(medicine);
      emit(MedicineSuccess('تم تحديث الدواء بنجاح'));
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('فشل في تحديث الدواء: ${e.toString()}'));
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await _repository.deleteMedicine(id);
      emit(const MedicineSuccess('تم حذف الدواء بنجاح'));
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('فشل في حذف الدواء: ${e.toString()}'));
    }
  }

  Future<bool> checkMedicineExists(String name) async {
    return await _repository.medicineExists(name);
  }

  Future<Medicine?> getMedicineByName(String name) async {
    try {
      return await _repository.getMedicineByName(name);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateQuantity(String name, int newQuantity) async {
    try {
      await _repository.updateMedicineQuantity(name, newQuantity);
      await loadMedicines();
    } catch (e) {
      emit(MedicineError('فشل في تحديث الكمية: ${e.toString()}'));
    }
  }
}

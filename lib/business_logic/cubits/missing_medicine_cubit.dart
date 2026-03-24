import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_state.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';
import 'package:smart_pharmacy_system/data/repositories/missing_medicine_repository.dart';

class MissingMedicineCubit extends Cubit<MissingMedicineState> {
  final MissingMedicineRepository _repository;

  MissingMedicineCubit(this._repository) : super(MissingMedicineInitial());

  int _currentPage = 0;
  static const int _pageSize = 20;

  Future<void> loadMissingMedicines() async {
    try {
      emit(MissingMedicineLoading());
      _currentPage = 0;
      final missingMedicines = await _repository.getPaginatedMissingMedicines(
        limit: _pageSize,
        offset: 0,
      );
      emit(
        MissingMedicineLoaded(
          missingMedicines,
          hasMore: missingMedicines.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(
        MissingMedicineError('فشل في تحميل الأدوية الناقصة: ${e.toString()}'),
      );
    }
  }

  Future<void> loadMoreMissingMedicines() async {
    final currentState = state;
    if (currentState is! MissingMedicineLoaded || !currentState.hasMore) return;

    try {
      _currentPage++;
      final moreMissing = await _repository.getPaginatedMissingMedicines(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      emit(
        currentState.copyWith(
          missingMedicines: [...currentState.missingMedicines, ...moreMissing],
          hasMore: moreMissing.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(
        MissingMedicineError(
          ' فشل في تحميل المزيد من الأدوية الناقصه:  ${e.toString()}',
        ),
      );
    }
  }

  Future<void> addMissingMedicine(MissingMedicine medicine) async {
    try {
      // Check if already in missing list
      final exists = await _repository.isMedicineInMissingList(
        medicine.medicineName,
      );
      if (exists) {
        // Increment request count
        await _repository.incrementRequestCount(medicine.medicineName);
        emit(const MissingMedicineSuccess('تم تحديث عدد الطلبات'));
      } else {
        // Add new missing medicine
        await _repository.addMissingMedicine(medicine);
        emit(const MissingMedicineSuccess('تمت إضافة الدواء للقائمة الناقصة'));
      }
      await loadMissingMedicines();
    } catch (e) {
      emit(MissingMedicineError('فشل في إضافة الدواء: ${e.toString()}'));
    }
  }

  Future<void> updateMissingMedicine(MissingMedicine medicine) async {
    try {
      await _repository.updateMissingMedicine(medicine);
      emit(const MissingMedicineSuccess('تم تحديث البديل بنجاح'));
      await loadMissingMedicines();
    } catch (e) {
      emit(MissingMedicineError('فشل في تحديث الدواء: ${e.toString()}'));
    }
  }

  Future<void> deleteMissingMedicine(String id) async {
    try {
      await _repository.deleteMissingMedicine(id);
      emit(const MissingMedicineSuccess('تم حذف الدواء من القائمة'));
      await loadMissingMedicines();
    } catch (e) {
      emit(MissingMedicineError('فشل في حذف الدواء: ${e.toString()}'));
    }
  }

  Future<MissingMedicine?> getMissingMedicineByName(String name) async {
    return await _repository.getMissingMedicineByName(name);
  }

  Future<void> clearOldMissing(DateTime date) async {
    try {
      await _repository.clearMissingBefore(date);
      await loadMissingMedicines();
    } catch (e) {
      emit(
        MissingMedicineError('فشل في مسح البيانات القديمة: ${e.toString()}'),
      );
    }
  }
}

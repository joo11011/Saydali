import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_state.dart';
import 'package:smart_pharmacy_system/data/models/sale.dart';
import 'package:smart_pharmacy_system/data/repositories/sale_repository.dart';

class SaleCubit extends Cubit<SaleState> {
  final SaleRepository _repository;
  SaleCubit(this._repository) : super(SaleIntial());
  int _currentPage = 0;
  static const int _pageSize = 20;

  Future<void> loadSales() async {
    try {
      if (state is! SaleLoaded) emit(SaleLoading());
      _currentPage = 0;

      final results = await Future.wait([
        _repository.getPaginatedSales(limit: _pageSize, offset: 0),
        _repository.getTodaySales(),
        _repository.getWeeklySales(),
        _repository.getMonthlySales(),
      ]);

      final sales = results[0];
      final todaySales = results[1];
      final weeklySales = results[2];
      final monthlySales = results[3];

      emit(
        SaleLoaded(
          sales: sales,
          todaySales: todaySales,
          weeklySales: weeklySales,
          monthlySales: monthlySales,
          filteredSales: sales,
          hasMore: sales.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(SaleError('فشل في تحميل المبيعات: ${e.toString()}'));
    }
  }

  Future<void> loadMoreSales() async {
    final currentState = state;
    if (currentState is! SaleLoaded || !currentState.hasMore) return;

    try {
      _currentPage++;
      final moreSales = await _repository.getPaginatedSales(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      emit(
        currentState.copyWith(
          sales: [...currentState.sales, ...moreSales],
          filteredSales: [...currentState.sales, ...moreSales],
          hasMore: moreSales.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(SaleError('فشل في تحميل المزيد من المبيعات : ${e.toString()}'));
    }
  }

  Future<void> filterSalesByDateRange(DateTime start, DateTime end) async {
    try {
      final currentState = state;
      if (currentState is! SaleLoaded) return;

      emit(SaleLoading());
      final filtered = await _repository.getSalesByDateRange(start, end);

      emit(currentState.copyWith(filteredSales: filtered, hasMore: false));
    } catch (e) {
      emit(SaleError('فشل تصفية المبيعات: $e'));
    }
  }

  void searchInHistory(String query) {
    final currentState = state;
    if (currentState is! SaleLoaded) return;

    if (query.isEmpty) {
      emit(currentState.copyWith(filteredSales: currentState.sales));
      return;
    }

    final filtered = currentState.sales
        .where(
          (s) => s.medicineName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    emit(currentState.copyWith(filteredSales: filtered));
  }

  Future<void> addSale(Sale sale) async {
    try {
      await _repository.addSale(sale);
      emit(const SaleSuccess('تمت إضافة عملية البيع بنجاح'));
      await loadSales();
    } catch (e) {
      emit(SaleError('فشل في إضافة عملية البيع: ${e.toString()}'));
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await _repository.deleteSale(id);
      emit(const SaleSuccess('تم حذف عملية البيع بنجاح'));
      await loadSales();
    } catch (e) {
      emit(SaleError('فشل في حذف عملية البيع: ${e.toString()}'));
    }
  }

  Future<void> clearOldSales(DateTime date) async {
    try {
      await _repository.clearSalesBefore(date);
      await loadSales();
    } catch (e) {
      emit(SaleError('فشل في مسح البيانات القديمة: ${e.toString()}'));
    }
  }
}

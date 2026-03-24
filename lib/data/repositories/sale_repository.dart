import 'package:hive/hive.dart';
import '../models/sale.dart';

class SaleRepository {
  static const String _boxName = 'sales';

  Future<Box<Sale>> get _box async => await Hive.openBox<Sale>(_boxName);

  // Get all sales
  Future<List<Sale>> getAllSales() async {
    final box = await _box;
    final sales = box.values.toList();
    sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return sales;
  }

  // Get paginated sales rather than all at once
  Future<List<Sale>> getPaginatedSales({int limit = 20, int offset = 0}) async {
    final box = await _box;
    final sales = box.values.toList();
    sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

    if (offset >= sales.length) return [];

    int end = offset + limit;
    if (end > sales.length) end = sales.length;

    return sales.sublist(offset, end);
  }

  // Add sale
  Future<void> addSale(Sale sale) async {
    final box = await _box;
    await box.put(sale.id, sale);
  }

  // Get sales by date range
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    final box = await _box;
    return box.values.where((sale) {
      return (sale.saleDate.isAtSameMomentAs(start) ||
              sale.saleDate.isAfter(start)) &&
          sale.saleDate.isBefore(end);
    }).toList();
  }

  // Get today's sales
  Future<List<Sale>> getTodaySales() async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final tomorrow = today.add(Duration(days: 1));
    return getSalesByDateRange(today, tomorrow);
  }

  // Get weekly sales
  Future<List<Sale>> getWeeklySales() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(Duration(days: 7));
    return getSalesByDateRange(lastWeek, now.add(Duration(seconds: 1)));
  }

  // Get monthly sales 
  Future<List<Sale>> getMonthlySales() async {
    final thisMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );
    return getSalesByDateRange(thisMonth, DateTime.now().add(Duration(seconds: 1)));
  }

  // Delete sale
  Future<void> deleteSale(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  // Clear sales before a specific date 
  Future<void> clearSalesBefore(DateTime date) async {
    final box = await _box;
    final keysToDelete = box.keys.where((key) {
      final sale = box.get(key);
      return sale != null && sale.saleDate.isBefore(date);
    }).toList();

    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }
}

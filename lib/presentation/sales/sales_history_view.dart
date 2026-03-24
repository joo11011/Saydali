import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_state.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';

class SalesHistoryView extends StatefulWidget {
  const SalesHistoryView({super.key});

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      if (mounted) {
        context.read<SaleCubit>().filterSalesByDateRange(
          picked.start,
          picked.end.add(const Duration(days: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المبيعات والتاريخ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDateRange(context),
            tooltip: 'تصفية بالتاريخ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _selectedDateRange = null);
              context.read<SaleCubit>().loadSales();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<SaleCubit, SaleState>(
              builder: (context, state) {
                if (state is SaleLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SaleLoaded) {
                  final list = state.filteredSales;
                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        list.length +
                        (state.hasMore && _selectedDateRange == null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return _buildLoadMoreButton(context);
                      }

                      final sale = list[index];
                      return _buildSaleCard(sale);
                    },
                  );
                }
                return const Center(child: Text('حدث خطأ'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => context.read<SaleCubit>().searchInHistory(val),
            decoration: InputDecoration(
              hintText: 'بحث في السجل (اسم الدواء)...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(
                  'من: ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} إلى: ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}',
                  style: const TextStyle(fontSize: 12),
                ),
                onDeleted: () {
                  setState(() => _selectedDateRange = null);
                  context.read<SaleCubit>().loadSales();
                },
                backgroundColor: AppColor.primaryColor.withOpacity(0.1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(dynamic sale) {
    return Dismissible(
      key: Key(sale.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("تأكيد الحذف"),
              content: const Text("هل تريد حذف عملية البيع هذه من السجل؟"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.errorColor,
                  ),
                  child: const Text("حذف"),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<SaleCubit>().deleteSale(sale.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: AppColor.primaryColor),
          ),
          title: Text(
            sale.medicineName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('الكمية المباعة: ${sale.quantity}'),
              Text(
                'الوقت: ${DateFormat('yyyy/MM/dd HH:mm').format(sale.saleDate)}',
              ),
            ],
          ),
          trailing: Text(
            '${sale.totalPrice?.toStringAsFixed(2) ?? '0.00'} ج.م',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColor.accentColor,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () => context.read<SaleCubit>().loadMoreSales(),
          icon: const Icon(Icons.add),
          label: const Text('عرض مبيعات سابقة'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج مطابقة لبحثك',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

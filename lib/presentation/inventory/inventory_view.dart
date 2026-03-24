import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_state.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  late List<String> _dynamicCategories;
  static const List<String> _defaultCategories = [
    'عام',
    'أقراص (Tablets)',
    'كبسولات (Capsules)',
    'شراب (Syrup)',
    'حقن (Injections)',
    'مراهم (Ointment)',
    'كريمات (Cream)',
    'بخاخات (Spray)',
    'قطرات (Drops)',
    'فوار (Effervescent)',
    'لبوس (Suppository)',
    'أكياس (Sachet)',
    'مضاد حيوي (Antibiotics)',
    'فيتامينات (Vitamins)',
    'غسول (Lotion)',
    'شامبو (Shampoo)',
    'صابون (Soap)',
    'مستحضرات تجميل (Cosmetics)',
    'مستلزمات طبية (Medical Supplies)',
    'ألبان أطفال (Baby Milk)',
    'أخرى',
  ];

  void _updateDynamicCategories(List<Medicine> medicines) {
    final Set<String> categories = Set.from(_defaultCategories);
    for (var medicine in medicines) {
      if (medicine.safeCategory.isNotEmpty) {
        categories.add(medicine.safeCategory);
      }
    }
    setState(() {
      _dynamicCategories = categories.toList();
    });
  }

  final _searchController = TextEditingController();
  String _searchQuery = '';

  String _normalizeText(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .toLowerCase()
        .trim();
  }

  @override
  void initState() {
    super.initState();
    _dynamicCategories = List.from(_defaultCategories);
    context.read<MedicineCubit>().loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<MedicineCubit>().loadMedicines(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: BlocConsumer<MedicineCubit, MedicineState>(
        listener: (context, state) {
          if (state is MedicineLoaded) {
            _updateDynamicCategories(state.medicines);
          }
          if (state is MedicineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.errorColor,
              ),
            );
          } else if (state is MedicineSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.accentColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MedicineLoading || state is MedicineInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل مخزون الأدوية...'),
                ],
              ),
            );
          } else if (state is MedicineLoaded) {
            final normalizedQuery = _normalizeText(_searchQuery);
            final filteredMedicines = state.medicines.where((m) {
              final normalizedName = _normalizeText(m.name);
              final normalizedCategory = _normalizeText(m.safeCategory);
              return normalizedName.contains(normalizedQuery) ||
                  normalizedCategory.contains(normalizedQuery);
            }).toList();

            // sort with priority to those that start with the query, then alphabetically
            filteredMedicines.sort((a, b) {
              final aStarts = _normalizeText(
                a.name,
              ).startsWith(normalizedQuery);
              final bStarts = _normalizeText(
                b.name,
              ).startsWith(normalizedQuery);
              if (aStarts && !bStarts) return -1;
              if (!aStarts && bStarts) return 1;
              return a.name.compareTo(b.name);
            });

            return Column(
              children: [
                _buildSearchField(),
                if (state.expiredMedicines.isNotEmpty)
                  _buildExpiryAlert(state.expiredMedicines, true),
                if (state.expiringSoonMedicines.isNotEmpty)
                  _buildExpiryAlert(state.expiringSoonMedicines, false),
                if (state.lowStockMedicines.isNotEmpty)
                  _buildLowStockAlert(state),
                _buildStatisticsCards(state),
                const SizedBox(height: 12),
                Expanded(
                  child: state.medicines.isEmpty
                      ? _buildEmptyState()
                      : _buildMedicineList(filteredMedicines, state.hasMore),
                ),
              ],
            );
          }
          return const Center(child: Text('حدث خطأ في تحميل البيانات'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addMedicine',
        onPressed: () => _showAddMedicineDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة دواء'),
      ),
    );
  }

  Widget _buildExpiryAlert(List<Medicine> medicines, bool isExpired) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isExpired ? AppColor.errorColor : AppColor.warningColor)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isExpired ? AppColor.errorColor : AppColor.warningColor)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.event_busy : Icons.event_note,
            color: isExpired ? AppColor.errorColor : AppColor.warningColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExpired
                  ? 'تنبيه: يوجد ${medicines.length} دواء منتهي الصلاحية!'
                  : 'تنبيه: يوجد ${medicines.length} دواء سينتهي قريباً (خلال 3 أشهر)',
              style: TextStyle(
                color: isExpired ? AppColor.errorColor : AppColor.warningColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                _showExpiryListDialog(context, medicines, isExpired),
            child: const Text('عرض'),
          ),
        ],
      ),
    );
  }

  void _showExpiryListDialog(
    BuildContext context,
    List<Medicine> medicines,
    bool isExpired,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isExpired ? 'أدوية منتهية الصلاحية' : 'أدوية تقترب من الانتهاء',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return ListTile(
                title: Text(medicine.name),
                subtitle: Text(
                  'تاريخ الانتهاء: ${DateFormat('yyyy/MM/dd').format(medicine.safeExpiryDate)}',
                ),
                trailing: Text(
                  '${medicine.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ابحث عن اسم الدواء...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildLowStockAlert(MedicineLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColor.warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تنبيه: ${state.lowStockMedicines.length} دواء بكمية منخفضة',
              style: const TextStyle(
                color: AppColor.warningColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                _showLowStockDialog(context, state.lowStockMedicines),
            child: const Text('عرض'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(MedicineLoaded state) {
    final totalMedicines = state.medicines.length;
    final lowStock = state.lowStockMedicines.length;
    final totalQuantity = state.medicines.fold(
      0,
      (sum, med) => sum + med.quantity,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الأدوية',
              totalMedicines.toString(),
              Icons.medication,
              AppColor.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'الكمية الكلية',
              totalQuantity.toString(),
              Icons.inventory_2,
              AppColor.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'كمية منخفضة',
              lowStock.toString(),
              Icons.warning,
              AppColor.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد أدوية في المخزون',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر أدناه لإضافة دواء',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList(List<Medicine> medicines, bool hasMore) {
    final showLoadMore = hasMore && _searchQuery.isEmpty;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == medicines.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () =>
                    context.read<MedicineCubit>().loadMoreMedicines(),
                child: const Text('تحميل المزيد من الأدوية'),
              ),
            ),
          );
        }
        final medicine = medicines[index];
        return Slidable(
          key: Key(medicine.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) =>
                    _showEditMedicineDialog(this.context, medicine),
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'تعديل',
              ),
              SlidableAction(
                onPressed: (context) =>
                    _deleteMedicine(this.context, medicine.id),
                backgroundColor: AppColor.errorColor,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'حذف',
              ),
            ],
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: medicine.isExpired
                      ? AppColor.errorColor.withOpacity(0.1)
                      : (medicine.isLowStock || medicine.isExpiringSoon
                            ? AppColor.warningColor.withOpacity(0.1)
                            : AppColor.primaryColor.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication,
                  color: medicine.isExpired
                      ? AppColor.errorColor
                      : (medicine.isLowStock || medicine.isExpiringSoon
                            ? AppColor.warningColor
                            : AppColor.primaryColor),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      medicine.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine.safeCategory,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 14,
                            color: medicine.isLowStock
                                ? AppColor.warningColor
                                : AppColor.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text('الكمية: ${medicine.quantity}'),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: medicine.isExpired
                                ? AppColor.errorColor
                                : (medicine.isExpiringSoon
                                      ? AppColor.warningColor
                                      : AppColor.textSecondaryColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'انتهاء: ${DateFormat('MM/yy').format(medicine.safeExpiryDate)}',
                            style: TextStyle(
                              color: medicine.isExpired
                                  ? AppColor.errorColor
                                  : (medicine.isExpiringSoon
                                        ? AppColor.warningColor
                                        : null),
                              fontWeight:
                                  (medicine.isExpired ||
                                      medicine.isExpiringSoon)
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text('السعر: ${medicine.price.toStringAsFixed(2)} ج.م'),
                ],
              ),
              trailing: medicine.isExpired
                  ? const Chip(
                      label: Text(
                        'منتهي',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      backgroundColor: AppColor.errorColor,
                    )
                  : (medicine.isLowStock
                        ? const Chip(
                            label: Text(
                              'منخفض',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor: AppColor.warningColor,
                          )
                        : null),
            ),
          ),
        );
      },
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final thresholdController = TextEditingController(text: '10');
    DateTime selectedExpiry = DateTime.now().add(const Duration(days: 365));
    String selectedCategory = 'عام'; // Default internal value
    final formKey = GlobalKey<FormState>();

    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة دواء جديد'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الدواء',
                      prefixIcon: Icon(Icons.medication),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'الرجاء إدخال الاسم'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            labelText: 'الكمية',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              (value == null || int.tryParse(value) == null)
                              ? 'أدخل رقم'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'السعر'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              (value == null || double.tryParse(value) == null)
                              ? 'أدخل سعر'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Searchable Category
                  RawAutocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _dynamicCategories;
                      }
                      return _dynamicCategories.where((String option) {
                        return option.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    onSelected: (String selection) {
                      selectedCategory = selection;
                      categoryController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'التصنيف (ابحث أو اختر)',
                              hintText: 'مثال: عام، أقراص...',
                              prefixIcon: Icon(Icons.category),
                            ),
                            onChanged: (val) =>
                                selectedCategory = val.isEmpty ? 'عام' : val,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'الرجاء اختيار تصنيف'
                                : null,
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topRight,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 300,
                            constraints: const BoxConstraints(maxHeight: 250),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiry,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setState(() => selectedExpiry = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الانتهاء',
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(
                        DateFormat('yyyy/MM/dd').format(selectedExpiry),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final medicine = Medicine(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    quantity: int.parse(quantityController.text.trim()),
                    price: double.parse(priceController.text.trim()),
                    expiryDate: selectedExpiry,
                    category: selectedCategory,
                    lowStockThreshold: int.parse(
                      thresholdController.text.trim(),
                    ),
                  );
                  context.read<MedicineCubit>().addMedicine(medicine);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicineDialog(BuildContext context, Medicine medicine) {
    final nameController = TextEditingController(text: medicine.name);
    final quantityController = TextEditingController(
      text: medicine.quantity.toString(),
    );
    final priceController = TextEditingController(
      text: medicine.price.toString(),
    );
    final thresholdController = TextEditingController(
      text: medicine.safeLowStockThreshold.toString(),
    );
    DateTime selectedExpiry = medicine.safeExpiryDate;
    String selectedCategory = medicine.safeCategory;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الدواء'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدواء',
                    prefixIcon: Icon(Icons.medication),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم الدواء';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الكمية';
                    }
                    if (int.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال سعر صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: thresholdController,
                  decoration: const InputDecoration(
                    labelText: 'حد التنبيه',
                    prefixIcon: Icon(Icons.warning),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      (value == null || int.tryParse(value) == null)
                      ? 'أدخل رقم صحيح'
                      : null,
                ),
                const SizedBox(height: 16),
                // Searchable Category
                RawAutocomplete<String>(
                  initialValue: TextEditingValue(text: selectedCategory),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _dynamicCategories;
                    }
                    return _dynamicCategories.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    selectedCategory = selection;
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'التصنيف',
                            hintText: 'مثال: عام، أقراص...',
                            prefixIcon: Icon(Icons.category),
                          ),
                          onChanged: (val) =>
                              selectedCategory = val.isEmpty ? 'عام' : val,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'الرجاء اختيار تصنيف'
                              : null,
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topRight,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiry,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => selectedExpiry = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الانتهاء',
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Text(
                      DateFormat('yyyy/MM/dd').format(selectedExpiry),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updatedMedicine = medicine.copyWith(
                  name: nameController.text.trim(),
                  quantity: int.parse(quantityController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                  lowStockThreshold: int.parse(thresholdController.text.trim()),
                  expiryDate: selectedExpiry,
                  category: selectedCategory,
                );

                context.read<MedicineCubit>().updateMedicine(updatedMedicine);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteMedicine(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الدواء؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MedicineCubit>().deleteMedicine(id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.errorColor,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showLowStockDialog(
    BuildContext context,
    List<Medicine> lowStockMedicines,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أدوية بكمية منخفضة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lowStockMedicines.length,
            itemBuilder: (context, index) {
              final medicine = lowStockMedicines[index];
              return ListTile(
                leading: const Icon(
                  Icons.warning,
                  color: AppColor.warningColor,
                ),
                title: Text(medicine.name),
                trailing: Text(
                  '${medicine.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColor.warningColor,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

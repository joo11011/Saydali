import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_state.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_state.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';
import 'package:smart_pharmacy_system/data/models/sale.dart';
import 'package:smart_pharmacy_system/presentation/sales/sales_history_view.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _alternativeController = TextEditingController();
  final _medicineFocusNode = FocusNode();
  double? _unitPrice;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateTotalPrice);
    _medicineNameController.addListener(_onMedicineNameChanged);
  }

  void _onMedicineNameChanged() {
    final selection = _medicineNameController.text.trim();
    final medicineState = context.read<MedicineCubit>().state;
    if (medicineState is MedicineLoaded) {
      try {
        final med = medicineState.medicines.firstWhere(
          (m) => _normalizeText(m.name) == _normalizeText(selection),
        );
        if (_unitPrice != med.price) {
          setState(() {
            _unitPrice = med.price;
          });
          _calculateTotalPrice();
        }
      } catch (_) {
        if (_unitPrice != null) {
          setState(() {
            _unitPrice = null;
          });
        }
      }
    }
  }

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

  void _calculateTotalPrice() {
    if (_unitPrice != null && _quantityController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text);
      if (quantity != null) {
        final total = _unitPrice! * quantity;
        _priceController.text = total.toStringAsFixed(2);
      } else {
        _priceController.text = '';
      }
    } else {
      _priceController.text = '';
    }
  }

  @override
  void dispose() {
    _medicineNameController.removeListener(_onMedicineNameChanged);
    _quantityController.removeListener(_calculateTotalPrice);
    _medicineNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _alternativeController.dispose();
    _medicineFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل المبيعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesHistoryView()),
            ),
            tooltip: 'سجل المبيعات',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SaleCubit, SaleState>(
            listener: (context, state) {
              if (state is SaleSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColor.accentColor,
                  ),
                );
              } else if (state is SaleError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColor.errorColor,
                  ),
                );
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const SizedBox(height: 8), _buildSaleForm()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'معلومات المبيعة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            BlocBuilder<MedicineCubit, MedicineState>(
              builder: (context, state) {
                List<String> options = [];
                if (state is MedicineLoaded) {
                  options = state.medicines.map((e) => e.name).toList();
                }
                return RawAutocomplete<String>(
                  textEditingController: _medicineNameController,
                  focusNode: _medicineFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    final normalizedQuery = _normalizeText(
                      textEditingValue.text,
                    );
                    return options.where((String option) {
                      return _normalizeText(option).contains(normalizedQuery);
                    });
                  },
                  onSelected: (String selection) {
                    // Update controller explicitly just in case
                    _medicineNameController.text = selection;
                    _onMedicineNameChanged();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
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
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    final medicineCubit = context.read<MedicineCubit>();

                    return Align(
                      alignment: Alignment.topRight,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 72,
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              // Safe lookup for medicine details
                              Medicine? med;
                              try {
                                if (medicineCubit.state is MedicineLoaded) {
                                  med = (medicineCubit.state as MedicineLoaded)
                                      .medicines
                                      .firstWhere(
                                        (m) => m.name == option,
                                        orElse: () => Medicine(
                                          id: '',
                                          name: option,
                                          quantity: 0,
                                          expiryDate: DateTime.now(),
                                          price: 0,
                                        ),
                                      );
                                }
                              } catch (_) {}

                              final isAvailable =
                                  med != null && med.quantity > 0;

                              return ListTile(
                                title: Text(
                                  option,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isAvailable
                                      ? 'متوفر: ${med?.quantity} عبوة - السعر: ${med?.price} ج.م'
                                      : '⚠️ غير متوفر',
                                  style: TextStyle(
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  onSelected(option);
                                  // Auto-fill price if available
                                  if (med != null && med.price > 0) {
                                    _priceController.text = med.price
                                        .toString();
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الكمية';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'الرجاء إدخال كمية صحيحة';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'السعر الإجمالي (يُحسب تلقائياً)',
                prefixIcon: Icon(Icons.calculate_outlined),
                suffixText: 'ج.م',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleSale(context, isAvailable: true),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('متوفر - تسجيل البيع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleSale(context, isAvailable: false),
                    icon: const Icon(Icons.error_outline),
                    label: const Text('غير متوفر'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.errorColor,
                      side: const BorderSide(color: AppColor.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSale(
    BuildContext context, {
    required bool isAvailable,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final medicineName = _medicineNameController.text.trim();
    final quantity = int.parse(_quantityController.text.trim());
    final price = _priceController.text.isNotEmpty
        ? double.tryParse(_priceController.text.trim())
        : null;

    final medicineCubit = context.read<MedicineCubit>();
    final medicineExists = await medicineCubit.checkMedicineExists(
      medicineName,
    );

    if (isAvailable) {
      if (!medicineExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الدواء غير موجود في المخزون. يرجى إضافته أولاً'),
            backgroundColor: AppColor.warningColor,
          ),
        );
        return;
      }

      final medicine = await medicineCubit.getMedicineByName(medicineName);
      if (medicine == null) return;

      if (medicine.quantity < quantity) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الكمية المتاحة: ${medicine.quantity} فقط'),
            backgroundColor: AppColor.warningColor,
          ),
        );
        return;
      }

      // Create sale
      final sale = Sale(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineName: medicineName,
        quantity: quantity,
        totalPrice: price,
      );

      if (!mounted) return;
      await context.read<SaleCubit>().addSale(sale);

      // Update inventory
      await medicineCubit.updateQuantity(
        medicineName,
        medicine.quantity - quantity,
      );

      _clearForm();
    } else {
      // Medicine not available - show alternative dialog
      if (!mounted) return;
      _showAlternativeDialog(context, medicineName);
    }
  }

  void _showAlternativeDialog(BuildContext context, String medicineName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الدواء غير متوفر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الدواء: $medicineName'),
            const SizedBox(height: 16),
            TextField(
              controller: _alternativeController,
              decoration: const InputDecoration(
                labelText: 'البديل اليدوي (اختياري)',
                hintText: 'أدخل اسم البديل إن وجد',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final alternative = _alternativeController.text.trim();
              final missingMedicine = MissingMedicine(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                medicineName: medicineName,
                manualAlternative: alternative.isNotEmpty ? alternative : null,
              );

              context.read<MissingMedicineCubit>().addMissingMedicine(
                missingMedicine,
              );

              Navigator.pop(dialogContext);
              _clearForm();
              _alternativeController.clear();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تمت إضافة الدواء للقائمة الناقصة'),
                  backgroundColor: AppColor.accentColor,
                ),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _medicineNameController.clear();
    _quantityController.clear();
    _priceController.clear();
    _unitPrice = null;
  }
}

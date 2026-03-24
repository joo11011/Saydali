import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_state.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';

class MissingMedicinesView extends StatefulWidget {
  const MissingMedicinesView({super.key});

  @override
  State<MissingMedicinesView> createState() => _MissingMedicinesViewState();
}

class _MissingMedicinesViewState extends State<MissingMedicinesView> {
  @override
  void initState() {
    super.initState();
    context.read<MissingMedicineCubit>().loadMissingMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأدوية الناقصة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<MissingMedicineCubit>().loadMissingMedicines(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: BlocConsumer<MissingMedicineCubit, MissingMedicineState>(
        listener: (context, state) {
          if (state is MissingMedicineError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.errorColor,
              ),
            );
          } else if (state is MissingMedicineSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColor.accentColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MissingMedicineLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MissingMedicineLoaded) {
            if (state.missingMedicines.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children: [
                _buildInfoCard(state.missingMedicines.length),
                Expanded(
                  child: _buildMissingMedicinesList(
                    state.missingMedicines,
                    state.hasMore,
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('حدث خطأ في تحميل البيانات'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reportMissing',
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColor.errorColor,
        icon: const Icon(Icons.add_alert),
        label: const Text('إبلاغ عن ناقص'),
      ),
    );
  }

  Widget _buildInfoCard(int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.errorColor.withOpacity(0.1),
            AppColor.warningColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColor.errorColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الأدوية الناقصة',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count دواء',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColor.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColor.accentColor,
          ),
          const SizedBox(height: 16),
          Text(
            'رائع! لا توجد أدوية ناقصة',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColor.accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            'جميع الأدوية متوفرة في المخزون',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMissingMedicinesList(
    List<MissingMedicine> medicines,
    bool hasMore,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == medicines.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () => context
                    .read<MissingMedicineCubit>()
                    .loadMoreMissingMedicines(),
                child: const Text('تحميل المزيد من النواقص'),
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
                    _showAddAlternativeDialog(this.context, medicine),
                backgroundColor: AppColor.accentColor,
                foregroundColor: Colors.white,
                icon: Icons.add,
                label: 'بديل',
              ),
              SlidableAction(
                onPressed: (context) =>
                    _deleteMissingMedicine(this.context, medicine.id),
                backgroundColor: AppColor.errorColor,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'حذف',
              ),
            ],
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: AppColor.errorColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.medicineName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColor.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'yyyy/MM/dd - hh:mm a',
                                    'ar',
                                  ).format(medicine.reportedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColor.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${medicine.requestCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (medicine.manualAlternative != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.swap_horiz,
                            color: AppColor.accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'البديل المسجل',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColor.textSecondaryColor,
                                ),
                              ),
                              Text(
                                medicine.manualAlternative!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showAddAlternativeDialog(context, medicine),
                          color: AppColor.primaryColor,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showAddAlternativeDialog(context, medicine),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة بديل يدوياً'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.accentColor,
                        side: const BorderSide(color: AppColor.accentColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddAlternativeDialog(
    BuildContext context,
    MissingMedicine medicine,
  ) {
    final alternativeController = TextEditingController(
      text: medicine.manualAlternative ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          medicine.manualAlternative == null ? 'إضافة بديل' : 'تعديل البديل',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الدواء الأصلي: ${medicine.medicineName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alternativeController,
              decoration: const InputDecoration(
                labelText: 'اسم الدواء البديل',
                hintText: 'أدخل اسم البديل المناسب',
                prefixIcon: Icon(Icons.medication),
              ),
              autofocus: true,
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
              final alternative = alternativeController.text.trim();
              if (alternative.isNotEmpty) {
                final updatedMedicine = medicine.copyWith(
                  manualAlternative: alternative,
                );
                context.read<MissingMedicineCubit>().updateMissingMedicine(
                  updatedMedicine,
                );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteMissingMedicine(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل الدواء أصبح متوفراً الآن؟\nسيتم حذفه من قائمة الأدوية الناقصة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MissingMedicineCubit>().deleteMissingMedicine(id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.accentColor,
            ),
            child: const Text('نعم، متوفر الآن'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إبلاغ عن دواء ناقص'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم الدواء',
            hintText: 'أدخل اسم الدواء الناقص',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final medicine = MissingMedicine(
                  id: DateTime.now().toString(),
                  medicineName: controller.text.trim(),
                  reportedDate: DateTime.now(),
                  requestCount: 1,
                );
                context.read<MissingMedicineCubit>().addMissingMedicine(
                  medicine,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

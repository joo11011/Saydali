import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_state.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_state.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_state.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/theme_cubit.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/core/utils/platform_file_helper_mobile.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';
import 'package:smart_pharmacy_system/data/models/sale.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isGeneratingReport = false;
  final _fileHelper = getHelper();

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final medicineCubit = context.read<MedicineCubit>();
      final saleCubit = context.read<SaleCubit>();
      final missingCubit = context.read<MissingMedicineCubit>();

      final medState = medicineCubit.state;
      final saleState = saleCubit.state;
      final missState = missingCubit.state;

      if (medState is! MedicineLoaded ||
          saleState is! SaleLoaded ||
          missState is! MissingMedicineLoaded) {
        throw Exception('البيانات غير جاهزة للتصدير، يرجى المحاولة مرة أخرى');
      }

      final data = {
        'medicines': medState.medicines.map((e) => e.toMap()).toList(),
        'sales': saleState.sales.map((e) => e.toMap()).toList(),
        'missing': missState.missingMedicines.map((e) => e.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      await _fileHelper.saveAndDownloadFile(
        "pharmacy_backup_${DateTime.now().millisecondsSinceEpoch}.json",
        bytes,
        mimeType: 'application/json',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير النسخة الاحتياطية بنجاح'),
            backgroundColor: AppColor.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التصدير: $e'),
            backgroundColor: AppColor.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final file = result.files.first;
      final jsonString = utf8.decode(file.bytes!);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final medicineCubit = context.read<MedicineCubit>();
      final saleCubit = context.read<SaleCubit>();
      final missingCubit = context.read<MissingMedicineCubit>();

      // 1. add Medicines from backup
      if (data.containsKey('medicines')) {
        for (var medData in data['medicines']) {
          await medicineCubit.addMedicine(Medicine.fromMap(medData));
        }
      }

      // 2. add Sales from backup
      if (data.containsKey('sales')) {
        for (var saleData in data['sales']) {
          await saleCubit.addSale(Sale.fromMap(saleData));
        }
      }

      // 3. add Missing Medicines from backup
      if (data.containsKey('missing')) {
        for (var missData in data['missing']) {
          await missingCubit.addMissingMedicine(
            MissingMedicine.fromMap(missData),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استعادة كافة البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل استعادة البيانات: $e'),
            backgroundColor: AppColor.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _generateSalesReport() async {
    setState(() => _isGeneratingReport = true);
    try {
      final salesState = context.read<SaleCubit>().state;
      if (salesState is! SaleLoaded) return;

      // Use ALL monthly sales
      final sales = salesState.monthlySales;

      if (sales.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد مبيعات مسجلة لهذا الشهر لإصدار تقرير'),
              backgroundColor: AppColor.warningColor,
            ),
          );
        }
        return;
      }

      List<List<dynamic>> rows = [];
      rows.add(["اسم الدواء", "الكمية", "السعر الإجمالي", "التاريخ"]);

      for (var sale in sales) {
        rows.add([
          sale.medicineName,
          sale.quantity,
          sale.totalPrice ?? 0.0,
          DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate),
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode("\uFEFF$csvData"); // BOM for Excel

      await _fileHelper.saveAndDownloadFile(
        "sales_report_${DateFormat('yyyy_MM').format(DateTime.now())}.csv",
        bytes,
        mimeType: 'text/csv',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم توليد تقرير المبيعات بنجاح'),
            backgroundColor: AppColor.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل توليد التقرير: $e'),
            backgroundColor: AppColor.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }

  Future<void> _clearOldData(int months) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تنظيف البيانات'),
        content: Text(
          'هل أنت متأكد من حذف البيانات الأقدم من $months شهر؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، احذف'),
          ),
        ],
      ),
    );

    if (result == true) {
      final saleCubit = context.read<SaleCubit>();
      final cutoffDate = DateTime.now().subtract(Duration(days: months * 30));
      await saleCubit.clearOldSales(cutoffDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تنظيف البيانات القديمة بنجاح'),
            backgroundColor: AppColor.accentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والبيانات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('المظهر'),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return Card(
                child: SwitchListTile(
                  title: const Text(
                    'الوضع الليلي (Dark Mode)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  secondary: Icon(
                    Icons.dark_mode,
                    color: mode == ThemeMode.dark ? Colors.purple : Colors.grey,
                  ),
                  value: mode == ThemeMode.dark,
                  onChanged: (val) {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('إدارة البيانات'),
          _buildActionCard(
            title: 'تنزيل نسخة احتياطية',
            subtitle: 'حفظ جميع بيانات الصيدلية كملف JSON',
            icon: Icons.cloud_download,
            color: AppColor.primaryColor,
            onTap: _exportBackup,
            isLoading: _isExporting,
          ),
          _buildActionCard(
            title: 'استعادة نسخة احتياطية',
            subtitle: 'رفع ملف JSON مسجل مسبقاً لاستعادة البيانات',
            icon: Icons.cloud_upload,
            color: AppColor.accentColor,
            onTap: _importBackup,
            isLoading: _isImporting,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('التقارير'),
          _buildActionCard(
            title: 'تقرير المبيعات الشهري',
            subtitle: 'تحميل ملف CSV متوافق مع Excel للمبيعات الحالية',
            icon: Icons.table_view,
            color: Colors.green,
            onTap: _generateSalesReport,
            isLoading: _isGeneratingReport,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('تنظيف البيانات الذكي'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حذف سجلات قديمة لتحسين الأداء',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [1, 3, 6, 12]
                        .map(
                          (m) => ActionChip(
                            label: Text('أقدم من $m شهر'),
                            onPressed: () => _clearOldData(m),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: isLoading ? null : onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_left, size: 20),
      ),
    );
  }
}

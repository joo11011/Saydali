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
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/presentation/inventory/inventory_view.dart';
import 'package:smart_pharmacy_system/presentation/missing_medicines/missing_medicines_view.dart';
import 'package:smart_pharmacy_system/presentation/sales/sales_history_view.dart';
import 'package:smart_pharmacy_system/presentation/sales/sales_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<MedicineCubit>().loadMedicines();
    context.read<SaleCubit>().loadSales();
    context.read<MissingMedicineCubit>().loadMissingMedicines();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 980;
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة الصيدلية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isWide ? 32 : 16),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1000 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(),
                        const SizedBox(height: 24),
                        _buildExpirySummary(isWide),
                        _buildQuickStats(isWide),
                        const SizedBox(height: 24),
                        // Quick Actions removed to reduce clutter as BottomNavBar handles this now
                        _buildTodaySalesCard(isWide),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildSidebarItem(Icons.dashboard, 'الرئيسية', true),
          _buildSidebarItem(Icons.point_of_sale, 'تسجيل مبيعة', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesView()),
            );
          }),
          _buildSidebarItem(Icons.inventory_2, 'إدارة المخزون', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InventoryView()),
            );
          }),
          _buildSidebarItem(Icons.error_outline, 'الأدوية الناقصة', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MissingMedicinesView(),
              ),
            );
          }),
          _buildSidebarItem(Icons.settings, 'الإعدادات والنسخ', false, () {
            Navigator.pushNamed(context, '/settings');
          }),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    bool isSelected, [
    VoidCallback? onTap,
  ]) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColor.primaryColor : Colors.grey.shade600,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColor.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColor.primaryColor.withOpacity(0.05),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE، d MMMM yyyy', 'ar');

    String greeting;
    final hour = now.hour;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء الخير';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primaryColor, AppColor.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'أهلاً بك في نظام إدارة الصيدلية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  formatter.format(now),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirySummary(bool isWide) {
    return BlocBuilder<MedicineCubit, MedicineState>(
      builder: (context, state) {
        if (state is MedicineLoaded) {
          final expiredCount = state.expiredMedicines.length;
          final expiringSoonCount = state.expiringSoonMedicines.length;

          if (expiredCount == 0 && expiringSoonCount == 0) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              if (expiredCount > 0)
                _buildAlertBanner(
                  title: 'تنبيه هام!',
                  message:
                      'يوجد $expiredCount دواء منتهي الصلاحية يجب سحبه فوراً.',
                  icon: Icons.dangerous,
                  color: AppColor.errorColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryView(),
                    ),
                  ),
                ),
              if (expiringSoonCount > 0)
                _buildAlertBanner(
                  title: 'صلاحية تقترب',
                  message:
                      'يوجد $expiringSoonCount دواء يقترب تاريخ انتهائها (خلال 3 أشهر).',
                  icon: Icons.warning_amber_rounded,
                  color: AppColor.warningColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryView(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAlertBanner({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isWide) {
    if (isWide) {
      return BlocBuilder<MedicineCubit, MedicineState>(
        builder: (context, medState) {
          return BlocBuilder<MissingMedicineCubit, MissingMedicineState>(
            builder: (context, missState) {
              return BlocBuilder<SaleCubit, SaleState>(
                builder: (context, saleState) {
                  int medCount = medState is MedicineLoaded
                      ? medState.medicines.length
                      : 0;
                  int missCount = missState is MissingMedicineLoaded
                      ? missState.missingMedicines.length
                      : 0;
                  double totalToday = 0;
                  int salesCount = 0;
                  if (saleState is SaleLoaded) {
                    salesCount = saleState.todaySales.length;
                    totalToday = saleState.todaySales.fold(
                      0,
                      (sum, item) => sum + (item.totalPrice ?? 0),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'المخزون',
                              medCount.toString(),
                              Icons.inventory_2,
                              AppColor.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MissingMedicinesView(),
                                ),
                              ),
                              child: _buildStatCard(
                                'نواقص',
                                missCount.toString(),
                                Icons.error_outline,
                                AppColor.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColor.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColor.accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColor.accentColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payments,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'دخل اليوم ($salesCount مبيعات)',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${totalToday.toStringAsFixed(2)} ج.م',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.trending_up,
                              color: AppColor.accentColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BlocBuilder<MedicineCubit, MedicineState>(
                builder: (context, state) {
                  int count = 0;
                  if (state is MedicineLoaded) {
                    count = state.medicines.length;
                  }
                  return _buildStatCard(
                    'المخزون',
                    count.toString(),
                    Icons.inventory_2,
                    AppColor.primaryColor,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<MissingMedicineCubit, MissingMedicineState>(
                builder: (context, state) {
                  int count = 0;
                  if (state is MissingMedicineLoaded) {
                    count = state.missingMedicines.length;
                  }
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MissingMedicinesView(),
                      ),
                    ),
                    child: _buildStatCard(
                      'نواقص',
                      count.toString(),
                      Icons.error_outline,
                      AppColor.errorColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<SaleCubit, SaleState>(
          builder: (context, state) {
            double totalToday = 0;
            double totalWeekly = 0;
            double totalMonthly = 0;
            int salesCountToday = 0;

            if (state is SaleLoaded) {
              salesCountToday = state.todaySales.length;
              totalToday = state.todaySales.fold(
                0,
                (sum, item) => sum + (item.totalPrice ?? 0),
              );
              totalWeekly = state.weeklySales.fold(
                0,
                (sum, item) => sum + (item.totalPrice ?? 0),
              );
              totalMonthly = state.monthlySales.fold(
                0,
                (sum, item) => sum + (item.totalPrice ?? 0),
              );
            }

            return Column(
              children: [
                _buildRevenueRow(
                  title: 'دخل اليوم ($salesCountToday مبيعات)',
                  value: totalToday,
                  icon: Icons.today,
                  color: AppColor.accentColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueRow(
                        title: 'دخل الأسبوع',
                        value: totalWeekly,
                        icon: Icons.calendar_view_week,
                        color: AppColor.accentColor,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRevenueRow(
                        title: 'دخل الشهر',
                        value: totalMonthly,
                        icon: Icons.calendar_month,
                        color: AppColor.accentColor,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueRow({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 20 : 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    fontSize: compact ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) Icon(Icons.trending_up, color: color),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // is not used i canoot find a reference
  Widget _buildQuickActions(bool isWide) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'تسجيل مبيعة',
                'إضافة عملية بيع جديدة',
                Icons.point_of_sale,
                AppColor.primaryColor,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesView()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'إدارة المخزون',
                'عرض وتحديث المخزون',
                Icons.inventory_2,
                AppColor.accentColor,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryView(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'الأدوية الناقصة',
          'عرض وإدارة الأدوية الغير متوفرة',
          Icons.error_outline,
          AppColor.errorColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MissingMedicinesView(),
            ),
          ),
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isWide = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isWide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 20),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
      ),
    );
  }

  Widget _buildTodaySalesCard(bool isWide) {
    return BlocBuilder<SaleCubit, SaleState>(
      builder: (context, state) {
        if (state is SaleLoaded && state.todaySales.isNotEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, color: AppColor.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'آخر المبيعات اليوم',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...state.todaySales.take(3).map((sale) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColor.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: AppColor.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.medicineName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'الكمية: ${sale.quantity}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (sale.totalPrice != null)
                            Text(
                              '${sale.totalPrice!.toStringAsFixed(2)} ج.م',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColor.accentColor,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (state.todaySales.length > 3)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SalesHistoryView(),
                        ),
                      ),
                      child: const Text('عرض الكل'),
                    ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

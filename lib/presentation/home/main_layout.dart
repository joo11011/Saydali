import 'package:flutter/material.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/presentation/debts/debts_view.dart';
import 'package:smart_pharmacy_system/presentation/home/home_view.dart';
import 'package:smart_pharmacy_system/presentation/inventory/inventory_view.dart';
import 'package:smart_pharmacy_system/presentation/sales/sales_view.dart';
import 'package:smart_pharmacy_system/presentation/settings/settings_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeView(),
    const SalesView(),
    const InventoryView(),
    const DebtsView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          indicatorColor: AppColor.primaryColor.withOpacity(0.2),
          elevation: 3,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColor.primaryColor),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(
                Icons.point_of_sale,
                color: AppColor.primaryColor,
              ),
              label: 'المبيعات',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(
                Icons.inventory_2,
                color: AppColor.primaryColor,
              ),
              label: 'المخزون',
            ),
            NavigationDestination(
              icon: Icon(Icons.request_quote_outlined),
              selectedIcon: Icon(
                Icons.request_quote,
                color: AppColor.primaryColor,
              ),
              label: 'الديون',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColor.primaryColor),
              label: 'إعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

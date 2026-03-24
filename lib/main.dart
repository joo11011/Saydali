import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/debt_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/missing_medicine_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/sale_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/theme_cubit.dart';
import 'package:smart_pharmacy_system/core/theme/app_theme.dart';
import 'package:smart_pharmacy_system/data/models/debt.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';
import 'package:smart_pharmacy_system/data/models/sale.dart';
import 'package:smart_pharmacy_system/data/repositories/debt_repository.dart';
import 'package:smart_pharmacy_system/data/repositories/medicine_repository.dart';
import 'package:smart_pharmacy_system/data/repositories/missing_medicine_repository.dart';
import 'package:smart_pharmacy_system/data/repositories/sale_repository.dart';
import 'package:smart_pharmacy_system/presentation/home/main_layout.dart';
import 'package:smart_pharmacy_system/presentation/inventory/inventory_view.dart';
import 'package:smart_pharmacy_system/presentation/missing_medicines/missing_medicines_view.dart';
import 'package:smart_pharmacy_system/presentation/sales/sales_view.dart';
import 'package:smart_pharmacy_system/presentation/settings/settings_view.dart';
import 'package:smart_pharmacy_system/presentation/splash/splash_view.dart';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e) {
    debugPrint('Error initializing binding: $e');
  }

  runApp(const PharmacistAppStarter());
}

class PharmacistAppStarter extends StatefulWidget {
  const PharmacistAppStarter({super.key});

  @override
  State<PharmacistAppStarter> createState() => _PharmacistAppStarterState();
}

class _PharmacistAppStarterState extends State<PharmacistAppStarter> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initApp();
  }

  Future<void> _initApp() async {
    try {
      await Hive.initFlutter().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint("⚠️ Hive initialization timed out - Proceeding anyway.");
        },
      );

      try {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(MedicineAdapter());
        }
        if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SaleAdapter());
        if (!Hive.isAdapterRegistered(2)) {
          Hive.registerAdapter(MissingMedicineAdapter());
        }
      } catch (e) {
        debugPrint("Adapter registration error: $e");
      }

      await initializeDateFormatting('ar', null);
    } catch (e) {
      debugPrint("Initialization Error: $e");
    }

    try {
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DebtAdapter());
    } catch (e) {
      debugPrint("Debt Adapter Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        return const MainAppStructure();
      },
    );
  }
}

class MainAppStructure extends StatelessWidget {
  const MainAppStructure({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => MedicineRepository()),
        RepositoryProvider(create: (context) => SaleRepository()),
        RepositoryProvider(create: (context) => MissingMedicineRepository()),
        RepositoryProvider(create: (context) => DebtRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create: (context) =>
                MedicineCubit(context.read<MedicineRepository>()),
          ),
          BlocProvider(
            create: (context) => SaleCubit(context.read<SaleRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                MissingMedicineCubit(context.read<MissingMedicineRepository>()),
          ),
          BlocProvider(
            create: (context) => DebtCubit(context.read<DebtRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'نظام إدارة الصيدلية',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              locale: const Locale('ar'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('ar'), Locale('en')],
              initialRoute: '/splash',
              routes: {
                '/splash': (context) => const SplashView(),
                '/home': (context) => const MainLayout(),
                '/sales': (context) => const SalesView(),
                '/inventory': (context) => const InventoryView(),
                '/missing': (context) => const MissingMedicinesView(),
                '/settings': (context) => const SettingsView(),
              },
            );
          },
        ),
      ),
    );
  }
}

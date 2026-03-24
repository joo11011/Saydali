import 'package:equatable/equatable.dart';
import 'package:smart_pharmacy_system/data/models/sale.dart';

abstract class SaleState extends Equatable {
  const SaleState();

  @override
  List<Object?> get props => [];
}

class SaleIntial extends SaleState {}

class SaleLoading extends SaleState {}

class SaleLoaded extends SaleState {
  final List<Sale> sales;
  final List<Sale> todaySales;
  final List<Sale> weeklySales;
  final List<Sale> monthlySales;
  final List<Sale> filteredSales;
  final bool hasMore;

  const SaleLoaded({
    required this.sales,
    required this.todaySales,
    this.weeklySales = const [],
    this.monthlySales = const [],
    this.filteredSales = const [],
    this.hasMore = true,
  });

  SaleLoaded copyWith({
    List<Sale>? sales,
    List<Sale>? todaySales,
    List<Sale>? weeklySales,
    List<Sale>? monthlySales,
    List<Sale>? filteredSales,
    bool? hasMore,
  }) {
    return SaleLoaded(
      sales: sales ?? this.sales,
      todaySales: todaySales ?? this.todaySales,
      weeklySales: weeklySales ?? this.weeklySales,
      monthlySales: monthlySales ?? this.monthlySales,
      filteredSales: filteredSales ?? this.filteredSales,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
    sales,
    todaySales,
    weeklySales,
    monthlySales,
    filteredSales,
    hasMore,
  ];
}

class SaleError extends SaleState {
  final String message;

  const SaleError(this.message);

  @override
  List<Object?> get props => [message];
}

class SaleSuccess extends SaleState {
  final String message;

  const SaleSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

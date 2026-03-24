import 'package:hive/hive.dart';

part 'sale.g.dart';

@HiveType(typeId: 1)
class Sale {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String medicineName;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final double? totalPrice;

  @HiveField(4)
  final DateTime saleDate;

  Sale({
    required this.id,
    required this.medicineName,
    required this.quantity,
    DateTime? saleDate,
    this.totalPrice,
  }) : saleDate = saleDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'saleDate': saleDate.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      medicineName: map['medicineName'] as String,
      quantity: map['quantity'] as int,
      totalPrice: map['totalPrice'] as double?,
      saleDate: DateTime.parse(map['saleDate'] as String),
    );
  }
}

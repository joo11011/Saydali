import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final int? lowStockThreshold;

  @HiveField(5)
  final DateTime? createdAt;

  @HiveField(6)
  final DateTime? expiryDate;

  @HiveField(7)
  final String? category;
  Medicine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.expiryDate,
    this.category,
    this.lowStockThreshold,
    this.createdAt,
  });
  int get safeLowStockThreshold => lowStockThreshold ?? 10;
  DateTime get safeCreatedAt => createdAt ?? DateTime.now();
  DateTime get safeExpiryDate =>
      expiryDate ?? DateTime.now().add(Duration(days: 365));
  String get safeCategory => category ?? 'عام';

  bool get isLowStock => quantity <= safeLowStockThreshold;
  bool get isExpired => safeExpiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon =>
      safeExpiryDate.isBefore(DateTime.now().add(Duration(days: 90)));

  Medicine copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? expiryDate,
    String? category,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'lowStockThreshold': safeLowStockThreshold,
      'createdAt': safeCreatedAt.toIso8601String(),
      'expiryDate': safeExpiryDate.toIso8601String(),
      'category': safeCategory,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      lowStockThreshold: map['lowStockThreshold'] as int?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      category: map['category'] as String?,
    );
  }
}

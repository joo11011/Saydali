import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 3)
class Debt {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String customerName;
  @HiveField(2)
  final double amount;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final String notes;

  @HiveField(5)
  final double paidAmount;
  Debt({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    this.notes = '',
    this.paidAmount = 0.0,
  });
  double get remainingAmount => amount - paidAmount;
  Debt copyWith({
    String? id,
    String? customerName,
    double? amount,
    DateTime? date,
    String? notes,
    double? paidAmount,
  }) {
    return Debt(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'amount': amount,
      'date': date.toIso8601String(),

      'notes': notes,
      'paidAmount': paidAmount,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      customerName: map['customerName'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
      paidAmount: map['paidAmount'] ?? 0.0,
    );
  }
}

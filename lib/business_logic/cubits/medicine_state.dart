import 'package:equatable/equatable.dart';
import 'package:smart_pharmacy_system/data/models/medicine.dart';

abstract class MedicineState extends Equatable {
  const MedicineState();

  @override
  List<Object?> get props => [];
}

class MedicineInitial extends MedicineState {}

class MedicineLoading extends MedicineState {}

class MedicineLoaded extends MedicineState {
  final List<Medicine> medicines;
  final List<Medicine> lowStockMedicines;
  final List<Medicine> expiredMedicines;
  final List<Medicine> expiringSoonMedicines;
  final bool hasMore;

  const MedicineLoaded({
    required this.medicines,
    required this.lowStockMedicines,
    required this.expiredMedicines,
    required this.expiringSoonMedicines,
    this.hasMore = true,
  });

  MedicineLoaded copyWith({
    List<Medicine>? medicines,
    List<Medicine>? lowStockMedicines,
    List<Medicine>? expiredMedicines,
    List<Medicine>? expiringSoonMedicines,
    bool? hasMore,
  }) {
    return MedicineLoaded(
      medicines: medicines ?? this.medicines,
      lowStockMedicines: lowStockMedicines ?? this.lowStockMedicines,
      expiredMedicines: expiredMedicines ?? this.expiredMedicines,
      expiringSoonMedicines:
          expiringSoonMedicines ?? this.expiringSoonMedicines,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
    medicines,
    lowStockMedicines,
    expiredMedicines,
    expiringSoonMedicines,
    hasMore,
  ];
}

class MedicineError extends MedicineState {
  final String message;

  const MedicineError(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicineSuccess extends MedicineState {
  final String message;

  const MedicineSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

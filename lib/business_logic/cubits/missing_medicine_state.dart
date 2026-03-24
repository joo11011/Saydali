import 'package:equatable/equatable.dart';
import 'package:smart_pharmacy_system/data/models/missing_medicine.dart';

abstract class MissingMedicineState extends Equatable {
  const MissingMedicineState();

  @override
  List<Object?> get props => [];
}

class MissingMedicineInitial extends MissingMedicineState {}

class MissingMedicineLoading extends MissingMedicineState {}

class MissingMedicineLoaded extends MissingMedicineState {
  final List<MissingMedicine> missingMedicines;
  final bool hasMore;

  const MissingMedicineLoaded(this.missingMedicines, {this.hasMore = true});

  MissingMedicineLoaded copyWith({
    List<MissingMedicine>? missingMedicines,
    bool? hasMore,
  }) {
    return MissingMedicineLoaded(
      missingMedicines ?? this.missingMedicines,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [missingMedicines, hasMore];
}

class MissingMedicineError extends MissingMedicineState {
  final String message;

  const MissingMedicineError(this.message);

  @override
  List<Object?> get props => [message];
}

class MissingMedicineSuccess extends MissingMedicineState {
  final String message;

  const MissingMedicineSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

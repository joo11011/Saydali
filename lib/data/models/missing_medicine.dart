import 'package:hive/hive.dart';
part 'missing_medicine.g.dart';

@HiveType(typeId: 2)
class MissingMedicine {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String medicineName;

  @HiveField(2)
  final String? manualAlternative;

  @HiveField(3)
  final DateTime reportedDate;

  @HiveField(4)
  final int requestCount;

  MissingMedicine({
    required this.id,
    required this.medicineName,
    this.manualAlternative,
    DateTime? reportedDate,
    this.requestCount = 1,
  }) : reportedDate = reportedDate ?? DateTime.now();
  MissingMedicine copyWith({
    String? id,
    String? medicineName,
    String? manualAlternative,
    DateTime? reportedDate,
    int? requestCount,
  }) {
    return MissingMedicine(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      manualAlternative: manualAlternative ?? this.manualAlternative,
      reportedDate: reportedDate ?? this.reportedDate,
      requestCount: requestCount ?? this.requestCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineName': medicineName,
      'manualAlternative': manualAlternative,
      'reportedDate': reportedDate.toIso8601String(),
      'requestCount': requestCount,
    };
  }

  factory MissingMedicine.fromMap(Map<String, dynamic> map) {
    return MissingMedicine(
      id: map['id'] as String,
      medicineName: map['medicineName'] as String,
      manualAlternative: map['manualAlternative'] as String?,
      reportedDate: DateTime.parse(map['reportedDate'] as String),
      requestCount: map['requestCount'] as int? ?? 1,
    );
  }
}

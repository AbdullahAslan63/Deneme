import 'package:equatable/equatable.dart';

import 'resident_info.dart';

enum PaymentStatus { paid, pending, overdue }

class ApartmentEntity extends Equatable {
  final String id;
  final String buildingId;
  final String apartmentNumber;
  final int? floor;
  final ResidentInfo? resident;
  final double monthlyDues;
  final PaymentStatus paymentStatus;
  final DateTime? lastPaymentDate;
  final double balance;

  const ApartmentEntity({
    required this.id,
    required this.buildingId,
    required this.apartmentNumber,
    this.floor,
    this.resident,
    this.monthlyDues = 0.0,
    this.paymentStatus = PaymentStatus.pending,
    this.lastPaymentDate,
    this.balance = 0.0,
  });

  /// Geriye uyumluluk için: UI'da `apt.residentName` çağrıları
  /// backend'den gelen sakin adına ya da boş daire metnine düşer.
  String get residentName => resident?.name ?? 'Boş Daire';

  /// Geriye uyumluluk için: UI'da `apt.phone` çağrıları sakinin
  /// telefon numarasını döner; sakin yoksa veya telefon paylaşmamışsa null.
  String? get phone => resident?.phone;

  bool get isOccupied => resident != null;

  ApartmentEntity copyWith({
    String? id,
    String? buildingId,
    String? apartmentNumber,
    int? floor,
    ResidentInfo? resident,
    bool clearResident = false,
    double? monthlyDues,
    PaymentStatus? paymentStatus,
    DateTime? lastPaymentDate,
    double? balance,
  }) {
    return ApartmentEntity(
      id: id ?? this.id,
      buildingId: buildingId ?? this.buildingId,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      floor: floor ?? this.floor,
      resident: clearResident ? null : (resident ?? this.resident),
      monthlyDues: monthlyDues ?? this.monthlyDues,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      balance: balance ?? this.balance,
    );
  }

  @override
  List<Object?> get props => [
        id,
        buildingId,
        apartmentNumber,
        floor,
        resident,
        monthlyDues,
        paymentStatus,
        lastPaymentDate,
        balance,
      ];
}

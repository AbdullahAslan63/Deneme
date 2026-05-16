import '../../domain/entities/building_entity.dart';

/// Belge §2.3: Prisma `Building` alanları.
/// `dueAmount` Decimal olduğu için JSON'da string gelir (örn. "600.00")
/// — güvenli parse için `_toDouble` kullanılır.
class BuildingModel {
  final String id;
  final String name;
  final String address;
  final String? city;
  final int? totalFloors;
  final int? apartmentsPerFloor;
  final String managerId;
  final double? dueAmount;
  final int? dueDay;
  final String? currency;

  /// `GET /buildings` yanıtında Prisma `_count.apartments` (§2.3).
  /// Yoksa (ör. `POST /buildings` yanıtı) `toEntity` kat × daire tahminini kullanır.
  final int? apartmentCountFromApi;

  BuildingModel({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.totalFloors,
    this.apartmentsPerFloor,
    required this.managerId,
    this.dueAmount,
    this.dueDay,
    this.currency,
    this.apartmentCountFromApi,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    int? apartmentCountFromApi;
    final rawCount = json['_count'];
    if (rawCount is Map<String, dynamic>) {
      final n = rawCount['apartments'];
      if (n is int) apartmentCountFromApi = n;
    }
    return BuildingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String?,
      totalFloors: json['totalFloors'] as int?,
      apartmentsPerFloor: json['apartmentsPerFloor'] as int?,
      managerId: json['managerId'] as String,
      dueAmount: _toDouble(json['dueAmount']),
      dueDay: json['dueDay'] as int?,
      currency: json['currency'] as String?,
      apartmentCountFromApi: apartmentCountFromApi,
    );
  }

  BuildingEntity toEntity() {
    final total = apartmentCountFromApi ??
        ((totalFloors ?? 0) * (apartmentsPerFloor ?? 0));
    final monthly = (dueAmount ?? 0) * total;
    return BuildingEntity(
      id: id,
      name: name,
      address: address,
      city: city ?? '',
      totalApartments: total,
      occupiedApartments: 0,
      totalMonthlyDues: monthly,
      collectedDues: 0.0,
      dueAmount: dueAmount,
      dueDay: dueDay,
      currency: currency ?? 'TRY',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

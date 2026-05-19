import '../../domain/entities/apartment_entity.dart';
import 'resident_model.dart';

class ApartmentModel {
  final String id;
  final String number;
  final int? floor;
  final String buildingId;
  final ResidentModel? resident;

  ApartmentModel({
    required this.id,
    required this.number,
    this.floor,
    required this.buildingId,
    this.resident,
  });

  factory ApartmentModel.fromJson(Map<String, dynamic> json) {
    final residentJson = json['resident'];
    return ApartmentModel(
      id: json['id'] as String,
      number: json['number'] as String,
      floor: json['floor'] as int?,
      buildingId: json['buildingId'] as String,
      resident: residentJson is Map<String, dynamic>
          ? ResidentModel.fromJson(residentJson)
          : null,
    );
  }

  ApartmentEntity toEntity() {
    return ApartmentEntity(
      id: id,
      buildingId: buildingId,
      apartmentNumber: number,
      floor: floor,
      resident: resident?.toEntity(),
    );
  }
}

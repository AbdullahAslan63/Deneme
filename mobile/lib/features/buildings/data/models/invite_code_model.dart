class InviteCodeModel {
  final String id;
  final String code;
  final String apartmentId;
  final DateTime expiresAt;
  final DateTime? usedAt;

  InviteCodeModel({
    required this.id,
    required this.code,
    required this.apartmentId,
    required this.expiresAt,
    this.usedAt,
  });

  factory InviteCodeModel.fromJson(Map<String, dynamic> json) {
    return InviteCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      apartmentId: json['apartmentId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'] as String)
          : null,
    );
  }
}

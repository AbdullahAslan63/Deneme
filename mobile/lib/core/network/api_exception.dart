class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalException;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalException,
  });

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'Ağ bağlantısı hatası'});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'Yetkisiz erişim'})
    : super(statusCode: 401);
}

class NotFoundException extends ApiException {
  NotFoundException({super.message = 'Kaynak bulunamadı'})
    : super(statusCode: 404);
}

class ServerException extends ApiException {
  ServerException({super.message = 'Sunucu hatası'}) : super(statusCode: 500);
}

class ValidationException extends ApiException {
  ValidationException({super.message = 'Doğrulama hatası'})
    : super(statusCode: 422);
}

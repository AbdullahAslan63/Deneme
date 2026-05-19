import '../../../../core/network/api_exception.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_datasource.dart';
import '../models/create_ticket_request.dart';
import '../models/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource _remoteDataSource;

  TicketRepositoryImpl({required TicketRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<TicketEntity>> getMyTickets({
    TicketStatus? status,
    TicketCategory? category,
  }) async {
    try {
      final models = await _remoteDataSource.getMyTickets(
        status: status != null ? TicketModel.statusToApi(status) : null,
        category:
            category != null ? TicketModel.categoryToApi(category) : null,
      );
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Talepler alınırken bir hata oluştu');
    }
  }

  @override
  Future<List<TicketEntity>> getBuildingTickets(
    String buildingId, {
    TicketStatus? status,
    TicketCategory? category,
  }) async {
    try {
      final models = await _remoteDataSource.getBuildingTickets(
        buildingId,
        status: status != null ? TicketModel.statusToApi(status) : null,
        category:
            category != null ? TicketModel.categoryToApi(category) : null,
      );
      return models.map((m) => m.toEntity()).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Bina talepleri alınırken bir hata oluştu');
    }
  }

  @override
  Future<TicketEntity> getTicketById(String ticketId) async {
    try {
      final model = await _remoteDataSource.getTicketById(ticketId);
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Talep detayı alınırken bir hata oluştu');
    }
  }

  @override
  Future<TicketEntity> createTicket({
    required String apartmentId,
    required String title,
    required String description,
    required TicketCategory category,
  }) async {
    try {
      final model = await _remoteDataSource.createTicket(
        apartmentId,
        CreateTicketRequest(
          title: title.trim(),
          description: description.trim(),
          category: TicketModel.categoryToApi(category),
        ),
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Talep oluşturulurken bir hata oluştu');
    }
  }

  @override
  Future<TicketEntity> addManagerUpdate({
    required String ticketId,
    required String message,
  }) async {
    try {
      await _remoteDataSource.addTicketUpdate(ticketId, message.trim());
      return getTicketById(ticketId);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Not eklenirken bir hata oluştu');
    }
  }

  @override
  Future<TicketEntity> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    try {
      final model = await _remoteDataSource.patchTicketStatus(
        ticketId,
        TicketModel.statusToApi(status),
      );
      return model.toEntity();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(message: 'Talep durumu güncellenirken bir hata oluştu');
    }
  }
}

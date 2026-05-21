import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/create_ticket_request.dart';
import '../models/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getMyTickets({
    String? status,
    String? category,
  });

  Future<List<TicketModel>> getBuildingTickets(
    String buildingId, {
    String? status,
    String? category,
  });

  Future<TicketModel> getTicketById(String ticketId);

  Future<TicketModel> createTicket(
    String apartmentId,
    CreateTicketRequest request,
  );

  Future<void> addTicketUpdate(String ticketId, String message);

  Future<TicketModel> patchTicketStatus(String ticketId, String status);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final DioClient _dioClient;

  TicketRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  Map<String, dynamic>? _query({String? status, String? category}) {
    final q = <String, dynamic>{};
    if (status != null) q['status'] = status;
    if (category != null) q['category'] = category;
    return q.isEmpty ? null : q;
  }

  List<TicketModel> _parseList(dynamic data) {
    final list = data as List;
    return list
        .map((json) => TicketModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TicketModel>> getMyTickets({
    String? status,
    String? category,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.myTickets,
      queryParameters: _query(status: status, category: category),
    );
    return _parseList(response.data['data']);
  }

  @override
  Future<List<TicketModel>> getBuildingTickets(
    String buildingId, {
    String? status,
    String? category,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.buildingTickets(buildingId),
      queryParameters: _query(status: status, category: category),
    );
    return _parseList(response.data['data']);
  }

  @override
  Future<TicketModel> getTicketById(String ticketId) async {
    final response = await _dioClient.get(ApiConstants.ticket(ticketId));
    return TicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<TicketModel> createTicket(
    String apartmentId,
    CreateTicketRequest request,
  ) async {
    final response = await _dioClient.post(
      ApiConstants.apartmentTickets(apartmentId),
      data: request.toJson(),
    );
    return TicketModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> addTicketUpdate(String ticketId, String message) async {
    await _dioClient.post(
      ApiConstants.ticketUpdates(ticketId),
      data: {'message': message},
    );
  }

  @override
  Future<TicketModel> patchTicketStatus(
    String ticketId,
    String status,
  ) async {
    final response = await _dioClient.patch(
      ApiConstants.ticketStatus(ticketId),
      data: {'status': status},
    );
    return TicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';

final ticketRemoteDataSourceProvider = Provider<TicketRemoteDataSource>((ref) {
  return TicketRemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepositoryImpl(
    remoteDataSource: ref.watch(ticketRemoteDataSourceProvider),
  );
});

class TicketsState {
  final bool isLoading;
  final List<TicketEntity> tickets;
  final String? error;

  const TicketsState({
    this.isLoading = false,
    this.tickets = const [],
    this.error,
  });

  TicketsState copyWith({
    bool? isLoading,
    List<TicketEntity>? tickets,
    String? error,
    bool clearError = false,
  }) {
    return TicketsState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TicketsNotifier extends StateNotifier<TicketsState> {
  final TicketRepository _repository;
  bool _isCreating = false;

  TicketsNotifier(this._repository) : super(const TicketsState());

  Future<void> loadMyTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _repository.getMyTickets();
      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(isLoading: false, tickets: tickets);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> loadBuildingTickets(String buildingId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _repository.getBuildingTickets(buildingId);
      tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(isLoading: false, tickets: tickets);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<bool> createTicket({
    required String apartmentId,
    required String title,
    required String description,
    required TicketCategory category,
  }) async {
    if (_isCreating) return false;
    _isCreating = true;
    try {
      final created = await _repository.createTicket(
        apartmentId: apartmentId,
        title: title,
        description: description,
        category: category,
      );
      state = state.copyWith(
        tickets: [created, ...state.tickets],
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException ? e.message : e.toString(),
      );
      return false;
    } finally {
      _isCreating = false;
    }
  }

  bool get isCreating => _isCreating;
}

final ticketsNotifierProvider =
    StateNotifierProvider<TicketsNotifier, TicketsState>((ref) {
  return TicketsNotifier(ref.watch(ticketRepositoryProvider));
});

final ticketDetailProvider =
    FutureProvider.family<TicketEntity, String>((ref, ticketId) async {
  return ref.watch(ticketRepositoryProvider).getTicketById(ticketId);
});

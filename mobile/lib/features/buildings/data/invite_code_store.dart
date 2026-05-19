import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import 'datasources/invite_code_remote_datasource.dart';
import 'models/invite_code_model.dart';
import 'repositories/invite_code_repository.dart';
import 'repositories/invite_code_repository_impl.dart';

class ActiveInviteCode {
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;

  const ActiveInviteCode({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remaining => expiresAt.difference(DateTime.now());
}

final inviteCodeRemoteDataSourceProvider =
    Provider<InviteCodeRemoteDataSource>((ref) {
  return InviteCodeRemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});

final inviteCodeRepositoryProvider = Provider<InviteCodeRepository>((ref) {
  return InviteCodeRepositoryImpl(
    remoteDataSource: ref.watch(inviteCodeRemoteDataSourceProvider),
  );
});

class InviteCodeNotifier
    extends StateNotifier<Map<String, ActiveInviteCode>> {
  final InviteCodeRepository _repository;

  InviteCodeNotifier(this._repository) : super(const {});

  ActiveInviteCode? activeFor(String apartmentId) {
    final entry = state[apartmentId];
    if (entry == null) return null;
    if (entry.isExpired) {
      final next = Map<String, ActiveInviteCode>.from(state)
        ..remove(apartmentId);
      state = next;
      return null;
    }
    return entry;
  }

  Future<ActiveInviteCode?> generateInviteCode(String apartmentId) async {
    try {
      final model = await _repository.generateInviteCode(apartmentId);
      final entry = _modelToActive(model);
      state = {...state, apartmentId: entry};
      return entry;
    } catch (_) {
      return null;
    }
  }

  void revoke(String apartmentId) {
    final next = Map<String, ActiveInviteCode>.from(state)
      ..remove(apartmentId);
    state = next;
  }

  ActiveInviteCode _modelToActive(InviteCodeModel model) {
    return ActiveInviteCode(
      code: model.code,
      createdAt: DateTime.now(),
      expiresAt: model.expiresAt,
    );
  }
}

final inviteCodeStoreProvider =
    StateNotifierProvider<InviteCodeNotifier, Map<String, ActiveInviteCode>>(
  (ref) => InviteCodeNotifier(ref.watch(inviteCodeRepositoryProvider)),
);

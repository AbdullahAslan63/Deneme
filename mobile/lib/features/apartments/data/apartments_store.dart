import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../domain/entities/apartment_entity.dart';
import 'datasources/apartment_remote_datasource.dart';
import 'repositories/apartment_repository.dart';
import 'repositories/apartment_repository_impl.dart';

final apartmentRemoteDataSourceProvider =
    Provider<ApartmentRemoteDataSource>((ref) {
  return ApartmentRemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});

final apartmentRepositoryProvider = Provider<ApartmentRepository>((ref) {
  return ApartmentRepositoryImpl(
    remoteDataSource: ref.watch(apartmentRemoteDataSourceProvider),
  );
});

class ApartmentsNotifier
    extends StateNotifier<AsyncValue<List<ApartmentEntity>>> {
  final ApartmentRepository _repository;
  final String buildingId;

  /// Aynı submit'in art arda tetiklenmesini engelleyen in-flight bayrağı.
  /// UI butonu disable ediyor; bu defansif katman.
  bool _isCreating = false;

  ApartmentsNotifier(this._repository, this.buildingId)
      : super(const AsyncValue.loading()) {
    loadApartments();
  }

  Future<void> loadApartments() async {
    state = const AsyncValue.loading();
    try {
      final apartments = await _repository.fetchApartments(buildingId);
      state = AsyncValue.data(apartments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addApartment({required String number, int? floor}) async {
    if (_isCreating) return;
    _isCreating = true;
    try {
      final apartment = await _repository.createApartment(
        buildingId: buildingId,
        number: number,
        floor: floor,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([...current, apartment]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isCreating = false;
    }
  }

  /// Hata varsa rethrow; state'i AsyncValue.error'a çevirmeyiz çünkü
  /// kullanıcı tüm daire listesini kaybeder. UI snackbar gösterir.
  Future<void> removeApartment(String apartmentId) async {
    await _repository.deleteApartment(
      buildingId: buildingId,
      id: apartmentId,
    );
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((a) => a.id != apartmentId).toList(),
    );
  }

  /// Belge §6: PUT /buildings/:bId/apartments/:id body `number?`, `floor?`.
  /// Backend yanıtında `resident` dönmediği için mevcut sakini korumak
  /// adına eski entity'nin resident'ini merge ediyoruz.
  Future<void> editApartment({
    required String apartmentId,
    String? number,
    int? floor,
  }) async {
    final updated = await _repository.updateApartment(
      buildingId: buildingId,
      id: apartmentId,
      number: number,
      floor: floor,
    );
    final current = state.value ?? [];
    final existing = current.firstWhere(
      (a) => a.id == apartmentId,
      orElse: () => updated,
    );
    final merged = updated.copyWith(resident: existing.resident);
    state = AsyncValue.data(
      current.map((a) => a.id == apartmentId ? merged : a).toList(),
    );
  }

  /// Tur 5 / §3.1 — Daireden sakini çıkarır. Hesap silinmez, sadece
  /// `resident` ilişkisi kopar; aidat geçmişi korunur. Hata olursa
  /// rethrow — UI snackbar gösterir, liste state'i bozulmaz.
  Future<void> removeResidentFromApartment(String apartmentId) async {
    final updated = await _repository.removeResident(
      buildingId: buildingId,
      apartmentId: apartmentId,
    );
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((a) => a.id == apartmentId ? updated : a).toList(),
    );
  }
}

final apartmentsStoreProvider = StateNotifierProvider.family<ApartmentsNotifier,
    AsyncValue<List<ApartmentEntity>>, String>(
  (ref, buildingId) => ApartmentsNotifier(
    ref.watch(apartmentRepositoryProvider),
    buildingId,
  ),
);

final apartmentCountProvider = Provider.family<int, String>((ref, buildingId) {
  return ref.watch(apartmentsStoreProvider(buildingId)).value?.length ?? 0;
});

final occupiedCountProvider = Provider.family<int, String>((ref, buildingId) {
  final apartments =
      ref.watch(apartmentsStoreProvider(buildingId)).value ?? [];
  return apartments.where((a) => a.isOccupied).length;
});

final paidCountProvider = Provider.family<int, String>((ref, buildingId) {
  final apartments =
      ref.watch(apartmentsStoreProvider(buildingId)).value ?? [];
  return apartments
      .where((a) => a.paymentStatus == PaymentStatus.paid)
      .length;
});

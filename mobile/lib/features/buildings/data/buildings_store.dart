import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../domain/entities/building_entity.dart';
import 'datasources/building_remote_datasource.dart';
import 'repositories/building_repository.dart';
import 'repositories/building_repository_impl.dart';

final buildingRemoteDataSourceProvider = Provider<BuildingRemoteDataSource>((ref) {
  return BuildingRemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});

final buildingRepositoryProvider = Provider<BuildingRepository>((ref) {
  return BuildingRepositoryImpl(
    remoteDataSource: ref.watch(buildingRemoteDataSourceProvider),
  );
});

class BuildingsNotifier
    extends StateNotifier<AsyncValue<List<BuildingEntity>>> {
  final BuildingRepository _repository;

  /// Submit anında butona art arda basılırsa (50+ kullanıcı için yaygın)
  /// aynı bina N kez oluşturulmasın diye in-flight guard. UI tarafında
  /// da buton disable ediliyor; bu defansif katman.
  bool _isCreating = false;

  BuildingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBuildings();
  }

  Future<void> loadBuildings() async {
    state = const AsyncValue.loading();
    try {
      final buildings = await _repository.fetchBuildings();
      state = AsyncValue.data(buildings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// PATCH aidat tutarı / gün sonrası vb.: `AsyncValue.loading` atlamadan
  /// bina listesini sunucudan yeniler. Böylece Binalar sekmesindeki
  /// `dueAmount` rozeti bayat kalmaz.
  Future<void> refreshBuildings() async {
    try {
      final buildings = await _repository.fetchBuildings();
      state = AsyncValue.data(buildings);
    } catch (_) {
      // Mevcut listeyi koru; aidat ekranında işlem zaten tamamlandı.
    }
  }

  Future<String?> addBuilding({
    required String name,
    required String address,
    required String city,
    int? totalFloors,
    int? apartmentsPerFloor,
    double? dueAmount,
    int? dueDay,
    String? currency,
  }) async {
    if (_isCreating) return null;
    _isCreating = true;
    try {
      final building = await _repository.createBuilding(
        name: name,
        address: address,
        city: city,
        totalFloors: totalFloors,
        apartmentsPerFloor: apartmentsPerFloor,
        dueAmount: dueAmount,
        dueDay: dueDay,
        currency: currency,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([...current, building]);
      return building.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    } finally {
      _isCreating = false;
    }
  }

  /// Hata UI tarafında ele alınmalı; state'i bozarsak (AsyncValue.error)
  /// kullanıcı bina listesini tamamen kaybeder. Bu yüzden hata olursa
  /// rethrow ediyoruz, başarı durumunda listeyi yeniden yazıyoruz.
  Future<void> removeBuilding(String buildingId) async {
    await _repository.deleteBuilding(buildingId);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((b) => b.id != buildingId).toList(),
    );
  }

  /// Belge §5: PUT /buildings/:id body `name?`, `address?`, `city?`.
  /// Hata olursa state'i bozmadan rethrow edilir; UI snackbar gösterir.
  Future<void> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
  }) async {
    final updated = await _repository.updateBuilding(
      id: id,
      name: name,
      address: address,
      city: city,
    );
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((b) => b.id == id ? updated : b).toList(),
    );
  }
}

final buildingsStoreProvider = StateNotifierProvider<BuildingsNotifier,
    AsyncValue<List<BuildingEntity>>>(
  (ref) => BuildingsNotifier(ref.watch(buildingRepositoryProvider)),
);

final buildingsCountProvider = Provider<int>((ref) {
  return ref.watch(buildingsStoreProvider).value?.length ?? 0;
});

final totalBuildingsDuesProvider = Provider<double>((ref) {
  final buildings = ref.watch(buildingsStoreProvider).value ?? [];
  return buildings.fold<double>(0, (sum, b) => sum + b.collectedDues);
});

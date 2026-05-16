import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../buildings/data/buildings_store.dart';
import '../../data/datasources/dues_remote_datasource.dart';
import '../../data/repositories/dues_repository_impl.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/repositories/dues_repository.dart';

final duesRemoteDataSourceProvider = Provider<DuesRemoteDataSource>((ref) {
  return DuesRemoteDataSourceImpl(
    dioClient: ref.watch(dioClientProvider),
  );
});

final duesRepositoryProvider = Provider<DuesRepository>((ref) {
  return DuesRepositoryImpl(
    remoteDataSource: ref.watch(duesRemoteDataSourceProvider),
  );
});

class DuesState {
  final bool isLoading;
  final List<DueEntity> dues;
  final String? error;

  const DuesState({
    this.isLoading = false,
    this.dues = const [],
    this.error,
  });

  DuesState copyWith({
    bool? isLoading,
    List<DueEntity>? dues,
    String? error,
    bool clearError = false,
  }) {
    return DuesState(
      isLoading: isLoading ?? this.isLoading,
      dues: dues ?? this.dues,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DuesNotifier extends StateNotifier<DuesState> {
  final DuesRepository _repository;

  /// Submit edilen async işlemlerin (status update / due-amount update) art
  /// arda tetiklenmesini engelleyen bayraklar. UI da butonu disable ediyor;
  /// bu defansif katman.
  bool _isUpdatingStatus = false;
  bool _isUpdatingDueAmount = false;

  /// `updateBuildingDueAmount` sonrası `affectCurrent=true` ise listeyi
  /// tazelemek için son sorgu filtrelerini saklarız (kullanıcının seçili
  /// ay/yıl/status filtresi kaybolmasın diye aynı setle reload).
  int? _lastMonth;
  int? _lastYear;
  DueStatus? _lastStatus;
  String? _loadedBuildingId;

  DuesNotifier(this._repository) : super(const DuesState());

  Future<void> loadBuildingDues(
    String buildingId, {
    int? month,
    int? year,
    DueStatus? status,
  }) async {
    final buildingChanged =
        _loadedBuildingId != null && _loadedBuildingId != buildingId;
    _loadedBuildingId = buildingId;
    _lastMonth = month;
    _lastYear = year;
    _lastStatus = status;
    // Aynı bina + filtre yenilemede önceki listeyi tutup üstte ince yükleme
    // göstermek için veriyi silmiyoruz; bina değişince yanlış veri
    // göstermemek için listeyi temizleriz.
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      dues: buildingChanged ? const [] : state.dues,
    );
    try {
      final dues = await _repository.getBuildingDues(
        buildingId,
        month: month,
        year: year,
        status: status,
      );
      state = state.copyWith(isLoading: false, dues: dues);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Aidatlar yüklenemedi');
    }
  }

  Future<void> loadMyDues({
    int? month,
    int? year,
    DueStatus? status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dues = await _repository.getMyDues(
        month: month,
        year: year,
        status: status,
      );
      state = state.copyWith(isLoading: false, dues: dues);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: 'Aidat geçmişi yüklenemedi');
    }
  }

  Future<void> updateStatus({
    required String buildingId,
    required String dueId,
    required DueStatus status,
  }) async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    state = state.copyWith(clearError: true);
    try {
      await _repository.updateDueStatus(
        buildingId: buildingId,
        dueId: dueId,
        status: status,
      );
      final dues = await _repository.getBuildingDues(
        buildingId,
        month: _lastMonth,
        year: _lastYear,
        status: _lastStatus,
      );
      state = state.copyWith(dues: dues);
    } catch (e) {
      state = state.copyWith(error: 'Aidat durumu güncellenemedi');
    } finally {
      _isUpdatingStatus = false;
    }
  }

  Future<bool> updateBuildingDueAmount({
    required String buildingId,
    required double dueAmount,
    int? dueDay,
    String? currency,
    bool affectCurrent = false,
  }) async {
    if (_isUpdatingDueAmount) return false;
    _isUpdatingDueAmount = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.updateBuildingDueAmount(
        buildingId: buildingId,
        dueAmount: dueAmount,
        dueDay: dueDay,
        currency: currency,
        affectCurrent: affectCurrent,
      );
      // affectCurrent false olsa bile sunucu tutar / gün günceller; liste
      // her zaman aynı filtreyle yenilenir (UI bayat kalmasın).
      final dues = await _repository.getBuildingDues(
        buildingId,
        month: _lastMonth,
        year: _lastYear,
        status: _lastStatus,
      );
      state = state.copyWith(isLoading: false, dues: dues);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Aidat tutarı güncellenemedi',
      );
      return false;
    } finally {
      _isUpdatingDueAmount = false;
    }
  }
}

final duesNotifierProvider = StateNotifierProvider<DuesNotifier, DuesState>(
  (ref) => DuesNotifier(ref.watch(duesRepositoryProvider)),
);

/// Manager dashboard hero card için kullanılan tüm binaların dues toplamı.
/// `Map<buildingId, List<DueEntity>>` döner; bina başına filtreleme için
/// alttaki [buildingCollectionRate] / [buildingOverdueCount] helper'ları
/// kullanılır.
///
/// Backend `Building` response'unda `collectedDues` döndürmediği için
/// `BuildingEntity.collectionRate` getter'ı her zaman 0 verirdi. Bu
/// provider gerçek hesaplama için dues listesinden faydalanır.
///
/// `buildingsStoreProvider` değişince otomatik yeniden hesaplanır
/// (yeni bina eklenince ya da silinince provider tetiklenir).
final allBuildingsDuesProvider =
    FutureProvider<Map<String, List<DueEntity>>>((ref) async {
  final buildingsAsync = ref.watch(buildingsStoreProvider);
  final buildings = buildingsAsync.value ?? const [];
  if (buildings.isEmpty) return const {};
  final repo = ref.watch(duesRepositoryProvider);
  // Paralel çek; bir bina yüklenmese bile diğerlerinin durmaması için
  // her future'ı ayrı try/catch içinde sarıyoruz.
  final results = await Future.wait(buildings.map((b) async {
    try {
      final dues = await repo.getBuildingDues(b.id);
      return MapEntry(b.id, dues);
    } catch (_) {
      return MapEntry(b.id, const <DueEntity>[]);
    }
  }));
  return Map.fromEntries(results);
});

/// Tüm binalardaki ödeme oranı: `PAID dues / total dues × 100`.
/// dues boşsa 0 döner. Hero card'daki "%" rozetinde kullanılır.
double globalCollectionRate(Map<String, List<DueEntity>> map) {
  final all = map.values.expand((l) => l).toList(growable: false);
  if (all.isEmpty) return 0;
  final paid = all.where((d) => d.status == DueStatus.paid).length;
  return (paid / all.length) * 100;
}

/// Tüm binalardaki gecikmiş aidat sayısı.
int globalOverdueCount(Map<String, List<DueEntity>> map) {
  return map.values
      .expand((l) => l)
      .where((d) => d.status == DueStatus.overdue)
      .length;
}

/// Tek bir binanın ödeme oranı. Bina kartlarında "Tahsilat" sütununda
/// kullanılır. Bina için dues yoksa 0 döner.
double buildingCollectionRate(
    Map<String, List<DueEntity>> map, String buildingId) {
  final dues = map[buildingId] ?? const [];
  if (dues.isEmpty) return 0;
  final paid = dues.where((d) => d.status == DueStatus.paid).length;
  return (paid / dues.length) * 100;
}

/// Tek bir binanın gecikmiş aidat sayısı.
int buildingOverdueCount(
    Map<String, List<DueEntity>> map, String buildingId) {
  return (map[buildingId] ?? const [])
      .where((d) => d.status == DueStatus.overdue)
      .length;
}

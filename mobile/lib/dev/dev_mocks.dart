/// Sunucu yokken (offline / dev preview) UI'ı test edebilmek için kullanılan
/// in-memory mock repository'ler. Sadece `lib/main_dev.dart` ile çalışan
/// dev preview build'inde inject edilir; production main.dart bu dosyayı
/// import etmez.
///
/// Belge §5/§6 sözleşmesini yansıtan minimal davranış:
///   - createBuilding/createApartment yeni id ile listeye ekler
///   - update kısmi alan günceller
///   - delete listeden çıkarır (FK simülasyonu için
///     [MockBuildingRepository.deleteBuilding] içinde "daire varsa hata" var)
///
/// Hızlı tepki için 200ms suni gecikme eklenmiştir; loading state'leri
/// gerçekçi görünsün diye.
library;

import '../core/network/api_exception.dart';
import '../features/apartments/data/repositories/apartment_repository.dart';
import '../features/apartments/domain/entities/apartment_entity.dart';
import '../features/apartments/domain/entities/resident_info.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart'
    show AuthRepository;
import '../features/auth/domain/entities/user_entity.dart';
import '../features/buildings/data/repositories/building_repository.dart';
import '../features/buildings/domain/entities/building_entity.dart';
import '../features/dues/domain/entities/due_entity.dart';
import '../features/dues/domain/repositories/dues_repository.dart';
import '../features/profile/data/repositories/profile_repository.dart';

/// Tek bir tetikleyici noktada her mock'u sıfırlamak için.
class MockState {
  static int _counter = 0;
  static String nextId(String prefix) {
    _counter++;
    return '${prefix}_$_counter';
  }
}

const _delay = Duration(milliseconds: 200);

class MockAuthRepository implements AuthRepository {
  static final UserEntity _devManager = UserEntity(
    id: 'dev_manager_1',
    email: 'dev@aidatpanel.com',
    name: 'Dev Yönetici',
    phone: '+905551112233',
    role: UserRole.manager,
    language: 'tr',
  );

  @override
  Future<UserEntity?> restoreSession() async {
    await Future.delayed(_delay);
    return _devManager;
  }

  @override
  Future<UserEntity> login(String identifier, String password) async {
    await Future.delayed(_delay);
    return _devManager;
  }

  @override
  Future<void> register(
      String email, String password, String name, String? phone) async {
    await Future.delayed(_delay);
  }

  @override
  Future<UserEntity> join(String inviteCode, String email, String password,
      String name, String? phone) async {
    await Future.delayed(_delay);
    return _devManager;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(_delay);
  }

  /// Tur 5 §10/6 — Backend her zaman 200 döner; mock da aynı davranışı
  /// gösterir, hiçbir kontrol yapmaz.
  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(_delay);
  }

  /// Mock kabul kodu: `ABCDEF` (her şey büyük). Diğer 6 karakter kodlar
  /// 400 ile reddedilir (UI insanlaştırması test edilebilsin diye).
  @override
  Future<void> resetPassword(String token, String password) async {
    await Future.delayed(_delay);
    if (token.toUpperCase() != 'ABCDEF') {
      throw ApiException(
        message: 'Invalid or expired token',
        statusCode: 400,
      );
    }
  }

  @override
  Future<UserEntity?> getStoredUser() async => _devManager;
}

/// Tur 5 §10/4-5 — `PUT /me/password` ve `DELETE /me` mock implementasyonu.
class MockProfileRepository implements ProfileRepository {
  /// Dev mock şifresi: `Eski123.` Bunun dışında ne girilirse 401 döner.
  String _currentPassword = 'Eski123.';

  /// Hesabı kapatma 1. denemede başarılı. Manager 409 davranışını test
  /// etmek isterseniz `forceManagerConflict` true yapın.
  bool forceManagerConflict = false;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(_delay);
    if (currentPassword != _currentPassword) {
      throw ApiException(
        message: 'Current password is incorrect',
        statusCode: 401,
      );
    }
    _currentPassword = newPassword;
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(_delay);
    if (forceManagerConflict) {
      throw ApiException(
        message:
            'You still manage one or more buildings. Delete or transfer them first.',
        statusCode: 409,
      );
    }
  }
}

class MockBuildingRepository implements BuildingRepository {
  /// Yetkili olarak ApartmentRepository'yi de görüp deleteBuilding sırasında
  /// FK kontrolü yapabilmek için referans tutuyoruz.
  final MockApartmentRepository apartments;

  final List<BuildingEntity> _buildings = [
    const BuildingEntity(
      id: 'b1',
      name: 'Çamlık Apartmanı',
      address: 'Atatürk Cad. No:42',
      city: 'İstanbul',
      totalApartments: 12,
      occupiedApartments: 0,
      totalMonthlyDues: 7200,
      collectedDues: 0,
      dueAmount: 600,
      dueDay: 5,
      currency: 'TRY',
    ),
    const BuildingEntity(
      id: 'b2',
      name: 'Yıldız Sitesi A Blok',
      address: 'Bağdat Cad. No:117',
      city: 'İstanbul',
      totalApartments: 8,
      occupiedApartments: 0,
      totalMonthlyDues: 6000,
      collectedDues: 0,
      dueAmount: 750,
      dueDay: 1,
      currency: 'TRY',
    ),
  ];

  MockBuildingRepository(this.apartments);

  @override
  Future<List<BuildingEntity>> fetchBuildings() async {
    await Future.delayed(_delay);
    return List.unmodifiable(_buildings);
  }

  /// Backend `buildingService.createBuildingService` davranışını simüle
  /// eder: tek "transaction" içinde bina + (totalFloors × apartmentsPerFloor)
  /// daire (1A, 1B, 2A, 2B …) seed eder. Mobile artık ayrı bir fallback
  /// seed loop'u çalıştırmıyor (Tur 5 §10/2).
  @override
  Future<BuildingEntity> createBuilding({
    required String name,
    required String address,
    required String city,
    int? totalFloors,
    int? apartmentsPerFloor,
    double? dueAmount,
    int? dueDay,
    String? currency,
  }) async {
    await Future.delayed(_delay);
    final floors = totalFloors ?? 0;
    final perFloor = apartmentsPerFloor ?? 0;
    final total = floors * perFloor;
    final id = MockState.nextId('b');
    final building = BuildingEntity(
      id: id,
      name: name,
      address: address,
      city: city,
      totalApartments: total,
      occupiedApartments: 0,
      totalMonthlyDues: (dueAmount ?? 0) * total,
      collectedDues: 0,
      dueAmount: dueAmount,
      dueDay: dueDay,
      currency: currency ?? 'TRY',
    );
    _buildings.add(building);
    apartments._seedForBuilding(
      buildingId: id,
      totalFloors: floors,
      apartmentsPerFloor: perFloor,
      monthlyDues: dueAmount ?? 0,
    );
    return building;
  }

  @override
  Future<BuildingEntity> updateBuilding({
    required String id,
    String? name,
    String? address,
    String? city,
  }) async {
    await Future.delayed(_delay);
    final idx = _buildings.indexWhere((b) => b.id == id);
    if (idx == -1) {
      throw ApiException(message: 'Bina bulunamadı', statusCode: 404);
    }
    final updated = _buildings[idx].copyWith(
      name: name,
      address: address,
      city: city,
    );
    _buildings[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteBuilding(String id) async {
    await Future.delayed(_delay);
    final hasApartments =
        (apartments._byBuilding[id]?.isNotEmpty ?? false);
    if (hasApartments) {
      // Belge §5: bina sakin/aidat varsa silinemez. UI bu hatayı insanlaştırır.
      throw ApiException(
        message: 'Cannot delete building: still has apartments',
        statusCode: 400,
      );
    }
    _buildings.removeWhere((b) => b.id == id);
  }
}

class MockApartmentRepository implements ApartmentRepository {
  /// Bina başına mock daire listesi.
  final Map<String, List<ApartmentEntity>> _byBuilding = {
    'b1': [
      const ApartmentEntity(
        id: 'a1_1',
        buildingId: 'b1',
        apartmentNumber: '1A',
        floor: 1,
        resident: ResidentInfo(
          id: 'r1',
          name: 'Ayşe Yılmaz',
          email: 'ayse@example.com',
          phone: '+905551112201',
          role: 'RESIDENT',
        ),
        monthlyDues: 600,
        paymentStatus: PaymentStatus.paid,
      ),
      const ApartmentEntity(
        id: 'a1_2',
        buildingId: 'b1',
        apartmentNumber: '1B',
        floor: 1,
        resident: ResidentInfo(
          id: 'r2',
          name: 'Mehmet Demir',
          email: 'mehmet@example.com',
          role: 'RESIDENT',
        ),
        monthlyDues: 600,
        paymentStatus: PaymentStatus.pending,
      ),
      ApartmentEntity(
        id: 'a1_3',
        buildingId: 'b1',
        apartmentNumber: '2A',
        floor: 2,
        monthlyDues: 600,
        paymentStatus: PaymentStatus.pending,
      ),
      ApartmentEntity(
        id: 'a1_4',
        buildingId: 'b1',
        apartmentNumber: '2B',
        floor: 2,
        monthlyDues: 600,
        paymentStatus: PaymentStatus.pending,
      ),
    ],
    'b2': [
      const ApartmentEntity(
        id: 'a2_1',
        buildingId: 'b2',
        apartmentNumber: '1',
        floor: 1,
        resident: ResidentInfo(
          id: 'r3',
          name: 'Zeynep Kaya',
          email: 'zeynep@example.com',
          phone: '+905551112202',
          role: 'RESIDENT',
        ),
        monthlyDues: 750,
        paymentStatus: PaymentStatus.overdue,
      ),
      ApartmentEntity(
        id: 'a2_2',
        buildingId: 'b2',
        apartmentNumber: '2',
        floor: 2,
        monthlyDues: 750,
        paymentStatus: PaymentStatus.pending,
      ),
    ],
  };

  /// Backend tarafında `createBuildingService` daireleri tek transaction
  /// içinde seed ediyor. Dev preview'de bunu MockBuildingRepository
  /// tetikler — apartmentsPerFloor 26'yı geçerse harf sarsa rolu ile
  /// (A..Z, AA..AZ) backend ile birebir aynı şemayı kullanırız.
  void _seedForBuilding({
    required String buildingId,
    required int totalFloors,
    required int apartmentsPerFloor,
    required double monthlyDues,
  }) {
    if (totalFloors <= 0 || apartmentsPerFloor <= 0) return;
    final list = <ApartmentEntity>[];
    for (var floor = 1; floor <= totalFloors; floor++) {
      for (var unit = 0; unit < apartmentsPerFloor; unit++) {
        final letter = unit < 26
            ? String.fromCharCode(65 + unit)
            : '${String.fromCharCode(65 + (unit ~/ 26) - 1)}${String.fromCharCode(65 + unit % 26)}';
        list.add(ApartmentEntity(
          id: MockState.nextId('a'),
          buildingId: buildingId,
          apartmentNumber: '$floor$letter',
          floor: floor,
          monthlyDues: monthlyDues,
        ));
      }
    }
    _byBuilding[buildingId] = list;
  }

  @override
  Future<List<ApartmentEntity>> fetchApartments(String buildingId) async {
    await Future.delayed(_delay);
    return List.unmodifiable(_byBuilding[buildingId] ?? const []);
  }

  @override
  Future<ApartmentEntity> createApartment({
    required String buildingId,
    required String number,
    int? floor,
  }) async {
    await Future.delayed(_delay);
    final apt = ApartmentEntity(
      id: MockState.nextId('a'),
      buildingId: buildingId,
      apartmentNumber: number,
      floor: floor,
    );
    _byBuilding.update(
      buildingId,
      (list) => [...list, apt],
      ifAbsent: () => [apt],
    );
    return apt;
  }

  @override
  Future<ApartmentEntity> updateApartment({
    required String buildingId,
    required String id,
    String? number,
    int? floor,
  }) async {
    await Future.delayed(_delay);
    final list = _byBuilding[buildingId];
    if (list == null) {
      throw ApiException(message: 'Bina bulunamadı', statusCode: 404);
    }
    final idx = list.indexWhere((a) => a.id == id);
    if (idx == -1) {
      throw ApiException(message: 'Daire bulunamadı', statusCode: 404);
    }
    final updated = list[idx].copyWith(
      apartmentNumber: number,
      floor: floor,
    );
    list[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteApartment({
    required String buildingId,
    required String id,
  }) async {
    await Future.delayed(_delay);
    final list = _byBuilding[buildingId];
    if (list == null) return;
    final apt = list.firstWhere(
      (a) => a.id == id,
      orElse: () => throw ApiException(
        message: 'Daire bulunamadı',
        statusCode: 404,
      ),
    );
    if (apt.resident != null) {
      // Belge §6: sakin atanmış daire silinince FK ihlali (dues vs.) gelebilir.
      // Mock olarak bu davranışı simüle ediyoruz; UI insanlaştırılmış mesaj basar.
      throw ApiException(
        message: 'Cannot delete apartment: resident still assigned',
        statusCode: 400,
      );
    }
    list.removeWhere((a) => a.id == id);
  }

  /// Tur 5 / §3.1 — Sakini daireden çıkarır. Backend
  /// `apartmentService.removeResidentFromApartmentService` davranışını
  /// simüle eder: sakin yoksa 404, varsa `resident: null` set eder ve
  /// güncel apartment'ı döner.
  @override
  Future<ApartmentEntity> removeResident({
    required String buildingId,
    required String apartmentId,
  }) async {
    await Future.delayed(_delay);
    final list = _byBuilding[buildingId];
    if (list == null) {
      throw ApiException(message: 'Bina bulunamadı', statusCode: 404);
    }
    final idx = list.indexWhere((a) => a.id == apartmentId);
    if (idx == -1) {
      throw ApiException(message: 'Daire bulunamadı', statusCode: 404);
    }
    if (list[idx].resident == null) {
      throw ApiException(
        message: 'No resident assigned to this apartment',
        statusCode: 404,
      );
    }
    final updated = list[idx].copyWith(clearResident: true);
    list[idx] = updated;
    return updated;
  }
}

/// Geçmiş 6 ay × bina dairelerinin senaryolu fake aidat üretici.
/// Dashboard `collectionRate`, ay/yıl filtresi, overdue rozeti gibi UI
/// öğelerini gerçekten test edebilmek için karışık statü dağılımı içerir.
class MockDuesRepository implements DuesRepository {
  /// Bina başına in-memory dues listesi. Update senaryolarında bu listede
  /// status değiştirebilmek için final var olarak tutuyoruz.
  late final Map<String, List<DueEntity>> _byBuilding;

  MockDuesRepository() {
    _byBuilding = {
      'b1': _generateB1Dues(),
      'b2': _generateB2Dues(),
    };
  }

  /// Aylık aidat üretici — verilen dairenin son `monthsBack` ay için
  /// statü kalıbına göre due üretir. Statü kalıbı bir liste olarak
  /// gelir; index 0 en yeni ay.
  List<DueEntity> _generateForApartment({
    required String buildingId,
    required String apartmentId,
    required String apartmentNumber,
    required double amount,
    required List<DueStatus> pattern, // index 0 = bu ay (en yeni)
  }) {
    final now = DateTime.now();
    final list = <DueEntity>[];
    for (var i = 0; i < pattern.length; i++) {
      final dt = DateTime(now.year, now.month - i, 1);
      final status = pattern[i];
      // Backend tipik olarak ayın 5'ini due day yapıyor (b1) veya 1'i (b2)
      final dueDay = buildingId == 'b1' ? 5 : 1;
      final dueDate = DateTime(dt.year, dt.month, dueDay);
      final overdueDays =
          status == DueStatus.overdue ? now.difference(dueDate).inDays : 0;
      final paidAt = status == DueStatus.paid
          ? DateTime(dt.year, dt.month, dueDay + 2)
          : null;
      list.add(DueEntity(
        id: '${apartmentId}_${dt.year}_${dt.month}',
        apartmentId: apartmentId,
        apartmentNumber: apartmentNumber,
        amount: amount,
        currency: 'TRY',
        month: dt.month,
        year: dt.year,
        dueDate: dueDate,
        status: status,
        paidAt: paidAt,
        overdueDays: overdueDays > 0 ? overdueDays : 0,
        createdAt: DateTime(dt.year, dt.month, 1),
        updatedAt: paidAt ?? DateTime(dt.year, dt.month, 1),
      ));
    }
    return list;
  }

  /// b1 — Çamlık Apartmanı (4 daire, ₺600/ay)
  /// - 1A (Ayşe — sakinli, düzenli ödeyici): hep PAID
  /// - 1B (Mehmet — sakinli, son 2 ay PENDING): 4 PAID + 2 PENDING
  /// - 2A (boş): hep PENDING
  /// - 2B (boş): hep PENDING
  /// Toplam: 24 due, 10 PAID, 14 PENDING → collection rate ~%41.6
  List<DueEntity> _generateB1Dues() {
    return [
      ..._generateForApartment(
        buildingId: 'b1',
        apartmentId: 'a1_1',
        apartmentNumber: '1A',
        amount: 600,
        pattern: List.filled(6, DueStatus.paid),
      ),
      ..._generateForApartment(
        buildingId: 'b1',
        apartmentId: 'a1_2',
        apartmentNumber: '1B',
        amount: 600,
        pattern: const [
          DueStatus.pending, // bu ay
          DueStatus.pending, // 1 ay önce
          DueStatus.paid,
          DueStatus.paid,
          DueStatus.paid,
          DueStatus.paid,
        ],
      ),
      ..._generateForApartment(
        buildingId: 'b1',
        apartmentId: 'a1_3',
        apartmentNumber: '2A',
        amount: 600,
        pattern: List.filled(6, DueStatus.pending),
      ),
      ..._generateForApartment(
        buildingId: 'b1',
        apartmentId: 'a1_4',
        apartmentNumber: '2B',
        amount: 600,
        pattern: List.filled(6, DueStatus.pending),
      ),
    ];
  }

  /// b2 — Yıldız Sitesi A Blok (2 daire, ₺750/ay)
  /// - 1 (Zeynep — sakinli, son 2 ay OVERDUE): 4 PAID + 2 OVERDUE
  /// - 2 (boş): hep PENDING
  /// Toplam: 12 due, 4 PAID, 2 OVERDUE, 6 PENDING → collection rate ~%33.3
  List<DueEntity> _generateB2Dues() {
    return [
      ..._generateForApartment(
        buildingId: 'b2',
        apartmentId: 'a2_1',
        apartmentNumber: '1',
        amount: 750,
        pattern: const [
          DueStatus.overdue, // bu ay
          DueStatus.overdue, // 1 ay önce
          DueStatus.paid,
          DueStatus.paid,
          DueStatus.paid,
          DueStatus.paid,
        ],
      ),
      ..._generateForApartment(
        buildingId: 'b2',
        apartmentId: 'a2_2',
        apartmentNumber: '2',
        amount: 750,
        pattern: List.filled(6, DueStatus.pending),
      ),
    ];
  }

  /// Tur 5 §10/3 — server-side filtre simulasyonu. Backend
  /// `dueController.getDuesByBuildingController` aynı parametreleri
  /// uyguladığı için mock da burada client-side filtre yapar.
  @override
  Future<List<DueEntity>> getBuildingDues(
    String buildingId, {
    int? month,
    int? year,
    DueStatus? status,
  }) async {
    await Future.delayed(_delay);
    final source = _byBuilding[buildingId] ?? const <DueEntity>[];
    return List.unmodifiable(source.where((d) {
      if (month != null && d.month != month) return false;
      if (year != null && d.year != year) return false;
      if (status != null && d.status != status) return false;
      return true;
    }));
  }

  @override
  Future<List<DueEntity>> getMyDues({
    int? month,
    int? year,
    DueStatus? status,
  }) async {
    // Dev preview otomatik manager girişi yapıyor; sakin akışı test
    // edilmeyeceği için boş döner.
    await Future.delayed(_delay);
    return const [];
  }

  @override
  Future<DueEntity> updateDueStatus({
    required String buildingId,
    required String dueId,
    required DueStatus status,
  }) async {
    await Future.delayed(_delay);
    final list = _byBuilding[buildingId];
    if (list == null) {
      throw ApiException(message: 'Bina bulunamadı', statusCode: 404);
    }
    final idx = list.indexWhere((d) => d.id == dueId);
    if (idx == -1) {
      throw ApiException(message: 'Aidat bulunamadı', statusCode: 404);
    }
    final old = list[idx];
    final now = DateTime.now();
    final updated = DueEntity(
      id: old.id,
      apartmentId: old.apartmentId,
      apartmentNumber: old.apartmentNumber,
      amount: old.amount,
      currency: old.currency,
      month: old.month,
      year: old.year,
      dueDate: old.dueDate,
      status: status,
      paidAt: status == DueStatus.paid ? now : null,
      overdueDays: status == DueStatus.overdue ? old.overdueDays : 0,
      note: old.note,
      createdAt: old.createdAt,
      updatedAt: now,
    );
    list[idx] = updated;
    return updated;
  }

  @override
  Future<void> updateBuildingDueAmount({
    required String buildingId,
    required double dueAmount,
    int? dueDay,
    String? currency,
    bool affectCurrent = false,
  }) async {
    await Future.delayed(_delay);
    if (!affectCurrent) return;
    // Mock: affectCurrent=true iken sadece PENDING aidatların amount'unu
    // güncelle (PAID olanlar dokunulmaz — backend §7'deki davranışı
    // simüle ediyoruz).
    final list = _byBuilding[buildingId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      if (list[i].status == DueStatus.pending) {
        final old = list[i];
        list[i] = DueEntity(
          id: old.id,
          apartmentId: old.apartmentId,
          apartmentNumber: old.apartmentNumber,
          amount: dueAmount,
          currency: currency ?? old.currency,
          month: old.month,
          year: old.year,
          dueDate: old.dueDate,
          status: old.status,
          paidAt: old.paidAt,
          overdueDays: old.overdueDays,
          note: old.note,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    }
  }
}

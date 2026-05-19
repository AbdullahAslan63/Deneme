import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/system_navigator_bridge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/providers/navigation_provider.dart';
import '../../../../shared/widgets/settings_tab.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../buildings/data/buildings_store.dart';
import '../../../buildings/domain/entities/building_entity.dart';
import '../../../buildings/presentation/screens/add_building_screen.dart';
import '../../../buildings/presentation/screens/building_residents_screen.dart';
import '../../../buildings/presentation/screens/invite_code_screen.dart';
import '../../../buildings/presentation/widgets/delete_building_dialog.dart';
import '../../../buildings/presentation/widgets/edit_building_bottom_sheet.dart';
import '../../../dues/domain/entities/due_entity.dart';
import '../../../dues/presentation/providers/dues_provider.dart';
import '../../../dues/presentation/screens/manager_dues_tab.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(managerTabIndexProvider);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      ref.read(managerTabIndexProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsStoreProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Tek geri basışta uygulamayı arka plana at; process yaşamaya devam
        // eder, kullanıcı tekrar açtığında aynı tab'da uyanır.
        await SystemNavigatorBridge.moveAppToBackground();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t.features.buildings.managerPanel),
          centerTitle: true,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHomeTab(buildingsAsync),
            _buildBuildingsTab(buildingsAsync),
            _buildDuesTab(),
            _buildSettingsTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.t.common.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.apartment_outlined),
              selectedIcon: const Icon(Icons.apartment),
              label: context.t.common.buildings,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_outlined),
              selectedIcon: const Icon(Icons.receipt),
              label: context.t.common.dues,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: context.t.common.settings,
            ),
          ],
          selectedIndex: ref.watch(managerTabIndexProvider),
          onDestinationSelected: (index) {
            ref.read(managerTabIndexProvider.notifier).state = index;
            _tabController.animateTo(index);
          },
        ),
      ),
    );
  }

  Widget _buildHomeTab(AsyncValue<List<BuildingEntity>> buildingsAsync) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? context.t.common.user;
    final buildings = buildingsAsync.value ?? const <BuildingEntity>[];
    // Tüm binaların dues'unu paralel çeken provider — collectionRate ve
    // overdueCount'u backend `collectedDues` döndürmediği için buradan
    // hesaplıyoruz (DuesNotifier sadece tek seçili binayı tutuyor).
    final allDuesAsync = ref.watch(allBuildingsDuesProvider);
    final allDues = allDuesAsync.value ?? const <String, List<DueEntity>>{};

    int totalApartments = 0;
    for (final b in buildings) {
      totalApartments += b.totalApartments;
    }
    final collectionRate = globalCollectionRate(allDues);
    final overdueCount = globalOverdueCount(allDues);

    return RefreshIndicator(
      onRefresh: _refreshHomeTab,
      color: AppColors.primary,
      // Boş bina listesinde de pull-to-refresh çalışsın diye
      // physics: AlwaysScrollableScrollPhysics
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSizes.screenBodyScrollPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSummaryCard(
              userName: userName,
              totalApartments: totalApartments,
              collectionRate: collectionRate,
              overdueCount: overdueCount,
            ),
            const SizedBox(height: AppSizes.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t.common.managedBuildings,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingS,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    buildings.length.toString(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingM),
            _BuildingsAsyncSection(
              buildingsAsync: buildingsAsync,
              onRetry: _onRetryBuildings,
              buildList: _buildBuildingCards,
            ),
          ],
        ),
      ),
    );
  }

  /// Pull-to-refresh: bina listesi + tüm binaların dues'u birlikte yenilenir.
  /// Hero card collectionRate / overdueCount allBuildingsDuesProvider'ı
  /// dinlediği için invalidate sonrası otomatik güncellenir.
  Future<void> _refreshHomeTab() async {
    ref.invalidate(allBuildingsDuesProvider);
    await ref.read(buildingsStoreProvider.notifier).loadBuildings();
  }

  Widget _buildBuildingsTab(AsyncValue<List<BuildingEntity>> buildingsAsync) {
    return SingleChildScrollView(
      padding: AppSizes.screenBodyScrollPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSizes.buttonHeightPrimary,
                  child: ElevatedButton.icon(
                    onPressed: _onAddBuildingPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_business),
                    label: Text(context.t.common.addBuilding),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: SizedBox(
                  height: AppSizes.buttonHeightPrimary,
                  child: ElevatedButton.icon(
                    onPressed: _onCreateInviteCodePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(context.t.common.inviteCode),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),
          Text(
            context.t.common.myBuildings,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          _BuildingsAsyncSection(
            buildingsAsync: buildingsAsync,
            onRetry: _onRetryBuildings,
            buildList: (list) => list
                .map((b) => _buildDetailedBuildingCard(b))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  void _onRetryBuildings() {
    ref.read(buildingsStoreProvider.notifier).loadBuildings();
  }

  Widget _buildDetailedBuildingCard(BuildingEntity building) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          onTap: () => _onBuildingTapped(building),
          child: _buildBuildingCardContent(building),
        ),
      ),
    );
  }

  Widget _buildBuildingCardContent(BuildingEntity building) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primaryLight.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: AppTypography.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 4)),
                          TextSpan(text: building.displayAddress),
                        ],
                      ),
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildBuildingActionsMenu(building),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.primary.withValues(alpha: 0.14)),
        Padding(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.door_front_door_outlined,
                  label: context.t.common.apartment,
                  value:
                      '${building.occupiedApartments}/${building.totalApartments}',
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
              Expanded(
                child: Builder(
                  builder: (_) {
                    final allDues =
                        ref.watch(allBuildingsDuesProvider).value ?? const {};
                    final rate = buildingCollectionRate(allDues, building.id);
                    return _buildStatItem(
                      icon: Icons.trending_up,
                      label: context.t.common.collection,
                      value: '%${rate.toStringAsFixed(0)}',
                      color: AppColors.success,
                    );
                  },
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.payments_outlined,
                  label: context.t.common.monthlyDues,
                  value: '₺${building.totalMonthlyDues.toStringAsFixed(0)}',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        if (building.dueAmount != null && building.dueAmount! > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSizes.spacingM,
              0,
              AppSizes.spacingM,
              AppSizes.spacingM,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingM,
              vertical: AppSizes.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSizes.spacingS),
                Text(
                  context.t.common.monthlyDuesPerApartment,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '₺${building.dueAmount!.toStringAsFixed(0)}',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Bina kartının sağ üstünde yer alan üç-nokta menüsü.
  /// 50+ yaş kuralı: 48x48dp dokunma alanı için PopupMenuButton'ın
  /// padding'ine ek olarak iconSize > 24 tutuyoruz.
  Widget _buildBuildingActionsMenu(BuildingEntity building) {
    return PopupMenuButton<_BuildingAction>(
      tooltip: '',
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 28,
      ),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _BuildingAction.edit:
            _onEditBuilding(building);
            break;
          case _BuildingAction.delete:
            _onDeleteBuilding(building);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _BuildingAction.edit,
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.spacingS),
              Text(
                context.t.common.editBuilding,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _BuildingAction.delete,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 22,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSizes.spacingS),
              Text(
                context.t.common.deleteBuilding,
                style: AppTypography.body1.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onEditBuilding(BuildingEntity building) {
    EditBuildingBottomSheet.show(context, building: building);
  }

  Future<void> _onDeleteBuilding(BuildingEntity building) async {
    await DeleteBuildingDialog.show(context, building: building);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _onAddBuildingPressed() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AddBuildingScreen()),
    );
  }

  void _onCreateInviteCodePressed() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => InviteCodeScreen(
          buildings: ref.read(buildingsStoreProvider).value ?? [],
        ),
      ),
    );
  }

  void _onBuildingTapped(BuildingEntity building) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BuildingResidentsScreen(building: building),
      ),
    );
  }

  Widget _buildDuesTab() {
    return const ManagerDuesTab();
  }

  Widget _buildSettingsTab() {
    return const SettingsTab();
  }

  List<Widget> _buildBuildingCards(List<BuildingEntity> buildings) {
    return buildings
        .map(
          (building) => Container(
            margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                onTap: () => _onBuildingTapped(building),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.18),
                              AppColors.primaryLight.withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              building.name,
                              style: AppTypography.h4.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const WidgetSpan(child: SizedBox(width: 4)),
                                  TextSpan(text: building.displayAddress),
                                ],
                              ),
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingS),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _BuildingsAsyncSection extends StatelessWidget {
  final AsyncValue<List<BuildingEntity>> buildingsAsync;
  final VoidCallback onRetry;
  final List<Widget> Function(List<BuildingEntity>) buildList;

  const _BuildingsAsyncSection({
    required this.buildingsAsync,
    required this.onRetry,
    required this.buildList,
  });

  @override
  Widget build(BuildContext context) {
    return buildingsAsync.when(
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buildList(list),
      ),
      // Veri varken arka planda yenileniyor (refresh) → eski listeyi göster.
      // Sadece ilk yüklemede (data null iken) loader çıkar.
      loading: () {
        final cached = buildingsAsync.value;
        if (cached != null && cached.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildList(cached),
          );
        }
        return const _BuildingsLoadingPlaceholder();
      },
      error: (err, _) => _BuildingsErrorPlaceholder(
        message: err is Exception ? err.toString() : '$err',
        onRetry: onRetry,
      ),
    );
  }
}

class _BuildingsLoadingPlaceholder extends StatelessWidget {
  const _BuildingsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.body2.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    // Tam genişlikte bir alan açıp spinner + yazıyı hem yatay hem dikey
    // olarak Center ile ortalıyoruz. Yükseklik ekrana göre dinamik:
    // hero card ve başlığın altında kalan boşluğun ortasına denk gelsin.
    final placeholderHeight = MediaQuery.of(context).size.height * 0.32;
    return SizedBox(
      width: double.infinity,
      height: placeholderHeight,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            Text(context.t.common.loadingBuildings, style: textStyle),
          ],
        ),
      ),
    );
  }
}

class _BuildingsErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BuildingsErrorPlaceholder({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacingM,
        AppSizes.spacingL,
        AppSizes.spacingM,
        AppSizes.spacingL,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 28),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Text(
                  context.t.common.loadFailed,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            message,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.spacingM),
          SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(context.t.common.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  final String userName;
  final int totalApartments;
  final double collectionRate;
  final int overdueCount;

  const _HeroSummaryCard({
    required this.userName,
    required this.totalApartments,
    required this.collectionRate,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.waving_hand_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.common.welcome,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      userName,
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spacingM),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricItem(
                  icon: Icons.apartment_outlined,
                  value: totalApartments.toString(),
                  label: context.t.common.totalApartments,
                  tint: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: _MetricItem(
                  icon: Icons.trending_up,
                  value: '%${collectionRate.toStringAsFixed(0)}',
                  label: context.t.common.collection,
                  tint: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: _MetricItem(
                  icon: Icons.warning_amber_rounded,
                  value: overdueCount.toString(),
                  label: context.t.common.overdueStatus,
                  tint: overdueCount > 0
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _BuildingAction { edit, delete }

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.14), tint.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tint.withValues(alpha: 0.22)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: tint, size: 16),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            value,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

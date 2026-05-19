import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../../buildings/data/buildings_store.dart';
import '../../../buildings/domain/entities/building_entity.dart';
import '../../domain/entities/due_entity.dart';
import '../providers/dues_provider.dart';

class ManagerDuesTab extends ConsumerStatefulWidget {
  const ManagerDuesTab({super.key});

  @override
  ConsumerState<ManagerDuesTab> createState() => _ManagerDuesTabState();
}

class _ManagerDuesTabState extends ConsumerState<ManagerDuesTab> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDayController = TextEditingController();

  String? _selectedBuildingId;
  DueStatus? _statusFilter;
  // Ay/Yıl filtresi — null = "Tümü". Default: bu ay & bu yıl, böylece
  // ekran ilk açıldığında kullanıcı sadece güncel dönemi görür.
  int? _monthFilter = DateTime.now().month;
  int? _yearFilter = DateTime.now().year;
  bool _affectCurrent = false;
  bool _initialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildings = ref.watch(buildingsStoreProvider).value ?? [];
    final duesState = ref.watch(duesNotifierProvider);

    _tryInitialize(buildings);

    final dues = duesState.dues;
    final isLoading = duesState.isLoading;

    return RefreshIndicator(
      onRefresh: _reloadDues,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.dashboardScreenPaddingHorizontal,
              AppSizes.spacingL,
              AppSizes.dashboardScreenPaddingHorizontal,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFilters(context, buildings, dues, isLoading),
                const SizedBox(height: AppSizes.spacingM),
                _buildDueAmountCard(context, buildings, isLoading),
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  context.t.common.buildingDues,
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.spacingM),
                if (isLoading && dues.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(minHeight: 3),
                    ),
                  ),
              ]),
            ),
          ),
          if (isLoading && dues.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dues.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.dashboardScreenPaddingHorizontal,
                0,
                AppSizes.dashboardScreenPaddingHorizontal,
                AppSizes.spacingL,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildEmptyState(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.dashboardScreenPaddingHorizontal,
                0,
                AppSizes.dashboardScreenPaddingHorizontal,
                AppSizes.spacingL,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => KeyedSubtree(
                    key: ValueKey<String>(dues[index].id),
                    child: _buildDueCard(context, dues[index]),
                  ),
                  childCount: dues.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _tryInitialize(List<BuildingEntity> buildings) {
    if (_initialized || buildings.isEmpty) return;
    _initialized = true;
    _selectedBuildingId = buildings.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedBuildingId == null) return;
      _reloadDues();
    });
  }

  /// Tur 5 §10/3 — Filtreler değişince veya bina seçimi değişince çağrılır.
  /// Notifier'a aktif filtreleri pas eder; sunucu zaten filtrelenmiş liste
  /// döner.
  Future<void> _reloadDues() async {
    final buildingId = _selectedBuildingId;
    if (buildingId == null) return;
    await ref.read(duesNotifierProvider.notifier).loadBuildingDues(
          buildingId,
          month: _monthFilter,
          year: _yearFilter,
          status: _statusFilter,
        );
  }

  void _invalidateDashboardDuesHero() {
    ref.invalidate(allBuildingsDuesProvider);
  }

  Widget _buildFilters(
    BuildContext context,
    List<BuildingEntity> buildings,
    List<DueEntity> dues,
    bool isLoading,
  ) {
    // Yıl listesi: bu yıl + son 4 yıl (her zaman 5 yıl gösterilir) +
    // dues içindeki distinct year (filtre uygulanmamışken eski yılları da
    // görebilelim diye). Server-side filtreleme olduğu için sunucudan
    // gelen küçük sete dayanmıyoruz; aksi halde "geçen yıl" filtresi
    // seçilmişken dropdown'da sadece o yıl görünüp kullanıcı geri dönemez.
    final currentYear = DateTime.now().year;
    final yearSet = <int>{
      for (var i = 0; i < 5; i++) currentYear - i,
      ...dues.map((d) => d.year),
    };
    final years = yearSet.toList()..sort((a, b) => b.compareTo(a));
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t.common.buildingDues,
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingM),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>('dues_building_${_selectedBuildingId ?? 'none'}'),
            initialValue: _selectedBuildingId,
            isExpanded: true,
            menuMaxHeight: 240,
            items: buildings
                .map(
                  (building) => DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(
                      building.name,
                      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: isLoading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _selectedBuildingId = value);
                    _reloadDues();
                  },
            decoration: InputDecoration(
              labelText: context.t.common.buildings,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          DropdownButtonFormField<DueStatus?>(
            key: ValueKey<String>('dues_status_${_statusFilter?.name ?? 'all'}'),
            initialValue: _statusFilter,
            isExpanded: true,
            menuMaxHeight: 240,
            items: [
              DropdownMenuItem<DueStatus?>(
                value: null,
                child: Text(context.t.common.all),
              ),
              DropdownMenuItem<DueStatus?>(
                value: DueStatus.pending,
                child: Text(context.t.common.pendingStatus),
              ),
              DropdownMenuItem<DueStatus?>(
                value: DueStatus.paid,
                child: Text(context.t.common.paidStatus),
              ),
              DropdownMenuItem<DueStatus?>(
                value: DueStatus.overdue,
                child: Text(context.t.common.overdueStatus),
              ),
              DropdownMenuItem<DueStatus?>(
                value: DueStatus.waived,
                child: Text(context.t.common.waivedStatus),
              ),
            ],
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() => _statusFilter = value);
                    _reloadDues();
                  },
            decoration: InputDecoration(
              labelText: context.t.common.status,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey<String>('dues_month_${_monthFilter ?? 'all'}'),
                  initialValue: _monthFilter,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.t.common.allMonths),
                    ),
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem<int?>(
                        value: m,
                        child: Text(_monthName(context, m)),
                      ),
                  ],
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() => _monthFilter = value);
                          _reloadDues();
                        },
                  decoration: InputDecoration(
                    labelText: context.t.common.month,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey<String>('dues_year_${_yearFilter ?? 'all'}'),
                  initialValue: _yearFilter,
                  isExpanded: true,
                  menuMaxHeight: 240,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.t.common.allYears),
                    ),
                    for (final y in years)
                      DropdownMenuItem<int?>(
                        value: y,
                        child: Text('$y'),
                      ),
                  ],
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() => _yearFilter = value);
                          _reloadDues();
                        },
                  decoration: InputDecoration(
                    labelText: context.t.common.year,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Locale-bağımsız ay adı: i18n monthJanuary…monthDecember anahtarlarını
  /// kullanır. Sayısal index 1..12 arası beklenir.
  String _monthName(BuildContext context, int month) {
    final t = context.t.common;
    switch (month) {
      case 1:
        return t.monthJanuary;
      case 2:
        return t.monthFebruary;
      case 3:
        return t.monthMarch;
      case 4:
        return t.monthApril;
      case 5:
        return t.monthMay;
      case 6:
        return t.monthJune;
      case 7:
        return t.monthJuly;
      case 8:
        return t.monthAugust;
      case 9:
        return t.monthSeptember;
      case 10:
        return t.monthOctober;
      case 11:
        return t.monthNovember;
      case 12:
        return t.monthDecember;
      default:
        return '$month';
    }
  }

  Widget _buildDueAmountCard(
    BuildContext context,
    List<BuildingEntity> buildings,
    bool isLoading,
  ) {
    final currencySymbol = _currencySymbol();
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t.common.updateDueAmount,
            style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            context.t.common.dueUpdateNeedAmountOrDay,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.t.common.amount,
              prefixText: '$currencySymbol ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          TextField(
            controller: _dueDayController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
              const _DueDayInputFormatter(),
            ],
            decoration: InputDecoration(
              labelText: context.t.common.dueDay,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _affectCurrent,
            onChanged:
                isLoading ? null : (value) => setState(() => _affectCurrent = value),
            title: Text(
              context.t.common.affectCurrentDues,
              style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              context.t.common.affectCurrentDuesHint,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          SizedBox(
            height: AppSizes.buttonHeightSecondary,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _updateDueAmount(buildings),
              child: Text(context.t.common.update),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueCard(BuildContext context, DueEntity due) {
    final statusVisual = _statusVisual(context, due.status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
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
              Expanded(
                child: Text(
                  due.apartmentNumber,
                  style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusVisual.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusVisual.label,
                  style: AppTypography.caption.copyWith(
                    color: statusVisual.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<DueStatus>(
                icon: const Icon(Icons.more_vert),
                onSelected: (status) => _updateStatus(due.id, status),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: DueStatus.paid,
                    child: Text(context.t.common.paidStatus),
                  ),
                  PopupMenuItem(
                    value: DueStatus.pending,
                    child: Text(context.t.common.pendingStatus),
                  ),
                  PopupMenuItem(
                    value: DueStatus.overdue,
                    child: Text(context.t.common.overdueStatus),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            '${_currencySymbol()}${due.amount.toStringAsFixed(2)}',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            '${_monthName(context, due.month)} ${due.year}',
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
          ),
          if (due.status == DueStatus.overdue && due.overdueDays > 0) ...[
            const SizedBox(height: AppSizes.spacingXS),
            Text(
              '${due.overdueDays} ${context.t.common.overdueDays}',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingL),
        child: Text(
          context.t.common.noDuesYet,
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Future<void> _updateDueAmount(List<BuildingEntity> buildings) async {
    final buildingId = _selectedBuildingId;
    if (buildingId == null) return;

    final toast = ref.read(toastProvider.notifier);
    void validationToast(String msg) {
      toast.show(msg, type: ToastType.info);
    }

    final amountText =
        _amountController.text.trim().replaceAll(',', '.').replaceAll(' ', '');
    final dueDayText = _dueDayController.text.trim();

    double? parsedAmount;
    if (amountText.isNotEmpty) {
      parsedAmount = double.tryParse(amountText);
      if (parsedAmount == null || parsedAmount <= 0) {
        validationToast(context.t.common.dueAmountInvalidPositive);
        return;
      }
    }

    int? dueDay;
    if (dueDayText.isNotEmpty) {
      final parsed = int.tryParse(dueDayText);
      if (parsed == null || parsed < 1 || parsed > 28) {
        validationToast(context.t.common.dueDayOutOfRange);
        return;
      }
      dueDay = parsed;
    }

    final hasAmount = parsedAmount != null && parsedAmount > 0;
    final hasDueDay = dueDay != null;
    if (!hasAmount && !hasDueDay) {
      validationToast(context.t.common.dueUpdateNeedAmountOrDay);
      return;
    }

    final building = _buildingFor(buildingId, buildings);
    late final double resolvedAmount;
    if (hasAmount) {
      resolvedAmount = parsedAmount;
    } else {
      final stored = building?.dueAmount;
      if (stored == null || stored <= 0) {
        validationToast(context.t.common.dueUpdateNeedStoredAmount);
        return;
      }
      resolvedAmount = stored;
    }

    final ok =
        await ref.read(duesNotifierProvider.notifier).updateBuildingDueAmount(
              buildingId: buildingId,
              dueAmount: resolvedAmount,
              dueDay: dueDay,
              currency: _currencyCode(),
              affectCurrent: _affectCurrent,
            );

    if (!mounted) return;
    toast.show(
      ok
          ? context.t.common.dueAmountUpdated
          : context.t.common.dueAmountUpdateFailed,
      type: ok ? ToastType.success : ToastType.error,
    );
    if (ok) {
      _amountController.clear();
      _dueDayController.clear();
      setState(() => _affectCurrent = false);
      await ref.read(buildingsStoreProvider.notifier).refreshBuildings();
      if (!mounted) return;
      _invalidateDashboardDuesHero();
    }
  }

  BuildingEntity? _buildingFor(String buildingId, List<BuildingEntity> list) {
    for (final b in list) {
      if (b.id == buildingId) return b;
    }
    return null;
  }

  Future<void> _updateStatus(String dueId, DueStatus status) async {
    final buildingId = _selectedBuildingId;
    if (buildingId == null) return;
    await ref.read(duesNotifierProvider.notifier).updateStatus(
          buildingId: buildingId,
          dueId: dueId,
          status: status,
        );
    if (!mounted) return;
    _invalidateDashboardDuesHero();
    ref.read(toastProvider.notifier).show(
          context.t.common.duesUpdated,
          type: ToastType.success,
        );
  }

  String _currencyCode() {
    return LocaleSettings.currentLocale == AppLocale.tr ? 'TRY' : 'USD';
  }

  String _currencySymbol() {
    return LocaleSettings.currentLocale == AppLocale.tr ? '₺' : r'$';
  }
}

class _DueDayInputFormatter extends TextInputFormatter {
  const _DueDayInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    if (!RegExp(r'^\d{1,2}$').hasMatch(t)) return oldValue;
    final n = int.parse(t);
    if (n < 1 || n > 28) return oldValue;
    return newValue;
  }
}

class _StatusVisual {
  final String label;
  final Color fg;
  final Color bg;

  const _StatusVisual({
    required this.label,
    required this.fg,
    required this.bg,
  });
}

_StatusVisual _statusVisual(BuildContext context, DueStatus status) {
  switch (status) {
    case DueStatus.paid:
      return _StatusVisual(
        label: context.t.common.paidStatus,
        fg: AppColors.success,
        bg: AppColors.successBg,
      );
    case DueStatus.overdue:
      return _StatusVisual(
        label: context.t.common.overdueStatus,
        fg: AppColors.error,
        bg: AppColors.errorBg,
      );
    case DueStatus.waived:
      return _StatusVisual(
        label: context.t.common.waivedStatus,
        fg: AppColors.textSecondary,
        bg: AppColors.borderColor,
      );
    case DueStatus.pending:
      return _StatusVisual(
        label: context.t.common.pendingStatus,
        fg: AppColors.warning,
        bg: AppColors.warningBg,
      );
  }
}

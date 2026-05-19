import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../data/buildings_store.dart';
import '../../data/cities_data.dart';

/// Backend `buildingService.createBuildingService` Zod aralıkları (Tur 5 §10/2):
///  - totalFloors: 1..200
///  - apartmentsPerFloor: 1..50
/// Backend bu aralıklar dışında 400 döner; mobile aynı kontrolü öne çekerek
/// kullanıcıya sunucu round-trip beklemeden form içi hata gösterir.
const int _kFloorsMin = 1;
const int _kFloorsMax = 200;
const int _kApartmentsPerFloorMin = 1;
const int _kApartmentsPerFloorMax = 50;

class AddBuildingScreen extends ConsumerStatefulWidget {
  const AddBuildingScreen({super.key});

  @override
  ConsumerState<AddBuildingScreen> createState() => _AddBuildingScreenState();
}

class _AddBuildingScreenState extends ConsumerState<AddBuildingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _floorsController = TextEditingController();
  final _apartmentsPerFloorController = TextEditingController();
  final _monthlyDuesController = TextEditingController();

  String? _selectedCity;
  String? _selectedDistrict;

  /// Submit edildiğinde buton disable'lanır + loading gösterilir.
  /// Aynı submit boyunca PopScope geri tuşunu da bastırır; aksi halde
  /// 50+ kullanıcı kazara back basınca create yarıda kalıp yarım state
  /// oluşur (bina yaratıldı ama daireler seed edilmedi gibi).
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _floorsController.dispose();
    _apartmentsPerFloorController.dispose();
    _monthlyDuesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.t.common.addBuildingNew),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _submitting ? null : () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _submitting,
            child: Form(
              key: _formKey,
              child: Builder(
                builder: (ctx) {
                  final items = _buildFormItems(ctx);
                  return ListView.builder(
                    padding: AppSizes.screenBodyScrollPadding,
                    itemCount: items.length,
                    itemBuilder: (_, i) => items[i],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormItems(BuildContext context) => [
        _buildSectionTitle(context.t.common.basicInfo, Icons.info_outline),
        const SizedBox(height: AppSizes.spacingM),
        _buildTextField(
          controller: _nameController,
          label: context.t.common.buildingName,
          hint: context.t.common.buildingNameHint,
          icon: Icons.apartment,
          required: true,
        ),
        const SizedBox(height: AppSizes.spacingL),
        _buildSectionTitle(context.t.common.location, Icons.location_on_outlined),
        const SizedBox(height: AppSizes.spacingM),
        _buildCityPicker(),
        const SizedBox(height: AppSizes.spacingM),
        _buildDistrictPicker(),
        const SizedBox(height: AppSizes.spacingM),
        _buildTextField(
          controller: _addressController,
          label: context.t.common.streetAddress,
          hint: context.t.common.streetAddressHint,
          icon: Icons.home_outlined,
          required: true,
          maxLines: 2,
        ),
        const SizedBox(height: AppSizes.spacingL),
        _buildSectionTitle(context.t.common.details, Icons.tune),
        const SizedBox(height: AppSizes.spacingM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _floorsController,
                label: context.t.common.floorCount,
                hint: context.t.common.floorCountHint,
                icon: Icons.stairs_outlined,
                required: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _validateRange(
                  v,
                  min: _kFloorsMin,
                  max: _kFloorsMax,
                  rangeError: context.t.common.floorRangeError,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: _buildTextField(
                controller: _apartmentsPerFloorController,
                label: context.t.common.apartmentsPerFloor,
                hint: context.t.common.apartmentsPerFloorHint,
                icon: Icons.door_front_door_outlined,
                required: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _validateRange(
                  v,
                  min: _kApartmentsPerFloorMin,
                  max: _kApartmentsPerFloorMax,
                  rangeError: context.t.common.apartmentsPerFloorRangeError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingM),
        _buildTextField(
          controller: _monthlyDuesController,
          label: context.t.common.monthlyDuesLabel,
          hint: context.t.common.monthlyDuesHint,
          icon: Icons.payments_outlined,
          required: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSizes.spacingXL),
        SizedBox(
          height: AppSizes.buttonHeightPrimary,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _submitting
                  ? context.t.common.loading
                  : context.t.common.createBuilding,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacingM),
        SizedBox(
          height: AppSizes.buttonHeightSecondary,
          child: OutlinedButton(
            onPressed: _submitting ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.borderColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.t.common.cancelBtn,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ];

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? context.t.common.fieldRequired
                  : null
              : null),
    );
  }

  /// Sayısal alan için zorunlu + aralık kontrolü.
  /// Boş ise [fieldRequired], parse edilemez veya aralık dışıysa [rangeError]
  /// döndürür. Backend Zod kuralları ile birebir uyumlu olsun diye
  /// kullanılır.
  String? _validateRange(
    String? value, {
    required int min,
    required int max,
    required String rangeError,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return context.t.common.fieldRequired;
    final n = int.tryParse(raw);
    if (n == null || n < min || n > max) return rangeError;
    return null;
  }

  Widget _buildCityPicker() {
    return _buildDropdownField(
      label: context.t.common.cityRequired,
      value: _selectedCity,
      hint: context.t.common.selectCity,
      icon: Icons.location_city,
      onTap: _showCityPicker,
    );
  }

  Widget _buildDistrictPicker() {
    final hasCity = _selectedCity != null;
    return _buildDropdownField(
      label: context.t.common.districtRequired,
      value: _selectedDistrict,
      hint: hasCity
          ? context.t.common.selectDistrict
          : context.t.common.selectCityFirst,
      icon: Icons.map_outlined,
      enabled: hasCity,
      onTap: hasCity ? _showDistrictPicker : null,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.textDisabled,
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
            ),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : AppColors.background.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
          ),
          child: Text(
            value ?? hint,
            style: AppTypography.body1.copyWith(
              color: value != null
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchablePicker(
        title: context.t.common.selectCityTitle,
        items: sortedCityNames,
        selected: _selectedCity,
        onSelected: (city) {
          setState(() {
            _selectedCity = city;
            _selectedDistrict = null; // şehir değiştiğinde ilçe sıfırlanır
          });
        },
      ),
    );
  }

  void _showDistrictPicker() {
    final districts = turkishCities[_selectedCity] ?? const [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchablePicker(
        title: context.t.common.selectDistrictTitle,
        items: districts,
        selected: _selectedDistrict,
        onSelected: (district) {
          setState(() => _selectedDistrict = district);
        },
      ),
    );
  }

  Future<void> _onSubmit() async {
    // Hızlı dürtüklenme + yarı yarıya işlenmiş submit'e karşı koruma.
    // Notifier seviyesinde de aynı guard var (BuildingsNotifier._isCreating);
    // bu UI guard'ı kullanıcıya görsel feedback sağlar (buton disable + spinner).
    if (_submitting) return;

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      ref
          .read(toastProvider.notifier)
          .show(context.t.common.fillRequiredFields, type: ToastType.error);
      return;
    }
    if (_selectedCity == null || _selectedDistrict == null) {
      ref
          .read(toastProvider.notifier)
          .show(context.t.common.selectCityAndDistrict, type: ToastType.error);
      return;
    }

    // Form validator zaten range + parse kontrolü yaptığı için burada
    // tryParse'lar güvenli (null gelmez). Yine de defansif fallback'le
    // okuyup runtime patlamasını önlüyoruz.
    final floors = int.tryParse(_floorsController.text.trim()) ?? 0;
    final apartmentsPerFloor =
        int.tryParse(_apartmentsPerFloorController.text.trim()) ?? 0;
    final dueAmount =
        double.tryParse(_monthlyDuesController.text.trim()) ?? 0;

    if (dueAmount <= 0) {
      ref.read(toastProvider.notifier).show(
            context.t.common.fillRequiredFields,
            type: ToastType.error,
          );
      return;
    }

    setState(() => _submitting = true);
    try {
      final address =
          '${_addressController.text.trim()}, $_selectedDistrict';

      // Backend `buildingService.createBuildingService` (commit 8cc2152)
      // tek transaction içinde:
      //   1. Building kaydı oluşturur
      //   2. totalFloors × apartmentsPerFloor adet daire (1A, 1B, 2A …) seed eder
      //   3. dueAmount > 0 ise her daire için içinde bulunulan aydan yıl
      //      sonuna kadar PENDING due üretir
      // Bu yüzden mobile artık ekstra "fallback seed loop" çalıştırmaz —
      // eski Tur 1-3 sürümünde yapılan _seedApartmentsIfNeeded kaldırıldı.
      final id = await ref.read(buildingsStoreProvider.notifier).addBuilding(
            name: _nameController.text.trim(),
            address: address,
            city: _selectedCity!,
            totalFloors: floors,
            apartmentsPerFloor: apartmentsPerFloor,
            dueAmount: dueAmount,
            dueDay: 1,
            currency: 'TRY',
          );

      if (!mounted) return;
      if (id == null) {
        ref.read(toastProvider.notifier).show(
              context.t.common.buildingAddFailed,
              type: ToastType.error,
            );
        return;
      }

      ref
          .read(toastProvider.notifier)
          .show(context.t.common.buildingAddedSuccess, type: ToastType.success);
      context.pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// Aranabilir liste seçici (şehir veya ilçe için)
class _SearchablePicker extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _SearchablePicker({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_SearchablePicker> createState() => _SearchablePickerState();
}

class _SearchablePickerState extends State<_SearchablePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dashboardScreenPaddingHorizontal,
              vertical: AppSizes.spacingS,
            ),
            child: Text(
              widget.title,
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.dashboardScreenPaddingHorizontal,
              vertical: AppSizes.spacingS,
            ),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: context.t.common.search,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      context.t.common.noResults,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      final isSelected = item == widget.selected;
                      return ListTile(
                        title: Text(
                          item,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.success)
                            : null,
                        onTap: () {
                          widget.onSelected(item);
                          context.pop();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

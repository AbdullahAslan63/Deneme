import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/strings.g.dart';
import '../../../../shared/widgets/toast_overlay.dart';
import '../../data/buildings_store.dart';
import '../../domain/entities/building_entity.dart';

/// Bina temel bilgilerini (ad/adres/şehir) düzenler.
/// Belge §5: PUT /buildings/:id body `name?`, `address?`, `city?`.
///
/// Kullanım:
/// ```dart
/// await EditBuildingBottomSheet.show(context, building: b);
/// ```
class EditBuildingBottomSheet extends ConsumerStatefulWidget {
  final BuildingEntity building;

  const EditBuildingBottomSheet({super.key, required this.building});

  static Future<void> show(BuildContext context, {required BuildingEntity building}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBuildingBottomSheet(building: building),
    );
  }

  @override
  ConsumerState<EditBuildingBottomSheet> createState() =>
      _EditBuildingBottomSheetState();
}

class _EditBuildingBottomSheetState extends ConsumerState<EditBuildingBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.building.name);
    _addressController = TextEditingController(text: widget.building.address);
    _cityController = TextEditingController(text: widget.building.city);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();

    // Sadece değişen alanları gönder; backend hepsini opsiyonel kabul ediyor
    // ama gereksiz alan göndermek changelog'u kirletir.
    final original = widget.building;
    final payloadName = name == original.name ? null : name;
    final payloadAddress = address == original.address ? null : address;
    final payloadCity = city == original.city ? null : city;

    if (payloadName == null && payloadAddress == null && payloadCity == null) {
      // Hiçbir şey değişmedi → sheet'i kapat, sessiz çık.
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      await ref.read(buildingsStoreProvider.notifier).updateBuilding(
            id: original.id,
            name: payloadName,
            address: payloadAddress,
            city: payloadCity,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(toastProvider.notifier).show(
            context.t.common.buildingUpdated,
            type: ToastType.success,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ref.read(toastProvider.notifier).show(
            e.message.isNotEmpty
                ? e.message
                : context.t.common.buildingUpdateFailed,
            type: ToastType.error,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ref.read(toastProvider.notifier).show(
            context.t.common.buildingUpdateFailed,
            type: ToastType.error,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: AppSizes.screenBodyScrollPadding,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  Text(
                    context.t.common.editBuilding,
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  _field(
                    controller: _nameController,
                    label: context.t.common.buildingNameField,
                    icon: Icons.apartment_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.t.common.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  _field(
                    controller: _addressController,
                    label: context.t.common.buildingAddressField,
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.t.common.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  _field(
                    controller: _cityController,
                    label: context.t.common.buildingCityField,
                    icon: Icons.location_city_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.t.common.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingXL),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightPrimary,
                          child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(
                                color: AppColors.borderColor,
                                width: 1.5,
                              ),
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
                      ),
                      const SizedBox(width: AppSizes.spacingM),
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeightPrimary,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(context.t.common.save),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        ),
      ),
      validator: validator,
    );
  }
}

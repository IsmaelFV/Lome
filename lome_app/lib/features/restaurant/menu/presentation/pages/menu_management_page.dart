import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/services/cloudinary_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../providers/menu_provider.dart';

/// Pagina de gestion del menu.
///
/// Permite gestionar categorias e items del menu con busqueda,
/// filtros y acciones CRUD completas.
class MenuManagementPage extends ConsumerStatefulWidget {
  const MenuManagementPage({super.key});

  @override
  ConsumerState<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends ConsumerState<MenuManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.menuManagementTitle,
        showBack: false,
        useGradient: true,
        actions: [
          TactileWrapper(
            onTap: () => context.push(RoutePaths.menuDesignEditor),
            child: Tooltip(
              message: 'Diseñar carta',
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  PhosphorIcons.palette(PhosphorIconsStyle.duotone),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          TactileWrapper(
            onTap: () => context.push(RoutePaths.menuQr),
            child: Tooltip(
              message: 'QR de la carta',
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  PhosphorIcons.qrCode(PhosphorIconsStyle.duotone),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
          indicatorColor: AppColors.primaryLight,
          tabs: [
            Tab(text: context.l10n.menuCategoriesTab),
            Tab(text: context.l10n.menuItemsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoriesTab(),
          _ItemsTab(searchController: _searchController),
        ],
      ),
      floatingActionButton: TactileWrapper(
        onTap: () {
          if (_tabController.index == 0) {
            _showCategoryDialog(context);
          } else {
            _showItemDialog(context);
          }
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.plus(PhosphorIconsStyle.bold),
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {CategoryEntity? category}) {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final title = category == null
        ? context.l10n.menuCreateCategory
        : context.l10n.menuEditCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => Theme(
        data: AppTheme.light,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingMd,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spacingLg,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.squaresFour(
                              PhosphorIconsStyle.duotone,
                            ),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey900,
                          ),
                        ),
                      ],
                    ),
                    TactileWrapper(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.grey100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          size: 16,
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                LomeTextField(
                  label: context.l10n.menuCategoryName,
                  controller: nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.l10n.menuCategoryNameRequired
                      : null,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                LomeTextField(
                  label: context.l10n.menuCategoryDescription,
                  controller: descCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: LomeButton(
                        label: context.l10n.cancel,
                        variant: LomeButtonVariant.text,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: LomeButton(
                        label: context.l10n.save,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            final crud = ref.read(
                              menuCategoryCrudProvider.notifier,
                            );
                            if (category == null) {
                              await crud.create(
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                              );
                            } else {
                              await crud.updateCategory(
                                category.id,
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showItemDialog(BuildContext context, {MenuItemEntity? item}) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final prepTimeCtrl = TextEditingController(
      text: item?.preparationTime?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId = item?.categoryId;
    bool isFeatured = item?.isFeatured ?? false;
    List<String> selectedAllergens = List.from(item?.allergens ?? []);
    List<String> selectedTags = List.from(item?.tags ?? []);

    // ---- Estado de imagen ----
    Uint8List? imageBytes;
    String? imageUrl = item?.imageUrl;
    bool isUploadingImage = false;

    final categories = ref.read(menuCategoriesProvider);

    final itemTitle = item == null
        ? context.l10n.menuCreateItem
        : context.l10n.menuEditItem;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => Theme(
        data: AppTheme.light,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollCtrl) => Padding(
              padding: EdgeInsets.only(
                left: AppTheme.spacingLg,
                right: AppTheme.spacingLg,
                top: AppTheme.spacingMd,
                bottom:
                    MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spacingLg,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(
                          bottom: AppTheme.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                      ),
                    ),
                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingSm),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: Icon(
                                PhosphorIcons.forkKnife(
                                  PhosphorIconsStyle.duotone,
                                ),
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text(
                              itemTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.grey900,
                              ),
                            ),
                          ],
                        ),
                        TactileWrapper(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.grey100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.x(PhosphorIconsStyle.bold),
                              size: 16,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // ========================================================
                    // Section: Imagen del plato
                    // ========================================================
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Text(
                        context.l10n.menuItemImage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _ImagePickerSection(
                      imageBytes: imageBytes,
                      imageUrl: imageUrl,
                      isUploading: isUploadingImage,
                      onPick: () async {
                        final picker = ImagePicker();
                        final xFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (xFile == null) return;

                        final bytes = await xFile.readAsBytes();
                        setDialogState(() {
                          imageBytes = bytes;
                          isUploadingImage = true;
                        });

                        try {
                          final tenantId = ref.read(activeTenantIdProvider);
                          final timestamp =
                              DateTime.now().millisecondsSinceEpoch;
                          final url = await CloudinaryService.uploadImage(
                            bytes: bytes,
                            folder: 'lome/restaurants/$tenantId/menu',
                            publicId: 'dish_$timestamp',
                          );
                          final optimized = CloudinaryService.optimizedUrl(
                            url,
                            width: 600,
                            height: 400,
                          );
                          setDialogState(() {
                            imageUrl = optimized;
                            isUploadingImage = false;
                          });
                        } catch (_) {
                          setDialogState(() => isUploadingImage = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.menuItemImageError),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      onRemove: () {
                        setDialogState(() {
                          imageBytes = null;
                          imageUrl = null;
                        });
                      },
                    ),
                    // Section: Información básica
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Text(
                        'Información básica',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    LomeTextField(
                      label: context.l10n.menuItemName,
                      controller: nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? context.l10n.menuItemNameRequired
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    LomeTextField(
                      label: context.l10n.menuItemPrice,
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return context.l10n.menuItemPriceRequired;
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return context.l10n.menuItemPriceRequired;
                        }
                        return null;
                      },
                    ),
                    // Section: Categoría
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Category dropdown
                    categories.when(
                      data: (cats) => DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: context.l10n.menuItemCategory,
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                        items: cats
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedCategoryId = v),
                      ),
                      loading: () => const LomeLoading(size: 24),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Section: Detalles
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Text(
                        'Detalles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    LomeTextField(
                      label: context.l10n.menuItemDescription,
                      controller: descCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    LomeTextField(
                      label: context.l10n.menuItemPrepTime,
                      controller: prepTimeCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    // Section: Etiquetas
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Text(
                        'Etiquetas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Allergens input
                    _ChipInputField(
                      label: context.l10n.menuAllergens,
                      values: selectedAllergens,
                      onChanged: (v) =>
                          setDialogState(() => selectedAllergens = v),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    // Tags input
                    _ChipInputField(
                      label: context.l10n.menuTags,
                      values: selectedTags,
                      onChanged: (v) => setDialogState(() => selectedTags = v),
                    ),
                    // Section: Opciones
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Text(
                        'Opciones',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Featured toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: SwitchListTile(
                        title: Text(context.l10n.menuFeatured),
                        value: isFeatured,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setDialogState(() => isFeatured = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Row(
                      children: [
                        Expanded(
                          child: LomeButton(
                            label: context.l10n.cancel,
                            variant: LomeButtonVariant.text,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: LomeButton(
                            label: context.l10n.save,
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              try {
                                final crud = ref.read(
                                  menuItemCrudProvider.notifier,
                                );
                                if (item == null) {
                                  await crud.create(
                                    name: nameCtrl.text.trim(),
                                    price: double.parse(priceCtrl.text.trim()),
                                    categoryId: selectedCategoryId,
                                    description: descCtrl.text.trim().isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                    imageUrl: imageUrl,
                                    preparationTime: int.tryParse(
                                      prepTimeCtrl.text.trim(),
                                    ),
                                    allergens: selectedAllergens,
                                    tags: selectedTags,
                                    isFeatured: isFeatured,
                                  );
                                } else {
                                  await crud.updateItem(item.id, {
                                    'name': nameCtrl.text.trim(),
                                    'price': double.parse(
                                      priceCtrl.text.trim(),
                                    ),
                                    'category_id': selectedCategoryId,
                                    'description': descCtrl.text.trim().isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                    'image_url': imageUrl,
                                    'preparation_time_min': int.tryParse(
                                      prepTimeCtrl.text.trim(),
                                    ),
                                    'allergens': selectedAllergens,
                                    'tags': selectedTags,
                                    'is_featured': isFeatured,
                                  });
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
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
      ),
    );
  }
}

// =============================================================================
// Categories Tab
// =============================================================================

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);

    return categoriesAsync.when(
      loading: () => const LomeLoading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (categories) {
        if (categories.isEmpty) {
          return LomeEmptyState(
            icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.duotone),
            title: context.l10n.menuManagementEmptyTitle,
            subtitle: context.l10n.menuManagementEmptySubtitle,
          );
        }
        return ReorderableListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) {
            // Reorder is visual-only; server sync can be added later
          },
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _CategoryCard(
              key: ValueKey(cat.id),
              category: cat,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final CategoryEntity category;
  final int index;

  const _CategoryCard({super.key, required this.category, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorStateOfType<_MenuManagementPageState>()!;

    return Dismissible(
          key: ValueKey('dismiss_${category.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppTheme.spacingLg),
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              PhosphorIcons.trash(PhosphorIconsStyle.duotone),
              color: AppColors.white,
            ),
          ),
          confirmDismiss: (_) async {
            final confirmed = await _confirmDelete(context);
            if (confirmed == true) {
              await ref
                  .read(menuCategoryCrudProvider.notifier)
                  .delete(category.id);
              return true;
            }
            return false;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppShadows.card,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(gradient: AppColors.heroGradient),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: category.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                              child: Image.network(
                                category.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                  ),
                                  child: Icon(
                                    PhosphorIcons.squaresFour(
                                      PhosphorIconsStyle.duotone,
                                    ),
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: Icon(
                                PhosphorIcons.squaresFour(
                                  PhosphorIconsStyle.duotone,
                                ),
                                color: AppColors.primary,
                              ),
                            ),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                      ),
                      subtitle:
                          category.description != null &&
                              category.description!.isNotEmpty
                          ? Text(
                              category.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.grey500,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIcons.forkKnife(
                                    PhosphorIconsStyle.duotone,
                                  ),
                                  size: 12,
                                  color: AppColors.grey500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${category.items.length} items',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              PhosphorIcons.dotsSixVertical(
                                PhosphorIconsStyle.bold,
                              ),
                              color: AppColors.grey300,
                            ),
                          ),
                        ],
                      ),
                      onTap: () =>
                          page._showCategoryDialog(context, category: category),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (60 * index).ms)
        .slideY(begin: 0.04, end: 0, duration: 300.ms, delay: (60 * index).ms);
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.menuDeleteConfirm),
        content: Text(context.l10n.menuDeleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Items Tab
// =============================================================================

class _ItemsTab extends ConsumerWidget {
  final TextEditingController searchController;

  const _ItemsTab({required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final dishesAsync = ref.watch(searchedDishesProvider);

    return Column(
      children: [
        // Search bar
        Container(
              margin: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
                0,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                boxShadow: AppShadows.card,
              ),
              child: LomeSearchField(
                controller: searchController,
                hint: context.l10n.menuManagementSearchHint,
                onChanged: (value) {
                  ref.read(dishSearchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  ref.read(dishSearchQueryProvider.notifier).state = '';
                },
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: -0.05, end: 0, duration: 300.ms),
        // Category filter chips
        categoriesAsync.when(
          data: (cats) => SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                  child: FilterChip(
                    label: Text(context.l10n.menuAllCategories),
                    selected: selectedCat == null,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) {
                      ref.read(selectedCategoryProvider.notifier).state = null;
                    },
                  ),
                ),
                ...cats.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: selectedCat == c.id,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state =
                            selectedCat == c.id ? null : c.id;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox(height: 52),
          error: (_, __) => const SizedBox(height: 52),
        ),
        // Items list
        Expanded(
          child: dishesAsync.when(
            loading: () => const LomeLoading(),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return LomeEmptyState(
                  icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                  title: context.l10n.menuManagementEmptyTitle,
                  subtitle: context.l10n.menuManagementEmptySubtitle,
                );
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _MenuItemCard(item: items[index], index: index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItemCard extends ConsumerWidget {
  final MenuItemEntity item;
  final int index;

  const _MenuItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = context.findAncestorStateOfType<_MenuManagementPageState>()!;

    return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppShadows.card,
          ),
          child: TactileWrapper(
            onTap: () => page._showItemDialog(context, item: item),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grey900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIcons.star(
                                        PhosphorIconsStyle.fill,
                                      ),
                                      size: 12,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      context.l10n.menuFeatured,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.12),
                                    AppColors.primary.withValues(alpha: 0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                '\$${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (item.categoryName != null) ...[
                              const SizedBox(width: AppTheme.spacingSm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  item.categoryName!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.preparationTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIcons.timer(
                                    PhosphorIconsStyle.duotone,
                                  ),
                                  size: 12,
                                  color: AppColors.grey500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.preparationTime} min',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: item.tags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusFull,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Availability toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.isAvailable
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Column(
                      children: [
                        Switch(
                          value: item.isAvailable,
                          activeColor: AppColors.success,
                          inactiveTrackColor: AppColors.error.withValues(
                            alpha: 0.3,
                          ),
                          onChanged: (v) {
                            ref
                                .read(menuItemCrudProvider.notifier)
                                .toggleAvailability(item.id, v);
                          },
                        ),
                        Text(
                          item.isAvailable
                              ? context.l10n.menuAvailable
                              : context.l10n.menuUnavailable,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.isAvailable
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
        .slideX(begin: 0.03, end: 0, duration: 300.ms, delay: (50 * index).ms);
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(
        PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
        color: AppColors.grey300,
      ),
    );
  }
}

// =============================================================================
// Image Picker Section
// =============================================================================

class _ImagePickerSection extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerSection({
    required this.imageBytes,
    required this.imageUrl,
    required this.isUploading,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || imageUrl != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: hasImage ? 180 : 100,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: hasImage
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.grey200,
          width: hasImage ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage ? _buildPreview(context) : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return TactileWrapper(
      onTap: onPick,
      semanticLabel: context.l10n.menuItemImage,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.camera(PhosphorIconsStyle.duotone),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              context.l10n.menuItemImageHint,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen
        if (imageBytes != null)
          Image.memory(imageBytes!, fit: BoxFit.cover)
        else if (imageUrl != null)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.grey100,
              child: Icon(
                PhosphorIcons.imageSquare(PhosphorIconsStyle.duotone),
                color: AppColors.grey300,
                size: 40,
              ),
            ),
          ),

        // Overlay de carga
        if (isUploading)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),

        // Gradient overlay en la parte inferior
        if (!isUploading)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cambiar imagen
                  _OverlayButton(
                    icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
                    onTap: onPick,
                    tooltip: context.l10n.menuItemImageChange,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  // Eliminar imagen
                  _OverlayButton(
                    icon: PhosphorIcons.trash(PhosphorIconsStyle.bold),
                    onTap: onRemove,
                    tooltip: context.l10n.menuItemImageRemove,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isDestructive;

  const _OverlayButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TactileWrapper(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDestructive ? Colors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Chip Input Field (allergens / tags)
// =============================================================================

class _ChipInputField extends StatefulWidget {
  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  const _ChipInputField({
    required this.label,
    required this.values,
    required this.onChanged,
  });

  @override
  State<_ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<_ChipInputField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addChip() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.values.contains(text)) return;
    widget.onChanged([...widget.values, text]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: 4,
          children: widget.values
              .map(
                (v) => Chip(
                  label: Text(v, style: const TextStyle(fontSize: 12)),
                  deleteIcon: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    size: 14,
                  ),
                  onDeleted: () {
                    final updated = List<String>.from(widget.values)..remove(v);
                    widget.onChanged(updated);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.label,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                onSubmitted: (_) => _addChip(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            TactileWrapper(
              onTap: _addChip,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                child: Icon(
                  PhosphorIcons.plusCircle(PhosphorIconsStyle.duotone),
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../providers/inventory_provider.dart';

/// Pagina de gestion de inventario.
class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredInventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.inventoryTitle,
        showBack: false,
        useGradient: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: LomeSearchField(
              hint: context.l10n.inventorySearchHint,
              onChanged: (q) =>
                  ref.read(inventorySearchQueryProvider.notifier).state = q,
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return LomeEmptyState(
                        icon: PhosphorIcons.package(PhosphorIconsStyle.duotone),
                        title: context.l10n.inventoryEmptyTitle,
                        subtitle: context.l10n.inventoryEmptySubtitle,
                        actionLabel: context.l10n.inventoryAddProduct,
                        onAction: () => _showItemDialog(context, ref),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.04, end: 0);
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(inventoryItemsProvider),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingMd,
                      0,
                      AppTheme.spacingMd,
                      100,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return _InventoryItemCard(
                            item: item,
                            onTap: () =>
                                _showItemDialog(context, ref, item: item),
                            onAdjustStock: () =>
                                _showAdjustStockDialog(context, ref, item),
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 50))
                          .slideX(begin: 0.03);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: TactileWrapper(
        onTap: () => _showItemDialog(context, ref),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(PhosphorIcons.plus(), color: Colors.white),
        ),
      ),
    );
  }

  // ── Diálogo crear/editar item ──

  void _showItemDialog(
    BuildContext context,
    WidgetRef ref, {
    InventoryItemEntity? item,
  }) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final unitCtrl = TextEditingController(text: item?.unit ?? '');
    final stockCtrl = TextEditingController(
      text: item?.currentStock.toString() ?? '0',
    );
    final minStockCtrl = TextEditingController(
      text: item?.minimumStock.toString() ?? '0',
    );
    final costCtrl = TextEditingController(
      text: item?.costPerUnit?.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(text: item?.category ?? '');
    final supplierCtrl = TextEditingController(text: item?.supplier ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final skuCtrl = TextEditingController(text: item?.sku ?? '');
    final formKey = GlobalKey<FormState>();

    final isEdit = item != null;
    final title = isEdit
        ? context.l10n.inventoryEditProduct
        : context.l10n.inventoryAddProduct;

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
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingMd,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
            ),
            child: Form(
              key: formKey,
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
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
                              PhosphorIcons.package(PhosphorIconsStyle.duotone),
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
                          padding: const EdgeInsets.all(AppTheme.spacingXs),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.duotone),
                            size: 18,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Name
                  LomeTextField(
                    label: context.l10n.inventoryName,
                    hint: context.l10n.inventoryNameHint,
                    controller: nameCtrl,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Unit + Category
                  Row(
                    children: [
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.inventoryUnit,
                          hint: context.l10n.inventoryUnitHint,
                          controller: unitCtrl,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.inventoryCategory,
                          hint: context.l10n.inventoryCategoryHint,
                          controller: categoryCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Stock + Min stock
                  Row(
                    children: [
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.inventoryCurrentStock,
                          controller: stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.inventoryMinimumStock,
                          controller: minStockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Cost + SKU
                  Row(
                    children: [
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.inventoryCostPerUnit,
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.inventorySku,
                          controller: skuCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Supplier
                  LomeTextField(
                    label: context.l10n.inventorySupplier,
                    hint: context.l10n.inventorySupplierHint,
                    controller: supplierCtrl,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Description
                  LomeTextField(
                    label: context.l10n.inventoryDescription,
                    controller: descCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            try {
                              if (isEdit) {
                                await ref
                                    .read(inventoryCrudProvider.notifier)
                                    .updateItem(item.id, {
                                      'name': nameCtrl.text.trim(),
                                      'unit': unitCtrl.text.trim(),
                                      'current_stock':
                                          double.tryParse(stockCtrl.text) ?? 0,
                                      'minimum_stock':
                                          double.tryParse(minStockCtrl.text) ??
                                          0,
                                      if (costCtrl.text.isNotEmpty)
                                        'cost_per_unit': double.tryParse(
                                          costCtrl.text,
                                        ),
                                      if (categoryCtrl.text.isNotEmpty)
                                        'category': categoryCtrl.text.trim(),
                                      if (supplierCtrl.text.isNotEmpty)
                                        'supplier': supplierCtrl.text.trim(),
                                      if (descCtrl.text.isNotEmpty)
                                        'description': descCtrl.text.trim(),
                                      if (skuCtrl.text.isNotEmpty)
                                        'sku': skuCtrl.text.trim(),
                                    });
                              } else {
                                await ref
                                    .read(inventoryCrudProvider.notifier)
                                    .create(
                                      name: nameCtrl.text.trim(),
                                      unit: unitCtrl.text.trim(),
                                      currentStock:
                                          double.tryParse(stockCtrl.text) ?? 0,
                                      minimumStock:
                                          double.tryParse(minStockCtrl.text) ??
                                          0,
                                      costPerUnit: double.tryParse(
                                        costCtrl.text,
                                      ),
                                      category: categoryCtrl.text.isNotEmpty
                                          ? categoryCtrl.text.trim()
                                          : null,
                                      supplier: supplierCtrl.text.isNotEmpty
                                          ? supplierCtrl.text.trim()
                                          : null,
                                      description: descCtrl.text.isNotEmpty
                                          ? descCtrl.text.trim()
                                          : null,
                                      sku: skuCtrl.text.isNotEmpty
                                          ? skuCtrl.text.trim()
                                          : null,
                                    );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.inventoryErrorCreate(
                                        e.toString(),
                                      ),
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isEdit
                                ? context.l10n.save
                                : context.l10n.inventoryAddProduct,
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

  // ── Diálogo ajustar stock ──

  void _showAdjustStockDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryItemEntity item,
  ) {
    final ctrl = TextEditingController(text: item.currentStock.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.inventoryAdjustStock),
        content: LomeTextField(
          label: '${item.name} (${item.unit})',
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newStock = double.tryParse(ctrl.text);
              if (newStock == null) return;
              try {
                await ref
                    .read(inventoryCrudProvider.notifier)
                    .adjustStock(item.id, newStock);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Card de item de inventario
// =============================================================================

class _InventoryItemCard extends StatelessWidget {
  final InventoryItemEntity item;
  final VoidCallback onTap;
  final VoidCallback onAdjustStock;

  const _InventoryItemCard({
    required this.item,
    required this.onTap,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isOutOfStock
        ? AppColors.error
        : item.isLowStock
        ? AppColors.warning
        : AppColors.success;
    final statusLabel = item.isOutOfStock
        ? context.l10n.inventoryOutOfStock
        : item.isLowStock
        ? context.l10n.inventoryLowStock
        : context.l10n.inventoryInStock;

    return TactileWrapper(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.category != null) ...[
                        Text(
                          item.category!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Stock count
            TactileWrapper(
              onTap: onAdjustStock,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm + 2,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      item.currentStock % 1 == 0
                          ? item.currentStock.toInt().toString()
                          : item.currentStock.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey900,
                      ),
                    ),
                    Text(
                      item.unit,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

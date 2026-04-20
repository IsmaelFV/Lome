import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/utils/extensions/context_extensions.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_empty_state.dart';
import '../../../../../core/widgets/lome_loading.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../../menu/domain/entities/menu_item_entity.dart';
import '../../../menu/presentation/providers/menu_provider.dart';
import '../../../tables/domain/entities/table_entity.dart';
import '../../../tables/presentation/pages/tables_page.dart'
    show tableStatusColor;
import '../../../tables/presentation/providers/tables_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/orders_provider.dart';
import 'ticket_preview_page.dart';

/// Página de gestión de pedido asociada a una mesa.
///
/// Recibe [tableId] y muestra/crea el pedido activo para esa mesa.
/// Desde esta pantalla el camarero gestiona el flujo completo:
/// añadir productos → enviar a cocina → marcar servido → cobrar.
class TableOrderPage extends ConsumerStatefulWidget {
  final String tableId;

  const TableOrderPage({super.key, required this.tableId});

  @override
  ConsumerState<TableOrderPage> createState() => _TableOrderPageState();
}

class _TableOrderPageState extends ConsumerState<TableOrderPage> {
  OrderEntity? _order;
  bool _loading = true;

  /// Key del item recién añadido para animarlo.
  String? _lastAddedItemId;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);
    try {
      final order = await ref
          .read(ordersProvider.notifier)
          .getActiveOrderForTable(widget.tableId);
      if (mounted)
        setState(() {
          _order = order;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDish(MenuItemEntity dish, {String? notes}) async {
    if (_order == null) return;
    await ref
        .read(ordersProvider.notifier)
        .addItem(
          orderId: _order!.id,
          menuItemId: dish.id,
          name: dish.name,
          unitPrice: dish.price,
          notes: notes,
        );
    // Recargar para obtener el nuevo item
    final updated = await ref
        .read(ordersProvider.notifier)
        .getActiveOrderForTable(widget.tableId);
    if (mounted && updated != null) {
      // El último item añadido es el que no estaba antes
      final oldIds = _order!.items.map((e) => e.id).toSet();
      final newItem = updated.items
          .where((e) => !oldIds.contains(e.id))
          .firstOrNull;
      setState(() {
        _order = updated;
        _lastAddedItemId = newItem?.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en los pedidos para auto-actualizar
    ref.listen(ordersProvider, (_, next) {
      next.whenData((_) => _loadOrder());
    });

    final tables = ref.watch(tablesProvider).valueOrNull ?? [];
    final table = tables.where((t) => t.id == widget.tableId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: table?.displayName ?? context.l10n.tableOrderDefaultTitle,
        actions: [
          if (_order != null)
            TactileWrapper(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketPreviewPage(
                    order: _order!,
                    tableName: table?.displayName,
                  ),
                ),
              ),
              child: Tooltip(
                message: context.l10n.tableOrderPrintTooltip,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  child: Icon(
                    PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
                    color: AppColors.grey700,
                  ),
                ),
              ),
            ),
          if (_order != null) _OrderStatusChip(status: _order!.status),
        ],
      ),
      body: _loading
          ? const LomeLoading()
          : _order == null
          ? LomeEmptyState(
              icon: PhosphorIcons.receipt(PhosphorIconsStyle.duotone),
              title: context.l10n.tableOrderEmptyTitle,
              subtitle: context.l10n.tableOrderEmptySubtitle,
            )
          : _OrderContent(
              order: _order!,
              table: table,
              onRefresh: _loadOrder,
              onAddDish: _addDish,
              lastAddedItemId: _lastAddedItemId,
            ),
      bottomNavigationBar: _order != null
          ? _ActionBar(order: _order!, table: table, onAction: _loadOrder)
          : null,
    );
  }
}

// =============================================================================
// Chip de estado del pedido
// =============================================================================

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _orderStatusColor(status);
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingMd),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// Contenido del pedido (header + items)
// =============================================================================

class _OrderContent extends ConsumerWidget {
  final OrderEntity order;
  final TableEntity? table;
  final VoidCallback onRefresh;
  final Future<void> Function(MenuItemEntity, {String? notes}) onAddDish;
  final String? lastAddedItemId;

  const _OrderContent({
    required this.order,
    this.table,
    required this.onRefresh,
    required this.onAddDish,
    this.lastAddedItemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // ── Header info ──
          _OrderHeader(order: order, table: table),
          const SizedBox(height: AppTheme.spacingLg),

          // ── Lista de items ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.tableOrderProductCount(order.itemCount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              if (order.status == OrderStatus.pending)
                FilledButton.tonalIcon(
                  onPressed: () => _showMenuPicker(context, ref),
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
                  label: Text(context.l10n.tableOrderAddButton),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),

          if (order.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                    size: 48,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    context.l10n.tableOrderAddProducts,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  OutlinedButton.icon(
                    onPressed: () => _showMenuPicker(context, ref),
                    icon: Icon(PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone)),
                    label: Text(context.l10n.tableOrderViewMenu),
                  ),
                ],
              ),
            )
          else
            ...order.items.map((item) {
              final isNew = item.id == lastAddedItemId;
              final tile = _OrderItemTile(
                item: item,
                orderId: order.id,
                canEdit: order.status == OrderStatus.pending,
              );
              if (isNew) {
                return tile
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.15, end: 0, duration: 300.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                    );
              }
              return tile;
            }),

          // ── Totales ──
          if (order.items.isNotEmpty) ...[
            const Divider(height: AppTheme.spacingXl),
            _TotalRow(label: context.l10n.subtotal, amount: order.subtotal),
            if (order.taxAmount > 0)
              _TotalRow(label: context.l10n.taxes, amount: order.taxAmount),
            if (order.discountAmount > 0)
              _TotalRow(
                label: context.l10n.discount,
                amount: -order.discountAmount,
                isDiscount: true,
              ),
            const SizedBox(height: AppTheme.spacingSm),
            _TotalRow(
              label: context.l10n.total,
              amount: order.total,
              isTotal: true,
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showMenuPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => _MenuPickerSheet(
          orderId: order.id,
          scrollController: scrollCtrl,
          onAddDish: onAddDish,
        ),
      ),
    );
  }
}

// =============================================================================
// Header del pedido
// =============================================================================

class _OrderHeader extends StatelessWidget {
  final OrderEntity order;
  final TableEntity? table;

  const _OrderHeader({required this.order, this.table});

  @override
  Widget build(BuildContext context) {
    final statusColor = table != null
        ? tableStatusColor(table!.status)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(
                '${table?.number ?? '?'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.orderNumberLabel(order.orderNumber.toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (table != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        table!.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                    ],
                    if (order.waiterName != null) ...[
                      Icon(
                        PhosphorIcons.user(PhosphorIconsStyle.duotone),
                        size: 14,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        order.waiterName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _paymentColor(order.paymentStatus).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              order.paymentStatus.label,
              style: TextStyle(
                color: _paymentColor(order.paymentStatus),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Item del pedido
// =============================================================================

class _OrderItemTile extends ConsumerWidget {
  final OrderItemEntity item;
  final String orderId;
  final bool canEdit;

  const _OrderItemTile({
    required this.item,
    required this.orderId,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _itemStatusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppShadows.card,
      ),
      child: TactileWrapper(
        onTap: canEdit ? () => _showEditNotesDialog(context, ref) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Cantidad con +/- si editable
              if (canEdit)
                _QuantityStepper(
                  quantity: item.quantity,
                  onChanged: (q) => ref
                      .read(ordersProvider.notifier)
                      .updateItemQuantity(item.id, orderId, q),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.notepad(PhosphorIconsStyle.duotone),
                              size: 12,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.notes!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            if (canEdit)
                              Icon(
                                PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone),
                                size: 12,
                                color: AppColors.grey400,
                              ),
                          ],
                        ),
                      )
                    else if (canEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          context.l10n.tableOrderAddNotesHint,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey300,
                          ),
                        ),
                      ),
                    // Item status chip (cuando ya se envió a cocina)
                    if (!canEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            item.status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '€${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              if (canEdit)
                TactileWrapper(
                  onTap: () => ref
                      .read(ordersProvider.notifier)
                      .removeItem(item.id, orderId),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      PhosphorIcons.x(PhosphorIconsStyle.bold),
                      size: 18,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo para editar notas de un ítem antes de enviar a cocina.
  void _showEditNotesDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: item.notes ?? '');
    final quickNotes = [
      context.l10n.quickNoteNoOnion,
      context.l10n.quickNoteExtraCheese,
      context.l10n.quickNoteGlutenFree,
      context.l10n.quickNoteRare,
      context.l10n.quickNoteWellDone,
      context.l10n.quickNoteNoSalt,
      context.l10n.quickNoteNoSpicy,
      context.l10n.quickNoteNoDairy,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spacingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l10n.tableOrderNotesTitle(item.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Wrap(
                  spacing: AppTheme.spacingSm,
                  runSpacing: AppTheme.spacingSm,
                  children: quickNotes.map((note) {
                    final selected = controller.text.contains(note);
                    return ChoiceChip(
                      label: Text(note),
                      selected: selected,
                      onSelected: (_) {
                        final current = controller.text;
                        if (current.contains(note)) {
                          controller.text = current
                              .replaceAll(note, '')
                              .replaceAll(', , ', ', ')
                              .trim();
                          if (controller.text.startsWith(', ')) {
                            controller.text = controller.text.substring(2);
                          }
                          if (controller.text.endsWith(', ')) {
                            controller.text = controller.text.substring(
                              0,
                              controller.text.length - 2,
                            );
                          }
                        } else {
                          controller.text = current.isEmpty
                              ? note
                              : '$current, $note';
                        }
                        setSheetState(() {});
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.grey600,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: context.l10n.quickNoteCustomHint,
                    filled: true,
                    fillColor: AppColors.grey100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 2,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final notes = controller.text.trim();
                      ref
                          .read(ordersProvider.notifier)
                          .updateItemNotes(
                            item.id,
                            notes.isEmpty ? null : notes,
                          );
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(context.l10n.tableOrderSaveNotes),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Stepper de cantidad inline
// =============================================================================

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperBtn(
            icon: quantity == 1 ? PhosphorIcons.trash(PhosphorIconsStyle.duotone) : PhosphorIcons.minus(PhosphorIconsStyle.bold),
            color: quantity == 1 ? AppColors.error : AppColors.grey600,
            onTap: () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          _StepperBtn(
            icon: PhosphorIcons.plus(PhosphorIconsStyle.bold),
            color: AppColors.primary,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StepperBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// =============================================================================
// Fila de totales
// =============================================================================

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  )
                : const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
          ),
          Text(
            '${isDiscount ? '-' : ''}€${amount.abs().toStringAsFixed(2)}',
            style: isTotal
                ? const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  )
                : TextStyle(
                    fontSize: 14,
                    color: isDiscount ? AppColors.success : AppColors.grey700,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Barra de acciones inferior (contextual según estado)
// =============================================================================

class _ActionBar extends ConsumerWidget {
  final OrderEntity order;
  final TableEntity? table;
  final VoidCallback onAction;

  const _ActionBar({required this.order, this.table, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        MediaQuery.of(context).padding.bottom + AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          // Botón cancelar (visible si el pedido se puede cancelar)
          if (order.canBeCancelled)
            TactileWrapper(
              onTap: () => _showCancelDialog(context, ref),
              child: Tooltip(
                message: context.l10n.tableOrderCancelTitle,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.duotone), color: AppColors.error),
                ),
              ),
            ),
          // Botón reembolso (visible si el pedido está pagado)
          if (order.isPaid)
            TactileWrapper(
              onTap: () => _showRefundDialog(context, ref),
              child: Tooltip(
                message: context.l10n.refundTitle,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.duotone), color: AppColors.warning),
                ),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.total,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
                Text(
                  '€${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(flex: 2, child: _buildActionButton(context, ref)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (order.status) {
      case OrderStatus.pending:
        return _ActionButton(
          label: context.l10n.tableOrderSendToKitchen,
          icon: PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
          color: AppColors.tableWaitingFood,
          enabled: order.items.isNotEmpty,
          onPressed: () =>
              ref.read(ordersProvider.notifier).sendToKitchen(order.id),
        );

      case OrderStatus.preparing:
        return _ActionButton(
          label: context.l10n.tableOrderInKitchen,
          icon: PhosphorIcons.hourglassMedium(PhosphorIconsStyle.duotone),
          color: AppColors.tableWaitingFood,
          enabled: false,
          onPressed: () {},
        );

      case OrderStatus.ready:
        return _ActionButton(
          label: context.l10n.tableOrderMarkServed,
          icon: PhosphorIcons.bellSimple(PhosphorIconsStyle.duotone),
          color: AppColors.success,
          onPressed: () =>
              ref.read(ordersProvider.notifier).markServed(order.id),
        );

      case OrderStatus.delivered:
        return _ActionButton(
          label: context.l10n.tableOrderPayment,
          icon: PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
          color: AppColors.tableWaitingPayment,
          onPressed: () => _showPaymentDialog(context, ref),
        );

      case OrderStatus.served:
        return _ActionButton(
          label: context.l10n.tableOrderPayment,
          icon: PhosphorIcons.creditCard(PhosphorIconsStyle.duotone),
          color: AppColors.tableWaitingPayment,
          onPressed: () => _showPaymentDialog(context, ref),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref) {
    String? selectedMethod;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(context.l10n.tableOrderPaymentDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '€${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                context.l10n.paymentMethod,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: AppTheme.spacingSm,
                children: [
                  ChoiceChip(
                    label: Text(context.l10n.paymentCash),
                    avatar: Icon(PhosphorIcons.money(PhosphorIconsStyle.duotone), size: 16),
                    selected: selectedMethod == 'cash',
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selectedMethod == 'cash' ? AppColors.primary : AppColors.grey600,
                    ),
                    onSelected: (_) =>
                        setDialogState(() => selectedMethod = 'cash'),
                  ),
                  ChoiceChip(
                    label: Text(context.l10n.paymentCard),
                    avatar: Icon(PhosphorIcons.creditCard(PhosphorIconsStyle.duotone), size: 16),
                    selected: selectedMethod == 'card',
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selectedMethod == 'card' ? AppColors.primary : AppColors.grey600,
                    ),
                    onSelected: (_) =>
                        setDialogState(() => selectedMethod = 'card'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: selectedMethod == null
                  ? null
                  : () {
                      ref
                          .read(ordersProvider.notifier)
                          .processPayment(order.id, selectedMethod!);
                      Navigator.pop(ctx);
                      context.pop();
                    },
              child: Text(context.l10n.tableOrderConfirmPayment),
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo de cancelación con motivo obligatorio.
  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();
    String? selectedReason;

    final reasons = [
      context.l10n.cancelReasonClientLeaving,
      context.l10n.cancelReasonOrderError,
      context.l10n.cancelReasonKitchenIssue,
      context.l10n.cancelReasonOutOfStock,
      context.l10n.cancelReasonDuplicate,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                PhosphorIcons.warning(PhosphorIconsStyle.fill),
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(context.l10n.tableOrderCancelTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.orderNumberLabel(order.orderNumber.toString()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(context.l10n.tableOrderCancelReason),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingSm,
                children: reasons.map((r) {
                  final selected = selectedReason == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: selected,
                    onSelected: (_) => setDialogState(() {
                      selectedReason = selected ? null : r;
                      if (!selected) reasonCtrl.text = r;
                    }),
                    selectedColor: AppColors.error.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.error : AppColors.grey600,
                      fontSize: 12,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  hintText: context.l10n.cancelReasonOtherHint,
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                maxLines: 2,
                onChanged: (v) => setDialogState(() {
                  selectedReason = null;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.back),
            ),
            FilledButton(
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () {
                      ref
                          .read(ordersProvider.notifier)
                          .cancelOrder(
                            order.id,
                            reason: reasonCtrl.text.trim(),
                          );
                      Navigator.pop(ctx);
                      context.pop();
                    },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(context.l10n.tableOrderConfirmCancel),
            ),
          ],
        ),
      ),
    );
  }

  /// Diálogo de reembolso.
  void _showRefundDialog(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                PhosphorIcons.arrowCounterClockwise(PhosphorIconsStyle.fill),
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(context.l10n.refundTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.orderNumberLabel(order.orderNumber.toString()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                '€${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(context.l10n.refundReasonLabel),
              const SizedBox(height: AppTheme.spacingSm),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  hintText: context.l10n.refundReasonHint,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                maxLines: 2,
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: reasonCtrl.text.trim().isEmpty
                  ? null
                  : () {
                      ref
                          .read(ordersProvider.notifier)
                          .refundOrder(
                            order.id,
                            reason: reasonCtrl.text.trim(),
                          );
                      Navigator.pop(ctx);
                      context.pop();
                    },
              style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
              child: Text(context.l10n.refundConfirm),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

// =============================================================================
// Menu picker – bottom sheet con categorías, búsqueda y notas
// =============================================================================

class _MenuPickerSheet extends ConsumerStatefulWidget {
  final String orderId;
  final ScrollController scrollController;
  final Future<void> Function(MenuItemEntity, {String? notes}) onAddDish;

  const _MenuPickerSheet({
    required this.orderId,
    required this.scrollController,
    required this.onAddDish,
  });

  @override
  ConsumerState<_MenuPickerSheet> createState() => _MenuPickerSheetState();
}

class _MenuPickerSheetState extends ConsumerState<_MenuPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);
    final dishesAsync = ref.watch(searchedDishesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: Row(
              children: [
                Icon(PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone), size: 22),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  context.l10n.tableOrderPickerTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(dishSearchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: context.l10n.tableOrderPickerSearchHint,
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? TactileWrapper(
                        onTap: () {
                          _searchCtrl.clear();
                          ref.read(dishSearchQueryProvider.notifier).state = '';
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            size: 18,
                            color: AppColors.grey400,
                          ),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Tabs de categorías
          categoriesAsync.when(
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  children: [
                    _CategoryChip(
                      label: context.l10n.tableOrderPickerAll,
                      selected: selectedCat == null,
                      onTap: () =>
                          ref.read(selectedCategoryProvider.notifier).state =
                              null,
                    ),
                    ...categories.map(
                      (c) => _CategoryChip(
                        label: c.name,
                        selected: selectedCat == c.id,
                        onTap: () =>
                            ref.read(selectedCategoryProvider.notifier).state =
                                selectedCat == c.id ? null : c.id,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingSm),

          // Grid de platos
          Expanded(
            child: dishesAsync.when(
              loading: () => const LomeLoading(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (dishes) {
                if (dishes.isEmpty) {
                  return LomeEmptyState(
                    icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
                    title: context.l10n.tableOrderPickerEmpty,
                    subtitle: context.l10n.tableOrderPickerEmptySubtitle,
                  );
                }
                return GridView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    0,
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppTheme.spacingSm,
                    crossAxisSpacing: AppTheme.spacingSm,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: dishes.length,
                  itemBuilder: (ctx, i) => _DishCard(
                    dish: dishes[i],
                    onTap: () => _showDishDetail(context, dishes[i]),
                    onQuickAdd: () => _quickAdd(dishes[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _quickAdd(MenuItemEntity dish) {
    widget.onAddDish(dish);
    _showAddedFeedback(dish.name);
  }

  void _showAddedFeedback(String name) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(context.l10n.tableOrderItemAdded(name))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _showDishDetail(
    BuildContext context,
    MenuItemEntity dish,
  ) async {
    final result = await showModalBottomSheet<_DishAddResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => _DishDetailSheet(dish: dish),
    );

    if (result != null) {
      await widget.onAddDish(
        dish,
        notes: result.notes.isNotEmpty ? result.notes : null,
      );
      if (mounted) _showAddedFeedback(dish.name);
    }
  }
}

// =============================================================================
// Chip de categoría
// =============================================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.grey600,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// =============================================================================
// Card de plato en grid
// =============================================================================

class _DishCard extends StatelessWidget {
  final MenuItemEntity dish;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;

  const _DishCard({
    required this.dish,
    required this.onTap,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: TactileWrapper(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen o placeholder
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (dish.imageUrl != null && dish.imageUrl!.isNotEmpty)
                    Image.network(
                      dish.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _dishPlaceholder(),
                    )
                  else
                    _dishPlaceholder(),

                  // Badge destacado
                  if (dish.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: const Text(
                          '★',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),

                  // Botón quick-add
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: TactileWrapper(
                      onTap: onQuickAdd,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Icon(
                          PhosphorIcons.plus(PhosphorIconsStyle.bold),
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '€${dish.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dishPlaceholder() {
    return Container(
      color: AppColors.grey100,
      child: Center(
        child: Icon(
          PhosphorIcons.forkKnife(PhosphorIconsStyle.duotone),
          size: 32,
          color: AppColors.grey300,
        ),
      ),
    );
  }
}

// =============================================================================
// Resultado de añadir plato desde la hoja de detalle
// =============================================================================

class _DishAddResult {
  final String notes;
  _DishAddResult({required this.notes});
}

// =============================================================================
// Hoja de detalle de plato (con notas especiales)
// =============================================================================

class _DishDetailSheet extends StatefulWidget {
  final MenuItemEntity dish;

  const _DishDetailSheet({required this.dish});

  @override
  State<_DishDetailSheet> createState() => _DishDetailSheetState();
}

class _DishDetailSheetState extends State<_DishDetailSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toggleQuickNote(String note) {
    final current = _notesCtrl.text;
    if (current.contains(note)) {
      _notesCtrl.text = current
          .replaceAll(note, '')
          .replaceAll(', , ', ', ')
          .trim();
      if (_notesCtrl.text.startsWith(', ')) {
        _notesCtrl.text = _notesCtrl.text.substring(2);
      }
      if (_notesCtrl.text.endsWith(', ')) {
        _notesCtrl.text = _notesCtrl.text.substring(
          0,
          _notesCtrl.text.length - 2,
        );
      }
    } else {
      _notesCtrl.text = current.isEmpty ? note : '$current, $note';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dish = widget.dish;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
          MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Nombre + precio
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                      ),
                      if (dish.description != null &&
                          dish.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dish.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.grey500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    '€${dish.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),

            // Info extra
            if (dish.allergens.isNotEmpty || dish.preparationTime != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingXs,
                children: [
                  if (dish.preparationTime != null)
                    _InfoTag(
                      icon: PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                      label: '${dish.preparationTime} min',
                    ),
                  ...dish.allergens.map(
                    (a) => _InfoTag(icon: PhosphorIcons.warning(PhosphorIconsStyle.duotone), label: a),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppTheme.spacingLg),

            // Notas rápidas
            Text(
              context.l10n.tableOrderSpecialNotes,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children:
                  [
                    context.l10n.quickNoteNoOnion,
                    context.l10n.quickNoteExtraCheese,
                    context.l10n.quickNoteGlutenFree,
                    context.l10n.quickNoteRare,
                    context.l10n.quickNoteWellDone,
                    context.l10n.quickNoteNoSalt,
                    context.l10n.quickNoteNoSpicy,
                    context.l10n.quickNoteNoDairy,
                  ].map((note) {
                    final selected = _notesCtrl.text.contains(note);
                    return ChoiceChip(
                      label: Text(note),
                      selected: selected,
                      onSelected: (_) => _toggleQuickNote(note),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.grey600,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Campo de notas libre
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                hintText: context.l10n.tableOrderWriteCustomNote,
                hintStyle: TextStyle(color: AppColors.grey400),
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Botón añadir
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  _DishAddResult(notes: _notesCtrl.text.trim()),
                ),
                icon: Icon(PhosphorIcons.shoppingCart(PhosphorIconsStyle.duotone)),
                label: Text(
                  context.l10n.tableOrderAddWithPrice(
                    dish.price.toStringAsFixed(2),
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tag de información (alérgenos, tiempo)
// =============================================================================

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey500),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.grey600)),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers de color
// =============================================================================

Color _orderStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pending => AppColors.statusPending,
  OrderStatus.confirmed => AppColors.statusConfirmed,
  OrderStatus.preparing => AppColors.statusPreparing,
  OrderStatus.ready => AppColors.statusReady,
  OrderStatus.served => AppColors.statusServed,
  OrderStatus.delivered => AppColors.statusDelivered,
  OrderStatus.cancelled => AppColors.statusCancelled,
  OrderStatus.completed => AppColors.statusCompleted,
};

Color _paymentColor(PaymentStatus status) => switch (status) {
  PaymentStatus.pending => AppColors.warning,
  PaymentStatus.paid => AppColors.success,
  PaymentStatus.refunded => AppColors.info,
  PaymentStatus.partial => AppColors.tableWaitingPayment,
};

Color _itemStatusColor(OrderItemStatus status) => switch (status) {
  OrderItemStatus.pending => AppColors.statusPending,
  OrderItemStatus.preparing => AppColors.statusPreparing,
  OrderItemStatus.ready => AppColors.statusReady,
  OrderItemStatus.served => AppColors.statusServed,
  OrderItemStatus.cancelled => AppColors.grey500,
};

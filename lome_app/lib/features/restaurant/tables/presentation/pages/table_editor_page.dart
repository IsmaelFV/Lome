import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/lome_text_field.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../../domain/entities/table_entity.dart';
import '../providers/tables_provider.dart';
import '../widgets/table_map_canvas.dart';

/// Editor visual de distribución de mesas.
///
/// Permite al administrador:
/// - Añadir mesas nuevas
/// - Mover mesas con drag & drop
/// - Editar propiedades (forma, tamaño, capacidad)
/// - Eliminar mesas
class TableEditorPage extends ConsumerStatefulWidget {
  const TableEditorPage({super.key});

  @override
  ConsumerState<TableEditorPage> createState() => _TableEditorPageState();
}

class _TableEditorPageState extends ConsumerState<TableEditorPage> {
  String? _editingTableId;

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(
        title: context.l10n.tableEditorTitle,
        useGradient: true,
        actions: [
          TactileWrapper(
            onTap: () => _showCreateDialog(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                PhosphorIcons.plus(PhosphorIconsStyle.bold),
                size: 18,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tables) {
          if (tables.isEmpty) {
            return Center(
              child:
                  Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIcons.gridFour(PhosphorIconsStyle.duotone),
                            size: 64,
                            color: AppColors.grey200,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            context.l10n.tableEditorEmptyTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey500,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          TactileWrapper(
                            onTap: () => _showCreateDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIcons.plus(PhosphorIconsStyle.bold),
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.tableEditorAddTable,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: AppTheme.durationFast)
                      .slideY(begin: 0.1, end: 0),
            );
          }

          return Column(
            children: [
              // ── Toolbar ──
              if (_editingTableId != null)
                _EditorToolbar(
                  table: tables.firstWhere(
                    (t) => t.id == _editingTableId,
                    orElse: () => tables.first,
                  ),
                  onEdit: () => _showEditDialog(
                    context,
                    tables.firstWhere((t) => t.id == _editingTableId),
                  ),
                  onDelete: () => _confirmDelete(
                    context,
                    tables.firstWhere((t) => t.id == _editingTableId),
                  ),
                  onDeselect: () => setState(() => _editingTableId = null),
                ),

              // ── Canvas ──
              Expanded(
                child: TableMapCanvas(
                  tables: tables,
                  isEditing: true,
                  onTableTap: (table) {
                    setState(() {
                      _editingTableId = _editingTableId == table.id
                          ? null
                          : table.id;
                    });
                    ref.read(selectedTableProvider.notifier).state =
                        _editingTableId;
                  },
                  onTableMoved: (table, x, y) {
                    ref
                        .read(tablesProvider.notifier)
                        .updateTablePosition(table.id, x, y);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Crear mesa
  // ---------------------------------------------------------------------------

  void _showCreateDialog(BuildContext context) {
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');
    final zoneCtrl = TextEditingController();
    var shape = TableShape.square;
    final formKey = GlobalKey<FormState>();

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
          builder: (ctx, setDialogState) => Padding(
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
                          PhosphorIcons.gridFour(PhosphorIconsStyle.duotone),
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        context.l10n.tableEditorNewTable,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacingXs),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            size: 18,
                            color: AppColors.grey600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  // Number + Capacity
                  Row(
                    children: [
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.tableEditorNumberLabel,
                          controller: numberCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (int.tryParse(v) == null)
                              return 'Número inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: LomeTextField(
                          label: context.l10n.tableEditorCapacityLabel,
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  LomeTextField(
                    label: context.l10n.tableEditorNameLabel,
                    hint: context.l10n.tableEditorNameHint,
                    controller: nameCtrl,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  LomeTextField(
                    label: context.l10n.tableEditorZoneLabel,
                    hint: context.l10n.tableEditorZoneHint,
                    controller: zoneCtrl,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  // Shape selector
                  Text(
                    context.l10n.tableEditorShapeLabel,
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: TableShape.values.map((s) {
                      final selected = s == shape;
                      final icon = switch (s) {
                        TableShape.round => PhosphorIcons.circle(
                          selected
                              ? PhosphorIconsStyle.fill
                              : PhosphorIconsStyle.light,
                        ),
                        TableShape.square => PhosphorIcons.square(
                          selected
                              ? PhosphorIconsStyle.fill
                              : PhosphorIconsStyle.light,
                        ),
                        TableShape.rectangle => PhosphorIcons.rectangle(
                          selected
                              ? PhosphorIconsStyle.fill
                              : PhosphorIconsStyle.light,
                        ),
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => shape = s),
                          child: AnimatedContainer(
                            duration: AppTheme.durationFast,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.grey50,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.grey200,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icon,
                                  size: 28,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.grey400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final number = int.tryParse(numberCtrl.text);
                            final capacity =
                                int.tryParse(capacityCtrl.text) ?? 4;
                            if (number == null) return;

                            ref
                                .read(tablesProvider.notifier)
                                .createTable(
                                  number: number,
                                  name: nameCtrl.text.isEmpty
                                      ? null
                                      : nameCtrl.text,
                                  capacity: capacity,
                                  zone: zoneCtrl.text.isEmpty
                                      ? null
                                      : zoneCtrl.text,
                                  shape: shape,
                                  width: shape == TableShape.rectangle
                                      ? 2.0
                                      : 1.0,
                                  height: 1.0,
                                );
                            Navigator.pop(ctx);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(context.l10n.create),
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

  // ---------------------------------------------------------------------------
  // Editar mesa
  // ---------------------------------------------------------------------------

  void _showEditDialog(BuildContext context, TableEntity table) {
    final nameCtrl = TextEditingController(text: table.name ?? '');
    final capacityCtrl = TextEditingController(text: '${table.capacity}');
    final zoneCtrl = TextEditingController(text: table.zone ?? '');
    var shape = table.shape;

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
          builder: (ctx, setDialogState) => Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              top: AppTheme.spacingMd,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spacingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      context.l10n.tableEditorEditTitle(table.displayName),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXs),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          size: 18,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                LomeTextField(
                  label: context.l10n.tableEditorNameLabel,
                  controller: nameCtrl,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: LomeTextField(
                        label: context.l10n.tableEditorCapacityLabel,
                        controller: capacityCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: LomeTextField(
                        label: context.l10n.tableEditorZoneLabel,
                        controller: zoneCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Shape selector
                Text(
                  context.l10n.tableEditorShapeLabel,
                  style: Theme.of(ctx).textTheme.labelLarge,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  children: TableShape.values.map((s) {
                    final selected = s == shape;
                    final icon = switch (s) {
                      TableShape.round => PhosphorIcons.circle(
                        selected
                            ? PhosphorIconsStyle.fill
                            : PhosphorIconsStyle.light,
                      ),
                      TableShape.square => PhosphorIcons.square(
                        selected
                            ? PhosphorIconsStyle.fill
                            : PhosphorIconsStyle.light,
                      ),
                      TableShape.rectangle => PhosphorIcons.rectangle(
                        selected
                            ? PhosphorIconsStyle.fill
                            : PhosphorIconsStyle.light,
                      ),
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => shape = s),
                        child: AnimatedContainer(
                          duration: AppTheme.durationFast,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.grey50,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey200,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                icon,
                                size: 28,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.grey400,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                        onPressed: () {
                          ref
                              .read(tablesProvider.notifier)
                              .updateTable(
                                tableId: table.id,
                                name: nameCtrl.text.isEmpty
                                    ? null
                                    : nameCtrl.text,
                                capacity: int.tryParse(capacityCtrl.text),
                                zone: zoneCtrl.text.isEmpty
                                    ? null
                                    : zoneCtrl.text,
                                shape: shape,
                                width: shape == TableShape.rectangle
                                    ? 2.0
                                    : 1.0,
                                height: 1.0,
                              );
                          Navigator.pop(ctx);
                          setState(() => _editingTableId = null);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(context.l10n.save),
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

  // ---------------------------------------------------------------------------
  // Eliminar mesa
  // ---------------------------------------------------------------------------

  void _confirmDelete(BuildContext context, TableEntity table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tableEditorDeleteTitle),
        content: Text(context.l10n.tableEditorDeleteConfirm(table.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(tablesProvider.notifier).deleteTable(table.id);
              Navigator.pop(ctx);
              setState(() => _editingTableId = null);
            },
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Toolbar de edición (aparece al seleccionar una mesa)
// =============================================================================

class _EditorToolbar extends StatelessWidget {
  final TableEntity table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDeselect;

  const _EditorToolbar({
    required this.table,
    required this.onEdit,
    required this.onDelete,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(bottom: BorderSide(color: AppColors.grey100)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              table.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            '${table.shape.label} · ${table.capacity} personas',
            style: const TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
          const Spacer(),
          TactileWrapper(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone),
                size: 20,
                color: AppColors.grey500,
              ),
            ),
          ),
          TactileWrapper(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                PhosphorIcons.trash(PhosphorIconsStyle.duotone),
                size: 20,
                color: AppColors.error,
              ),
            ),
          ),
          TactileWrapper(
            onTap: onDeselect,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                PhosphorIcons.x(PhosphorIconsStyle.bold),
                size: 20,
                color: AppColors.grey400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

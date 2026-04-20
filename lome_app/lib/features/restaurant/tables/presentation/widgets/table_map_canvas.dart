import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/table_entity.dart';
import '../pages/tables_page.dart' show tableStatusColor;
import '../providers/tables_provider.dart';

/// Tamaño base de una unidad (1×1) de mesa en px.
const double _cellSize = 80.0;

/// Tamaño del canvas virtual.
const double _canvasWidth = 1200.0;
const double _canvasHeight = 900.0;

/// Canvas interactivo que muestra todas las mesas.
///
/// [isEditing] activa el drag & drop de mesas.
/// [onTableTap] se invoca al pulsar una mesa (modo visualización).
/// [onTableMoved] notifica la nueva posición tras un drag (modo editor).
class TableMapCanvas extends ConsumerStatefulWidget {
  final List<TableEntity> tables;
  final bool isEditing;
  final void Function(TableEntity table)? onTableTap;
  final void Function(TableEntity table, double x, double y)? onTableMoved;

  const TableMapCanvas({
    super.key,
    required this.tables,
    this.isEditing = false,
    this.onTableTap,
    this.onTableMoved,
  });

  @override
  ConsumerState<TableMapCanvas> createState() => _TableMapCanvasState();
}

class _TableMapCanvasState extends ConsumerState<TableMapCanvas> {
  final TransformationController _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedTableProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: _transformCtrl,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.3,
          maxScale: 3.0,
          child: Container(
            width: _canvasWidth,
            height: _canvasHeight,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: CustomPaint(
              painter: _GridPainter(),
              child: Stack(
                clipBehavior: Clip.none,
                children: widget.tables.map((table) {
                  return _PositionedTable(
                    key: ValueKey(table.id),
                    table: table,
                    isSelected: table.id == selectedId,
                    isEditing: widget.isEditing,
                    onTap: () => widget.onTableTap?.call(table),
                    onMoved: (x, y) => widget.onTableMoved?.call(table, x, y),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Grid de fondo
// =============================================================================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey200.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += _cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// Mesa posicionada (soporta drag en modo editor)
// =============================================================================

class _PositionedTable extends StatefulWidget {
  final TableEntity table;
  final bool isSelected;
  final bool isEditing;
  final VoidCallback onTap;
  final void Function(double x, double y) onMoved;

  const _PositionedTable({
    super.key,
    required this.table,
    required this.isSelected,
    required this.isEditing,
    required this.onTap,
    required this.onMoved,
  });

  @override
  State<_PositionedTable> createState() => _PositionedTableState();
}

class _PositionedTableState extends State<_PositionedTable>
    with SingleTickerProviderStateMixin {
  late double _x;
  late double _y;
  bool _dragging = false;

  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _x = (widget.table.positionX ?? 0) * _cellSize;
    _y = (widget.table.positionY ?? 0) * _cellSize;

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant _PositionedTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) {
      _x = (widget.table.positionX ?? 0) * _cellSize;
      _y = (widget.table.positionY ?? 0) * _cellSize;
    }
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleCtrl.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _scaleCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    final w = table.width * _cellSize;
    final h = table.height * _cellSize;
    final color = tableStatusColor(table.status);

    Widget tableWidget = ScaleTransition(
      scale: _scaleAnim,
      child: _TableVisual(
        table: table,
        isSelected: widget.isSelected,
        isDragging: _dragging,
      ),
    );

    // Pulso luminoso al seleccionar
    if (widget.isSelected && !widget.isEditing) {
      tableWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          // Halo animado de fondo
          Positioned.fill(
            child: IgnorePointer(
              child:
                  Container(
                        decoration: BoxDecoration(
                          borderRadius: table.shape == TableShape.round
                              ? BorderRadius.circular(999)
                              : BorderRadius.circular(AppTheme.radiusMd + 4),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .boxShadow(
                        begin: BoxShadow(
                          color: color.withValues(alpha: 0.0),
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                        end: BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),
            ),
          ),
          tableWidget,
        ],
      );
    }

    if (widget.isEditing) {
      tableWidget = GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) {
          setState(() => _dragging = true);
          _scaleCtrl.forward();
        },
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
            // Clamp para mantener dentro del canvas
            final w = widget.table.width * _cellSize;
            final h = widget.table.height * _cellSize;
            _x = _x.clamp(0, _canvasWidth - w);
            _y = _y.clamp(0, _canvasHeight - h);
          });
        },
        onPanEnd: (_) {
          final w = widget.table.width * _cellSize;
          final h = widget.table.height * _cellSize;
          var snappedX = (_x / _cellSize).roundToDouble();
          var snappedY = (_y / _cellSize).roundToDouble();
          // Clamp en unidades de celda
          final maxX = ((_canvasWidth - w) / _cellSize).floorToDouble();
          final maxY = ((_canvasHeight - h) / _cellSize).floorToDouble();
          snappedX = snappedX.clamp(0, maxX);
          snappedY = snappedY.clamp(0, maxY);
          setState(() {
            _x = snappedX * _cellSize;
            _y = snappedY * _cellSize;
            _dragging = false;
          });
          _scaleCtrl.reverse();
          widget.onMoved(snappedX, snappedY);
        },
        child: tableWidget,
      );
    } else {
      tableWidget = GestureDetector(onTap: widget.onTap, child: tableWidget);
    }

    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: _x,
      top: _y,
      width: w,
      height: h,
      child: tableWidget,
    );
  }
}

// =============================================================================
// Widget visual de cada mesa
// =============================================================================

class _TableVisual extends StatelessWidget {
  final TableEntity table;
  final bool isSelected;
  final bool isDragging;

  const _TableVisual({
    required this.table,
    this.isSelected = false,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(table.status);
    final borderRadius = table.shape == TableShape.round
        ? BorderRadius.circular(999)
        : BorderRadius.circular(AppTheme.radiusMd);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: borderRadius,
        border: Border.all(
          color: isSelected ? AppColors.primary : color.withValues(alpha: 0.6),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isDragging || isSelected)
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Icono de reserva
          if (table.status == TableStatus.reserved)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                PhosphorIcons.bookmarkSimple(),
                size: 14,
                color: AppColors.tableReserved,
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre / número
                Text(
                  table.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Capacidad
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.users(),
                      size: 10,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${table.capacity}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Dot de estado
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Chip de estado reutilizable con color-coding semantico.
///
/// Usado en pedidos, mesas, reservaciones y entregas.
/// Estilo Nubank: pill redondeado con color de fondo suave.
class LomeStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  const LomeStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 10 : 12, color: color),
            SizedBox(width: compact ? 2 : 4),
          ],
          Text(
            label,
            style: AppTypography.badge(
              color: color,
            ).copyWith(fontSize: compact ? 9 : 11),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Factory helpers para estados comunes
  // ---------------------------------------------------------------------------

  factory LomeStatusChip.pending(String label) =>
      LomeStatusChip(label: label, color: AppColors.statusPending);

  factory LomeStatusChip.confirmed(String label) =>
      LomeStatusChip(label: label, color: AppColors.statusConfirmed);

  factory LomeStatusChip.preparing(String label) =>
      LomeStatusChip(label: label, color: AppColors.statusPreparing);

  factory LomeStatusChip.ready(String label) =>
      LomeStatusChip(label: label, color: AppColors.statusReady);

  factory LomeStatusChip.completed(String label) =>
      LomeStatusChip(label: label, color: AppColors.statusCompleted);

  factory LomeStatusChip.cancelled(String label) =>
      LomeStatusChip(label: label, color: AppColors.statusCancelled);
}

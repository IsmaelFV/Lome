import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/lome_button.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../../../../core/widgets/lome_app_bar.dart';
import '../../../../../core/widgets/tactile_wrapper.dart';
import '../providers/restaurant_hours_provider.dart';

/// Página de gestión de horarios del restaurante.
///
/// Muestra los 7 días de la semana con sus franjas horarias configuradas.
/// El administrador puede añadir, editar y eliminar franjas.
class RestaurantHoursPage extends ConsumerWidget {
  const RestaurantHoursPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoursState = ref.watch(restaurantHoursProvider);

    ref.listen<RestaurantHoursState>(restaurantHoursProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: LomeAppBar(title: context.l10n.restaurantHoursTitle),
      body: hoursState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              itemCount: 7,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacingSm),
              itemBuilder: (context, day) {
                final slots = hoursState.hoursForDay(day);
                final isOpen = slots.isNotEmpty;

                return _DayCard(
                  dayIndex: day,
                  slots: slots,
                  isOpen: isOpen,
                  onAddSlot: () =>
                      _showTimeDialog(context, ref, dayOfWeek: day),
                  onEditSlot: (h) => _showTimeDialog(context, ref, existing: h),
                  onDeleteSlot: (h) => ref
                      .read(restaurantHoursProvider.notifier)
                      .deleteHour(h.id!),
                )
                    .animate(delay: Duration(milliseconds: 50 * day))
                    .fadeIn(duration: AppTheme.durationFast)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
    );
  }

  void _showTimeDialog(
    BuildContext context,
    WidgetRef ref, {
    int? dayOfWeek,
    RestaurantHour? existing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _TimeSlotDialog(
        dayOfWeek: dayOfWeek ?? existing!.dayOfWeek,
        existing: existing,
      ),
    );
  }
}

// =============================================================================
// Day card
// =============================================================================

class _DayCard extends StatelessWidget {
  final int dayIndex;
  final List<RestaurantHour> slots;
  final bool isOpen;
  final VoidCallback onAddSlot;
  final ValueChanged<RestaurantHour> onEditSlot;
  final ValueChanged<RestaurantHour> onDeleteSlot;

  const _DayCard({
    required this.dayIndex,
    required this.slots,
    required this.isOpen,
    required this.onAddSlot,
    required this.onEditSlot,
    required this.onDeleteSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.success : AppColors.grey300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    RestaurantHour.dayName(dayIndex),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                ],
              ),
              TactileWrapper(
                onTap: onAddSlot,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    PhosphorIcons.plus(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (slots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spacingMd + 8,
                bottom: AppTheme.spacingXs,
              ),
              child: Text(
                context.l10n.restaurantHoursClosed,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey400,
                ),
              ),
            )
          else
            ...slots.map(
              (slot) => Padding(
                padding: const EdgeInsets.only(
                  left: AppTheme.spacingMd + 8,
                  bottom: AppTheme.spacingXs,
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.clock(PhosphorIconsStyle.duotone),
                      size: 14,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${slot.openTime} - ${slot.closeTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey700,
                      ),
                    ),
                    const Spacer(),
                    TactileWrapper(
                      onTap: () => onEditSlot(slot),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone),
                          size: 16,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TactileWrapper(
                      onTap: () => onDeleteSlot(slot),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Time slot dialog
// =============================================================================

class _TimeSlotDialog extends ConsumerStatefulWidget {
  final int dayOfWeek;
  final RestaurantHour? existing;

  const _TimeSlotDialog({required this.dayOfWeek, this.existing});

  @override
  ConsumerState<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends ConsumerState<_TimeSlotDialog> {
  late TimeOfDay _open;
  late TimeOfDay _close;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _open = _parseTime(widget.existing!.openTime);
      _close = _parseTime(widget.existing!.closeTime);
    } else {
      _open = const TimeOfDay(hour: 9, minute: 0);
      _close = const TimeOfDay(hour: 22, minute: 0);
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isOpen}) async {
    final current = isOpen ? _open : _close;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _open = picked;
        } else {
          _close = picked;
        }
      });
    }
  }

  void _save() {
    final openStr = _formatTime(_open);
    final closeStr = _formatTime(_close);

    if (openStr.compareTo(closeStr) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.restaurantHoursValidation),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ref
        .read(restaurantHoursProvider.notifier)
        .saveHour(
          id: widget.existing?.id,
          dayOfWeek: widget.dayOfWeek,
          openTime: openStr,
          closeTime: closeStr,
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayName = RestaurantHour.dayName(widget.dayOfWeek);

    return AlertDialog(
      title: Text(
        widget.existing != null
            ? context.l10n.restaurantHoursEditTitle(dayName)
            : context.l10n.restaurantHoursNewTitle(dayName),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.restaurantHoursOpenLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
            trailing: TextButton(
              onPressed: () => _pickTime(isOpen: true),
              child: Text(
                _formatTime(_open),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.restaurantHoursCloseLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.grey500,
              ),
            ),
            trailing: TextButton(
              onPressed: () => _pickTime(isOpen: false),
              child: Text(
                _formatTime(_close),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        LomeButton(label: context.l10n.save, onPressed: _save),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../tables/domain/entities/table_entity.dart';
import '../providers/reservations_provider.dart';

/// Bottom sheet para crear una nueva reserva.
///
/// Recibe la [table] para la que se crea la reserva.
class ReservationFormSheet extends ConsumerStatefulWidget {
  final TableEntity table;

  const ReservationFormSheet({super.key, required this.table});

  @override
  ConsumerState<ReservationFormSheet> createState() =>
      _ReservationFormSheetState();
}

class _ReservationFormSheetState extends ConsumerState<ReservationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _guests = 2;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingMd,
          AppTheme.spacingLg,
          MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Título
                Text(
                  'Reservar ${widget.table.displayName}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Nombre del cliente
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre del cliente',
                    prefixIcon: Icon(PhosphorIcons.user()),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Teléfono
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(PhosphorIcons.phone()),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Fecha y hora
                Row(
                  children: [
                    Expanded(
                      child: _DateSelector(
                        date: _date,
                        onChanged: (d) => setState(() => _date = d),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: _TimeSelector(
                        time: _time,
                        onChanged: (t) => setState(() => _time = t),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Número de personas
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.users(),
                      color: AppColors.grey400,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      'Personas',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(PhosphorIcons.minusCircle()),
                      onPressed: _guests > 1
                          ? () => setState(() => _guests--)
                          : null,
                    ),
                    Text(
                      '$_guests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.plusCircle()),
                      onPressed: _guests < widget.table.capacity
                          ? () => setState(() => _guests++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Notas
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(PhosphorIcons.notepad()),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Botón guardar
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(PhosphorIcons.bookmarkSimple()),
                  label: const Text('Confirmar reserva'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final reservationTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    try {
      await ref
          .read(reservationsProvider.notifier)
          .createReservation(
            tableId: widget.table.id,
            customerName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            reservationTime: reservationTime,
            guests: _guests,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
          );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }
}

// =============================================================================
// Selector de fecha
// =============================================================================

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DateSelector({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          prefixIcon: Icon(PhosphorIcons.calendar(), size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

// =============================================================================
// Selector de hora
// =============================================================================

class _TimeSelector extends StatelessWidget {
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimeSelector({required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hora',
          prefixIcon: Icon(PhosphorIcons.clock(), size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        child: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

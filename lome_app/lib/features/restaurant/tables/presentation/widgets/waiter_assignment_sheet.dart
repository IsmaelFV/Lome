import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions/context_extensions.dart';
import '../../domain/entities/table_entity.dart';
import '../providers/table_assignments_provider.dart';

/// Bottom sheet para asignar/desasignar un camarero a una mesa.
class WaiterAssignmentSheet extends ConsumerWidget {
  final TableEntity table;

  const WaiterAssignmentSheet({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAssignment = ref.watch(assignmentForTableProvider(table.id));
    final waitersAsync = ref.watch(availableWaitersProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
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

            // Título
            Text(
              'Asignar camarero – ${table.displayName}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Asignación actual
            if (currentAssignment != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Icon(
                        PhosphorIcons.user(),
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAssignment.waiterName ?? 'Camarero',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Asignado actualmente',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(tableAssignmentsProvider.notifier)
                            .unassignWaiter(table.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(PhosphorIcons.x(), size: 16),
                      label: Text(context.l10n.remove),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                context.l10n.changeTo,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],

            // Lista de camareros
            waitersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (waiters) {
                if (waiters.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Center(
                      child: Text(
                        'No hay camareros disponibles',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: waiters.length,
                    itemBuilder: (context, index) {
                      final w = waiters[index];
                      final userId = w['user_id'] as String;
                      final name =
                          (w['profiles'] as Map<String, dynamic>)['full_name']
                              as String?;
                      final isCurrentlyAssigned =
                          currentAssignment?.waiterId == userId;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.grey100,
                          child: Text(
                            (name ?? '?').substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey700,
                            ),
                          ),
                        ),
                        title: Text(
                          name ?? 'Sin nombre',
                          style: TextStyle(
                            fontWeight: isCurrentlyAssigned
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: isCurrentlyAssigned
                            ? Icon(
                                PhosphorIcons.checkCircle(),
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: isCurrentlyAssigned
                            ? null
                            : () async {
                                await ref
                                    .read(tableAssignmentsProvider.notifier)
                                    .assignWaiter(
                                      tableId: table.id,
                                      waiterId: userId,
                                    );
                                if (context.mounted) Navigator.pop(context);
                              },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

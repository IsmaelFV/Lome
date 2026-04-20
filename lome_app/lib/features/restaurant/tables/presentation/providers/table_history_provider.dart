import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/table_repository_impl.dart';
import '../../domain/entities/table_history_entry.dart';

// =============================================================================
// Provider: historial de uso de una mesa específica
// =============================================================================

final tableHistoryProvider = FutureProvider.family
    .autoDispose<List<TableHistoryEntry>, String>((ref, tableId) async {
      final repo = ref.read(tableRepositoryProvider);
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId == null) return [];

      final rows = await repo.getTableHistory(tenantId, tableId);

      return rows.map((r) => TableHistoryEntry.fromJson(r)).toList();
    });

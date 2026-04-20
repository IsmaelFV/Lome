import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Subscription stats (RPC)
// ---------------------------------------------------------------------------

final adminSubscriptionStatsProvider =
    FutureProvider<SubscriptionStats>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getSubscriptionStats();
  return SubscriptionStats.fromJson(response);
});

// ---------------------------------------------------------------------------
// All subscriptions
// ---------------------------------------------------------------------------

final adminSubscriptionFilterProvider =
    StateProvider<String>((_) => 'all'); // all, active, past_due, cancelled

final adminSubscriptionsProvider =
    FutureProvider<List<Subscription>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final filter = ref.watch(adminSubscriptionFilterProvider);

  final response = await repo.getSubscriptions(
    status: filter != 'all' ? filter : null,
  );

  return response
      .map((r) => Subscription.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// All invoices
// ---------------------------------------------------------------------------

final adminInvoiceFilterProvider =
    StateProvider<String>((_) => 'all'); // all, pending, paid, overdue

final adminInvoicesProvider =
    FutureProvider<List<Invoice>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final filter = ref.watch(adminInvoiceFilterProvider);

  final response = await repo.getInvoices(
    status: filter != 'all' ? filter : null,
  );

  return response
      .map((r) => Invoice.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// Update subscription
// ---------------------------------------------------------------------------

final updateSubscriptionProvider =
    FutureProvider.family<void, ({String id, Map<String, dynamic> data})>(
        (ref, params) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.updateSubscription(params.id, params.data);

  ref.invalidate(adminSubscriptionsProvider);
  ref.invalidate(adminSubscriptionStatsProvider);
});

// ---------------------------------------------------------------------------
// Mark invoice as paid
// ---------------------------------------------------------------------------

final markInvoicePaidProvider =
    FutureProvider.family<void, String>((ref, invoiceId) async {
  final repo = ref.read(adminRepositoryProvider);
  await repo.markInvoicePaid(invoiceId);

  ref.invalidate(adminInvoicesProvider);
  ref.invalidate(adminSubscriptionStatsProvider);
});

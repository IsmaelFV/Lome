import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/marketplace_repository_impl.dart';
import '../../../domain/entities/review_entities.dart';

// ---------------------------------------------------------------------------
// Reviews de un restaurante
// ---------------------------------------------------------------------------

final restaurantReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, tenantId) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final data = await repo.getRestaurantReviews(tenantId);
  return data
      .map((r) => Review.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// Verificar si el usuario ya valoró un pedido
// ---------------------------------------------------------------------------

final hasReviewedOrderProvider =
    FutureProvider.family<bool, String>((ref, orderId) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser?.id;
  if (userId == null) return false;
  final response = await repo.getUserReviewForOrder(userId, orderId);
  return response != null;
});

// ---------------------------------------------------------------------------
// Enviar valoración
// ---------------------------------------------------------------------------

class ReviewSubmission {
  final String tenantId;
  final String orderId;
  final int rating;
  final String? comment;

  const ReviewSubmission({
    required this.tenantId,
    required this.orderId,
    required this.rating,
    this.comment,
  });
}

final submitReviewProvider =
    FutureProvider.family<void, ReviewSubmission>((ref, submission) async {
  final repo = ref.read(marketplaceRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;

  await repo.submitReview({
    'tenant_id': submission.tenantId,
    'user_id': userId,
    'order_id': submission.orderId,
    'rating': submission.rating,
    'comment': submission.comment,
  });

  ref.invalidate(restaurantReviewsProvider(submission.tenantId));
  ref.invalidate(hasReviewedOrderProvider(submission.orderId));
});

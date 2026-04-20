import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/admin_repository_impl.dart';
import '../../../domain/entities/admin_entities.dart';

// ---------------------------------------------------------------------------
// Flagged reviews for moderation
// ---------------------------------------------------------------------------

final flaggedReviewsProvider =
    FutureProvider<List<FlaggedReview>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  final response = await repo.getFlaggedReviews();

  return response
      .map((r) => FlaggedReview.fromJson(r))
      .toList();
});

// ---------------------------------------------------------------------------
// Approve review (unflag and keep visible)
// ---------------------------------------------------------------------------

final approveReviewProvider =
    FutureProvider.family<void, String>((ref, reviewId) async {
  final repo = ref.read(adminRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;
  await repo.approveReview(reviewId, moderatedBy: userId);

  ref.invalidate(flaggedReviewsProvider);
});

// ---------------------------------------------------------------------------
// Reject review (hide and unflag)
// ---------------------------------------------------------------------------

final rejectReviewProvider =
    FutureProvider.family<void, String>((ref, reviewId) async {
  final repo = ref.read(adminRepositoryProvider);
  final userId = SupabaseConfig.auth.currentUser!.id;
  await repo.rejectReview(reviewId, moderatedBy: userId);

  ref.invalidate(flaggedReviewsProvider);
});

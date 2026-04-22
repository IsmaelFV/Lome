/// Contrato del repositorio del marketplace.
///
/// Agrupa: restaurantes, menú público, reseñas, favoritos, promociones,
/// recomendaciones.
abstract class MarketplaceRepository {
  // ---------------------------------------------------------------------------
  // Restaurantes
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRestaurants({
    String? status,
    bool? deliveryOnly,
    bool? featuredOnly,
    String? cuisineType,
    int limit = 50,
  });

  Future<Map<String, dynamic>?> getRestaurantDetail(String restaurantId);

  Future<List<String>> getCuisineTypes();

  // ---------------------------------------------------------------------------
  // Menú público
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMenuCategories(String tenantId);

  Future<List<Map<String, dynamic>>> getMenuItems(
    String tenantId, {
    String? categoryId,
  });

  /// Busca platos globalmente por nombre (ilike).
  Future<List<Map<String, dynamic>>> searchDishes(
    String query, {
    int limit = 20,
  });

  /// Busca restaurantes por nombre (ilike).
  Future<List<Map<String, dynamic>>> searchRestaurants(
    String query, {
    int limit = 15,
  });

  // ---------------------------------------------------------------------------
  // Reseñas
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRestaurantReviews(String tenantId);

  Future<Map<String, dynamic>?> getUserReviewForOrder(
    String userId,
    String orderId,
  );

  Future<void> submitReview(Map<String, dynamic> data);

  // ---------------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------------

  Future<List<String>> getFavoriteIds(String userId);

  Future<bool> isFavorite(String userId, String tenantId);

  Future<void> addFavorite(String userId, String tenantId);

  Future<void> removeFavorite(String userId, String tenantId);

  Future<List<Map<String, dynamic>>> getFavoriteRestaurants(
    List<String> tenantIds,
  );

  // ---------------------------------------------------------------------------
  // Promociones y recomendaciones
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getActivePromotions();

  Future<List<Map<String, dynamic>>> getRestaurantPromotions(String tenantId);

  Future<List<Map<String, dynamic>>> getRecommendedRestaurants(String userId);
}

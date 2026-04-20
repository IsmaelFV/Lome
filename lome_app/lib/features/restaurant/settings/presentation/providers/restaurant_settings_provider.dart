import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/cloudinary_service.dart';
import '../../../data/repositories/restaurant_config_repository_impl.dart';
import '../../../domain/repositories/restaurant_config_repository.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

// =============================================================================
// Modelo
// =============================================================================

class RestaurantData {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? phone;
  final String? email;
  final String? website;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final List<String> cuisineType;

  const RestaurantData({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.phone,
    this.email,
    this.website,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.cuisineType = const [],
  });

  factory RestaurantData.fromJson(Map<String, dynamic> json) {
    return RestaurantData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      cuisineType:
          (json['cuisine_type'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  RestaurantData copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? phone,
    String? email,
    String? website,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    List<String>? cuisineType,
  }) {
    return RestaurantData(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      cuisineType: cuisineType ?? this.cuisineType,
    );
  }
}

// =============================================================================
// State
// =============================================================================

class RestaurantSettingsState {
  final RestaurantData? data;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const RestaurantSettingsState({
    this.data,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  RestaurantSettingsState copyWith({
    RestaurantData? data,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RestaurantSettingsState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final restaurantSettingsProvider =
    StateNotifierProvider.autoDispose<
      RestaurantSettingsNotifier,
      RestaurantSettingsState
    >((ref) {
      final repo = ref.watch(restaurantConfigRepositoryProvider);
      final tenantId = ref.watch(activeTenantIdProvider);
      return RestaurantSettingsNotifier(repo, tenantId);
    });

class RestaurantSettingsNotifier
    extends StateNotifier<RestaurantSettingsState> {
  final RestaurantConfigRepository _repo;
  final String? _tenantId;

  RestaurantSettingsNotifier(this._repo, this._tenantId)
    : super(const RestaurantSettingsState()) {
    if (_tenantId != null) loadData();
  }

  Future<void> loadData() async {
    if (_tenantId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final row = await _repo.getRestaurantData(_tenantId);
      if (!mounted) return;

      state = state.copyWith(
        data: RestaurantData.fromJson(row),
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar los datos: $e',
      );
    }
  }

  Future<void> save(RestaurantData updated) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _repo.updateRestaurantData(_tenantId!, {
        'name': updated.name,
        'description': updated.description,
        'phone': updated.phone,
        'email': updated.email,
        'website': updated.website,
        'address_line1': updated.addressLine1,
        'address_line2': updated.addressLine2,
        'city': updated.city,
        'state': updated.state,
        'postal_code': updated.postalCode,
        'country': updated.country,
        'cuisine_type': updated.cuisineType,
      });
      if (!mounted) return;

      state = state.copyWith(
        data: updated,
        isSaving: false,
        successMessage: 'Datos guardados correctamente',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar: $e',
      );
    }
  }

  Future<void> uploadLogo(Uint8List bytes) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final url = await CloudinaryService.uploadImage(
        bytes: bytes,
        folder: 'lome/restaurants/$_tenantId',
        publicId: 'logo',
      );
      if (!mounted) return;

      final optimized = CloudinaryService.optimizedUrl(
        url,
        width: 300,
        height: 300,
      );

      await _repo.updateLogoUrl(_tenantId!, optimized);
      if (!mounted) return;

      state = state.copyWith(
        data: state.data?.copyWith(logoUrl: optimized),
        isSaving: false,
        successMessage: 'Logo actualizado',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al subir el logo: $e',
      );
    }
  }
}

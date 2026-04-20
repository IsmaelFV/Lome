import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../data/repositories/customer_order_repository_impl.dart';
import '../../../domain/entities/checkout_entities.dart';
import '../../../domain/repositories/customer_order_repository.dart';

// ---------------------------------------------------------------------------
// Direcciones del cliente
// ---------------------------------------------------------------------------

/// Lista de direcciones del usuario autenticado.
final customerAddressesProvider =
    FutureProvider.autoDispose<List<DeliveryAddress>>((ref) async {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) return [];

      final repo = ref.read(customerOrderRepositoryProvider);
      final data = await repo.getAddresses(userId);
      return data.map((json) => DeliveryAddress.fromJson(json)).toList();
    });

/// Dirección seleccionada para el checkout.
final selectedAddressProvider = StateProvider<DeliveryAddress?>((ref) => null);

// ---------------------------------------------------------------------------
// CRUD de direcciones
// ---------------------------------------------------------------------------

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService(ref.read(customerOrderRepositoryProvider));
});

class AddressService {
  final CustomerOrderRepository _repo;

  AddressService(this._repo);

  Future<DeliveryAddress> createAddress({
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    String? state,
    required String postalCode,
    String? instructions,
    bool isDefault = false,
  }) async {
    final userId = SupabaseConfig.auth.currentUser!.id;

    if (isDefault) {
      await _repo.clearDefaultAddresses(userId);
    }

    final data = await _repo.createAddress({
      'user_id': userId,
      'label': label,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'instructions': instructions,
      'is_default': isDefault,
    });

    return DeliveryAddress.fromJson(data);
  }

  Future<void> deleteAddress(String addressId) async {
    await _repo.softDeleteAddress(addressId);
  }

  Future<void> setDefault(String addressId) async {
    final userId = SupabaseConfig.auth.currentUser!.id;
    await _repo.clearDefaultAddresses(userId);
    await _repo.setDefaultAddress(addressId);
  }
}

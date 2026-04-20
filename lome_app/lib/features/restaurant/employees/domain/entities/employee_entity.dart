import 'package:equatable/equatable.dart';

/// Entidad de empleado del restaurante.
class EmployeeEntity extends Equatable {
  final String id;
  final String userId;
  final String tenantId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const EmployeeEntity({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Propietario';
      case 'manager':
        return 'Gerente';
      case 'waiter':
        return 'Camarero';
      case 'kitchen':
        return 'Cocina';
      case 'viewer':
        return 'Observador';
      default:
        return role;
    }
  }

  @override
  List<Object?> get props => [id, userId, role, isActive];
}

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../../core/errors/exceptions.dart';
import '../../domain/entities/employee_entity.dart';
import '../models/invitation_model.dart';

/// Datasource remoto para gestionar invitaciones en Supabase.
///
/// Tabla esperada: `invitations`
/// Columnas: id, tenant_id, email, role, invited_by, status, token,
///           created_at, expires_at, accepted_at
abstract class InvitationRemoteDataSource {
  Future<InvitationModel> sendInvitation({
    required String tenantId,
    required String email,
    required String role,
  });

  Future<List<InvitationModel>> getInvitations({
    required String tenantId,
    String? filterStatus,
  });

  Future<void> cancelInvitation({required String invitationId});

  Future<InvitationModel> resendInvitation({required String invitationId});

  Future<void> acceptInvitation({required String invitationId});

  Future<void> rejectInvitation({required String invitationId});

  Future<void> removeEmployee({
    required String tenantId,
    required String membershipId,
  });

  Future<void> updateEmployeeRole({
    required String membershipId,
    required String newRole,
  });

  Future<List<EmployeeEntity>> getEmployees({required String tenantId});
}

class InvitationRemoteDataSourceImpl implements InvitationRemoteDataSource {
  final SupabaseClient _client;

  InvitationRemoteDataSourceImpl({required SupabaseClient client})
    : _client = client;

  @override
  Future<InvitationModel> sendInvitation({
    required String tenantId,
    required String email,
    required String role,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'No hay sesión activa');
      }

      // Verificar que no exista invitación pendiente duplicada
      final existing = await _client
          .from('invitations')
          .select()
          .eq('tenant_id', tenantId)
          .eq('email', email.toLowerCase().trim())
          .eq('status', 'pending')
          .maybeSingle();

      if (existing != null) {
        throw const ServerException(
          message: 'Ya existe una invitación pendiente para este email',
        );
      }

      // Verificar que el email no sea ya miembro del tenant
      final existingMember = await _client
          .from('profiles')
          .select(
            'id, tenant_memberships!tenant_memberships_user_id_fkey!inner(tenant_id)',
          )
          .eq('email', email.toLowerCase().trim())
          .eq('tenant_memberships.tenant_id', tenantId)
          .maybeSingle();

      if (existingMember != null) {
        throw const ServerException(
          message: 'Este usuario ya es miembro del restaurante',
        );
      }

      // Crear la invitación con expiración de 7 días
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      final response = await _client
          .from('invitations')
          .insert({
            'tenant_id': tenantId,
            'email': email.toLowerCase().trim(),
            'role': role,
            'invited_by': currentUser.id,
            'status': 'pending',
            'expires_at': expiresAt.toIso8601String(),
          })
          .select('''
            *,
            tenants (name),
            inviter:profiles!invited_by (full_name)
          ''')
          .single();

      // Invocar Edge Function para enviar email de invitación
      try {
        await _client.functions.invoke(
          'send-invitation-email',
          body: {
            'invitation_id': response['id'],
            'email': email.toLowerCase().trim(),
            'tenant_name': response['tenants']?['name'] ?? '',
            'role': role,
            'invited_by_name': response['inviter']?['full_name'] ?? '',
            'tenant_id': tenantId,
          },
        );
      } catch (_) {
        // El email es best-effort; la invitación ya se creó
      }

      return InvitationModel.fromJson(response);
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Error al enviar la invitación: $e');
    }
  }

  @override
  Future<List<InvitationModel>> getInvitations({
    required String tenantId,
    String? filterStatus,
  }) async {
    try {
      var query = _client
          .from('invitations')
          .select('''
            *,
            tenants (name),
            inviter:profiles!invited_by (full_name)
          ''')
          .eq('tenant_id', tenantId);

      if (filterStatus != null) {
        query = query.eq('status', filterStatus);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => InvitationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Error al obtener invitaciones: $e');
    }
  }

  @override
  Future<void> cancelInvitation({required String invitationId}) async {
    try {
      await _client
          .from('invitations')
          .update({'status': 'cancelled'})
          .eq('id', invitationId)
          .eq('status', 'pending');
    } catch (e) {
      throw ServerException(message: 'Error al cancelar la invitación: $e');
    }
  }

  @override
  Future<InvitationModel> resendInvitation({
    required String invitationId,
  }) async {
    try {
      final newExpiry = DateTime.now().add(const Duration(days: 7));

      final response = await _client
          .from('invitations')
          .update({
            'expires_at': newExpiry.toIso8601String(),
            'status': 'pending',
          })
          .eq('id', invitationId)
          .select('''
            *,
            tenants (name),
            inviter:profiles!invited_by (full_name)
          ''')
          .single();

      // Reenviar email
      try {
        await _client.functions.invoke(
          'send-invitation-email',
          body: {
            'invitation_id': response['id'],
            'email': response['email'],
            'tenant_name': response['tenants']?['name'] ?? '',
            'role': response['role'],
            'invited_by_name': response['inviter']?['full_name'] ?? '',
            'tenant_id': response['tenant_id'],
          },
        );
      } catch (_) {
        // Email best-effort
      }

      return InvitationModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Error al reenviar la invitación: $e');
    }
  }

  @override
  Future<void> acceptInvitation({required String invitationId}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'No hay sesión activa');
      }

      // Obtener la invitación
      final invitation = await _client
          .from('invitations')
          .select()
          .eq('id', invitationId)
          .eq('status', 'pending')
          .single();

      // Verificar que no ha expirado
      final expiresAt = DateTime.parse(invitation['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        await _client
            .from('invitations')
            .update({'status': 'expired'})
            .eq('id', invitationId);
        throw const ServerException(message: 'La invitación ha expirado');
      }

      // Crear la membresía
      await _client.from('tenant_memberships').insert({
        'user_id': currentUser.id,
        'tenant_id': invitation['tenant_id'],
        'role': invitation['role'],
        'is_active': true,
      });

      // Marcar invitación como aceptada
      await _client
          .from('invitations')
          .update({
            'status': 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Error al aceptar la invitación: $e');
    }
  }

  @override
  Future<void> rejectInvitation({required String invitationId}) async {
    try {
      await _client
          .from('invitations')
          .update({'status': 'rejected'})
          .eq('id', invitationId)
          .eq('status', 'pending');
    } catch (e) {
      throw ServerException(message: 'Error al rechazar la invitación: $e');
    }
  }

  @override
  Future<void> removeEmployee({
    required String tenantId,
    required String membershipId,
  }) async {
    try {
      await _client
          .from('tenant_memberships')
          .update({'is_active': false})
          .eq('id', membershipId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw ServerException(message: 'Error al eliminar el empleado: $e');
    }
  }

  @override
  Future<void> updateEmployeeRole({
    required String membershipId,
    required String newRole,
  }) async {
    try {
      await _client
          .from('tenant_memberships')
          .update({'role': newRole})
          .eq('id', membershipId);
    } catch (e) {
      throw ServerException(message: 'Error al actualizar el rol: $e');
    }
  }

  @override
  Future<List<EmployeeEntity>> getEmployees({required String tenantId}) async {
    try {
      final response = await _client
          .from('tenant_memberships')
          .select('''
            id, user_id, tenant_id, role, is_active, created_at,
            profiles!user_id (full_name, email, phone, avatar_url)
          ''')
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('created_at');

      return (response as List).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>? ?? {};
        return EmployeeEntity(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          tenantId: json['tenant_id'] as String,
          fullName: profile['full_name'] as String? ?? 'Sin nombre',
          email: profile['email'] as String? ?? '',
          phone: profile['phone'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
          role: json['role'] as String,
          isActive: json['is_active'] as bool? ?? true,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw ServerException(message: 'Error al obtener empleados: $e');
    }
  }
}

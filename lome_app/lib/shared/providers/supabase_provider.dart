import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Provider del cliente Supabase.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseConfig.client;
});

/// Provider del servicio de autenticacion de Supabase.
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return SupabaseConfig.auth;
});

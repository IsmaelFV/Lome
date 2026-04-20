import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

/// Inicializacion y acceso global al cliente Supabase.
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Inicializa Supabase. Debe llamarse antes de runApp.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shortcuts
  // -------------------------------------------------------------------------

  static GoTrueClient get auth => client.auth;
  static SupabaseQueryBuilder Function(String table) get from => client.from;
  static RealtimeChannel Function(String name) get channel => client.channel;
  static SupabaseStorageClient get storage => client.storage;
}

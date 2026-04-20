// supabase/functions/delete-account/index.ts
//
// Edge Function: Eliminación / anonimización de cuenta de usuario (GDPR).
//
// Estrategia: ANONIMIZACIÓN en lugar de borrado físico.
// - Los datos personales se eliminan o reemplazan con valores genéricos.
// - Las referencias existentes (pedidos, movimientos, etc.) mantienen el
//   user_id intacto para preservar la integridad referencial.
// - La cuenta de auth se desactiva/elimina para impedir el acceso.
//
// Flujo:
// 1. Verificar que el usuario autenticado solicita eliminar SU propia cuenta.
// 2. Anonimizar los datos del perfil:
//    - full_name → 'Usuario eliminado'
//    - email → '<hash>@deleted.lome.app'
//    - phone → null
//    - avatar_url → null
//    - is_active → false
// 3. Desactivar todas las membresías del usuario (is_active = false).
// 4. Cancelar todas las invitaciones pendientes enviadas por el usuario.
// 5. Eliminar direcciones de envío del usuario.
// 6. Eliminar la cuenta de auth (auth.users) para impedir login futuro.
//
// Las tablas que referencian al usuario (orders.customer_id, orders.waiter_id,
// order_items.prepared_by, table_sessions.opened_by, inventory_movements.performed_by)
// conservan el UUID pero los datos personales ya están anonimizados en profiles.
//
// Seguridad:
// - Solo el propio usuario (JWT) o un super_admin puede ejecutar esta función.
// - Se usa el service_role key para operaciones admin (borrar auth.users).

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Manejo de CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Autenticar al usuario que invoca la función ──

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No autorizado" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Cliente con permisos del usuario (para verificar identidad)
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: { headers: { Authorization: authHeader } },
      },
    );

    const {
      data: { user },
      error: authError,
    } = await supabaseUser.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Sesión inválida" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2. Leer el body ──

    const { user_id } = await req.json();

    // El usuario solo puede eliminar su propia cuenta,
    // a menos que sea super_admin.
    if (user_id !== user.id) {
      // Verificar si es super_admin
      const { data: profile } = await supabaseUser
        .from("profiles")
        .select("is_super_admin")
        .eq("id", user.id)
        .single();

      if (!profile?.is_super_admin) {
        return new Response(
          JSON.stringify({ error: "Solo puedes eliminar tu propia cuenta" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    // ── 3. Cliente con service_role para operaciones admin ──

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // ── 4. Anonimizar el perfil ──
    // Generar un hash corto para el email anonimizado
    const anonHash = crypto.randomUUID().slice(0, 8);

    const { error: profileError } = await supabaseAdmin
      .from("profiles")
      .update({
        full_name: "Usuario eliminado",
        email: `${anonHash}@deleted.lome.app`,
        phone: null,
        avatar_url: null,
        is_active: false,
        metadata: { deleted_at: new Date().toISOString() },
      })
      .eq("id", user_id);

    if (profileError) {
      throw new Error(`Error al anonimizar perfil: ${profileError.message}`);
    }

    // ── 5. Desactivar todas las membresías ──

    const { error: membershipError } = await supabaseAdmin
      .from("tenant_memberships")
      .update({ is_active: false })
      .eq("user_id", user_id);

    if (membershipError) {
      throw new Error(`Error al desactivar membresías: ${membershipError.message}`);
    }

    // ── 6. Cancelar invitaciones pendientes enviadas por este usuario ──

    await supabaseAdmin
      .from("invitations")
      .update({ status: "cancelled" })
      .eq("invited_by", user_id)
      .eq("status", "pending");

    // ── 7. Eliminar direcciones de envío ──

    await supabaseAdmin
      .from("customer_addresses")
      .delete()
      .eq("user_id", user_id);

    // ── 8. Eliminar la cuenta de auth ──
    // Esto invalida todos los tokens y impide futuro login.

    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
      user_id,
    );

    if (deleteAuthError) {
      throw new Error(`Error al eliminar cuenta auth: ${deleteAuthError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Cuenta eliminada y datos anonimizados correctamente",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

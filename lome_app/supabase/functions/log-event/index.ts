// supabase/functions/log-event/index.ts
//
// Edge Function: Registro centralizado de eventos de monitorización.
//
// Recibe lotes de eventos desde Flutter (errores, métricas API, etc.)
// y los inserta en las tablas correspondientes.
//
// Endpoints:
//   POST /log-event  { type: "error" | "api_usage" | "audit", payload: {...} }
//   POST /log-event  { type: "batch", events: [...] }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Autenticar al usuario ──
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No autorizado" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Verificar JWT
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Sesión inválida" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // ── 2. Parse request body ──
    const body = await req.json();
    const { type } = body;

    // ── 3. Procesar según tipo ──
    if (type === "batch") {
      // Procesar lote de eventos
      const events = body.events as Array<{ type: string; payload: Record<string, unknown> }>;
      if (!Array.isArray(events) || events.length === 0) {
        return new Response(
          JSON.stringify({ error: "Se requiere un array 'events' no vacío" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      // Limitar a 100 eventos por lote
      const batch = events.slice(0, 100);
      const results = { errors: 0, api_usage: 0, audit: 0, failed: 0 };

      for (const event of batch) {
        try {
          await processEvent(supabase, user.id, event.type, event.payload);
          if (event.type in results) {
            results[event.type as keyof typeof results]++;
          }
        } catch {
          results.failed++;
        }
      }

      return new Response(
        JSON.stringify({ success: true, processed: results }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Evento individual
    const { payload } = body;
    if (!type || !payload) {
      return new Response(
        JSON.stringify({ error: "Se requiere 'type' y 'payload'" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const result = await processEvent(supabase, user.id, type, payload);

    return new Response(
      JSON.stringify({ success: true, id: result }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error interno";
    return new Response(
      JSON.stringify({ error: message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

// ── Procesador de eventos ──

async function processEvent(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  type: string,
  payload: Record<string, unknown>,
): Promise<string | null> {
  switch (type) {
    case "error": {
      const { data, error } = await supabase.from("error_logs").insert({
        user_id: userId,
        severity: payload.severity ?? "error",
        source: payload.source ?? "flutter",
        message: payload.message,
        stack_trace: payload.stack_trace ?? null,
        tenant_id: payload.tenant_id ?? null,
        device_info: payload.device_info ?? {},
        app_version: payload.app_version ?? null,
        context: payload.context ?? {},
      }).select("id").single();

      if (error) throw new Error(error.message);
      return data?.id ?? null;
    }

    case "api_usage": {
      const { data, error } = await supabase.from("api_usage_logs").insert({
        user_id: userId,
        tenant_id: payload.tenant_id ?? null,
        endpoint: payload.endpoint,
        method: payload.method ?? "GET",
        status_code: payload.status_code ?? null,
        response_time_ms: payload.response_time_ms ?? null,
        request_size_bytes: payload.request_size_bytes ?? null,
        response_size_bytes: payload.response_size_bytes ?? null,
        metadata: payload.metadata ?? {},
      }).select("id").single();

      if (error) throw new Error(error.message);
      return data?.id ?? null;
    }

    case "audit": {
      const { data, error } = await supabase.from("audit_logs").insert({
        user_id: userId,
        tenant_id: payload.tenant_id ?? null,
        action: payload.action,
        entity_type: payload.entity_type,
        entity_id: payload.entity_id ?? null,
        new_data: payload.new_data ?? null,
        metadata: payload.metadata ?? {},
      }).select("id").single();

      if (error) throw new Error(error.message);
      return data?.id ?? null;
    }

    default:
      throw new Error(`Tipo de evento no soportado: ${type}`);
  }
}

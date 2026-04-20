// ============================================================================
// Edge Function: send-push-notification
//
// Disparada por Database Webhook al INSERT en `notifications`.
// Busca los device_tokens del usuario destinatario y envía push via FCM v1.
//
// Secrets requeridos (configurar en Supabase Dashboard → Edge Functions):
//   FIREBASE_SERVICE_ACCOUNT  — JSON completo de la service account de Firebase
// ============================================================================

import { serve } from "std/http/server.ts";
import { createClient } from "@supabase/supabase-js";

// ── Mapeo tipo → categoría de preferencia ──

const TYPE_CATEGORY: Record<string, string> = {
  new_order: "orders",
  order_ready: "orders",
  order_update: "orders",
  new_review: "reviews",
  low_stock: "stock",
  admin_message: "system",
  incident: "system",
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();

    // El webhook envía { type: 'INSERT', table: 'notifications', record: {...} }
    const record = body.record ?? body;

    if (!record?.user_id || !record?.title) {
      return new Response(
        JSON.stringify({ error: "Payload inválido: falta user_id o title" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { user_id, title, body: notifBody, type, data } = record;
    const category = TYPE_CATEGORY[type] || "system";

    // ── Cliente Supabase con service_role ──

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // ── Obtener tokens del usuario ──

    const { data: tokens, error: tokensError } = await supabase
      .from("device_tokens")
      .select("token, platform, preferences")
      .eq("user_id", user_id)
      .eq("push_enabled", true);

    if (tokensError) {
      console.error("Error consultando tokens:", tokensError.message);
      return new Response(
        JSON.stringify({ sent: 0, error: tokensError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!tokens?.length) {
      return new Response(
        JSON.stringify({ sent: 0, reason: "no_tokens" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Filtrar por preferencias de categoría ──

    interface DeviceToken {
      token: string;
      platform: string;
      preferences: Record<string, boolean>;
    }

    const eligible = (tokens as DeviceToken[]).filter((t) => {
      const prefs = t.preferences || {};
      return prefs[category] !== false; // true por defecto
    });

    if (!eligible.length) {
      return new Response(
        JSON.stringify({ sent: 0, reason: "category_disabled" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Obtener access token de Firebase ──

    const accessToken = await getFirebaseAccessToken();
    const projectId = getProjectId();

    if (!accessToken || !projectId) {
      return new Response(
        JSON.stringify({ error: "Firebase no configurado" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Enviar FCM a cada dispositivo ──

    const results = await Promise.allSettled(
      eligible.map((t) =>
        sendFCMMessage(accessToken, projectId, t.token, {
          title,
          body: notifBody || "",
          type: type || "general",
          data: data || {},
        })
      ),
    );

    // ── Limpiar tokens inválidos ──

    const invalidTokens: string[] = [];
    results.forEach((r, i) => {
      if (r.status === "rejected") {
        const reason = String(r.reason?.message || r.reason || "");
        if (
          reason.includes("NOT_FOUND") ||
          reason.includes("UNREGISTERED") ||
          reason.includes("INVALID_ARGUMENT")
        ) {
          invalidTokens.push(eligible[i].token);
        }
      }
    });

    if (invalidTokens.length) {
      await supabase
        .from("device_tokens")
        .delete()
        .in("token", invalidTokens);
      console.log(`Tokens inválidos eliminados: ${invalidTokens.length}`);
    }

    const sent = results.filter((r) => r.status === "fulfilled").length;
    console.log(`Push enviados: ${sent}/${eligible.length}`);

    return new Response(
      JSON.stringify({ sent, total: eligible.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Error en send-push-notification:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

// =============================================================================
// FCM HTTP v1 API
// =============================================================================

function getProjectId(): string {
  try {
    const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}");
    return sa.project_id || "";
  } catch {
    return "";
  }
}

async function getFirebaseAccessToken(): Promise<string> {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT no configurado");

  const sa = JSON.parse(raw);
  const now = Math.floor(Date.now() / 1000);

  // ── Crear JWT ──

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const encodedHeader = base64url(
    new TextEncoder().encode(JSON.stringify(header)),
  );
  const encodedPayload = base64url(
    new TextEncoder().encode(JSON.stringify(payload)),
  );
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  // ── Importar clave privada RSA ──

  const binaryKey = pemToBinary(sa.private_key);
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // ── Firmar ──

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );
  const encodedSignature = base64url(new Uint8Array(signature));
  const jwt = `${signingInput}.${encodedSignature}`;

  // ── Intercambiar por access token ──

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!response.ok) {
    throw new Error(`Token exchange falló: ${await response.text()}`);
  }

  const { access_token } = await response.json();
  return access_token;
}

async function sendFCMMessage(
  accessToken: string,
  projectId: string,
  token: string,
  notification: {
    title: string;
    body: string;
    type: string;
    data: Record<string, unknown>;
  },
): Promise<unknown> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: {
            type: notification.type,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            ...Object.fromEntries(
              Object.entries(notification.data).map(([k, v]) => [
                k,
                String(v),
              ]),
            ),
          },
          android: {
            priority: "high",
            notification: {
              channel_id: "lome_notifications",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
          webpush: {
            notification: {
              icon: "/icons/Icon-192.png",
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody);
  }

  return response.json();
}

// =============================================================================
// Helpers
// =============================================================================

function base64url(data: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < data.length; i++) {
    binary += String.fromCharCode(data[i]);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToBinary(pem: string): ArrayBuffer {
  const lines = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(lines);
  const buffer = new ArrayBuffer(binary.length);
  const view = new Uint8Array(buffer);
  for (let i = 0; i < binary.length; i++) {
    view[i] = binary.charCodeAt(i);
  }
  return buffer;
}

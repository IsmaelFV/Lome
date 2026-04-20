// supabase/functions/send-invitation-email/index.ts
//
// Edge Function: Envío de email de invitación a empleados.
//
// Flujo:
// 1. Recibe invitation_id, email, tenant_name, role, invited_by_name.
// 2. Obtiene la plantilla personalizada del tenant (o usa defaults).
// 3. Renderiza el HTML del email con las variables sustituidas.
// 4. Envía el email vía Resend API.
//
// Variables de entorno requeridas:
// - RESEND_API_KEY: API key de Resend (https://resend.com/api-keys)
// - APP_URL: URL base de la app (ej: https://lome.app)
//
// Variables disponibles en las plantillas:
// - {restaurant}: nombre del restaurante
// - {inviter}: nombre de quien invita
// - {role}: rol asignado
// - {email}: email del invitado
// - {expire_date}: fecha de expiración de la invitación

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ── Mapa de roles legibles ──────────────────────────────────────────────────

const ROLE_LABELS: Record<string, string> = {
  owner: "Propietario",
  manager: "Gerente",
  chef: "Chef",
  waiter: "Camarero/a",
  cashier: "Cajero/a",
  customer: "Cliente",
};

// ── Estilos base por template_style ─────────────────────────────────────────

interface TemplateColors {
  primary: string;
  secondary: string;
  background: string;
  button: string;
  text: string;
  accent: string;
}

const TEMPLATE_PRESETS: Record<string, TemplateColors> = {
  professional: {
    primary: "#1A1A2E",
    secondary: "#16213E",
    background: "#F8F9FA",
    button: "#0F3460",
    text: "#2D3436",
    accent: "#E94560",
  },
  casual: {
    primary: "#FF6B35",
    secondary: "#2D3436",
    background: "#FFF8F0",
    button: "#FF6B35",
    text: "#2D3436",
    accent: "#FDCB6E",
  },
  elegant: {
    primary: "#2C3E50",
    secondary: "#8E6F47",
    background: "#FAF8F5",
    button: "#8E6F47",
    text: "#2C3E50",
    accent: "#D4A574",
  },
  minimal: {
    primary: "#000000",
    secondary: "#666666",
    background: "#FFFFFF",
    button: "#000000",
    text: "#333333",
    accent: "#999999",
  },
  colorful: {
    primary: "#6C5CE7",
    secondary: "#A29BFE",
    background: "#F8F7FF",
    button: "#6C5CE7",
    text: "#2D3436",
    accent: "#FD79A8",
  },
};

// ── Renderizado de HTML ─────────────────────────────────────────────────────

interface TemplateData {
  templateStyle: string;
  primaryColor: string;
  secondaryColor: string;
  backgroundColor: string;
  buttonColor: string;
  textColor: string;
  accentColor: string;
  logoUrl: string | null;
  showLogo: boolean;
  showRestaurantInfo: boolean;
  subjectLine: string;
  headerText: string;
  bodyText: string;
  buttonText: string;
  footerText: string;
  declineText: string;
}

interface EmailVars {
  restaurant: string;
  inviter: string;
  role: string;
  email: string;
  expireDate: string;
  acceptUrl: string;
  declineUrl: string;
  tenantLogoUrl: string | null;
}

function replaceVars(text: string, vars: EmailVars): string {
  return text
    .replace(/\{restaurant\}/g, vars.restaurant)
    .replace(/\{inviter\}/g, vars.inviter)
    .replace(/\{role\}/g, ROLE_LABELS[vars.role] ?? vars.role)
    .replace(/\{email\}/g, vars.email)
    .replace(/\{expire_date\}/g, vars.expireDate);
}

function renderEmailHtml(template: TemplateData, vars: EmailVars): string {
  const headerText = replaceVars(template.headerText, vars);
  const bodyText = replaceVars(template.bodyText, vars);
  const buttonText = replaceVars(template.buttonText, vars);
  const footerText = replaceVars(template.footerText, vars);
  const declineText = replaceVars(template.declineText, vars);

  const logoUrl = template.logoUrl ?? vars.tenantLogoUrl;
  const showLogo = template.showLogo && logoUrl;

  // Calcular color de texto del botón (blanco o negro según luminancia)
  const btnTextColor = isLightColor(template.buttonColor) ? "#000000" : "#FFFFFF";

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${replaceVars(template.subjectLine, vars)}</title>
</head>
<body style="margin:0;padding:0;background-color:${template.backgroundColor};font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:${template.backgroundColor};">
    <tr>
      <td align="center" style="padding:40px 20px;">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg, ${template.primaryColor}, ${template.secondaryColor});padding:${showLogo ? "32px 40px 24px" : "40px"};text-align:center;">
              ${showLogo ? `<img src="${logoUrl}" alt="${vars.restaurant}" style="width:64px;height:64px;border-radius:50%;border:3px solid rgba(255,255,255,0.3);margin-bottom:16px;object-fit:cover;" />` : ""}
              ${template.showRestaurantInfo ? `<h2 style="margin:0;color:#FFFFFF;font-size:18px;font-weight:500;opacity:0.9;">${vars.restaurant}</h2>` : ""}
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:40px;">
              <h1 style="margin:0 0 16px;color:${template.primaryColor};font-size:28px;font-weight:700;">
                ${headerText}
              </h1>
              <p style="margin:0 0 32px;color:${template.textColor};font-size:16px;line-height:1.6;">
                ${bodyText}
              </p>

              <!-- Role badge -->
              <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto 32px;">
                <tr>
                  <td style="background-color:${template.accentColor}20;border:2px solid ${template.accentColor};border-radius:24px;padding:8px 20px;">
                    <span style="color:${template.primaryColor};font-size:14px;font-weight:600;">
                      Rol: ${ROLE_LABELS[vars.role] ?? vars.role}
                    </span>
                  </td>
                </tr>
              </table>

              <!-- CTA Button -->
              <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto 24px;">
                <tr>
                  <td style="background-color:${template.buttonColor};border-radius:12px;">
                    <a href="${vars.acceptUrl}" target="_blank" style="display:inline-block;padding:16px 48px;color:${btnTextColor};text-decoration:none;font-size:16px;font-weight:700;letter-spacing:0.5px;">
                      ${buttonText}
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Decline link -->
              <p style="text-align:center;margin:0;">
                <a href="${vars.declineUrl}" style="color:${template.accentColor};font-size:13px;text-decoration:underline;">
                  ${declineText}
                </a>
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:24px 40px;background-color:${template.backgroundColor};border-top:1px solid #E9ECEF;">
              <p style="margin:0;color:#999999;font-size:13px;line-height:1.5;text-align:center;">
                ${footerText}
              </p>
              <p style="margin:12px 0 0;color:#CCCCCC;font-size:11px;text-align:center;">
                Powered by LŌME
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function isLightColor(hex: string): boolean {
  const c = hex.replace("#", "");
  const r = parseInt(c.substring(0, 2), 16);
  const g = parseInt(c.substring(2, 4), 16);
  const b = parseInt(c.substring(4, 6), 16);
  return (r * 299 + g * 587 + b * 114) / 1000 > 150;
}

// ── Handler principal ───────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY no configurada");
    }

    const appUrl = Deno.env.get("APP_URL") ?? "https://lome.app";

    // ── 1. Autenticar ──

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No autorizado" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2. Leer body ──

    const {
      invitation_id,
      email,
      tenant_name,
      role,
      invited_by_name,
      tenant_id,
    } = await req.json();

    if (!invitation_id || !email || !tenant_name || !role) {
      return new Response(
        JSON.stringify({ error: "Faltan campos requeridos" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 3. Obtener plantilla del tenant ──

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    let templateData: TemplateData;

    if (tenant_id) {
      const { data: dbTemplate } = await supabaseAdmin
        .from("invitation_templates")
        .select("*")
        .eq("tenant_id", tenant_id)
        .maybeSingle();

      if (dbTemplate) {
        templateData = {
          templateStyle: dbTemplate.template_style,
          primaryColor: dbTemplate.primary_color,
          secondaryColor: dbTemplate.secondary_color,
          backgroundColor: dbTemplate.background_color,
          buttonColor: dbTemplate.button_color,
          textColor: dbTemplate.text_color,
          accentColor: dbTemplate.accent_color,
          logoUrl: dbTemplate.logo_url,
          showLogo: dbTemplate.show_logo,
          showRestaurantInfo: dbTemplate.show_restaurant_info,
          subjectLine: dbTemplate.subject_line,
          headerText: dbTemplate.header_text,
          bodyText: dbTemplate.body_text,
          buttonText: dbTemplate.button_text,
          footerText: dbTemplate.footer_text,
          declineText: dbTemplate.decline_text,
        };
      } else {
        templateData = getDefaultTemplate();
      }
    } else {
      templateData = getDefaultTemplate();
    }

    // Obtener logo del tenant si no hay logo personalizado
    let tenantLogoUrl: string | null = null;
    if (tenant_id) {
      const { data: tenant } = await supabaseAdmin
        .from("tenants")
        .select("logo_url")
        .eq("id", tenant_id)
        .maybeSingle();
      tenantLogoUrl = tenant?.logo_url ?? null;
    }

    // ── 4. Calcular fechas y URLs ──

    const expireDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const expireDateStr = expireDate.toLocaleDateString("es-ES", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });

    const acceptUrl = `${appUrl}/invitation/${invitation_id}/accept`;
    const declineUrl = `${appUrl}/invitation/${invitation_id}/decline`;

    const vars: EmailVars = {
      restaurant: tenant_name,
      inviter: invited_by_name ?? "Un administrador",
      role,
      email,
      expireDate: expireDateStr,
      acceptUrl,
      declineUrl,
      tenantLogoUrl,
    };

    // ── 5. Renderizar HTML ──

    const html = renderEmailHtml(templateData, vars);
    const subject = replaceVars(templateData.subjectLine, vars);

    // ── 6. Enviar con Resend ──

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "LŌME <noreply@lome.app>",
        to: [email],
        subject,
        html,
      }),
    });

    if (!resendResponse.ok) {
      const errorBody = await resendResponse.text();
      throw new Error(`Resend error (${resendResponse.status}): ${errorBody}`);
    }

    const resendData = await resendResponse.json();

    return new Response(
      JSON.stringify({
        success: true,
        message_id: resendData.id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("send-invitation-email error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

function getDefaultTemplate(): TemplateData {
  const preset = TEMPLATE_PRESETS.casual;
  return {
    templateStyle: "casual",
    primaryColor: preset.primary,
    secondaryColor: preset.secondary,
    backgroundColor: preset.background,
    buttonColor: preset.button,
    textColor: preset.text,
    accentColor: preset.accent,
    logoUrl: null,
    showLogo: true,
    showRestaurantInfo: true,
    subjectLine: "¡Te han invitado a unirte a {restaurant}!",
    headerText: "¡Hola!",
    bodyText: "{inviter} te ha invitado a unirte al equipo de {restaurant} como {role}. Haz clic en el botón para aceptar la invitación.",
    buttonText: "Aceptar Invitación",
    footerText: "Esta invitación expira el {expire_date}. Si no esperabas este email, puedes ignorarlo.",
    declineText: "Si prefieres rechazar, haz clic aquí",
  };
}

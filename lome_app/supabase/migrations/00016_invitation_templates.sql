-- ============================================================================
-- LŌME — Migración 00016: Plantillas de Email de Invitación
-- ============================================================================
-- Sistema de plantillas personalizables para emails de invitación.
-- Cada restaurante puede elegir una plantilla predeterminada y
-- personalizarla (colores, textos, logo).
-- ============================================================================

BEGIN;

-- ============================================================================
-- TABLA: invitation_templates
-- ============================================================================

CREATE TABLE public.invitation_templates (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE UNIQUE,

  -- Estilo base de la plantilla
  template_style TEXT NOT NULL DEFAULT 'professional'
    CHECK (template_style IN (
      'professional', 'casual', 'elegant', 'minimal', 'colorful'
    )),

  -- Colores
  primary_color    TEXT NOT NULL DEFAULT '#FF6B35',
  secondary_color  TEXT NOT NULL DEFAULT '#2D3436',
  background_color TEXT NOT NULL DEFAULT '#F8F9FA',
  button_color     TEXT NOT NULL DEFAULT '#FF6B35',
  text_color       TEXT NOT NULL DEFAULT '#2D3436',
  accent_color     TEXT NOT NULL DEFAULT '#FDCB6E',

  -- Logo y branding
  logo_url              TEXT, -- NULL = usa logo del tenant
  show_logo             BOOLEAN NOT NULL DEFAULT true,
  show_restaurant_info  BOOLEAN NOT NULL DEFAULT true,

  -- Textos personalizables
  subject_line  TEXT NOT NULL DEFAULT '¡Te han invitado a unirte a {restaurant}!',
  header_text   TEXT NOT NULL DEFAULT '¡Hola!',
  body_text     TEXT NOT NULL DEFAULT '{inviter} te ha invitado a unirte al equipo de {restaurant} como {role}. Haz clic en el botón para aceptar la invitación.',
  button_text   TEXT NOT NULL DEFAULT 'Aceptar Invitación',
  footer_text   TEXT NOT NULL DEFAULT 'Esta invitación expira en 7 días. Si no esperabas este email, puedes ignorarlo.',
  decline_text  TEXT NOT NULL DEFAULT 'Si prefieres rechazar, haz clic aquí',

  -- Metadatos
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.invitation_templates
  IS 'Plantillas de email personalizables para invitaciones de empleados. Variables: {restaurant}, {inviter}, {role}, {email}, {expire_date}';

CREATE INDEX idx_invitation_templates_tenant
  ON public.invitation_templates(tenant_id);

CREATE TRIGGER set_invitation_templates_updated_at
  BEFORE UPDATE ON public.invitation_templates
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.invitation_templates ENABLE ROW LEVEL SECURITY;

-- Staff puede ver la plantilla de su restaurante
CREATE POLICY "invitation_templates_select_staff" ON public.invitation_templates
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE tenant_memberships.tenant_id = invitation_templates.tenant_id
        AND tenant_memberships.user_id = auth.uid()
        AND tenant_memberships.is_active = true
    )
    OR public.is_super_admin()
  );

-- Solo owner/manager pueden crear/editar plantillas
CREATE POLICY "invitation_templates_insert_managers" ON public.invitation_templates
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

CREATE POLICY "invitation_templates_update_managers" ON public.invitation_templates
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

CREATE POLICY "invitation_templates_delete_managers" ON public.invitation_templates
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner']::user_role[])
    OR public.is_super_admin()
  );

-- ============================================================================
-- RPC: Obtener o crear plantilla de invitación
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_or_create_invitation_template(p_tenant_id UUID)
RETURNS SETOF public.invitation_templates
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  IF EXISTS (SELECT 1 FROM public.invitation_templates WHERE tenant_id = p_tenant_id) THEN
    RETURN QUERY SELECT * FROM public.invitation_templates WHERE tenant_id = p_tenant_id;
  ELSE
    RETURN QUERY
    INSERT INTO public.invitation_templates (tenant_id)
    VALUES (p_tenant_id)
    RETURNING *;
  END IF;
END;
$$;

-- Auditoría
CREATE TRIGGER audit_invitation_templates
  AFTER INSERT OR UPDATE OR DELETE ON public.invitation_templates
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

COMMIT;

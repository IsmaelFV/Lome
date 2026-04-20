-- ============================================================================
-- LŌME — Migración 00015: Tabla de Invitaciones
-- ============================================================================
-- La tabla `invitations` era referenciada por:
--   - anonymize_user_account() en 00002
--   - Edge Function delete-account
--   - Dart: invitation_remote_datasource.dart (CRUD completo)
-- Pero nunca fue creada. Esta migración la crea con RLS completo.
-- ============================================================================

BEGIN;

-- ============================================================================
-- TABLA: invitations
-- ============================================================================

CREATE TABLE public.invitations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id   UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  role        public.user_role NOT NULL DEFAULT 'waiter',
  invited_by  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  status      TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'expired', 'cancelled')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at  TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  accepted_at TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.invitations
  IS 'Invitaciones a empleados para unirse a un restaurante';

-- ── Índices ──────────────────────────────────────────────────────────────────

CREATE INDEX idx_invitations_tenant ON public.invitations(tenant_id);
CREATE INDEX idx_invitations_email ON public.invitations(email);
CREATE INDEX idx_invitations_invited_by ON public.invitations(invited_by);
CREATE INDEX idx_invitations_status ON public.invitations(status);

-- Evitar invitaciones pendientes duplicadas al mismo email en el mismo tenant
CREATE UNIQUE INDEX idx_invitations_unique_pending
  ON public.invitations(tenant_id, email)
  WHERE status = 'pending';

-- ── Trigger updated_at ───────────────────────────────────────────────────────

CREATE TRIGGER set_invitations_updated_at
  BEFORE UPDATE ON public.invitations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- Owner/manager del tenant pueden ver las invitaciones de su restaurante
CREATE POLICY "invitations_select_managers" ON public.invitations
  FOR SELECT USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- Los usuarios invitados pueden ver sus propias invitaciones (por email)
CREATE POLICY "invitations_select_invitee" ON public.invitations
  FOR SELECT USING (
    email = (
      SELECT p.email FROM public.profiles p WHERE p.id = auth.uid()
    )
  );

-- Solo owner/manager pueden crear invitaciones
CREATE POLICY "invitations_insert_managers" ON public.invitations
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- Owner/manager pueden actualizar (cancelar) invitaciones de su tenant
-- El invitado también puede actualizar (aceptar/rechazar) sus invitaciones
CREATE POLICY "invitations_update_managers" ON public.invitations
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR email = (
      SELECT p.email FROM public.profiles p WHERE p.id = auth.uid()
    )
    OR public.is_super_admin()
  );

-- Solo owner puede eliminar invitaciones
CREATE POLICY "invitations_delete_owner" ON public.invitations
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner']::user_role[])
    OR public.is_super_admin()
  );

-- ============================================================================
-- TRIGGER DE AUDITORÍA
-- ============================================================================

CREATE TRIGGER audit_invitations
  AFTER INSERT OR UPDATE OR DELETE ON public.invitations
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

COMMIT;

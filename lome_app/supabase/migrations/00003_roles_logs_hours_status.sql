-- ============================================================================
-- LŌME — Migración 003: Roles personalizados, Activity logs, Horarios, Estado
-- ============================================================================
-- Sistemas implementados:
--   1. Roles personalizados por restaurante (custom_roles + custom_role_assignments)
--   2. Activity logs de auditoría (activity_logs)
--   3. Horarios de apertura/cierre (restaurant_hours)
--   4. Estado del restaurante (campo status + is_open en tenants)
-- ============================================================================

-- ============================================================================
-- ENUMERADO: estado operativo del restaurante
-- ============================================================================

CREATE TYPE public.restaurant_operational_status AS ENUM (
  'open',
  'closed',
  'temporarily_closed'
);

-- ============================================================================
-- 1. ROLES PERSONALIZADOS
-- ============================================================================
-- Cada restaurante puede crear roles adicionales más allá de los roles
-- predefinidos del sistema (owner, manager, chef, waiter, cashier).
-- Los permisos se almacenan como JSON para máxima flexibilidad.
-- ============================================================================

CREATE TABLE public.custom_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  -- JSON array de strings con los permisos activos, ej:
  -- ["create_orders","edit_orders","view_menu","view_kitchen"]
  permissions JSONB NOT NULL DEFAULT '[]',
  color TEXT,                          -- color hex para badges
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, name)
);

CREATE INDEX idx_custom_roles_tenant ON public.custom_roles(tenant_id);

-- Trigger updated_at
CREATE TRIGGER set_custom_roles_updated_at
  BEFORE UPDATE ON public.custom_roles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Asignación de roles personalizados a miembros
-- Un miembro puede tener su user_role del sistema + un custom_role adicional
CREATE TABLE public.custom_role_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  membership_id UUID NOT NULL REFERENCES public.tenant_memberships(id) ON DELETE CASCADE,
  custom_role_id UUID NOT NULL REFERENCES public.custom_roles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (membership_id, custom_role_id)
);

CREATE INDEX idx_custom_role_assignments_tenant ON public.custom_role_assignments(tenant_id);
CREATE INDEX idx_custom_role_assignments_membership ON public.custom_role_assignments(membership_id);

-- RLS
ALTER TABLE public.custom_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_role_assignments ENABLE ROW LEVEL SECURITY;

-- Cualquier miembro activo del tenant puede ver los roles
CREATE POLICY "custom_roles_select" ON public.custom_roles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE user_id = auth.uid()
      AND tenant_id = custom_roles.tenant_id
      AND is_active = true
    )
  );

-- Solo owner/manager pueden crear/editar/eliminar roles
CREATE POLICY "custom_roles_insert" ON public.custom_roles
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "custom_roles_update" ON public.custom_roles
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "custom_roles_delete" ON public.custom_roles
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- Asignaciones: mismas políticas
CREATE POLICY "custom_role_assignments_select" ON public.custom_role_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE user_id = auth.uid()
      AND tenant_id = custom_role_assignments.tenant_id
      AND is_active = true
    )
  );

CREATE POLICY "custom_role_assignments_manage" ON public.custom_role_assignments
  FOR ALL USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ============================================================================
-- 2. ACTIVITY LOGS
-- ============================================================================
-- Registra acciones clave para auditoría. Tabla de solo inserción (append-only).
-- ============================================================================

CREATE TABLE public.activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,             -- 'order.created', 'menu.updated', etc.
  entity_type TEXT NOT NULL,        -- 'order', 'menu_item', 'inventory', etc.
  entity_id UUID,                   -- ID de la entidad afectada
  details JSONB DEFAULT '{}',       -- datos extra (old_value, new_value, etc.)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activity_logs_tenant ON public.activity_logs(tenant_id);
CREATE INDEX idx_activity_logs_tenant_date ON public.activity_logs(tenant_id, created_at DESC);
CREATE INDEX idx_activity_logs_entity ON public.activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_user ON public.activity_logs(user_id);

-- RLS
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Miembros activos con rol manager+ pueden ver logs de su tenant
CREATE POLICY "activity_logs_select" ON public.activity_logs
  FOR SELECT USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- Cualquier miembro activo puede insertar logs (se valida por app)
CREATE POLICY "activity_logs_insert" ON public.activity_logs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE user_id = auth.uid()
      AND tenant_id = activity_logs.tenant_id
      AND is_active = true
    )
  );

-- Función helper para insertar logs fácilmente
CREATE OR REPLACE FUNCTION public.log_activity(
  p_tenant_id UUID,
  p_action TEXT,
  p_entity_type TEXT,
  p_entity_id UUID DEFAULT NULL,
  p_details JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO public.activity_logs (tenant_id, user_id, action, entity_type, entity_id, details)
  VALUES (p_tenant_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_details)
  RETURNING id INTO v_log_id;
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. HORARIOS DEL RESTAURANTE
-- ============================================================================
-- Cada restaurante define horarios por día de la semana.
-- Soporta múltiples franjas por día (ej: mediodía + noche).
-- ============================================================================

CREATE TABLE public.restaurant_hours (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  -- 0 = Lunes, 1 = Martes, ..., 6 = Domingo
  open_time TIME NOT NULL,
  close_time TIME NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_time_range CHECK (open_time < close_time)
);

CREATE INDEX idx_restaurant_hours_tenant ON public.restaurant_hours(tenant_id);
CREATE UNIQUE INDEX idx_restaurant_hours_unique
  ON public.restaurant_hours(tenant_id, day_of_week, open_time)
  WHERE is_active = true;

-- Trigger updated_at
CREATE TRIGGER set_restaurant_hours_updated_at
  BEFORE UPDATE ON public.restaurant_hours
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- RLS
ALTER TABLE public.restaurant_hours ENABLE ROW LEVEL SECURITY;

-- Lectura pública (los clientes necesitan ver el horario)
CREATE POLICY "restaurant_hours_select" ON public.restaurant_hours
  FOR SELECT USING (true);

-- Solo owner/manager pueden gestionar horarios
CREATE POLICY "restaurant_hours_manage" ON public.restaurant_hours
  FOR ALL USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- Función para verificar si el restaurante está abierto ahora
CREATE OR REPLACE FUNCTION public.is_restaurant_open(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_status public.restaurant_operational_status;
  v_now TIME;
  v_today INTEGER;
BEGIN
  -- 1. Comprobar estado manual
  SELECT operational_status INTO v_status
  FROM public.tenants WHERE id = p_tenant_id;

  IF v_status = 'closed' OR v_status = 'temporarily_closed' THEN
    RETURN false;
  END IF;

  -- 2. Comprobar horario (lunes = 0)
  v_now := LOCALTIME;
  v_today := EXTRACT(DOW FROM CURRENT_DATE)::INTEGER;
  -- PostgreSQL DOW: 0=domingo → convertir a 0=lunes
  v_today := CASE WHEN v_today = 0 THEN 6 ELSE v_today - 1 END;

  RETURN EXISTS (
    SELECT 1 FROM public.restaurant_hours
    WHERE tenant_id = p_tenant_id
    AND day_of_week = v_today
    AND is_active = true
    AND v_now BETWEEN open_time AND close_time
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 4. ESTADO OPERATIVO DEL RESTAURANTE
-- ============================================================================
-- Agrega el campo operational_status a la tabla tenants.
-- ============================================================================

ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS operational_status public.restaurant_operational_status
    NOT NULL DEFAULT 'open';

-- Índice para filtrar restaurantes abiertos en marketplace
CREATE INDEX idx_tenants_operational_status
  ON public.tenants(operational_status)
  WHERE status = 'active';

-- ============================================================================
-- PERMISOS DE ROLES PERSONALIZADOS: lista canónica de permisos disponibles
-- ============================================================================
-- Se almacena como comentario de referencia. El frontend usa los mismos strings.
--
-- create_orders     — Crear nuevos pedidos
-- edit_orders       — Editar pedidos existentes
-- cancel_orders     — Cancelar pedidos
-- manage_menu       — Gestionar menú (crear, editar, eliminar platos)
-- view_analytics    — Ver panel de analíticas
-- manage_inventory  — Gestionar inventario
-- view_kitchen      — Ver pantalla de cocina
-- manage_tables     — Gestionar mesas
-- manage_employees  — Gestionar empleados
-- manage_settings   — Gestionar configuración
-- view_billing      — Ver facturación
-- manage_billing    — Gestionar facturación
-- view_activity_logs — Ver logs de actividad
-- manage_hours      — Gestionar horarios
-- manage_roles      — Gestionar roles personalizados
-- ============================================================================

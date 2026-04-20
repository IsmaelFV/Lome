-- ============================================================================
-- Migración 00006: Asignaciones camarero→mesa + RPCs de historial y estadísticas
-- ============================================================================

-- ============================================================================
-- TABLA: table_assignments (asignación de camareros a mesas)
-- ============================================================================

CREATE TABLE public.table_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  table_id UUID NOT NULL REFERENCES public.restaurant_tables(id) ON DELETE CASCADE,
  waiter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES public.profiles(id),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.table_assignments
  IS 'Asignación de camareros a mesas del restaurante';

CREATE INDEX idx_table_assignments_tenant ON public.table_assignments(tenant_id);
CREATE INDEX idx_table_assignments_table ON public.table_assignments(table_id);
CREATE INDEX idx_table_assignments_waiter ON public.table_assignments(waiter_id);
CREATE INDEX idx_table_assignments_active ON public.table_assignments(tenant_id, is_active)
  WHERE is_active = true;

-- Solo una asignación activa por mesa
CREATE UNIQUE INDEX idx_table_assignments_unique_active
  ON public.table_assignments(table_id) WHERE is_active = true;

CREATE TRIGGER table_assignments_updated_at
  BEFORE UPDATE ON public.table_assignments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE public.table_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "table_assignments_select_staff" ON public.table_assignments
  FOR SELECT USING (
    tenant_id IN (
      SELECT tm.tenant_id FROM public.tenant_memberships tm
      WHERE tm.user_id = auth.uid() AND tm.is_active = true
    )
  );

CREATE POLICY "table_assignments_insert_managers" ON public.table_assignments
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "table_assignments_update_managers" ON public.table_assignments
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "table_assignments_delete_managers" ON public.table_assignments
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

ALTER PUBLICATION supabase_realtime ADD TABLE public.table_assignments;

-- ============================================================================
-- RPC: Historial de uso de una mesa (pedidos completados)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_table_history(
  p_tenant_id UUID,
  p_table_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  order_id UUID,
  order_number INTEGER,
  waiter_name TEXT,
  guests_count INTEGER,
  total NUMERIC,
  payment_method TEXT,
  opened_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  duration_minutes INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    o.id AS order_id,
    o.order_number,
    p.full_name AS waiter_name,
    ts.guests_count,
    o.total,
    o.payment_method,
    ts.created_at AS opened_at,
    ts.closed_at,
    EXTRACT(EPOCH FROM (COALESCE(ts.closed_at, NOW()) - ts.created_at))::INTEGER / 60 AS duration_minutes
  FROM public.orders o
  JOIN public.table_sessions ts ON ts.id = o.table_session_id
  LEFT JOIN public.profiles p ON p.id = o.waiter_id
  WHERE ts.table_id = p_table_id
    AND o.tenant_id = p_tenant_id
    AND o.status = 'completed'
  ORDER BY ts.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC: Estadísticas de ocupación de mesas
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_table_occupancy_stats(
  p_tenant_id UUID,
  p_from TIMESTAMPTZ DEFAULT NOW() - INTERVAL '30 days',
  p_to TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  table_id UUID,
  table_number INTEGER,
  table_name TEXT,
  total_sessions INTEGER,
  total_orders INTEGER,
  total_revenue NUMERIC,
  avg_duration_minutes INTEGER,
  avg_guests NUMERIC,
  avg_ticket NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    rt.id AS table_id,
    rt.number AS table_number,
    rt.label AS table_name,
    COUNT(DISTINCT ts.id)::INTEGER AS total_sessions,
    COUNT(DISTINCT o.id)::INTEGER AS total_orders,
    COALESCE(SUM(o.total), 0) AS total_revenue,
    COALESCE(AVG(
      EXTRACT(EPOCH FROM (COALESCE(ts.closed_at, NOW()) - ts.created_at)) / 60
    ), 0)::INTEGER AS avg_duration_minutes,
    COALESCE(AVG(ts.guests_count), 0) AS avg_guests,
    CASE
      WHEN COUNT(DISTINCT o.id) > 0
      THEN COALESCE(SUM(o.total), 0) / COUNT(DISTINCT o.id)
      ELSE 0
    END AS avg_ticket
  FROM public.restaurant_tables rt
  LEFT JOIN public.table_sessions ts
    ON ts.table_id = rt.id
    AND ts.created_at >= p_from
    AND ts.created_at <= p_to
  LEFT JOIN public.orders o
    ON o.table_session_id = ts.id
    AND o.status = 'completed'
  WHERE rt.tenant_id = p_tenant_id
    AND rt.is_active = true
  GROUP BY rt.id, rt.number, rt.label
  ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

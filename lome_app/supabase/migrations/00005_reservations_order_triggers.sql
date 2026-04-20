-- ============================================================================
-- Migración 00005: Reservas + Triggers de estado mesa ← pedido
-- ============================================================================

-- ============================================================================
-- TABLA: reservations (reservas de mesas)
-- ============================================================================

CREATE TABLE public.reservations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  table_id UUID NOT NULL REFERENCES public.restaurant_tables(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  phone TEXT,
  reservation_time TIMESTAMPTZ NOT NULL,
  guests INTEGER NOT NULL DEFAULT 2,
  status TEXT NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.reservations
  IS 'Reservas anticipadas de mesas del restaurante';
COMMENT ON COLUMN public.reservations.status
  IS 'pending | active | fulfilled | cancelled | no_show';

CREATE INDEX idx_reservations_tenant ON public.reservations(tenant_id);
CREATE INDEX idx_reservations_table ON public.reservations(table_id);
CREATE INDEX idx_reservations_time ON public.reservations(tenant_id, reservation_time);
CREATE INDEX idx_reservations_active ON public.reservations(tenant_id, status)
  WHERE status IN ('pending', 'active');

CREATE TRIGGER reservations_updated_at
  BEFORE UPDATE ON public.reservations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reservations_select_staff" ON public.reservations
  FOR SELECT USING (
    tenant_id IN (
      SELECT tm.tenant_id FROM public.tenant_memberships tm
      WHERE tm.user_id = auth.uid() AND tm.is_active = true
    )
  );

CREATE POLICY "reservations_insert_staff" ON public.reservations
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager', 'waiter']::user_role[])
  );

CREATE POLICY "reservations_update_staff" ON public.reservations
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager', 'waiter']::user_role[])
  );

CREATE POLICY "reservations_delete_managers" ON public.reservations
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ── Realtime ─────────────────────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE public.reservations;
-- orders ya añadida en 00001_initial_schema.sql

-- ============================================================================
-- TRIGGER: Propagar estado del pedido → estado de la mesa
-- ============================================================================
--
-- Flujo:
--   order.status = 'preparing'  →  table = 'waiting_food'
--   order.status = 'delivered'  →  table = 'waiting_payment'
--   order.payment_status = 'paid'  →  cerrar sesión → table = 'available'
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_table_status_on_order()
RETURNS TRIGGER AS $$
DECLARE
  v_table_id UUID;
BEGIN
  -- Solo pedidos dine-in vinculados a una sesión afectan la mesa
  IF NEW.table_session_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT table_id INTO v_table_id
  FROM public.table_sessions
  WHERE id = NEW.table_session_id;

  IF v_table_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Pedido enviado a cocina → mesa esperando comida
  IF NEW.status = 'preparing' AND OLD.status IS DISTINCT FROM 'preparing' THEN
    UPDATE public.restaurant_tables
    SET status = 'waiting_food'
    WHERE id = v_table_id;
  END IF;

  -- Comida entregada → mesa esperando pago
  IF NEW.status = 'delivered' AND OLD.status IS DISTINCT FROM 'delivered' THEN
    UPDATE public.restaurant_tables
    SET status = 'waiting_payment'
    WHERE id = v_table_id;
  END IF;

  -- Pago completado → cerrar sesión (el trigger existente pone mesa available)
  IF NEW.payment_status = 'paid' AND OLD.payment_status IS DISTINCT FROM 'paid' THEN
    UPDATE public.table_sessions
    SET is_active = false, closed_at = NOW()
    WHERE id = NEW.table_session_id AND is_active = true;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_status_change
  AFTER UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_table_status_on_order();

-- ============================================================================
-- FUNCIÓN RPC: Activar reservas próximas
-- ============================================================================
-- Llamada periódicamente desde el cliente. Activa reservas cuyo horario
-- está dentro de los próximos 15 minutos y marca como no_show las que ya
-- pasaron hace más de 30 minutos sin ser atendidas.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.activate_upcoming_reservations(p_tenant_id UUID)
RETURNS void AS $$
BEGIN
  -- Activar reservas dentro de ventana de 15 minutos
  UPDATE public.reservations
  SET status = 'active'
  WHERE tenant_id = p_tenant_id
    AND status = 'pending'
    AND reservation_time <= NOW() + INTERVAL '15 minutes'
    AND reservation_time >= NOW() - INTERVAL '30 minutes';

  -- Marcar mesas con reserva activa como 'reserved'
  UPDATE public.restaurant_tables rt
  SET status = 'reserved'
  FROM public.reservations r
  WHERE r.table_id = rt.id
    AND r.tenant_id = p_tenant_id
    AND r.status = 'active'
    AND rt.status = 'available';

  -- Marcar reservas caducadas como no_show
  UPDATE public.reservations
  SET status = 'no_show'
  WHERE tenant_id = p_tenant_id
    AND status IN ('pending', 'active')
    AND reservation_time < NOW() - INTERVAL '30 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

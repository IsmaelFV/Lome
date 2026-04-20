-- ============================================================================
-- LŌME — Migración 00014: Endurecimiento de RLS y Seguridad
-- ============================================================================
-- Vulnerabilidades corregidas:
--
--   1. search_path hijacking: Todas las funciones SECURITY DEFINER carecían
--      de SET search_path, permitiendo inyección vía tablas temporales.
--
--   2. Escalada de privilegios en memberships: Cualquier usuario autenticado
--      podía añadirse a cualquier tenant con cualquier rol
--      (OR auth.uid() IS NOT NULL en memberships_insert_tenant).
--
--   3. promotions_manage_staff: Referencia a tabla inexistente tenant_users
--      (política rota / siempre deniega). Corregido a tenant_memberships
--      y restringido a owner/manager.
--
--   4. notifications INSERT sin restricción: WITH CHECK (true) permitía
--      inserción arbitraria. Restringido a managers/super_admin;
--      triggers SECURITY DEFINER siguen funcionando (bypasean RLS).
--
--   5. audit_logs INSERT abierto: Cualquier autenticado podía insertar
--      registros de auditoría arbitrarios. Eliminada política directa;
--      inserciones pasan por audit_trigger_fn() / insert_audit_log()
--      que son SECURITY DEFINER.
--
--   6. RPCs SECURITY DEFINER sin verificación: 11 funciones aceptaban
--      tenant_id sin verificar que el llamante tuviera acceso.
--
--   7. table_sessions sin política DELETE: Añadida para managers.
--
--   8. get_recommended_restaurants: Aceptaba cualquier user_id sin
--      verificar que fuera el usuario actual.
--
--   9. Políticas super_admin faltantes en varias tablas.
--
--  10. Constraint UNIQUE faltante en tenant_memberships(tenant_id, user_id).
-- ============================================================================

BEGIN;

-- ============================================================================
-- PARTE 1: HARDENING search_path EN FUNCIONES SECURITY DEFINER
-- ============================================================================
-- Sin SET search_path, un atacante con permiso CREATE en public o pg_temp
-- podría crear tablas con nombres idénticos y desviar las queries de las
-- funciones SECURITY DEFINER (que se ejecutan con privilegios elevados).
-- ============================================================================

-- Helpers base
ALTER FUNCTION public.is_super_admin()
  SET search_path = public;

ALTER FUNCTION public.has_role_in_tenant(UUID, user_role[])
  SET search_path = public;

-- Triggers de auth / negocio
ALTER FUNCTION public.handle_new_user()
  SET search_path = public;

ALTER FUNCTION public.update_tenant_rating()
  SET search_path = public;

ALTER FUNCTION public.handle_inventory_movement()
  SET search_path = public;

ALTER FUNCTION public.update_tenant_orders_count()
  SET search_path = public;

ALTER FUNCTION public.update_table_status_on_session()
  SET search_path = public;

ALTER FUNCTION public.update_table_status_on_order()
  SET search_path = public;

ALTER FUNCTION public.notify_waiter_order_ready()
  SET search_path = public;

ALTER FUNCTION public.notify_order_cancelled()
  SET search_path = public;

ALTER FUNCTION public.audit_trigger_fn()
  SET search_path = public;

ALTER FUNCTION public.anonymize_user_account(UUID)
  SET search_path = public;

-- RPCs admin (ya tienen is_super_admin() check interno)
ALTER FUNCTION public.get_admin_stats()
  SET search_path = public;

ALTER FUNCTION public.get_admin_platform_metrics()
  SET search_path = public;

ALTER FUNCTION public.get_admin_restaurant_stats(UUID)
  SET search_path = public;

ALTER FUNCTION public.get_top_restaurants_by_revenue(INTEGER)
  SET search_path = public;

ALTER FUNCTION public.get_admin_subscription_stats()
  SET search_path = public;

ALTER FUNCTION public.get_audit_logs(TEXT, TEXT, UUID, UUID, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, INTEGER)
  SET search_path = public;

ALTER FUNCTION public.get_audit_summary(INTEGER)
  SET search_path = public;

ALTER FUNCTION public.get_monitoring_dashboard(INTEGER)
  SET search_path = public;

ALTER FUNCTION public.get_error_logs(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, INTEGER)
  SET search_path = public;

ALTER FUNCTION public.purge_old_logs(INTEGER)
  SET search_path = public;

-- Logging
ALTER FUNCTION public.log_error(TEXT, TEXT, TEXT, TEXT, UUID, JSONB, TEXT, JSONB)
  SET search_path = public;

ALTER FUNCTION public.log_api_usage(TEXT, TEXT, INTEGER, INTEGER, INTEGER, INTEGER, UUID, JSONB)
  SET search_path = public;

-- ============================================================================
-- PARTE 2: HELPER — Verificar acceso a tenant
-- ============================================================================
-- Función utilitaria para verificar que el llamante es miembro activo del
-- tenant o super_admin. Lanza excepción si no está autorizado.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.verify_tenant_access(p_tenant_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.tenant_memberships
    WHERE user_id = auth.uid()
      AND tenant_id = p_tenant_id
      AND is_active = true
  ) AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'No autorizado: acceso denegado al tenant %', p_tenant_id;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- PARTE 3: AUTO-ASIGNACIÓN DE OWNER AL CREAR TENANT
-- ============================================================================
-- Problema: memberships_insert_tenant tenía "OR auth.uid() IS NOT NULL"
-- para permitir auto-asignación en onboarding, pero esto permitía a
-- cualquier usuario añadirse a CUALQUIER tenant con CUALQUIER rol.
--
-- Solución: Trigger que auto-asigna al creador como owner.
-- Luego la política INSERT se restringe solo a owners/managers.
-- ============================================================================

-- Garantizar unicidad (tenant_id, user_id) para ON CONFLICT
CREATE UNIQUE INDEX IF NOT EXISTS idx_memberships_unique_tenant_user
  ON public.tenant_memberships(tenant_id, user_id);

CREATE OR REPLACE FUNCTION public.auto_assign_tenant_owner()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.tenant_memberships (tenant_id, user_id, role, is_active)
  VALUES (NEW.id, auth.uid(), 'owner', true)
  ON CONFLICT (tenant_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_tenant_created_assign_owner
  AFTER INSERT ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.auto_assign_tenant_owner();

-- Corregir política: eliminar "OR auth.uid() IS NOT NULL"
DROP POLICY IF EXISTS "memberships_insert_tenant" ON public.tenant_memberships;
CREATE POLICY "memberships_insert_tenant" ON public.tenant_memberships
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- ============================================================================
-- PARTE 4: CORRECCIONES CRÍTICAS DE POLÍTICAS RLS
-- ============================================================================

-- ─── 4.1 PROMOTIONS: Referencia a tabla inexistente ─────────────────────────
-- La política original referenciaba "tenant_users" que NO EXISTE.
-- Esto causaba que la política siempre denegara (error silencioso en RLS).
-- Corregido: usar tenant_memberships y restringir a owner/manager.

DROP POLICY IF EXISTS "promotions_manage_staff" ON public.promotions;

CREATE POLICY "promotions_select_staff" ON public.promotions
  FOR SELECT USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

CREATE POLICY "promotions_insert_managers" ON public.promotions
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "promotions_update_managers" ON public.promotions
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "promotions_delete_managers" ON public.promotions
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ─── 4.2 NOTIFICATIONS INSERT: Abierto a todos ─────────────────────────────
-- Antes: WITH CHECK (true) — literalmente cualquiera podía insertar.
-- Los triggers SECURITY DEFINER (notify_waiter_order_ready, etc.) bypasean
-- RLS, así que siguen funcionando. Solo restringimos INSERT directo.

DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
CREATE POLICY "notifications_insert_authorized" ON public.notifications
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- ─── 4.3 AUDIT_LOGS INSERT: Abierto a cualquier autenticado ────────────────
-- El audit_trigger_fn() y insert_audit_log() son SECURITY DEFINER,
-- así que bypasean RLS. No se necesita política INSERT directa.
-- Eliminar la permisiva y no reemplazar = solo SECURITY DEFINER puede insertar.

DROP POLICY IF EXISTS "audit_insert" ON public.audit_logs;

-- ─── 4.4 TABLE_SESSIONS: Falta política DELETE ─────────────────────────────

CREATE POLICY "sessions_delete_managers" ON public.table_sessions
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ─── 4.5 MENU_DESIGNS: Separar política FOR ALL en operaciones específicas ──
-- La política FOR ALL permite DELETE a cualquier staff (solo USING se evalúa).
-- Corregir: solo owner/manager pueden modificar/eliminar.

DROP POLICY IF EXISTS "Staff can manage own menu design" ON public.menu_designs;

CREATE POLICY "menu_designs_select_staff" ON public.menu_designs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE tenant_memberships.tenant_id = menu_designs.tenant_id
        AND tenant_memberships.user_id = auth.uid()
        AND tenant_memberships.is_active = true
    )
    OR public.is_super_admin()
  );

CREATE POLICY "menu_designs_insert_managers" ON public.menu_designs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE tenant_memberships.tenant_id = menu_designs.tenant_id
        AND tenant_memberships.user_id = auth.uid()
        AND tenant_memberships.is_active = true
        AND tenant_memberships.role IN ('owner', 'manager')
    )
    OR public.is_super_admin()
  );

CREATE POLICY "menu_designs_update_managers" ON public.menu_designs
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.tenant_memberships
      WHERE tenant_memberships.tenant_id = menu_designs.tenant_id
        AND tenant_memberships.user_id = auth.uid()
        AND tenant_memberships.is_active = true
        AND tenant_memberships.role IN ('owner', 'manager')
    )
    OR public.is_super_admin()
  );

CREATE POLICY "menu_designs_delete_managers" ON public.menu_designs
  FOR DELETE USING (
    public.has_role_in_tenant(
      menu_designs.tenant_id,
      ARRAY['owner', 'manager']::user_role[]
    )
    OR public.is_super_admin()
  );

-- ============================================================================
-- PARTE 5: POLÍTICAS SUPER ADMIN FALTANTES
-- ============================================================================
-- Asegurar que el super admin pueda acceder a todas las tablas para
-- el panel de administración.

CREATE POLICY "sessions_select_super_admin" ON public.table_sessions
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "assignments_select_super_admin" ON public.table_assignments
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "reservations_select_super_admin" ON public.reservations
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "custom_roles_select_super_admin" ON public.custom_roles
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "custom_role_assignments_select_super_admin" ON public.custom_role_assignments
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "restaurant_hours_select_super_admin" ON public.restaurant_hours
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "inventory_movements_select_super_admin" ON public.inventory_movements
  FOR SELECT USING (public.is_super_admin());

CREATE POLICY "promotions_select_super_admin" ON public.promotions
  FOR SELECT USING (public.is_super_admin());

-- ============================================================================
-- PARTE 6: HARDENING DE RPCs — VERIFICACIÓN DE AUTORIZACIÓN
-- ============================================================================
-- Funciones SECURITY DEFINER que aceptan tenant_id pero no verificaban
-- que el llamante tuviera acceso al tenant. Un usuario malicioso podía
-- obtener estadísticas de cualquier restaurante.
-- ============================================================================

-- ─── 6.1 get_restaurant_stats ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_restaurant_stats(p_tenant_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  SELECT json_build_object(
    'today_orders', (
      SELECT COUNT(*) FROM public.orders
      WHERE tenant_id = p_tenant_id
      AND created_at >= CURRENT_DATE
    ),
    'today_revenue', (
      SELECT COALESCE(SUM(total), 0) FROM public.orders
      WHERE tenant_id = p_tenant_id
      AND created_at >= CURRENT_DATE
      AND payment_status = 'paid'
    ),
    'active_tables', (
      SELECT COUNT(*) FROM public.restaurant_tables
      WHERE tenant_id = p_tenant_id
      AND status = 'occupied'
    ),
    'pending_orders', (
      SELECT COUNT(*) FROM public.orders
      WHERE tenant_id = p_tenant_id
      AND status IN ('pending', 'confirmed', 'preparing')
    ),
    'avg_rating', (
      SELECT COALESCE(AVG(rating), 0) FROM public.reviews
      WHERE tenant_id = p_tenant_id AND is_visible = true
    ),
    'low_stock_items', (
      SELECT COUNT(*) FROM public.inventory_items
      WHERE tenant_id = p_tenant_id
      AND current_stock <= minimum_stock
      AND is_active = true
    )
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ─── 6.2 get_or_create_menu_design ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_or_create_menu_design(p_tenant_id UUID)
RETURNS SETOF public.menu_designs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  IF EXISTS (SELECT 1 FROM public.menu_designs WHERE tenant_id = p_tenant_id) THEN
    RETURN QUERY SELECT * FROM public.menu_designs WHERE tenant_id = p_tenant_id;
  ELSE
    RETURN QUERY
    INSERT INTO public.menu_designs (tenant_id, sections)
    VALUES (
      p_tenant_id,
      '[
        {"id": "header", "type": "header", "visible": true, "animation": "fade", "config": {"showLogo": true, "showName": true, "showDescription": true}},
        {"id": "featured", "type": "featured", "visible": true, "animation": "scale", "config": {"title": "Destacados", "layout": "carousel"}},
        {"id": "categories", "type": "categories", "visible": true, "animation": "stagger", "config": {"layout": "tabs"}}
      ]'::jsonb
    )
    RETURNING *;
  END IF;
END;
$$;

-- ─── 6.3 activate_upcoming_reservations ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.activate_upcoming_reservations(p_tenant_id UUID)
RETURNS void AS $$
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  UPDATE public.reservations
  SET status = 'active'
  WHERE tenant_id = p_tenant_id
    AND status = 'pending'
    AND reservation_time <= NOW() + INTERVAL '15 minutes'
    AND reservation_time >= NOW() - INTERVAL '30 minutes';

  UPDATE public.restaurant_tables rt
  SET status = 'reserved'
  FROM public.reservations r
  WHERE r.table_id = rt.id
    AND r.tenant_id = p_tenant_id
    AND r.status = 'active'
    AND rt.status = 'available';

  UPDATE public.reservations
  SET status = 'no_show'
  WHERE tenant_id = p_tenant_id
    AND status IN ('pending', 'active')
    AND reservation_time < NOW() - INTERVAL '30 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.4 get_table_history ───────────────────────────────────────────────────

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
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.5 get_table_occupancy_stats ───────────────────────────────────────────

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
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.6 get_order_metrics ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_order_metrics(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  SELECT json_build_object(
    'total_orders', COALESCE(COUNT(*), 0),
    'completed_orders', COALESCE(COUNT(*) FILTER (WHERE status IN ('completed', 'delivered')), 0),
    'cancelled_orders', COALESCE(COUNT(*) FILTER (WHERE status = 'cancelled'), 0),
    'total_revenue', COALESCE(SUM(total) FILTER (WHERE status IN ('completed', 'delivered')), 0),
    'avg_ticket', COALESCE(AVG(total) FILTER (WHERE status IN ('completed', 'delivered')), 0),
    'avg_prep_time_minutes', COALESCE(
      EXTRACT(EPOCH FROM AVG(
        CASE
          WHEN status IN ('completed', 'delivered', 'ready')
            AND updated_at IS NOT NULL
          THEN updated_at - created_at
        END
      )) / 60,
      0
    )
  ) INTO result
  FROM public.orders
  WHERE tenant_id = p_tenant_id
    AND created_at >= p_start_date
    AND created_at < p_end_date;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.7 get_top_dishes ─────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_top_dishes(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_limit INT DEFAULT 10
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  SELECT json_agg(row_to_json(t)) INTO result
  FROM (
    SELECT
      oi.name,
      SUM(oi.quantity) AS total_quantity,
      SUM(oi.total_price) AS total_revenue
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE oi.tenant_id = p_tenant_id
      AND o.created_at >= p_start_date
      AND o.created_at < p_end_date
      AND o.status NOT IN ('cancelled')
    GROUP BY oi.name
    ORDER BY total_quantity DESC
    LIMIT p_limit
  ) t;
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.8 get_orders_by_hour ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_orders_by_hour(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  SELECT json_agg(row_to_json(t)) INTO result
  FROM (
    SELECT
      EXTRACT(HOUR FROM created_at) AS hour,
      COUNT(*) AS order_count,
      COALESCE(SUM(total), 0) AS revenue
    FROM public.orders
    WHERE tenant_id = p_tenant_id
      AND created_at >= p_start_date
      AND created_at < p_end_date
      AND status NOT IN ('cancelled')
    GROUP BY EXTRACT(HOUR FROM created_at)
    ORDER BY hour
  ) t;
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.9 get_recommended_restaurants ─────────────────────────────────────────
-- Verificar que p_user_id sea el usuario actual o super_admin.

CREATE OR REPLACE FUNCTION public.get_recommended_restaurants(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  description TEXT,
  logo_url TEXT,
  cover_image_url TEXT,
  cuisine_type JSONB,
  rating DECIMAL,
  total_reviews INTEGER,
  delivery_enabled BOOLEAN,
  takeaway_enabled BOOLEAN,
  delivery_radius_km DECIMAL,
  minimum_order_amount DECIMAL,
  delivery_fee DECIMAL,
  estimated_delivery_time_min INTEGER,
  average_price_range TEXT,
  city TEXT,
  latitude DECIMAL,
  longitude DECIMAL,
  is_featured BOOLEAN,
  status TEXT,
  score NUMERIC
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Solo puedes consultar tus propias recomendaciones (o ser super_admin)
  IF p_user_id != auth.uid() AND NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'No autorizado: solo puedes consultar tus propias recomendaciones';
  END IF;

  RETURN QUERY
  WITH user_cuisines AS (
    SELECT DISTINCT jsonb_array_elements_text(t.cuisine_type) AS cuisine
    FROM public.orders o
    JOIN public.tenants t ON t.id = o.tenant_id
    WHERE o.customer_id = p_user_id
      AND o.status NOT IN ('cancelled')
  ),
  fav_cuisines AS (
    SELECT DISTINCT jsonb_array_elements_text(t.cuisine_type) AS cuisine
    FROM public.favorites f
    JOIN public.tenants t ON t.id = f.tenant_id
    WHERE f.user_id = p_user_id
  ),
  all_preferred AS (
    SELECT cuisine FROM user_cuisines
    UNION
    SELECT cuisine FROM fav_cuisines
  ),
  scored AS (
    SELECT
      t.id, t.name, t.slug, t.description, t.logo_url, t.cover_image_url,
      t.cuisine_type, t.rating, t.total_reviews,
      t.delivery_enabled, t.takeaway_enabled, t.delivery_radius_km,
      t.minimum_order_amount, t.delivery_fee, t.estimated_delivery_time_min,
      t.average_price_range, t.city, t.latitude, t.longitude,
      t.is_featured, t.status,
      (
        COALESCE((
          SELECT COUNT(*)::NUMERIC * 3
          FROM all_preferred ap
          WHERE ap.cuisine IN (
            SELECT jsonb_array_elements_text(t.cuisine_type)
          )
        ), 0)
        + COALESCE(t.rating::NUMERIC, 0)
        + LEAST(COALESCE(t.total_orders::NUMERIC, 0) / 10.0, 5)
        + CASE WHEN t.is_featured THEN 2 ELSE 0 END
      ) AS score
    FROM public.tenants t
    WHERE t.status = 'active'
      AND t.id NOT IN (
        SELECT o.tenant_id FROM public.orders o
        WHERE o.customer_id = p_user_id
          AND o.created_at > NOW() - INTERVAL '3 days'
      )
      AND t.id NOT IN (
        SELECT f.tenant_id FROM public.favorites f
        WHERE f.user_id = p_user_id
      )
  )
  SELECT
    s.id, s.name, s.slug, s.description, s.logo_url, s.cover_image_url,
    s.cuisine_type, s.rating, s.total_reviews,
    s.delivery_enabled, s.takeaway_enabled, s.delivery_radius_km,
    s.minimum_order_amount, s.delivery_fee, s.estimated_delivery_time_min,
    s.average_price_range, s.city, s.latitude, s.longitude,
    s.is_featured, s.status, s.score
  FROM scored s
  ORDER BY s.score DESC, s.rating DESC
  LIMIT 10;
END;
$$;

-- ─── 6.10 insert_audit_log — Verificar acceso al tenant ─────────────────────

CREATE OR REPLACE FUNCTION public.insert_audit_log(
  p_action TEXT,
  p_entity_type TEXT,
  p_entity_id UUID DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_old_data JSONB DEFAULT NULL,
  p_new_data JSONB DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  -- Verificar autorización: si hay tenant_id, verificar acceso
  IF p_tenant_id IS NOT NULL THEN
    PERFORM public.verify_tenant_access(p_tenant_id);
  ELSIF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Solo super admins pueden crear logs sin tenant';
  END IF;

  INSERT INTO public.audit_logs (
    tenant_id, user_id, action, entity_type, entity_id,
    old_data, new_data, metadata
  ) VALUES (
    p_tenant_id, auth.uid(), p_action, p_entity_type, p_entity_id,
    p_old_data, p_new_data, p_metadata
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── 6.11 log_activity — Verificar acceso al tenant ─────────────────────────

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
  -- Verificar autorización
  PERFORM public.verify_tenant_access(p_tenant_id);

  INSERT INTO public.activity_logs (tenant_id, user_id, action, entity_type, entity_id, details)
  VALUES (p_tenant_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_details)
  RETURNING id INTO v_log_id;
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

COMMIT;

-- ============================================================================
-- RESUMEN DE CAMBIOS
-- ============================================================================
--
-- FUNCIONES MODIFICADAS (search_path):           24
-- FUNCIONES REESCRITAS (auth + search_path):     11
-- FUNCIONES NUEVAS:                               2 (verify_tenant_access, auto_assign_tenant_owner)
-- TRIGGERS NUEVOS:                                1 (on_tenant_created_assign_owner)
-- POLÍTICAS ELIMINADAS:                           4 (memberships_insert, notifications_insert,
--                                                    audit_insert, promotions_manage_staff,
--                                                    "Staff can manage own menu design")
-- POLÍTICAS CREADAS:                             16
-- ÍNDICES NUEVOS:                                 1 (idx_memberships_unique_tenant_user)
--
-- NOTA PARA EL EQUIPO:
-- Si el flujo de onboarding en la app hace INSERT directo en tenant_memberships
-- después de crear un tenant, ese INSERT ya no es necesario porque el trigger
-- on_tenant_created_assign_owner lo hace automáticamente. La app puede:
--   1. Solo INSERT en tenants → el trigger crea la membresía 'owner'.
--   2. O seguir haciendo ambos INSERT → ON CONFLICT DO NOTHING evita duplicados.
-- ============================================================================

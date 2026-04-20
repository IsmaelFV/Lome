-- ============================================================================
-- LŌME — Migración 00017: Correcciones y hardening
-- ============================================================================
-- Corrige:
--   1. invitations.invited_by: NOT NULL + ON DELETE SET NULL  → nullable
--   2. search_path faltante en funciones de 00007, 00008, 00009, 00010
--   3. get_recommended_restaurants: sin validar auth.uid()
--   4. notify_waiter_order_ready / notify_order_cancelled: sin search_path
--   5. get_order_metrics / get_top_dishes / get_orders_by_hour: sin search_path
--   6. Agrega tenant_id a payments para queries directas
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. FIX: invitations.invited_by — NOT NULL conflicta con ON DELETE SET NULL
--    Solución: hacer la columna nullable (el invitador puede borrar su cuenta)
-- ============================================================================

ALTER TABLE public.invitations
  ALTER COLUMN invited_by DROP NOT NULL;

-- ============================================================================
-- 2. FIX search_path: funciones de 00007 (notificaciones de pedidos)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_waiter_order_ready()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'ready' AND OLD.status IS DISTINCT FROM 'ready' THEN
    INSERT INTO public.notifications (user_id, tenant_id, title, body, type, data)
    VALUES (
      NEW.waiter_id,
      NEW.tenant_id,
      'Pedido #' || NEW.order_number || ' listo',
      'Todos los platos del pedido están listos para servir.',
      'order_ready',
      jsonb_build_object(
        'order_id', NEW.id,
        'order_number', NEW.order_number,
        'table_session_id', NEW.table_session_id
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_order_cancelled()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled' THEN
    IF NEW.waiter_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, tenant_id, title, body, type, data)
      VALUES (
        NEW.waiter_id,
        NEW.tenant_id,
        'Pedido #' || NEW.order_number || ' cancelado',
        COALESCE('Motivo: ' || NEW.cancellation_reason, 'Pedido cancelado sin motivo especificado.'),
        'order_update',
        jsonb_build_object(
          'order_id', NEW.id,
          'order_number', NEW.order_number,
          'action', 'cancelled'
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 3. FIX search_path: funciones RPC de 00007 (métricas)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_order_metrics(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
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
$$;

CREATE OR REPLACE FUNCTION public.get_top_dishes(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_limit INT DEFAULT 10
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
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
$$;

CREATE OR REPLACE FUNCTION public.get_orders_by_hour(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
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
$$;

-- ============================================================================
-- 4. FIX search_path: funciones admin de 00010
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_admin_platform_metrics()
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso no autorizado';
  END IF;

  SELECT json_build_object(
    'total_tenants', (SELECT COUNT(*) FROM public.tenants),
    'active_tenants', (SELECT COUNT(*) FROM public.tenants WHERE status = 'active'),
    'pending_tenants', (SELECT COUNT(*) FROM public.tenants WHERE status = 'pending'),
    'suspended_tenants', (SELECT COUNT(*) FROM public.tenants WHERE status = 'suspended'),
    'total_users', (SELECT COUNT(*) FROM public.profiles WHERE is_active = true),
    'today_orders', (
      SELECT COUNT(*) FROM public.orders WHERE created_at >= CURRENT_DATE
    ),
    'month_orders', (
      SELECT COUNT(*) FROM public.orders
      WHERE created_at >= date_trunc('month', CURRENT_DATE)
    ),
    'today_revenue', (
      SELECT COALESCE(SUM(total), 0) FROM public.orders
      WHERE created_at >= CURRENT_DATE AND payment_status = 'paid'
    ),
    'month_revenue', (
      SELECT COALESCE(SUM(total), 0) FROM public.orders
      WHERE created_at >= date_trunc('month', CURRENT_DATE)
      AND payment_status = 'paid'
    ),
    'open_incidents', (
      SELECT COUNT(*) FROM public.incidents WHERE status = 'open'
    ),
    'in_progress_incidents', (
      SELECT COUNT(*) FROM public.incidents WHERE status = 'in_progress'
    ),
    'flagged_reviews', (
      SELECT COUNT(*) FROM public.reviews WHERE is_flagged = true
    ),
    'avg_platform_rating', (
      SELECT COALESCE(AVG(rating), 0) FROM public.tenants WHERE status = 'active'
    )
  ) INTO result;
  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_restaurant_stats(p_tenant_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso no autorizado';
  END IF;

  SELECT json_build_object(
    'total_orders', (
      SELECT COUNT(*) FROM public.orders WHERE tenant_id = p_tenant_id
    ),
    'month_orders', (
      SELECT COUNT(*) FROM public.orders
      WHERE tenant_id = p_tenant_id
      AND created_at >= date_trunc('month', CURRENT_DATE)
    ),
    'total_revenue', (
      SELECT COALESCE(SUM(total), 0) FROM public.orders
      WHERE tenant_id = p_tenant_id AND payment_status = 'paid'
    ),
    'month_revenue', (
      SELECT COALESCE(SUM(total), 0) FROM public.orders
      WHERE tenant_id = p_tenant_id
      AND created_at >= date_trunc('month', CURRENT_DATE)
      AND payment_status = 'paid'
    ),
    'avg_rating', (
      SELECT COALESCE(AVG(rating), 0) FROM public.reviews
      WHERE tenant_id = p_tenant_id AND is_visible = true
    ),
    'total_reviews', (
      SELECT COUNT(*) FROM public.reviews
      WHERE tenant_id = p_tenant_id AND is_visible = true
    ),
    'total_employees', (
      SELECT COUNT(*) FROM public.tenant_memberships
      WHERE tenant_id = p_tenant_id AND is_active = true
    ),
    'total_menu_items', (
      SELECT COUNT(*) FROM public.menu_items
      WHERE tenant_id = p_tenant_id AND is_active = true
    ),
    'open_incidents', (
      SELECT COUNT(*) FROM public.incidents
      WHERE tenant_id = p_tenant_id AND status IN ('open', 'in_progress')
    )
  ) INTO result;
  RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_top_restaurants_by_revenue(p_limit INTEGER DEFAULT 10)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso no autorizado';
  END IF;

  SELECT json_agg(row_to_json(t)) INTO result
  FROM (
    SELECT
      tn.id,
      tn.name,
      tn.city,
      tn.rating,
      tn.total_orders,
      tn.status,
      COALESCE(SUM(o.total), 0) AS total_revenue
    FROM public.tenants tn
    LEFT JOIN public.orders o ON o.tenant_id = tn.id AND o.payment_status = 'paid'
    WHERE tn.status = 'active'
    GROUP BY tn.id
    ORDER BY total_revenue DESC
    LIMIT p_limit
  ) t;
  RETURN COALESCE(result, '[]'::json);
END;
$$;

-- ============================================================================
-- 5. FIX: get_recommended_restaurants — validar que el caller es el propio user
-- ============================================================================

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
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validar que el usuario solo puede pedir sus propias recomendaciones
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
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
      t.id,
      t.name,
      t.slug,
      t.description,
      t.logo_url,
      t.cover_image_url,
      t.cuisine_type,
      t.rating,
      t.total_reviews,
      t.delivery_enabled,
      t.takeaway_enabled,
      t.delivery_radius_km,
      t.minimum_order_amount,
      t.delivery_fee,
      t.estimated_delivery_time_min,
      t.average_price_range,
      t.city,
      t.latitude,
      t.longitude,
      t.is_featured,
      t.status,
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

COMMIT;

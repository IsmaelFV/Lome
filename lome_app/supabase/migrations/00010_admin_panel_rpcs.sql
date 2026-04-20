-- ============================================================================
-- LŌME - RPCs adicionales para el Panel de Administración
-- ============================================================================

-- ─── Stats de plataforma con métricas extendidas ─────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_platform_metrics()
RETURNS JSON AS $$
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
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ─── Stats por restaurante para admin ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_restaurant_stats(p_tenant_id UUID)
RETURNS JSON AS $$
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
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ─── Top restaurantes por ingresos ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_top_restaurants_by_revenue(p_limit INTEGER DEFAULT 10)
RETURNS JSON AS $$
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
      COALESCE(SUM(o.total), 0) as total_revenue
    FROM public.tenants tn
    LEFT JOIN public.orders o ON o.tenant_id = tn.id AND o.payment_status = 'paid'
    WHERE tn.status = 'active'
    GROUP BY tn.id
    ORDER BY total_revenue DESC
    LIMIT p_limit
  ) t;
  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

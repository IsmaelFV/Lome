-- ============================================================================
-- LŌME - Sistema de Auditoría y Monitorización Técnica
-- ============================================================================
-- Migración: 00012
-- Descripción:
--   1. Sistema de auditoría automática: triggers en tablas críticas que
--      registran automáticamente cada INSERT/UPDATE/DELETE en audit_logs.
--   2. Tablas de monitorización técnica: error_logs, api_usage_logs,
--      response_time_logs, y RPCs de consulta para el dashboard de admin.
-- ============================================================================

-- ============================================================================
-- PARTE 1: SISTEMA DE AUDITORÍA AUTOMÁTICA
-- ============================================================================

-- Función genérica de auditoría invocada por triggers.
-- Registra automáticamente la acción, entidad, datos antiguos y nuevos.
CREATE OR REPLACE FUNCTION public.audit_trigger_fn()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_tenant_id UUID;
  v_action TEXT;
  v_old JSONB;
  v_new JSONB;
BEGIN
  -- Obtener el user_id del JWT actual (puede ser NULL en triggers internos)
  v_user_id := auth.uid();

  -- Determinar la acción
  v_action := TG_OP; -- INSERT, UPDATE, DELETE

  -- Serializar datos
  IF TG_OP = 'DELETE' THEN
    v_old := to_jsonb(OLD);
    v_new := NULL;
    v_tenant_id := CASE WHEN TG_TABLE_NAME IN ('tenants') THEN OLD.id
                        WHEN OLD ? 'tenant_id' THEN (OLD.tenant_id)::UUID
                        ELSE NULL END;
  ELSIF TG_OP = 'INSERT' THEN
    v_old := NULL;
    v_new := to_jsonb(NEW);
    v_tenant_id := CASE WHEN TG_TABLE_NAME IN ('tenants') THEN NEW.id
                        WHEN NEW ? 'tenant_id' THEN (NEW.tenant_id)::UUID
                        ELSE NULL END;
  ELSE -- UPDATE
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    v_tenant_id := CASE WHEN TG_TABLE_NAME IN ('tenants') THEN NEW.id
                        WHEN NEW ? 'tenant_id' THEN (NEW.tenant_id)::UUID
                        ELSE NULL END;
  END IF;

  INSERT INTO public.audit_logs (
    tenant_id, user_id, action, entity_type, entity_id,
    old_data, new_data, metadata
  ) VALUES (
    v_tenant_id,
    v_user_id,
    lower(v_action),
    TG_TABLE_NAME,
    CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
    v_old,
    v_new,
    jsonb_build_object(
      'trigger', TG_NAME,
      'schema', TG_TABLE_SCHEMA,
      'timestamp', NOW()
    )
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.audit_trigger_fn() IS
  'Función genérica que registra INSERT/UPDATE/DELETE en audit_logs.'
  ' Se adjunta a tablas críticas mediante triggers.';

-- ---------------------------------------------------------------------------
-- Triggers de auditoría en tablas críticas
-- ---------------------------------------------------------------------------

-- Pedidos: cada cambio de estado es un evento auditable
CREATE TRIGGER audit_orders
  AFTER INSERT OR UPDATE OR DELETE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Ítems de pedido
CREATE TRIGGER audit_order_items
  AFTER INSERT OR UPDATE OR DELETE ON public.order_items
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Pagos
CREATE TRIGGER audit_payments
  AFTER INSERT OR UPDATE OR DELETE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Restaurantes (tenants): alta, activación, suspensión
CREATE TRIGGER audit_tenants
  AFTER INSERT OR UPDATE OR DELETE ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Membresías: asignación/revocación de roles
CREATE TRIGGER audit_memberships
  AFTER INSERT OR UPDATE OR DELETE ON public.tenant_memberships
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Menú: cambios en ítems del menú
CREATE TRIGGER audit_menu_items
  AFTER INSERT OR UPDATE OR DELETE ON public.menu_items
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Inventario: movimientos de stock
CREATE TRIGGER audit_inventory_movements
  AFTER INSERT ON public.inventory_movements
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Suscripciones: cambios de plan, estado
CREATE TRIGGER audit_subscriptions
  AFTER INSERT OR UPDATE OR DELETE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Facturas
CREATE TRIGGER audit_invoices
  AFTER INSERT OR UPDATE ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Incidencias
CREATE TRIGGER audit_incidents
  AFTER INSERT OR UPDATE ON public.incidents
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Reseñas (moderación)
CREATE TRIGGER audit_reviews
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Perfiles de usuario
CREATE TRIGGER audit_profiles
  AFTER UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- Promociones
CREATE TRIGGER audit_promotions
  AFTER INSERT OR UPDATE OR DELETE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_fn();

-- ---------------------------------------------------------------------------
-- RPC: Insertar log de auditoría manual (desde Edge Functions o cliente)
-- ---------------------------------------------------------------------------

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
  INSERT INTO public.audit_logs (
    tenant_id, user_id, action, entity_type, entity_id,
    old_data, new_data, metadata
  ) VALUES (
    p_tenant_id,
    auth.uid(),
    p_action,
    p_entity_type,
    p_entity_id,
    p_old_data,
    p_new_data,
    p_metadata
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.insert_audit_log IS
  'Inserta un registro de auditoría manualmente desde clientes o Edge Functions.';

-- ---------------------------------------------------------------------------
-- RPC: Consultar logs de auditoría (solo super_admin)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_audit_logs(
  p_entity_type TEXT DEFAULT NULL,
  p_action TEXT DEFAULT NULL,
  p_user_id UUID DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_from TIMESTAMPTZ DEFAULT NULL,
  p_to TIMESTAMPTZ DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  tenant_id UUID,
  user_id UUID,
  user_name TEXT,
  action TEXT,
  entity_type TEXT,
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  metadata JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol super_admin';
  END IF;

  RETURN QUERY
  SELECT
    al.id,
    al.tenant_id,
    al.user_id,
    p.full_name AS user_name,
    al.action,
    al.entity_type,
    al.entity_id,
    al.old_data,
    al.new_data,
    al.metadata,
    al.created_at
  FROM public.audit_logs al
  LEFT JOIN public.profiles p ON p.id = al.user_id
  WHERE (p_entity_type IS NULL OR al.entity_type = p_entity_type)
    AND (p_action IS NULL OR al.action = p_action)
    AND (p_user_id IS NULL OR al.user_id = p_user_id)
    AND (p_tenant_id IS NULL OR al.tenant_id = p_tenant_id)
    AND (p_from IS NULL OR al.created_at >= p_from)
    AND (p_to IS NULL OR al.created_at <= p_to)
  ORDER BY al.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- RPC: Resumen de auditoría para dashboard admin
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_audit_summary(
  p_hours INTEGER DEFAULT 24
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_since TIMESTAMPTZ;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol super_admin';
  END IF;

  v_since := NOW() - (p_hours || ' hours')::INTERVAL;

  SELECT jsonb_build_object(
    'total_events', COUNT(*),
    'actions', (
      SELECT jsonb_object_agg(action, cnt)
      FROM (
        SELECT action, COUNT(*) AS cnt
        FROM public.audit_logs
        WHERE created_at >= v_since
        GROUP BY action
      ) sub
    ),
    'entities', (
      SELECT jsonb_object_agg(entity_type, cnt)
      FROM (
        SELECT entity_type, COUNT(*) AS cnt
        FROM public.audit_logs
        WHERE created_at >= v_since
        GROUP BY entity_type
      ) sub
    ),
    'top_users', (
      SELECT jsonb_agg(row_to_json(sub))
      FROM (
        SELECT al.user_id, p.full_name, COUNT(*) AS event_count
        FROM public.audit_logs al
        LEFT JOIN public.profiles p ON p.id = al.user_id
        WHERE al.created_at >= v_since AND al.user_id IS NOT NULL
        GROUP BY al.user_id, p.full_name
        ORDER BY event_count DESC
        LIMIT 10
      ) sub
    ),
    'period_hours', p_hours,
    'since', v_since
  ) INTO v_result
  FROM public.audit_logs
  WHERE created_at >= v_since;

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;


-- ============================================================================
-- PARTE 2: SISTEMA DE MONITORIZACIÓN TÉCNICA
-- ============================================================================

-- ---------------------------------------------------------------------------
-- TABLA: error_logs (errores del sistema)
-- ---------------------------------------------------------------------------

CREATE TABLE public.error_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  severity TEXT NOT NULL DEFAULT 'error'
    CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),
  source TEXT NOT NULL, -- 'flutter', 'edge_function', 'database', 'rls'
  message TEXT NOT NULL,
  stack_trace TEXT,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL,
  device_info JSONB DEFAULT '{}',
  app_version TEXT,
  context JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_error_logs_severity ON public.error_logs(severity);
CREATE INDEX idx_error_logs_source ON public.error_logs(source);
CREATE INDEX idx_error_logs_created ON public.error_logs(created_at);
CREATE INDEX idx_error_logs_user ON public.error_logs(user_id);

COMMENT ON TABLE public.error_logs IS
  'Registro centralizado de errores de toda la plataforma (Flutter, Edge Functions, DB)';

-- ---------------------------------------------------------------------------
-- TABLA: api_usage_logs (uso de API / Edge Functions)
-- ---------------------------------------------------------------------------

CREATE TABLE public.api_usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL,
  endpoint TEXT NOT NULL,        -- '/rest/v1/orders', '/functions/v1/delete-account'
  method TEXT NOT NULL,          -- 'GET', 'POST', 'PATCH', 'DELETE', 'RPC'
  status_code INTEGER,
  response_time_ms INTEGER,      -- Tiempo de respuesta en milisegundos
  request_size_bytes INTEGER,
  response_size_bytes INTEGER,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_usage_endpoint ON public.api_usage_logs(endpoint);
CREATE INDEX idx_api_usage_method ON public.api_usage_logs(method);
CREATE INDEX idx_api_usage_status ON public.api_usage_logs(status_code);
CREATE INDEX idx_api_usage_created ON public.api_usage_logs(created_at);
CREATE INDEX idx_api_usage_user ON public.api_usage_logs(user_id);
CREATE INDEX idx_api_usage_response_time ON public.api_usage_logs(response_time_ms);

COMMENT ON TABLE public.api_usage_logs IS
  'Registro de uso de la API: endpoints, tiempos de respuesta, códigos de estado';

-- ---------------------------------------------------------------------------
-- TABLA: performance_metrics (métricas de rendimiento agregadas)
-- ---------------------------------------------------------------------------

CREATE TABLE public.performance_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metric_name TEXT NOT NULL,     -- 'avg_response_time', 'error_rate', 'active_users'
  metric_value DOUBLE PRECISION NOT NULL,
  unit TEXT,                     -- 'ms', 'percent', 'count', 'bytes'
  dimensions JSONB DEFAULT '{}', -- { "endpoint": "/orders", "method": "GET" }
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_perf_metrics_name ON public.performance_metrics(metric_name);
CREATE INDEX idx_perf_metrics_period ON public.performance_metrics(period_start, period_end);

COMMENT ON TABLE public.performance_metrics IS
  'Métricas de rendimiento agregadas por periodo (computadas periódicamente)';

-- ---------------------------------------------------------------------------
-- RLS POLICIES
-- ---------------------------------------------------------------------------

ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_metrics ENABLE ROW LEVEL SECURITY;

-- Super admins: acceso total a todos los logs
CREATE POLICY "Super admins full access to error_logs"
  ON public.error_logs FOR ALL
  USING (public.is_super_admin());

CREATE POLICY "Super admins full access to api_usage_logs"
  ON public.api_usage_logs FOR ALL
  USING (public.is_super_admin());

CREATE POLICY "Super admins full access to performance_metrics"
  ON public.performance_metrics FOR ALL
  USING (public.is_super_admin());

-- Cualquier usuario autenticado puede insertar errores (para reporte desde Flutter)
CREATE POLICY "Authenticated users can insert error_logs"
  ON public.error_logs FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Cualquier usuario autenticado puede insertar api_usage (para reporte desde Flutter)
CREATE POLICY "Authenticated users can insert api_usage_logs"
  ON public.api_usage_logs FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- ---------------------------------------------------------------------------
-- RPC: Insertar error desde clientes (Flutter, Edge Functions)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_error(
  p_severity TEXT,
  p_source TEXT,
  p_message TEXT,
  p_stack_trace TEXT DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_device_info JSONB DEFAULT '{}',
  p_app_version TEXT DEFAULT NULL,
  p_context JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.error_logs (
    severity, source, message, stack_trace,
    user_id, tenant_id, device_info, app_version, context
  ) VALUES (
    p_severity, p_source, p_message, p_stack_trace,
    auth.uid(), p_tenant_id, p_device_info, p_app_version, p_context
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- RPC: Registrar uso de API desde clientes
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_api_usage(
  p_endpoint TEXT,
  p_method TEXT,
  p_status_code INTEGER DEFAULT NULL,
  p_response_time_ms INTEGER DEFAULT NULL,
  p_request_size_bytes INTEGER DEFAULT NULL,
  p_response_size_bytes INTEGER DEFAULT NULL,
  p_tenant_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.api_usage_logs (
    user_id, tenant_id, endpoint, method, status_code,
    response_time_ms, request_size_bytes, response_size_bytes, metadata
  ) VALUES (
    auth.uid(), p_tenant_id, p_endpoint, p_method, p_status_code,
    p_response_time_ms, p_request_size_bytes, p_response_size_bytes, p_metadata
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- RPC: Dashboard de monitorización (solo super_admin)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_monitoring_dashboard(
  p_hours INTEGER DEFAULT 24
)
RETURNS JSONB AS $$
DECLARE
  v_since TIMESTAMPTZ;
  v_result JSONB;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol super_admin';
  END IF;

  v_since := NOW() - (p_hours || ' hours')::INTERVAL;

  SELECT jsonb_build_object(
    -- Error stats
    'errors', (
      SELECT jsonb_build_object(
        'total', COUNT(*),
        'critical', COUNT(*) FILTER (WHERE severity = 'critical'),
        'error', COUNT(*) FILTER (WHERE severity = 'error'),
        'warning', COUNT(*) FILTER (WHERE severity = 'warning'),
        'by_source', (
          SELECT jsonb_object_agg(source, cnt)
          FROM (
            SELECT source, COUNT(*) AS cnt
            FROM public.error_logs
            WHERE created_at >= v_since
            GROUP BY source
          ) s
        )
      )
      FROM public.error_logs
      WHERE created_at >= v_since
    ),
    -- API usage stats
    'api_usage', (
      SELECT jsonb_build_object(
        'total_requests', COUNT(*),
        'avg_response_time_ms', ROUND(AVG(response_time_ms)::NUMERIC, 2),
        'p95_response_time_ms', ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms)::NUMERIC, 2),
        'p99_response_time_ms', ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time_ms)::NUMERIC, 2),
        'error_rate_percent', ROUND(
          (COUNT(*) FILTER (WHERE status_code >= 400)::NUMERIC /
           GREATEST(COUNT(*), 1) * 100), 2
        ),
        'by_method', (
          SELECT jsonb_object_agg(method, cnt)
          FROM (
            SELECT method, COUNT(*) AS cnt
            FROM public.api_usage_logs
            WHERE created_at >= v_since
            GROUP BY method
          ) s
        ),
        'top_endpoints', (
          SELECT jsonb_agg(row_to_json(sub))
          FROM (
            SELECT endpoint, COUNT(*) AS hits,
                   ROUND(AVG(response_time_ms)::NUMERIC, 2) AS avg_ms
            FROM public.api_usage_logs
            WHERE created_at >= v_since
            GROUP BY endpoint
            ORDER BY hits DESC
            LIMIT 10
          ) sub
        ),
        'slow_endpoints', (
          SELECT jsonb_agg(row_to_json(sub))
          FROM (
            SELECT endpoint, method,
                   ROUND(AVG(response_time_ms)::NUMERIC, 2) AS avg_ms,
                   COUNT(*) AS sample_count
            FROM public.api_usage_logs
            WHERE created_at >= v_since AND response_time_ms IS NOT NULL
            GROUP BY endpoint, method
            HAVING AVG(response_time_ms) > 1000
            ORDER BY avg_ms DESC
            LIMIT 10
          ) sub
        )
      )
      FROM public.api_usage_logs
      WHERE created_at >= v_since
    ),
    -- Recent critical errors
    'recent_critical_errors', (
      SELECT jsonb_agg(row_to_json(sub))
      FROM (
        SELECT id, severity, source, message, app_version, created_at
        FROM public.error_logs
        WHERE created_at >= v_since AND severity IN ('critical', 'error')
        ORDER BY created_at DESC
        LIMIT 20
      ) sub
    ),
    'period_hours', p_hours,
    'generated_at', NOW()
  ) INTO v_result;

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- RPC: Errores recientes paginados (solo super_admin)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_error_logs(
  p_severity TEXT DEFAULT NULL,
  p_source TEXT DEFAULT NULL,
  p_from TIMESTAMPTZ DEFAULT NULL,
  p_to TIMESTAMPTZ DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  severity TEXT,
  source TEXT,
  message TEXT,
  stack_trace TEXT,
  user_id UUID,
  user_name TEXT,
  tenant_id UUID,
  device_info JSONB,
  app_version TEXT,
  context JSONB,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol super_admin';
  END IF;

  RETURN QUERY
  SELECT
    el.id, el.severity, el.source, el.message, el.stack_trace,
    el.user_id, p.full_name AS user_name, el.tenant_id,
    el.device_info, el.app_version, el.context, el.created_at
  FROM public.error_logs el
  LEFT JOIN public.profiles p ON p.id = el.user_id
  WHERE (p_severity IS NULL OR el.severity = p_severity)
    AND (p_source IS NULL OR el.source = p_source)
    AND (p_from IS NULL OR el.created_at >= p_from)
    AND (p_to IS NULL OR el.created_at <= p_to)
  ORDER BY el.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- Política de retención: función para purgar logs antiguos
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.purge_old_logs(
  p_retention_days INTEGER DEFAULT 90
)
RETURNS JSONB AS $$
DECLARE
  v_cutoff TIMESTAMPTZ;
  v_audit_count BIGINT;
  v_error_count BIGINT;
  v_api_count BIGINT;
  v_perf_count BIGINT;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso denegado: se requiere rol super_admin';
  END IF;

  v_cutoff := NOW() - (p_retention_days || ' days')::INTERVAL;

  DELETE FROM public.audit_logs WHERE created_at < v_cutoff;
  GET DIAGNOSTICS v_audit_count = ROW_COUNT;

  DELETE FROM public.error_logs WHERE created_at < v_cutoff;
  GET DIAGNOSTICS v_error_count = ROW_COUNT;

  DELETE FROM public.api_usage_logs WHERE created_at < v_cutoff;
  GET DIAGNOSTICS v_api_count = ROW_COUNT;

  DELETE FROM public.performance_metrics WHERE created_at < v_cutoff;
  GET DIAGNOSTICS v_perf_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'purged_before', v_cutoff,
    'audit_logs_deleted', v_audit_count,
    'error_logs_deleted', v_error_count,
    'api_usage_logs_deleted', v_api_count,
    'performance_metrics_deleted', v_perf_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- Realtime para errores críticos (para notificación instantánea al admin)
-- ---------------------------------------------------------------------------

ALTER PUBLICATION supabase_realtime ADD TABLE public.error_logs;

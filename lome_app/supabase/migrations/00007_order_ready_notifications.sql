-- ============================================================================
-- Migración 007: Notificaciones automáticas de pedido listo + campos extras
-- ============================================================================

-- Trigger: cuando TODOS los items de un pedido están en ready/served/cancelled
-- y el pedido pasa a 'ready', se inserta una notificación para el camarero.

CREATE OR REPLACE FUNCTION notify_waiter_order_ready()
RETURNS TRIGGER AS $$
BEGIN
  -- Solo actuar cuando el pedido pasa a 'ready'
  IF NEW.status = 'ready' AND OLD.status IS DISTINCT FROM 'ready' THEN
    INSERT INTO notifications (user_id, tenant_id, title, body, type, data)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_waiter_order_ready ON orders;
CREATE TRIGGER trg_notify_waiter_order_ready
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_waiter_order_ready();

-- Trigger: cuando un pedido se cancela, notificar a cocina (todos los staff del tenant)
CREATE OR REPLACE FUNCTION notify_order_cancelled()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM 'cancelled' THEN
    -- Notificar al camarero asignado
    IF NEW.waiter_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, tenant_id, title, body, type, data)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_order_cancelled ON orders;
CREATE TRIGGER trg_notify_order_cancelled
  AFTER UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION notify_order_cancelled();

-- ============================================================================
-- Vista materializada para métricas de pedidos (se refresca manualmente o con cron)
-- ============================================================================

-- Función RPC: Métricas de pedidos por período
CREATE OR REPLACE FUNCTION get_order_metrics(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
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
  FROM orders
  WHERE tenant_id = p_tenant_id
    AND created_at >= p_start_date
    AND created_at < p_end_date;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función RPC: Platos más vendidos por período
CREATE OR REPLACE FUNCTION get_top_dishes(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ,
  p_limit INT DEFAULT 10
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO result
  FROM (
    SELECT
      oi.name,
      SUM(oi.quantity) AS total_quantity,
      SUM(oi.total_price) AS total_revenue
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función RPC: Pedidos por hora del día (para gráfico)
CREATE OR REPLACE FUNCTION get_orders_by_hour(
  p_tenant_id UUID,
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_agg(row_to_json(t)) INTO result
  FROM (
    SELECT
      EXTRACT(HOUR FROM created_at) AS hour,
      COUNT(*) AS order_count,
      COALESCE(SUM(total), 0) AS revenue
    FROM orders
    WHERE tenant_id = p_tenant_id
      AND created_at >= p_start_date
      AND created_at < p_end_date
      AND status NOT IN ('cancelled')
    GROUP BY EXTRACT(HOUR FROM created_at)
    ORDER BY hour
  ) t;

  RETURN COALESCE(result, '[]'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

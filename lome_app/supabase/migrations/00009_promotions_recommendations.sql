-- ============================================================================
-- MIGRACIÓN 00009: Tabla promotions + RLS + RPCs de recomendaciones
-- ============================================================================

-- ============================================================================
-- ENUM: promotion_type
-- ============================================================================

CREATE TYPE public.promotion_type AS ENUM ('percentage', 'fixed', 'time_limited');

-- ============================================================================
-- TABLA: promotions
-- ============================================================================

CREATE TABLE public.promotions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  type public.promotion_type NOT NULL,
  value DECIMAL(10, 2) NOT NULL,          -- porcentaje (ej: 15.00) o monto fijo (ej: 5.00)
  minimum_order_amount DECIMAL(10, 2),     -- pedido mínimo para aplicar
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,                    -- NULL = sin límite temporal
  is_active BOOLEAN NOT NULL DEFAULT true,
  max_uses INTEGER,                        -- NULL = ilimitado
  current_uses INTEGER NOT NULL DEFAULT 0,
  code TEXT,                               -- código promocional opcional
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_promotions_tenant ON public.promotions(tenant_id);
CREATE INDEX idx_promotions_active ON public.promotions(is_active, start_date, end_date);
CREATE INDEX idx_promotions_code ON public.promotions(code) WHERE code IS NOT NULL;

CREATE TRIGGER promotions_updated_at
  BEFORE UPDATE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.promotions IS 'Promociones y descuentos de restaurantes';

-- ============================================================================
-- RLS: promotions
-- ============================================================================

ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;

-- Todos pueden ver promociones activas
CREATE POLICY "promotions_select_public" ON public.promotions
  FOR SELECT USING (
    is_active = true
    AND start_date <= NOW()
    AND (end_date IS NULL OR end_date > NOW())
  );

-- Staff del restaurante gestiona sus promociones
CREATE POLICY "promotions_manage_staff" ON public.promotions
  FOR ALL USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  ) WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ============================================================================
-- RPC: get_recommended_restaurants
-- Recomienda restaurantes basándose en:
--   1. Tipos de cocina de pedidos anteriores del usuario
--   2. Restaurantes favoritos del usuario (cocina similar)
--   3. Popularidad general (rating + total_orders)
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
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH user_cuisines AS (
    -- Tipos de cocina preferidos del usuario (basado en pedidos)
    SELECT DISTINCT jsonb_array_elements_text(t.cuisine_type) AS cuisine
    FROM public.orders o
    JOIN public.tenants t ON t.id = o.tenant_id
    WHERE o.customer_id = p_user_id
      AND o.status NOT IN ('cancelled')
  ),
  fav_cuisines AS (
    -- Tipos de cocina de restaurantes favoritos
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
        -- Puntuación por coincidencia de cocina preferida
        COALESCE((
          SELECT COUNT(*)::NUMERIC * 3
          FROM all_preferred ap
          WHERE ap.cuisine IN (
            SELECT jsonb_array_elements_text(t.cuisine_type)
          )
        ), 0)
        -- Bonus por rating
        + COALESCE(t.rating::NUMERIC, 0)
        -- Bonus por popularidad
        + LEAST(COALESCE(t.total_orders::NUMERIC, 0) / 10.0, 5)
        -- Bonus si es destacado
        + CASE WHEN t.is_featured THEN 2 ELSE 0 END
      ) AS score
    FROM public.tenants t
    WHERE t.status = 'active'
      -- Excluir restaurantes ya pedidos recientemente (últimos 3 días)
      AND t.id NOT IN (
        SELECT o.tenant_id FROM public.orders o
        WHERE o.customer_id = p_user_id
          AND o.created_at > NOW() - INTERVAL '3 days'
      )
      -- Excluir favoritos (ya los conoce)
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

COMMENT ON FUNCTION public.get_recommended_restaurants IS
  'Devuelve restaurantes recomendados según historial, favoritos y popularidad';

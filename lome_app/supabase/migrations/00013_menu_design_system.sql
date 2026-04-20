-- =============================================================================
-- 00013: Sistema de diseño digital de carta / menú
-- =============================================================================
-- Permite a cada restaurante personalizar su carta digital:
-- colores, fuentes, layouts, bloques y animaciones.
-- Los clientes acceden vía QR a una experiencia interactiva.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Tabla: menu_designs — configuración visual de la carta digital
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS menu_designs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,

  -- Tema de colores
  primary_color     TEXT NOT NULL DEFAULT '#FF6B35',
  secondary_color   TEXT NOT NULL DEFAULT '#2D3436',
  background_color  TEXT NOT NULL DEFAULT '#FAFAFA',
  accent_color      TEXT NOT NULL DEFAULT '#FDCB6E',
  card_color        TEXT NOT NULL DEFAULT '#FFFFFF',
  text_color        TEXT NOT NULL DEFAULT '#2D3436',

  -- Tipografía
  font_family        TEXT NOT NULL DEFAULT 'Poppins',
  header_font_family TEXT NOT NULL DEFAULT 'Playfair Display',
  font_size_base     INTEGER NOT NULL DEFAULT 14,

  -- Layout
  layout_style TEXT NOT NULL DEFAULT 'classic'
    CHECK (layout_style IN ('classic', 'modern', 'elegant', 'minimal', 'bold', 'rustic')),
  items_layout TEXT NOT NULL DEFAULT 'list'
    CHECK (items_layout IN ('list', 'grid', 'cards', 'magazine')),

  -- Opciones de visualización
  show_images       BOOLEAN NOT NULL DEFAULT true,
  show_prices       BOOLEAN NOT NULL DEFAULT true,
  show_descriptions BOOLEAN NOT NULL DEFAULT true,
  show_allergens    BOOLEAN NOT NULL DEFAULT true,
  show_calories     BOOLEAN NOT NULL DEFAULT false,
  show_prep_time    BOOLEAN NOT NULL DEFAULT false,
  show_tags         BOOLEAN NOT NULL DEFAULT true,

  -- Cabecera
  header_image_url       TEXT,
  logo_position          TEXT NOT NULL DEFAULT 'center'
    CHECK (logo_position IN ('left', 'center', 'right', 'hidden')),
  show_restaurant_info   BOOLEAN NOT NULL DEFAULT true,
  header_style           TEXT NOT NULL DEFAULT 'full'
    CHECK (header_style IN ('full', 'compact', 'minimal', 'hero')),

  -- Animaciones
  animation_style TEXT NOT NULL DEFAULT 'fade'
    CHECK (animation_style IN ('none', 'fade', 'slide', 'scale', 'stagger', 'elegant', 'playful')),
  animation_intensity TEXT NOT NULL DEFAULT 'medium'
    CHECK (animation_intensity IN ('subtle', 'medium', 'dramatic')),

  -- Bloques: lista ordenada de secciones personalizables
  -- Cada bloque: { "id": "uuid", "type": "...", "config": {...}, "animation": "..." }
  sections JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- Estilos adicionales / overrides
  custom_styles JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Metadatos
  is_published BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger de updated_at
CREATE TRIGGER set_menu_designs_updated_at
  BEFORE UPDATE ON menu_designs
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Índice para búsqueda rápida por tenant
CREATE INDEX IF NOT EXISTS idx_menu_designs_tenant
  ON menu_designs(tenant_id);

-- ---------------------------------------------------------------------------
-- RLS: solo el staff del restaurante puede gestionar su diseño
-- ---------------------------------------------------------------------------

ALTER TABLE menu_designs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Staff can manage own menu design"
  ON menu_designs
  USING (
    EXISTS (
      SELECT 1 FROM tenant_memberships
      WHERE tenant_memberships.tenant_id = menu_designs.tenant_id
        AND tenant_memberships.user_id = auth.uid()
        AND tenant_memberships.is_active = true
    )
    OR is_super_admin()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tenant_memberships
      WHERE tenant_memberships.tenant_id = menu_designs.tenant_id
        AND tenant_memberships.user_id = auth.uid()
        AND tenant_memberships.is_active = true
        AND tenant_memberships.role IN ('owner', 'manager')
    )
    OR is_super_admin()
  );

-- Lectura pública del diseño (los clientes necesitan verlo vía QR)
CREATE POLICY "Anyone can read published menu designs"
  ON menu_designs FOR SELECT
  USING (is_published = true);

-- ---------------------------------------------------------------------------
-- RPC: obtener o crear diseño de menú para un restaurante
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_or_create_menu_design(p_tenant_id UUID)
RETURNS SETOF menu_designs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Intentar obtener existente
  IF EXISTS (SELECT 1 FROM menu_designs WHERE tenant_id = p_tenant_id) THEN
    RETURN QUERY SELECT * FROM menu_designs WHERE tenant_id = p_tenant_id;
  ELSE
    -- Crear con valores por defecto y secciones iniciales
    RETURN QUERY
    INSERT INTO menu_designs (tenant_id, sections)
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

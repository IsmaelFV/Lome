-- ============================================================================
-- Migración 00004: Añadir shape/dimensiones a mesas + nuevos estados
-- ============================================================================

-- Tipo enumerado para la forma de la mesa
CREATE TYPE public.table_shape AS ENUM ('round', 'square', 'rectangle');

-- Nuevos campos en restaurant_tables
ALTER TABLE public.restaurant_tables
  ADD COLUMN shape public.table_shape NOT NULL DEFAULT 'square',
  ADD COLUMN width  DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  ADD COLUMN height DOUBLE PRECISION NOT NULL DEFAULT 1.0;

COMMENT ON COLUMN public.restaurant_tables.shape  IS 'Forma visual: round, square, rectangle';
COMMENT ON COLUMN public.restaurant_tables.width  IS 'Ancho relativo en el mapa (unidades de grid)';
COMMENT ON COLUMN public.restaurant_tables.height IS 'Alto relativo en el mapa (unidades de grid)';

-- Añadir estados faltantes al enum table_status
ALTER TYPE public.table_status ADD VALUE IF NOT EXISTS 'waiting_food';
ALTER TYPE public.table_status ADD VALUE IF NOT EXISTS 'waiting_payment';

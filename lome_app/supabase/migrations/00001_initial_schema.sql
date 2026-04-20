-- ============================================================================
-- LŌME - Esquema Completo de Base de Datos PostgreSQL (Supabase)
-- ============================================================================
-- Versión: 1.0.0
-- Descripción: Esquema multi-tenant con Row Level Security (RLS),
--              triggers, funciones auxiliares e índices optimizados.
-- ============================================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- ============================================================================
-- TIPOS ENUMERADOS
-- ============================================================================

CREATE TYPE public.user_role AS ENUM ('super_admin', 'owner', 'manager', 'chef', 'waiter', 'cashier', 'customer');
CREATE TYPE public.tenant_status AS ENUM ('active', 'pending', 'suspended', 'cancelled');
CREATE TYPE public.table_status AS ENUM ('available', 'occupied', 'reserved', 'maintenance');
CREATE TYPE public.order_type AS ENUM ('dine_in', 'takeaway', 'delivery');
CREATE TYPE public.order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'delivering', 'delivered', 'completed', 'cancelled');
CREATE TYPE public.payment_status AS ENUM ('pending', 'paid', 'refunded', 'failed');
CREATE TYPE public.order_item_status AS ENUM ('pending', 'preparing', 'ready', 'served', 'cancelled');
CREATE TYPE public.inventory_movement_type AS ENUM ('purchase', 'sale', 'adjustment', 'waste', 'transfer');
CREATE TYPE public.incident_priority AS ENUM ('critical', 'high', 'medium', 'low');
CREATE TYPE public.incident_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');

-- ============================================================================
-- FUNCIÓN AUXILIAR: updated_at automático
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCIÓN AUXILIAR: obtener tenant_id del usuario actual
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_current_tenant_id()
RETURNS UUID AS $$
BEGIN
  RETURN (current_setting('request.jwt.claims', true)::json ->> 'tenant_id')::UUID;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- FUNCIÓN AUXILIAR: verificar si el usuario es super_admin
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND is_super_admin = true
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- FUNCIÓN AUXILIAR: verificar rol del usuario en un tenant
-- ============================================================================

CREATE OR REPLACE FUNCTION public.has_role_in_tenant(
  p_tenant_id UUID,
  p_roles user_role[]
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.tenant_memberships
    WHERE user_id = auth.uid()
    AND tenant_id = p_tenant_id
    AND role = ANY(p_roles)
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- TABLA: profiles (extiende auth.users)
-- ============================================================================

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  is_super_admin BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.profiles IS 'Perfiles de usuario extendidos desde auth.users';

-- ============================================================================
-- TABLA: tenants (restaurantes)
-- ============================================================================

CREATE TABLE public.tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  logo_url TEXT,
  cover_image_url TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,

  -- Dirección
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT NOT NULL DEFAULT 'ES',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,

  -- Configuración del restaurante
  cuisine_type TEXT[] DEFAULT '{}',
  average_price_range TEXT, -- 'low', 'medium', 'high', 'premium'
  opening_hours JSONB DEFAULT '{}',
  delivery_enabled BOOLEAN NOT NULL DEFAULT false,
  takeaway_enabled BOOLEAN NOT NULL DEFAULT false,
  delivery_radius_km DOUBLE PRECISION,
  minimum_order_amount DECIMAL(10, 2),
  delivery_fee DECIMAL(10, 2),
  estimated_delivery_time_min INTEGER,

  -- Facturación
  tax_id TEXT, -- CIF/NIF
  tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 10.00,
  currency TEXT NOT NULL DEFAULT 'EUR',

  -- Estado
  status public.tenant_status NOT NULL DEFAULT 'pending',
  is_featured BOOLEAN NOT NULL DEFAULT false,
  rating DECIMAL(3, 2) DEFAULT 0,
  total_reviews INTEGER NOT NULL DEFAULT 0,
  total_orders INTEGER NOT NULL DEFAULT 0,

  -- Suscripción
  subscription_plan TEXT DEFAULT 'basic', -- 'basic', 'pro', 'enterprise'
  subscription_expires_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_slug ON public.tenants(slug);
CREATE INDEX idx_tenants_status ON public.tenants(status);
CREATE INDEX idx_tenants_city ON public.tenants(city);
CREATE INDEX idx_tenants_cuisine_type ON public.tenants USING GIN(cuisine_type);
CREATE INDEX idx_tenants_location ON public.tenants(latitude, longitude) WHERE latitude IS NOT NULL;
CREATE INDEX idx_tenants_is_featured ON public.tenants(is_featured) WHERE is_featured = true;

CREATE TRIGGER tenants_updated_at
  BEFORE UPDATE ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.tenants IS 'Restaurantes registrados en la plataforma (multi-tenant)';

-- ============================================================================
-- TABLA: tenant_memberships (relación usuario-restaurante con rol)
-- ============================================================================

CREATE TABLE public.tenant_memberships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  role public.user_role NOT NULL DEFAULT 'waiter',
  is_active BOOLEAN NOT NULL DEFAULT true,
  invited_by UUID REFERENCES public.profiles(id),
  invited_at TIMESTAMPTZ,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, tenant_id)
);

CREATE INDEX idx_memberships_user ON public.tenant_memberships(user_id);
CREATE INDEX idx_memberships_tenant ON public.tenant_memberships(tenant_id);
CREATE INDEX idx_memberships_active ON public.tenant_memberships(tenant_id) WHERE is_active = true;

CREATE TRIGGER memberships_updated_at
  BEFORE UPDATE ON public.tenant_memberships
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.tenant_memberships IS 'Membresías de usuarios a restaurantes con roles';

-- ============================================================================
-- TABLA: restaurant_tables (mesas del restaurante)
-- ============================================================================

CREATE TABLE public.restaurant_tables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  number INTEGER NOT NULL,
  label TEXT, -- Nombre descriptivo: "Terraza 1", "Barra A"
  capacity INTEGER NOT NULL DEFAULT 4,
  zone TEXT, -- 'interior', 'terraza', 'barra', 'vip'
  status public.table_status NOT NULL DEFAULT 'available',
  qr_code TEXT, -- URL del QR para pedidos
  position_x DOUBLE PRECISION, -- Posición en el mapa del restaurante
  position_y DOUBLE PRECISION,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (tenant_id, number)
);

CREATE INDEX idx_tables_tenant ON public.restaurant_tables(tenant_id);
CREATE INDEX idx_tables_status ON public.restaurant_tables(tenant_id, status);

CREATE TRIGGER tables_updated_at
  BEFORE UPDATE ON public.restaurant_tables
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.restaurant_tables IS 'Mesas de cada restaurante';

-- ============================================================================
-- TABLA: table_sessions (sesiones de mesa abierta)
-- ============================================================================

CREATE TABLE public.table_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  table_id UUID NOT NULL REFERENCES public.restaurant_tables(id) ON DELETE CASCADE,
  opened_by UUID REFERENCES public.profiles(id),
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ,
  guests_count INTEGER DEFAULT 1,
  notes TEXT,
  total_amount DECIMAL(10, 2) DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_tenant ON public.table_sessions(tenant_id);
CREATE INDEX idx_sessions_table ON public.table_sessions(table_id) WHERE is_active = true;
CREATE INDEX idx_sessions_active ON public.table_sessions(tenant_id) WHERE is_active = true;

CREATE TRIGGER sessions_updated_at
  BEFORE UPDATE ON public.table_sessions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.table_sessions IS 'Sesiones activas en las mesas (apertura/cierre)';

-- ============================================================================
-- TABLA: menu_categories (categorías del menú)
-- ============================================================================

CREATE TABLE public.menu_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_tenant ON public.menu_categories(tenant_id);
CREATE INDEX idx_categories_sort ON public.menu_categories(tenant_id, sort_order);

CREATE TRIGGER categories_updated_at
  BEFORE UPDATE ON public.menu_categories
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.menu_categories IS 'Categorías del menú del restaurante';

-- ============================================================================
-- TABLA: menu_items (ítems del menú)
-- ============================================================================

CREATE TABLE public.menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.menu_categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  image_url TEXT,
  allergens TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}', -- 'vegetarian', 'vegan', 'gluten_free', 'spicy', etc.
  preparation_time_min INTEGER DEFAULT 15,
  calories INTEGER,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_available BOOLEAN NOT NULL DEFAULT true,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_items_tenant ON public.menu_items(tenant_id);
CREATE INDEX idx_items_category ON public.menu_items(category_id);
CREATE INDEX idx_items_available ON public.menu_items(tenant_id) WHERE is_available = true AND is_active = true;
CREATE INDEX idx_items_tags ON public.menu_items USING GIN(tags);
CREATE INDEX idx_items_allergens ON public.menu_items USING GIN(allergens);

CREATE TRIGGER items_updated_at
  BEFORE UPDATE ON public.menu_items
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.menu_items IS 'Ítems del menú del restaurante';

-- ============================================================================
-- TABLA: menu_item_options (opciones/modificadores de ítems)
-- ============================================================================

CREATE TABLE public.menu_item_options (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  group_name TEXT NOT NULL, -- "Tamaño", "Extras", "Salsa"
  name TEXT NOT NULL, -- "Grande", "Extra queso", "BBQ"
  price_modifier DECIMAL(10, 2) NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  max_selections INTEGER DEFAULT 1,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_options_item ON public.menu_item_options(menu_item_id);
CREATE INDEX idx_options_tenant ON public.menu_item_options(tenant_id);

CREATE TRIGGER options_updated_at
  BEFORE UPDATE ON public.menu_item_options
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.menu_item_options IS 'Opciones y modificadores de ítems del menú';

-- ============================================================================
-- TABLA: orders (pedidos)
-- ============================================================================

CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  order_number SERIAL, -- Número secuencial por restaurante
  customer_id UUID REFERENCES public.profiles(id),
  table_session_id UUID REFERENCES public.table_sessions(id),
  waiter_id UUID REFERENCES public.profiles(id),

  -- Tipo y estado
  order_type public.order_type NOT NULL DEFAULT 'dine_in',
  status public.order_status NOT NULL DEFAULT 'pending',
  payment_status public.payment_status NOT NULL DEFAULT 'pending',
  payment_method TEXT, -- 'cash', 'card', 'online'

  -- Montos
  subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  delivery_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  tip_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL DEFAULT 0,

  -- Delivery
  delivery_address_id UUID,
  delivery_notes TEXT,
  estimated_delivery_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,

  -- Metadata
  notes TEXT,
  cancellation_reason TEXT,
  rated_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_tenant ON public.orders(tenant_id);
CREATE INDEX idx_orders_customer ON public.orders(customer_id);
CREATE INDEX idx_orders_status ON public.orders(tenant_id, status);
CREATE INDEX idx_orders_session ON public.orders(table_session_id);
CREATE INDEX idx_orders_date ON public.orders(tenant_id, created_at);
CREATE INDEX idx_orders_payment ON public.orders(tenant_id, payment_status);

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.orders IS 'Pedidos del restaurante';

-- ============================================================================
-- TABLA: order_items (ítems del pedido)
-- ============================================================================

CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES public.menu_items(id) ON DELETE SET NULL,
  name TEXT NOT NULL, -- Snapshot del nombre
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  options JSONB DEFAULT '[]', -- Snapshot de opciones seleccionadas
  notes TEXT,
  status public.order_item_status NOT NULL DEFAULT 'pending',
  prepared_by UUID REFERENCES public.profiles(id),
  prepared_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON public.order_items(order_id);
CREATE INDEX idx_order_items_tenant ON public.order_items(tenant_id);
CREATE INDEX idx_order_items_status ON public.order_items(tenant_id, status);

CREATE TRIGGER order_items_updated_at
  BEFORE UPDATE ON public.order_items
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.order_items IS 'Ítems individuales dentro de un pedido';

-- ============================================================================
-- TABLA: inventory_items (inventario)
-- ============================================================================

CREATE TABLE public.inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  sku TEXT,
  category TEXT,
  unit TEXT NOT NULL DEFAULT 'unidad', -- 'kg', 'litro', 'unidad', 'gramo'
  current_stock DECIMAL(10, 3) NOT NULL DEFAULT 0,
  minimum_stock DECIMAL(10, 3) NOT NULL DEFAULT 0,
  maximum_stock DECIMAL(10, 3),
  cost_per_unit DECIMAL(10, 2) NOT NULL DEFAULT 0,
  supplier TEXT,
  location TEXT, -- Ubicación en almacén
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_restocked_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inventory_tenant ON public.inventory_items(tenant_id);
CREATE INDEX idx_inventory_low_stock ON public.inventory_items(tenant_id)
  WHERE current_stock <= minimum_stock AND is_active = true;
CREATE INDEX idx_inventory_category ON public.inventory_items(tenant_id, category);

CREATE TRIGGER inventory_updated_at
  BEFORE UPDATE ON public.inventory_items
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.inventory_items IS 'Ítems de inventario del restaurante';

-- ============================================================================
-- TABLA: inventory_movements (movimientos de inventario)
-- ============================================================================

CREATE TABLE public.inventory_movements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  inventory_item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
  movement_type public.inventory_movement_type NOT NULL,
  quantity DECIMAL(10, 3) NOT NULL,
  previous_stock DECIMAL(10, 3) NOT NULL,
  new_stock DECIMAL(10, 3) NOT NULL,
  unit_cost DECIMAL(10, 2),
  total_cost DECIMAL(10, 2),
  reference_id UUID, -- order_id, etc.
  notes TEXT,
  performed_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_movements_tenant ON public.inventory_movements(tenant_id);
CREATE INDEX idx_movements_item ON public.inventory_movements(inventory_item_id);
CREATE INDEX idx_movements_date ON public.inventory_movements(tenant_id, created_at);

COMMENT ON TABLE public.inventory_movements IS 'Historial de movimientos de inventario';

-- ============================================================================
-- TABLA: customer_addresses (direcciones de clientes)
-- ============================================================================

CREATE TABLE public.customer_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL DEFAULT 'Casa', -- 'Casa', 'Trabajo', 'Otro'
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state TEXT,
  postal_code TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'ES',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  instructions TEXT, -- Instrucciones de entrega
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_addresses_user ON public.customer_addresses(user_id);

CREATE TRIGGER addresses_updated_at
  BEFORE UPDATE ON public.customer_addresses
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.customer_addresses IS 'Direcciones de entrega de los clientes';

-- ============================================================================
-- TABLA: reviews (reseñas de clientes)
-- ============================================================================

CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  reply TEXT, -- Respuesta del restaurante
  replied_at TIMESTAMPTZ,
  replied_by UUID REFERENCES public.profiles(id),
  is_visible BOOLEAN NOT NULL DEFAULT true,
  is_flagged BOOLEAN NOT NULL DEFAULT false,
  flag_reason TEXT,
  moderated_at TIMESTAMPTZ,
  moderated_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, order_id)
);

CREATE INDEX idx_reviews_tenant ON public.reviews(tenant_id);
CREATE INDEX idx_reviews_user ON public.reviews(user_id);
CREATE INDEX idx_reviews_rating ON public.reviews(tenant_id, rating);
CREATE INDEX idx_reviews_flagged ON public.reviews(is_flagged) WHERE is_flagged = true;

CREATE TRIGGER reviews_updated_at
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.reviews IS 'Reseñas de clientes sobre restaurantes';

-- ============================================================================
-- TABLA: favorites (favoritos de clientes)
-- ============================================================================

CREATE TABLE public.favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, tenant_id)
);

CREATE INDEX idx_favorites_user ON public.favorites(user_id);
CREATE INDEX idx_favorites_tenant ON public.favorites(tenant_id);

COMMENT ON TABLE public.favorites IS 'Restaurantes favoritos de los clientes';

-- ============================================================================
-- TABLA: incidents (incidencias de la plataforma)
-- ============================================================================

CREATE TABLE public.incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  reported_by UUID REFERENCES public.profiles(id),
  assigned_to UUID REFERENCES public.profiles(id),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  priority public.incident_priority NOT NULL DEFAULT 'medium',
  status public.incident_status NOT NULL DEFAULT 'open',
  category TEXT, -- 'payment', 'delivery', 'quality', 'technical', 'other'
  resolution TEXT,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.profiles(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_incidents_tenant ON public.incidents(tenant_id);
CREATE INDEX idx_incidents_status ON public.incidents(status);
CREATE INDEX idx_incidents_priority ON public.incidents(priority);
CREATE INDEX idx_incidents_assigned ON public.incidents(assigned_to) WHERE status IN ('open', 'in_progress');

CREATE TRIGGER incidents_updated_at
  BEFORE UPDATE ON public.incidents
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.incidents IS 'Incidencias y tickets de soporte de la plataforma';

-- ============================================================================
-- TABLA: audit_logs (registro de auditoría)
-- ============================================================================

CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL, -- 'create', 'update', 'delete', 'login', 'logout', etc.
  entity_type TEXT NOT NULL, -- 'order', 'menu_item', 'table', etc.
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_tenant ON public.audit_logs(tenant_id);
CREATE INDEX idx_audit_user ON public.audit_logs(user_id);
CREATE INDEX idx_audit_entity ON public.audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_date ON public.audit_logs(created_at);

COMMENT ON TABLE public.audit_logs IS 'Registro de auditoría de acciones en la plataforma';

-- ============================================================================
-- TABLA: notifications (notificaciones)
-- ============================================================================

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL, -- 'order_update', 'new_review', 'low_stock', 'incident', etc.
  data JSONB DEFAULT '{}', -- Datos adicionales para navegación
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id) WHERE is_read = false;

COMMENT ON TABLE public.notifications IS 'Notificaciones push y in-app para usuarios';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurant_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.table_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ─── PROFILES ────────────────────────────────────────────────────────────────

-- Los usuarios pueden ver su propio perfil
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Los miembros de un tenant pueden ver perfiles de otros miembros
CREATE POLICY "profiles_select_tenant_members" ON public.profiles
  FOR SELECT USING (
    id IN (
      SELECT tm2.user_id FROM public.tenant_memberships tm2
      WHERE tm2.tenant_id IN (
        SELECT tm1.tenant_id FROM public.tenant_memberships tm1
        WHERE tm1.user_id = auth.uid() AND tm1.is_active = true
      )
    )
  );

-- Super admins pueden ver todos los perfiles
CREATE POLICY "profiles_select_super_admin" ON public.profiles
  FOR SELECT USING (public.is_super_admin());

-- Los usuarios pueden editar su propio perfil
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Solo super admins pueden modificar is_super_admin
CREATE POLICY "profiles_update_admin_fields" ON public.profiles
  FOR UPDATE USING (public.is_super_admin());

-- ─── TENANTS ─────────────────────────────────────────────────────────────────

-- Los restaurantes activos son visibles para todos los usuarios autenticados (marketplace)
CREATE POLICY "tenants_select_active" ON public.tenants
  FOR SELECT USING (status = 'active');

-- Los miembros de un tenant pueden ver su restaurante aunque no sea active
CREATE POLICY "tenants_select_members" ON public.tenants
  FOR SELECT USING (
    id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- Super admins ven todos
CREATE POLICY "tenants_select_super_admin" ON public.tenants
  FOR SELECT USING (public.is_super_admin());

-- Solo owners/managers pueden actualizar su restaurante
CREATE POLICY "tenants_update_owners" ON public.tenants
  FOR UPDATE USING (
    public.has_role_in_tenant(id, ARRAY['owner', 'manager']::user_role[])
  );

-- Super admins pueden actualizar cualquier restaurante
CREATE POLICY "tenants_update_super_admin" ON public.tenants
  FOR UPDATE USING (public.is_super_admin());

-- Cualquier autenticado puede crear un restaurante (onboarding)
CREATE POLICY "tenants_insert_authenticated" ON public.tenants
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Solo super admins pueden eliminar
CREATE POLICY "tenants_delete_super_admin" ON public.tenants
  FOR DELETE USING (public.is_super_admin());

-- ─── TENANT MEMBERSHIPS ─────────────────────────────────────────────────────

-- Ver membresías propias
CREATE POLICY "memberships_select_own" ON public.tenant_memberships
  FOR SELECT USING (user_id = auth.uid());

-- Owners/managers ven membresías de su tenant
CREATE POLICY "memberships_select_tenant" ON public.tenant_memberships
  FOR SELECT USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- Super admins ven todas
CREATE POLICY "memberships_select_super_admin" ON public.tenant_memberships
  FOR SELECT USING (public.is_super_admin());

-- Owners/managers pueden gestionar membresías de su tenant
CREATE POLICY "memberships_insert_tenant" ON public.tenant_memberships
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR auth.uid() IS NOT NULL -- Para auto-asignación en onboarding
  );

CREATE POLICY "memberships_update_tenant" ON public.tenant_memberships
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "memberships_delete_tenant" ON public.tenant_memberships
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner']::user_role[])
  );

-- ─── RESTAURANT TABLES ──────────────────────────────────────────────────────

-- Staff del restaurante puede ver las mesas
CREATE POLICY "tables_select_staff" ON public.restaurant_tables
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- Super admins
CREATE POLICY "tables_select_super_admin" ON public.restaurant_tables
  FOR SELECT USING (public.is_super_admin());

-- Managers+ pueden gestionar mesas
CREATE POLICY "tables_insert_managers" ON public.restaurant_tables
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "tables_update_staff" ON public.restaurant_tables
  FOR UPDATE USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "tables_delete_managers" ON public.restaurant_tables
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ─── TABLE SESSIONS ─────────────────────────────────────────────────────────

CREATE POLICY "sessions_select_staff" ON public.table_sessions
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "sessions_insert_staff" ON public.table_sessions
  FOR INSERT WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "sessions_update_staff" ON public.table_sessions
  FOR UPDATE USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- ─── MENU CATEGORIES ────────────────────────────────────────────────────────

-- Cualquiera puede ver categorías de restaurantes activos (marketplace)
CREATE POLICY "categories_select_public" ON public.menu_categories
  FOR SELECT USING (
    tenant_id IN (SELECT id FROM public.tenants WHERE status = 'active')
    OR tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "categories_insert_managers" ON public.menu_categories
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "categories_update_managers" ON public.menu_categories
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "categories_delete_managers" ON public.menu_categories
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ─── MENU ITEMS ──────────────────────────────────────────────────────────────

-- Cualquiera puede ver menú de restaurantes activos
CREATE POLICY "items_select_public" ON public.menu_items
  FOR SELECT USING (
    tenant_id IN (SELECT id FROM public.tenants WHERE status = 'active')
    OR tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "items_insert_managers" ON public.menu_items
  FOR INSERT WITH CHECK (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "items_update_managers" ON public.menu_items
  FOR UPDATE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager', 'chef']::user_role[])
  );

CREATE POLICY "items_delete_managers" ON public.menu_items
  FOR DELETE USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ─── MENU ITEM OPTIONS ──────────────────────────────────────────────────────

CREATE POLICY "options_select_public" ON public.menu_item_options
  FOR SELECT USING (
    tenant_id IN (SELECT id FROM public.tenants WHERE status = 'active')
    OR tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "options_manage_managers" ON public.menu_item_options
  FOR ALL USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

-- ─── ORDERS ──────────────────────────────────────────────────────────────────

-- Staff puede ver pedidos de su restaurante
CREATE POLICY "orders_select_staff" ON public.orders
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- Clientes ven sus propios pedidos
CREATE POLICY "orders_select_customer" ON public.orders
  FOR SELECT USING (customer_id = auth.uid());

-- Super admins
CREATE POLICY "orders_select_super_admin" ON public.orders
  FOR SELECT USING (public.is_super_admin());

-- Clientes crean pedidos y staff crea pedidos internos
CREATE POLICY "orders_insert" ON public.orders
  FOR INSERT WITH CHECK (
    customer_id = auth.uid()
    OR tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- Staff actualiza pedidos
CREATE POLICY "orders_update_staff" ON public.orders
  FOR UPDATE USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- ─── ORDER ITEMS ─────────────────────────────────────────────────────────────

CREATE POLICY "order_items_select" ON public.order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders) -- Hereda políticas de orders
  );

CREATE POLICY "order_items_insert" ON public.order_items
  FOR INSERT WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
    OR order_id IN (
      SELECT id FROM public.orders WHERE customer_id = auth.uid()
    )
  );

CREATE POLICY "order_items_update_staff" ON public.order_items
  FOR UPDATE USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- ─── INVENTORY ───────────────────────────────────────────────────────────────

CREATE POLICY "inventory_select_staff" ON public.inventory_items
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "inventory_manage_managers" ON public.inventory_items
  FOR ALL USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
  );

CREATE POLICY "inventory_movements_select" ON public.inventory_movements
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

CREATE POLICY "inventory_movements_insert" ON public.inventory_movements
  FOR INSERT WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
  );

-- ─── CUSTOMER ADDRESSES ─────────────────────────────────────────────────────

CREATE POLICY "addresses_own" ON public.customer_addresses
  FOR ALL USING (user_id = auth.uid());

-- ─── REVIEWS ─────────────────────────────────────────────────────────────────

-- Reseñas visibles de restaurantes activos
CREATE POLICY "reviews_select_public" ON public.reviews
  FOR SELECT USING (
    is_visible = true
    OR user_id = auth.uid()
    OR public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- Clientes crean reseñas
CREATE POLICY "reviews_insert_customer" ON public.reviews
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Clientes editan sus reseñas, managers responden
CREATE POLICY "reviews_update" ON public.reviews
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- ─── FAVORITES ───────────────────────────────────────────────────────────────

CREATE POLICY "favorites_own" ON public.favorites
  FOR ALL USING (user_id = auth.uid());

-- ─── INCIDENTS ───────────────────────────────────────────────────────────────

-- Staff ve incidencias de su restaurante
CREATE POLICY "incidents_select_staff" ON public.incidents
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_memberships
      WHERE user_id = auth.uid() AND is_active = true
    )
    OR reported_by = auth.uid()
    OR public.is_super_admin()
  );

CREATE POLICY "incidents_insert" ON public.incidents
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "incidents_update" ON public.incidents
  FOR UPDATE USING (
    assigned_to = auth.uid()
    OR public.is_super_admin()
  );

-- ─── AUDIT LOGS ──────────────────────────────────────────────────────────────

-- Solo lectura para managers y super admins
CREATE POLICY "audit_select_managers" ON public.audit_logs
  FOR SELECT USING (
    public.has_role_in_tenant(tenant_id, ARRAY['owner', 'manager']::user_role[])
    OR public.is_super_admin()
  );

-- Solo insert por sistema (service_role) o autenticados
CREATE POLICY "audit_insert" ON public.audit_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

CREATE POLICY "notifications_own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

-- Sistema puede insertar notificaciones (vía service_role o funciones)
CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (true); -- Controlado por functions/triggers

-- ============================================================================
-- TRIGGERS: Lógica de negocio automática
-- ============================================================================

-- ─── Auto-crear perfil al registrarse ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
    NEW.email,
    NEW.raw_user_meta_data ->> 'phone'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── Actualizar rating del restaurante al crear/actualizar reseña ────────────

CREATE OR REPLACE FUNCTION public.update_tenant_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.tenants
  SET
    rating = (
      SELECT COALESCE(AVG(rating), 0)
      FROM public.reviews
      WHERE tenant_id = COALESCE(NEW.tenant_id, OLD.tenant_id)
      AND is_visible = true
    ),
    total_reviews = (
      SELECT COUNT(*)
      FROM public.reviews
      WHERE tenant_id = COALESCE(NEW.tenant_id, OLD.tenant_id)
      AND is_visible = true
    )
  WHERE id = COALESCE(NEW.tenant_id, OLD.tenant_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_review_change
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_tenant_rating();

-- ─── Actualizar stock al registrar movimiento ───────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_inventory_movement()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.inventory_items
  SET current_stock = NEW.new_stock,
      last_restocked_at = CASE
        WHEN NEW.movement_type = 'purchase' THEN NOW()
        ELSE last_restocked_at
      END
  WHERE id = NEW.inventory_item_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_inventory_movement
  AFTER INSERT ON public.inventory_movements
  FOR EACH ROW EXECUTE FUNCTION public.handle_inventory_movement();

-- ─── Actualizar total_orders del tenant al completar pedido ──────────────────

CREATE OR REPLACE FUNCTION public.update_tenant_orders_count()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE public.tenants
    SET total_orders = total_orders + 1
    WHERE id = NEW.tenant_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_order_completed
  AFTER UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_tenant_orders_count();

-- ─── Actualizar estado de la mesa según sesiones ─────────────────────────────

CREATE OR REPLACE FUNCTION public.update_table_status_on_session()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.restaurant_tables
    SET status = 'occupied'
    WHERE id = NEW.table_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.is_active = false AND OLD.is_active = true THEN
    UPDATE public.restaurant_tables
    SET status = 'available'
    WHERE id = NEW.table_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_session_change
  AFTER INSERT OR UPDATE ON public.table_sessions
  FOR EACH ROW EXECUTE FUNCTION public.update_table_status_on_session();

-- ============================================================================
-- FUNCIONES RPC (llamables desde el cliente)
-- ============================================================================

-- ─── Buscar restaurantes por proximidad ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.nearby_restaurants(
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION DEFAULT 10
)
RETURNS SETOF public.tenants AS $$
BEGIN
  RETURN QUERY
  SELECT t.*
  FROM public.tenants t
  WHERE t.status = 'active'
    AND t.latitude IS NOT NULL
    AND t.longitude IS NOT NULL
    AND (
      6371 * acos(
        cos(radians(p_latitude)) * cos(radians(t.latitude))
        * cos(radians(t.longitude) - radians(p_longitude))
        + sin(radians(p_latitude)) * sin(radians(t.latitude))
      )
    ) <= p_radius_km
  ORDER BY (
    6371 * acos(
      cos(radians(p_latitude)) * cos(radians(t.latitude))
      * cos(radians(t.longitude) - radians(p_longitude))
      + sin(radians(p_latitude)) * sin(radians(t.latitude))
    )
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ─── Búsqueda full-text de restaurantes ──────────────────────────────────────

CREATE OR REPLACE FUNCTION public.search_restaurants(p_query TEXT)
RETURNS SETOF public.tenants AS $$
BEGIN
  RETURN QUERY
  SELECT t.*
  FROM public.tenants t
  WHERE t.status = 'active'
    AND (
      unaccent(lower(t.name)) LIKE '%' || unaccent(lower(p_query)) || '%'
      OR unaccent(lower(COALESCE(t.description, ''))) LIKE '%' || unaccent(lower(p_query)) || '%'
      OR unaccent(lower(COALESCE(t.city, ''))) LIKE '%' || unaccent(lower(p_query)) || '%'
      OR p_query = ANY(t.cuisine_type)
    )
  ORDER BY t.rating DESC, t.total_orders DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ─── Dashboard stats para el restaurante ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_restaurant_stats(p_tenant_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
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
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ─── Dashboard stats para admin global ───────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Solo super admins
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso no autorizado';
  END IF;

  SELECT json_build_object(
    'total_tenants', (SELECT COUNT(*) FROM public.tenants),
    'active_tenants', (SELECT COUNT(*) FROM public.tenants WHERE status = 'active'),
    'pending_tenants', (SELECT COUNT(*) FROM public.tenants WHERE status = 'pending'),
    'total_users', (SELECT COUNT(*) FROM public.profiles WHERE is_active = true),
    'today_orders', (
      SELECT COUNT(*) FROM public.orders WHERE created_at >= CURRENT_DATE
    ),
    'today_revenue', (
      SELECT COALESCE(SUM(total), 0) FROM public.orders
      WHERE created_at >= CURRENT_DATE AND payment_status = 'paid'
    ),
    'open_incidents', (
      SELECT COUNT(*) FROM public.incidents WHERE status IN ('open', 'in_progress')
    ),
    'flagged_reviews', (
      SELECT COUNT(*) FROM public.reviews WHERE is_flagged = true
    )
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================================
-- REALTIME: Habilitar subscripciones en tiempo real
-- ============================================================================

-- Tablas habilitadas para Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.restaurant_tables;
ALTER PUBLICATION supabase_realtime ADD TABLE public.table_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ============================================================================
-- DATOS INICIALES (seed)
-- ============================================================================

-- Insertar categorías de cocina comunes (para tags/filtros)
-- Se maneja desde la app, no se necesitan datos seed en producción.

-- ============================================================================
-- FIN DEL ESQUEMA
-- ============================================================================

-- ============================================================================
-- LŌME — Migración 00019: Crear tenant desde handle_new_user (server-side)
-- ============================================================================
-- Problema raíz:
--   _createTenantForOwner() en Dart sufre una race condition:
--   auth.signUp() emite authStateChange → el router redirige a /marketplace
--   ANTES de que _createTenantForOwner() pueda insertar el tenant.
--   Además, si algo falla en el INSERT del cliente, el error se traga.
--
-- Solución:
--   Mover la creación del tenant al trigger handle_new_user() que ya se
--   ejecuta como SECURITY DEFINER en el contexto de auth.users INSERT.
--   Esto garantiza que profile + tenant + membership se crean atómicamente
--   ANTES de que el SDK retorne la sesión al cliente.
--
--   El trigger auto_assign_tenant_owner ya existe y crea la membership
--   al insertar un tenant, PERO usa auth.uid() que es NULL en el contexto
--   del trigger de auth.users. Por eso creamos la membership manualmente
--   desde handle_new_user.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 0. Fix audit_trigger_fn: NEW/OLD son records, no jsonb.
--    El operador `?` solo funciona con jsonb, hay que convertir primero.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.audit_trigger_fn()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
    v_tenant_id := CASE WHEN TG_TABLE_NAME = 'tenants' THEN OLD.id
                        WHEN v_old ? 'tenant_id' THEN (v_old->>'tenant_id')::UUID
                        ELSE NULL END;
  ELSIF TG_OP = 'INSERT' THEN
    v_old := NULL;
    v_new := to_jsonb(NEW);
    v_tenant_id := CASE WHEN TG_TABLE_NAME = 'tenants' THEN NEW.id
                        WHEN v_new ? 'tenant_id' THEN (v_new->>'tenant_id')::UUID
                        ELSE NULL END;
  ELSE -- UPDATE
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    v_tenant_id := CASE WHEN TG_TABLE_NAME = 'tenants' THEN NEW.id
                        WHEN v_new ? 'tenant_id' THEN (v_new->>'tenant_id')::UUID
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
$$;

-- ============================================================================
-- 1. handle_new_user: Crear profile + tenant + membership atómicamente
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _account_type text;
  _restaurant_name text;
  _slug text;
  _tenant_id uuid;
BEGIN
  -- 1. Crear el perfil
  INSERT INTO public.profiles (id, email, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'phone'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    phone = COALESCE(EXCLUDED.phone, profiles.phone);

  -- 2. Si es owner, crear tenant y membership
  _account_type := NEW.raw_user_meta_data->>'account_type';
  _restaurant_name := NEW.raw_user_meta_data->>'restaurant_name';

  IF _account_type = 'owner' AND _restaurant_name IS NOT NULL THEN
    -- Generar slug
    _slug := lower(regexp_replace(_restaurant_name, '[^a-zA-Z0-9]+', '-', 'g'));
    _slug := _slug || '-' || extract(epoch FROM now())::bigint::text;

    -- Crear tenant (el trigger auto_assign_tenant_owner se disparará
    -- pero no hará nada porque auth.uid() es NULL — ver fix abajo)
    INSERT INTO tenants (name, slug, status)
    VALUES (_restaurant_name, _slug, 'active')
    RETURNING id INTO _tenant_id;

    -- Crear membership manualmente (handle_new_user sabe el user_id = NEW.id)
    INSERT INTO tenant_memberships (tenant_id, user_id, role, is_active)
    VALUES (_tenant_id, NEW.id, 'owner', true);
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================================================
-- 1b. Fix auto_assign_tenant_owner: skip si auth.uid() es NULL
--     (ocurre cuando el INSERT en tenants viene desde handle_new_user)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.auto_assign_tenant_owner()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Si auth.uid() es NULL (ej: llamado desde otro trigger server-side),
  -- no hacer nada — el caller ya maneja la membership.
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.tenant_memberships (tenant_id, user_id, role, is_active)
  VALUES (NEW.id, auth.uid(), 'owner', true)
  ON CONFLICT (tenant_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 2. Fix dueños huérfanos: usuarios owner existentes sin tenant
-- ============================================================================

DO $$
DECLARE
  r RECORD;
  _slug text;
  _tenant_id uuid;
BEGIN
  FOR r IN
    SELECT
      au.id AS user_id,
      au.raw_user_meta_data->>'restaurant_name' AS restaurant_name
    FROM auth.users au
    WHERE au.raw_user_meta_data->>'account_type' = 'owner'
      AND au.raw_user_meta_data->>'restaurant_name' IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM tenant_memberships tm WHERE tm.user_id = au.id
      )
  LOOP
    _slug := lower(regexp_replace(r.restaurant_name, '[^a-zA-Z0-9]+', '-', 'g'));
    _slug := _slug || '-' || extract(epoch FROM now())::bigint::text;

    INSERT INTO tenants (name, slug, status)
    VALUES (r.restaurant_name, _slug, 'active')
    RETURNING id INTO _tenant_id;

    INSERT INTO tenant_memberships (tenant_id, user_id, role, is_active)
    VALUES (_tenant_id, r.user_id, 'owner', true);

    RAISE NOTICE 'Created tenant % for orphan owner %', _tenant_id, r.user_id;
  END LOOP;
END;
$$;

COMMIT;

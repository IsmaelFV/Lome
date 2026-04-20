-- ============================================================================
-- LŌME — Migración 00018: Fix flujo de registro de restaurante
-- ============================================================================
-- Problemas detectados:
--   1. No existía política INSERT en profiles → upsert desde el cliente
--      fallaba por RLS, impidiendo que el código Dart llegara a crear
--      el tenant y la membership.
--   2. handle_new_user() no incluía phone del metadata.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. Política INSERT para profiles (permite al usuario insertar su propio perfil)
-- ============================================================================

CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 2. Mejorar handle_new_user para incluir phone del metadata
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
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
  RETURN NEW;
END;
$$;

COMMIT;

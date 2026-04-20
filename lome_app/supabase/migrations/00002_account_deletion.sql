-- ============================================================================
-- Migración: Función de anonimización de cuenta (GDPR)
-- ============================================================================
-- Esta función puede invocarse como alternativa a la Edge Function
-- para ejecutar toda la anonimización en una sola transacción atómica.
--
-- Estrategia: ANONIMIZACIÓN vs BORRADO FÍSICO
-- ─────────────────────────────────────────────
-- ¿Por qué anonimizar y no borrar?
--
-- 1. INTEGRIDAD REFERENCIAL: Las tablas `orders`, `order_items`,
--    `table_sessions`, `inventory_movements` referencian al user_id.
--    Borrar la fila de `profiles` con CASCADE eliminaría los pedidos
--    históricos, rompiendo reportes contables y analíticas.
--
-- 2. CUMPLIMIENTO LEGAL (GDPR Art. 17 + Art. 6):
--    - El derecho al olvido exige eliminar datos PERSONALES.
--    - Pero Art. 6(1)(c) permite retener datos anonimizados para
--      obligaciones legales (contabilidad, facturación).
--    - Al reemplazar nombre/email/teléfono/avatar con datos genéricos,
--      el registro deja de ser "dato personal" según el RGPD.
--
-- 3. TRAZABILIDAD: Los pedidos mantienen su waiter_id/customer_id
--    pero al consultar el nombre siempre se ve "Usuario eliminado".
--
-- Tablas afectadas y tratamiento:
-- ┌──────────────────────┬──────────────────────────────────────┐
-- │ Tabla                │ Tratamiento                          │
-- ├──────────────────────┼──────────────────────────────────────┤
-- │ profiles             │ Anonimizar (name, email, phone, etc) │
-- │ tenant_memberships   │ Desactivar (is_active = false)       │
-- │ invitations          │ Cancelar pendientes                  │
-- │ customer_addresses   │ Eliminar (datos personales puros)    │
-- │ orders               │ SIN CAMBIOS (ref intacta)            │
-- │ order_items          │ SIN CAMBIOS (ref intacta)            │
-- │ table_sessions       │ SIN CAMBIOS (ref intacta)            │
-- │ inventory_movements  │ SIN CAMBIOS (ref intacta)            │
-- │ auth.users           │ Eliminar (la Edge Function lo hace)  │
-- └──────────────────────┴──────────────────────────────────────┘

CREATE OR REPLACE FUNCTION public.anonymize_user_account(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_anon_hash TEXT;
BEGIN
  -- Generar hash para email anonimizado
  v_anon_hash := encode(gen_random_bytes(4), 'hex');

  -- 1. Anonimizar perfil
  UPDATE public.profiles
  SET
    full_name = 'Usuario eliminado',
    email = v_anon_hash || '@deleted.lome.app',
    phone = NULL,
    avatar_url = NULL,
    is_active = false,
    metadata = jsonb_build_object('deleted_at', NOW()::text)
  WHERE id = p_user_id;

  -- 2. Desactivar membresías
  UPDATE public.tenant_memberships
  SET is_active = false
  WHERE user_id = p_user_id;

  -- 3. Cancelar invitaciones pendientes
  UPDATE public.invitations
  SET status = 'cancelled'
  WHERE invited_by = p_user_id
    AND status = 'pending';

  -- 4. Eliminar direcciones (datos personales puros)
  DELETE FROM public.customer_addresses
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Solo super_admin o el service_role pueden ejecutar esta función
REVOKE ALL ON FUNCTION public.anonymize_user_account(UUID) FROM PUBLIC;
COMMENT ON FUNCTION public.anonymize_user_account IS
  'Anonimiza los datos personales de un usuario manteniendo la integridad referencial (GDPR Art. 17)';

-- ============================================================================
-- Migración 00020: Push Notifications — tabla device_tokens
-- ============================================================================
-- Almacena tokens FCM de cada dispositivo para enviar push notifications.
-- Un usuario puede tener múltiples dispositivos registrados.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token       TEXT NOT NULL UNIQUE,
  platform    TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  preferences JSONB NOT NULL DEFAULT '{"orders": true, "reviews": true, "stock": true, "system": true}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.device_tokens IS 'Tokens FCM por dispositivo para push notifications';

-- ── Índices ──

CREATE INDEX idx_device_tokens_user
  ON public.device_tokens(user_id);

CREATE INDEX idx_device_tokens_active
  ON public.device_tokens(user_id)
  WHERE push_enabled = true;

-- ── RLS ──

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Cada usuario gestiona sus propios tokens
CREATE POLICY "users_manage_own_tokens"
  ON public.device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Auto-update updated_at ──

CREATE OR REPLACE FUNCTION public.set_device_token_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_device_tokens_updated
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION public.set_device_token_updated_at();

-- ============================================================================
-- CONFIGURACIÓN PENDIENTE (manual en Supabase Dashboard):
--
-- 1. Ir a Database → Webhooks → Create Webhook
-- 2. Nombre: send-push-notification
-- 3. Tabla: notifications
-- 4. Eventos: INSERT
-- 5. Tipo: Supabase Edge Function
-- 6. Función: send-push-notification
-- 7. Headers: Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
--
-- Esto dispara la Edge Function cada vez que se inserta una notificación,
-- enviando push a los dispositivos registrados del usuario destinatario.
-- ============================================================================

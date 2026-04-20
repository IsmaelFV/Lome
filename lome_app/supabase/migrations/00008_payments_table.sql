-- ============================================================================
-- MIGRACIÓN 00008: Tabla payments + RLS + Realtime
-- ============================================================================

-- ============================================================================
-- ENUM: payment_method_type
-- ============================================================================

CREATE TYPE public.payment_method_type AS ENUM ('card', 'online', 'cash');

-- ============================================================================
-- TABLA: payments (registros de pago)
-- ============================================================================

CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  method public.payment_method_type NOT NULL,
  status public.payment_status NOT NULL DEFAULT 'pending',
  transaction_ref TEXT, -- Referencia de transacción externa
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON public.payments(order_id);
CREATE INDEX idx_payments_status ON public.payments(status);

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.payments IS 'Registros de pago asociados a pedidos';

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Cliente ve sus propios pagos (pedidos donde es customer)
CREATE POLICY "payments_select_customer" ON public.payments
  FOR SELECT USING (
    order_id IN (
      SELECT id FROM public.orders WHERE customer_id = auth.uid()
    )
  );

-- Staff ve pagos de su restaurante
CREATE POLICY "payments_select_staff" ON public.payments
  FOR SELECT USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      WHERE o.tenant_id IN (
        SELECT tenant_id FROM public.tenant_memberships
        WHERE user_id = auth.uid() AND is_active = true
      )
    )
  );

-- Inserción: cliente crea pago para su pedido
CREATE POLICY "payments_insert_customer" ON public.payments
  FOR INSERT WITH CHECK (
    order_id IN (
      SELECT id FROM public.orders WHERE customer_id = auth.uid()
    )
  );

-- Staff puede actualizar pagos
CREATE POLICY "payments_update_staff" ON public.payments
  FOR UPDATE USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      WHERE o.tenant_id IN (
        SELECT tenant_id FROM public.tenant_memberships
        WHERE user_id = auth.uid() AND is_active = true
      )
    )
  );

-- Super admin
CREATE POLICY "payments_select_super_admin" ON public.payments
  FOR SELECT USING (public.is_super_admin());

-- ============================================================================
-- Realtime
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;

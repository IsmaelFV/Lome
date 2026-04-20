-- ============================================================================
-- LŌME - Suscripciones SaaS & Facturación
-- ============================================================================

-- ─── Tabla de suscripciones ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','basic','pro','enterprise')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','past_due','cancelled','trialing')),
  amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'EUR',
  billing_cycle TEXT NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly','yearly')),
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days'),
  renewal_date TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(tenant_id)
);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can manage subscriptions"
  ON public.subscriptions FOR ALL
  USING (public.is_super_admin());

CREATE POLICY "Tenant owners can view own subscription"
  ON public.subscriptions FOR SELECT
  USING (
    tenant_id IN (
      SELECT tm.tenant_id FROM public.tenant_memberships tm
      WHERE tm.user_id = auth.uid() AND tm.role = 'owner' AND tm.is_active = true
    )
  );

-- ─── Tabla de facturas ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  invoice_number TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  tax NUMERIC(10,2) NOT NULL DEFAULT 0,
  total NUMERIC(10,2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'EUR',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','overdue','cancelled','refunded')),
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  paid_at TIMESTAMPTZ,
  due_date TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can manage invoices"
  ON public.invoices FOR ALL
  USING (public.is_super_admin());

CREATE POLICY "Tenant owners can view own invoices"
  ON public.invoices FOR SELECT
  USING (
    tenant_id IN (
      SELECT tm.tenant_id FROM public.tenant_memberships tm
      WHERE tm.user_id = auth.uid() AND tm.role = 'owner' AND tm.is_active = true
    )
  );

-- Índices
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant ON public.subscriptions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant ON public.invoices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON public.invoices(due_date);

-- ─── Triggers updated_at ─────────────────────────────────────────────────────

CREATE TRIGGER set_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_invoices_updated_at
  BEFORE UPDATE ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─── RPC: Stats de suscripciones para admin ──────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_subscription_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Acceso no autorizado';
  END IF;

  SELECT json_build_object(
    'total_subscriptions', (SELECT COUNT(*) FROM public.subscriptions),
    'active_subscriptions', (SELECT COUNT(*) FROM public.subscriptions WHERE status = 'active'),
    'past_due_subscriptions', (SELECT COUNT(*) FROM public.subscriptions WHERE status = 'past_due'),
    'cancelled_subscriptions', (SELECT COUNT(*) FROM public.subscriptions WHERE status = 'cancelled'),
    'mrr', (
      SELECT COALESCE(SUM(
        CASE WHEN billing_cycle = 'yearly' THEN amount / 12 ELSE amount END
      ), 0) FROM public.subscriptions WHERE status = 'active'
    ),
    'plan_distribution', (
      SELECT json_object_agg(plan, cnt)
      FROM (
        SELECT plan, COUNT(*) as cnt
        FROM public.subscriptions
        WHERE status IN ('active', 'trialing')
        GROUP BY plan
      ) sub
    ),
    'total_revenue_invoices', (
      SELECT COALESCE(SUM(total), 0) FROM public.invoices WHERE status = 'paid'
    ),
    'pending_invoices', (SELECT COUNT(*) FROM public.invoices WHERE status = 'pending'),
    'overdue_invoices', (SELECT COUNT(*) FROM public.invoices WHERE status = 'overdue')
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

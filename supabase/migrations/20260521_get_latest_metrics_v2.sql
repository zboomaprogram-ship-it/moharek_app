-- ============================================================
-- Fix: get_latest_metrics — return all ecom_metrics fields
-- including clicks, impressions, add_to_cart added in v2
-- Must DROP first because return type (OUT params) changed.
-- ============================================================

-- Drop old version so we can change the return type
DROP FUNCTION IF EXISTS public.get_latest_metrics(uuid);

CREATE OR REPLACE FUNCTION public.get_latest_metrics(p_project_id uuid)
RETURNS TABLE (
  id             uuid,
  total_sales    numeric,
  prev_sales     numeric,
  orders_count   int,
  prev_orders    int,
  roas           numeric,
  prev_roas      numeric,
  conversion_rate    numeric,
  prev_conversion_rate numeric,
  net_profit     numeric,
  ad_spend       numeric,
  clicks         int,
  impressions    int,
  add_to_cart    int,
  currency       text,
  period_start   date,
  period_end     date,
  is_published   boolean,
  published_at   timestamptz
)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT
    id,
    total_sales, prev_sales,
    orders_count, prev_orders,
    roas, prev_roas,
    conversion_rate,
    COALESCE(prev_conversion_rate, 0),
    net_profit,
    COALESCE(ad_spend, 0),
    COALESCE(clicks, 0),
    COALESCE(impressions, 0),
    COALESCE(add_to_cart, 0),
    COALESCE(currency, 'SAR'),
    period_start, period_end,
    is_published,
    published_at
  FROM public.ecom_metrics
  WHERE project_id = p_project_id
    AND is_published = true
  ORDER BY period_end DESC
  LIMIT 1;
$$;

-- Grant to authenticated users (clients read their own via RLS on ecom_metrics)
GRANT EXECUTE ON FUNCTION public.get_latest_metrics(uuid) TO authenticated;

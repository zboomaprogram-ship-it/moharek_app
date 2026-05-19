-- ============================================================
-- RABHAN AUTOMATED NOTIFICATIONS & ALERTS
-- Run this script in your Supabase SQL Editor.
-- ============================================================

-- ------------------------------------------------------------
-- 1. E-COMMERCE METRICS UPDATE TRIGGER
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.on_metrics_published()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_company_name TEXT;
BEGIN
  -- Only trigger when a report changes from unpublished to published, or is inserted as published
  IF (TG_OP = 'INSERT' AND NEW.is_published = true) OR 
     (TG_OP = 'UPDATE' AND NEW.is_published = true AND (OLD.is_published = false OR OLD.is_published IS NULL)) THEN
     
    -- Get client ID and Company Name
    SELECT client_id, name INTO v_client_id, v_company_name
    FROM public.projects
    WHERE id = NEW.project_id;
    
    IF v_client_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        user_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        link_path
      ) VALUES (
        v_client_id,
        '📈 تحديث أداء المتجر جديد لـ ' || COALESCE(v_company_name, 'متجرك'),
        '📈 New E-commerce Performance Update',
        'تم نشر تقرير مبيعات وأداء جديد لمتجرك للفترة من ' || NEW.period_start || ' إلى ' || NEW.period_end || '. تفقد النتائج الآن.',
        'A new sales and performance report has been published for your store from ' || NEW.period_start || ' to ' || NEW.period_end || '.',
        'metrics',
        '/dashboard/analytics'
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_metrics_published ON public.ecom_metrics;
CREATE TRIGGER trigger_metrics_published
  AFTER INSERT OR UPDATE ON public.ecom_metrics
  FOR EACH ROW
  EXECUTE FUNCTION public.on_metrics_published();

-- ------------------------------------------------------------
-- 2. PACKAGE EXPIRY ALERT CHECK (CRON OR SCHEDULED CALL)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_expiring_packages()
RETURNS TABLE (notified_count INT) AS $$
DECLARE
  v_pkg RECORD;
  v_client_id UUID;
  v_company_name TEXT;
  v_inserted_count INT := 0;
BEGIN
  -- Find packages expiring in exactly 3 days (or between 2 and 3 days from now)
  -- and make sure we don't spam duplicate alerts within 24 hours
  FOR v_pkg IN 
    SELECT p.id, p.project_id, p.package_name, p.renews_at
    FROM public.packages p
    WHERE p.status = 'active'
      AND p.renews_at >= (now() + interval '2 days')
      AND p.renews_at <= (now() + interval '3 days')
  LOOP
    -- Get client details
    SELECT client_id, name INTO v_client_id, v_company_name
    FROM public.projects
    WHERE id = v_pkg.project_id;
    
    IF v_client_id IS NOT NULL THEN
      -- Ensure no similar notification was sent in the last 3 days to prevent spam
      IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = v_client_id 
          AND type = 'package_alert'
          AND created_at >= (now() - interval '3 days')
      ) THEN
        INSERT INTO public.notifications (
          user_id,
          title_ar,
          title_en,
          body_ar,
          body_en,
          type,
          link_path
        ) VALUES (
          v_client_id,
          '⚠️ تنبيه: قُرب انتهاء باقة ' || COALESCE(v_pkg.package_name, 'النمو'),
          '⚠️ Alert: Package Expiring Soon',
          'باقة ' || COALESCE(v_pkg.package_name, 'النمو') || ' لـ ' || COALESCE(v_company_name, 'متجرك') || ' ستنتهي خلال 3 أيام بتاريخ ' || v_pkg.renews_at::date || '.',
          'Your ' || COALESCE(v_pkg.package_name, 'Growth') || ' subscription is set to expire in 3 days on ' || v_pkg.renews_at::date || '.',
          'package_alert',
          '/dashboard/growth'
        );
        v_inserted_count := v_inserted_count + 1;
      END IF;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT v_inserted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------
-- CRON JOB SCHEDULING (Optional, requires pg_cron enabled in Supabase)
-- ------------------------------------------------------------
-- To schedule this to run automatically every day at 8:00 AM:
-- SELECT cron.schedule('package-expiry-alert-daily', '0 8 * * *', 'SELECT public.check_expiring_packages()');
